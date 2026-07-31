import 'dart:async';

import 'package:flutter/services.dart';

import 'voice_agent_preferences.dart';

class SpeechOutputCapabilities {
  const SpeechOutputCapabilities({
    required this.available,
    required this.english,
    required this.tamil,
    this.englishVoice,
    this.tamilVoice,
  });

  final bool available;
  final bool english;
  final bool tamil;
  final String? englishVoice;
  final String? tamilVoice;

  bool supports(String languageTag) =>
      languageTag.toLowerCase().startsWith('ta') ? tamil : english;
}

abstract interface class SpeechOutputController {
  Future<SpeechOutputCapabilities> initialize();
  Future<bool> speak(String text, {required String languageTag});
  Future<void> stop();
  Future<void> dispose();
}

class NativeSpeechOutputController implements SpeechOutputController {
  NativeSpeechOutputController({MethodChannel? channel, String? preferredVoice})
    : _channel = channel ?? const MethodChannel(_channelName),
      _preferredVoice = preferredVoice;

  static const _channelName = 'com.inschemes.app/speech_output';
  final MethodChannel _channel;
  final String? _preferredVoice;
  final Map<String, Completer<bool>> _utterances = {};
  final Map<String, bool> _earlyTerminalEvents = {};
  SpeechOutputCapabilities? _capabilities;
  bool _disposed = false;

  @override
  Future<SpeechOutputCapabilities> initialize() async {
    if (_capabilities != null) return _capabilities!;
    _channel.setMethodCallHandler(_handleNativeCall);
    try {
      final response = await _channel.invokeMapMethod<String, dynamic>(
        'capabilities',
      );
      return _capabilities = SpeechOutputCapabilities(
        available: response?['available'] == true,
        english: response?['english'] == true,
        tamil: response?['tamil'] == true,
        englishVoice: response?['englishVoice'] as String?,
        tamilVoice: response?['tamilVoice'] as String?,
      );
    } on PlatformException {
      return _unavailableCapabilities();
    } on MissingPluginException {
      return _unavailableCapabilities();
    }
  }

  SpeechOutputCapabilities _unavailableCapabilities() {
    return _capabilities = const SpeechOutputCapabilities(
      available: false,
      english: false,
      tamil: false,
    );
  }

  @override
  Future<bool> speak(String text, {required String languageTag}) async {
    if (_disposed || text.trim().isEmpty) return false;
    final capabilities = await initialize();
    if (!capabilities.supports(languageTag)) return false;
    try {
      final voiceStyle = _preferredVoice ?? await _loadPersistedVoiceStyle();
      final utteranceId = await _channel.invokeMethod<String>('speak', {
        'text': text.trim(),
        'languageTag': languageTag,
        'voiceStyle': voiceStyle,
      });
      if (utteranceId == null) return false;
      final completer = Completer<bool>();
      _utterances[utteranceId] = completer;
      final earlyResult = _earlyTerminalEvents.remove(utteranceId);
      if (earlyResult != null) {
        _utterances.remove(utteranceId);
        return earlyResult;
      }
      final estimatedSeconds = (text.trim().length / 11).ceil() + 8;
      final timeoutSeconds = estimatedSeconds.clamp(15, 60);
      return await completer.future.timeout(
        Duration(seconds: timeoutSeconds),
        onTimeout: () {
          _utterances.remove(utteranceId);
          return false;
        },
      );
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<String> _loadPersistedVoiceStyle() async {
    try {
      return await VoiceAgentPreferences.loadVoice();
    } catch (_) {
      return VoiceAgentPreferences.defaultVoice;
    }
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method != 'speechEvent') return;
    final arguments = Map<String, dynamic>.from(call.arguments as Map);
    final utteranceId = arguments['utteranceId'] as String?;
    if (utteranceId == null) return;
    final event = arguments['event'] as String?;
    if (event != 'completed' && event != 'error') return;
    final completer = _utterances.remove(utteranceId);
    if (completer != null && !completer.isCompleted) {
      completer.complete(event == 'completed');
    } else {
      // A very short utterance can finish before invokeMethod returns its ID.
      _earlyTerminalEvents[utteranceId] = event == 'completed';
    }
  }

  @override
  Future<void> stop() async {
    if (_disposed) return;
    for (final completer in _utterances.values) {
      if (!completer.isCompleted) completer.complete(false);
    }
    _utterances.clear();
    _earlyTerminalEvents.clear();
    try {
      await _channel.invokeMethod<void>('stop');
    } on PlatformException {
      // The displayed question remains usable when native TTS is unavailable.
    } on MissingPluginException {
      // The displayed question remains usable when native TTS is unavailable.
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    await stop();
    _disposed = true;
    _channel.setMethodCallHandler(null);
    // SpeechOutputBridge belongs to the Activity, not an individual overlay.
    // MainActivity cleans it up with the FlutterEngine. Disposing it here would
    // leave future Regular/Companion sessions without a method-channel handler.
  }
}
