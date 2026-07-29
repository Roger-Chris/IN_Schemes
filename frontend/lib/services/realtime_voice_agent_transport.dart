import 'dart:async';
import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'voice_agent_controller.dart';

class RealtimeVoiceAgentTransport implements VoiceAgentTransport {
  RealtimeVoiceAgentTransport({
    SupabaseClient? supabase,
    http.Client? httpClient,
  }) : _supabase = supabase ?? Supabase.instance.client,
       _http = httpClient ?? http.Client();

  final SupabaseClient _supabase;
  static RealtimeVoiceAgentTransport? _activeTransport;
  final http.Client _http;
  final StreamController<Map<String, Object?>> _events =
      StreamController<Map<String, Object?>>.broadcast();
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  MediaStream? _localStream;
  Timer? _levelTimer;
  int _generation = 0;
  bool _closed = true;

  @override
  Stream<Map<String, Object?>> get events => _events.stream;

  @override
  Future<void> connect(VoiceAgentTransportConfig config) async {
    final previous = _activeTransport;
    if (previous != null && !identical(previous, this)) {
      await previous.close();
    }
    _activeTransport = this;
    await close();
    _activeTransport = this;
    final generation = ++_generation;
    _closed = false;

    final accessToken = _supabase.auth.currentSession?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw StateError('Sign in is required for cloud voice.');
    }
    final response = await _supabase.functions.invoke(
      'realtime-session',
      body: {'surface': config.surface.name, 'voice': config.voice},
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.status < 200 || response.status >= 300) {
      throw StateError('Voice session service returned ${response.status}.');
    }
    final data = response.data;
    if (data is! Map) throw StateError('Invalid voice session response.');
    final secret = data['client_secret'];
    final ephemeralKey = secret is Map
        ? secret['value']?.toString()
        : secret?.toString();
    if (ephemeralKey == null || ephemeralKey.isEmpty) {
      throw StateError('Voice session did not include a client secret.');
    }

    final localStream = await navigator.mediaDevices.getUserMedia({
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': false,
    });
    if (_closed || generation != _generation) {
      for (final track in localStream.getTracks()) {
        await track.stop();
      }
      return;
    }
    _localStream = localStream;
    final peerConnection = await createPeerConnection({
      'iceServers': const [],
      'sdpSemantics': 'unified-plan',
    });
    _peerConnection = peerConnection;
    for (final track in localStream.getAudioTracks()) {
      await peerConnection.addTrack(track, localStream);
    }
    peerConnection.onTrack = (event) async {
      if (event.track.kind == 'audio') {
        await Helper.setSpeakerphoneOn(true);
      }
    };
    peerConnection.onConnectionState = (state) {
      if (_closed || generation != _generation) return;
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _events.add({
          'type': 'error',
          'error': {'message': 'Realtime voice connection was interrupted.'},
        });
      }
    };
    final dataChannel = await peerConnection.createDataChannel(
      'oai-events',
      RTCDataChannelInit()..ordered = true,
    );
    _dataChannel = dataChannel;
    final dataChannelOpened = Completer<void>();
    dataChannel.onDataChannelState = (state) {
      if (state == RTCDataChannelState.RTCDataChannelOpen &&
          !dataChannelOpened.isCompleted) {
        dataChannelOpened.complete();
      } else if (state == RTCDataChannelState.RTCDataChannelClosed &&
          !dataChannelOpened.isCompleted) {
        dataChannelOpened.completeError(
          StateError('Realtime data channel closed during setup.'),
        );
      }
    };
    dataChannel.onMessage = (message) {
      if (_closed || generation != _generation || message.isBinary) return;
      try {
        final decoded = jsonDecode(message.text);
        if (decoded is Map<String, dynamic>) {
          _events.add(Map<String, Object?>.from(decoded));
        }
      } catch (_) {
        _events.add({
          'type': 'error',
          'error': {'message': 'Received an invalid voice event.'},
        });
      }
    };

    final offer = await peerConnection.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': false,
    });
    await peerConnection.setLocalDescription(offer);
    final sdpResponse = await _http.post(
      Uri.parse('https://api.openai.com/v1/realtime/calls'),
      headers: {
        'Authorization': 'Bearer $ephemeralKey',
        'Content-Type': 'application/sdp',
      },
      body: offer.sdp,
    );
    if (sdpResponse.statusCode < 200 || sdpResponse.statusCode >= 300) {
      throw StateError(
        'Realtime negotiation failed (${sdpResponse.statusCode}).',
      );
    }
    await peerConnection.setRemoteDescription(
      RTCSessionDescription(sdpResponse.body, 'answer'),
    );
    await dataChannelOpened.future.timeout(const Duration(seconds: 12));
    _startAudioLevelPolling(generation);
  }

  @override
  Future<void> send(Map<String, Object?> event) async {
    final channel = _dataChannel;
    if (_closed ||
        channel == null ||
        channel.state != RTCDataChannelState.RTCDataChannelOpen) {
      throw StateError('Realtime data channel is not open.');
    }
    await channel.send(RTCDataChannelMessage(jsonEncode(event)));
  }

  @override
  Future<void> setMuted(bool muted) async {
    for (final track
        in _localStream?.getAudioTracks() ?? const <MediaStreamTrack>[]) {
      track.enabled = !muted;
    }
  }

  void _startAudioLevelPolling(int generation) {
    _levelTimer?.cancel();
    _levelTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      if (_closed || generation != _generation) return;
      try {
        final reports = await _peerConnection?.getStats();
        double? level;
        for (final report in reports ?? const <StatsReport>[]) {
          if (report.type != 'media-source' && report.type != 'outbound-rtp') {
            continue;
          }
          final raw = report.values['audioLevel'];
          if (raw is num) level = raw.toDouble();
        }
        if (level != null) {
          _events.add({
            'type': 'client.audio_level',
            'level': level.clamp(0.0, 1.0),
          });
        }
      } catch (_) {
        // VAD speech events still animate the UI when audioLevel is absent.
      }
    });
  }

  @override
  Future<void> close() async {
    _closed = true;
    _generation++;
    _levelTimer?.cancel();
    _levelTimer = null;
    final stream = _localStream;
    _localStream = null;
    for (final track in stream?.getTracks() ?? const <MediaStreamTrack>[]) {
      await track.stop();
    }
    await stream?.dispose();
    await _dataChannel?.close();
    _dataChannel = null;
    await _peerConnection?.close();
    await _peerConnection?.dispose();
    _peerConnection = null;
    if (identical(_activeTransport, this)) _activeTransport = null;
  }

  Future<void> dispose() async {
    await close();
    _http.close();
    await _events.close();
  }
}
