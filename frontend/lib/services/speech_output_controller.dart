import 'dart:async';

import 'package:flutter/services.dart';

class SpeechOutputCapabilities {
  const SpeechOutputCapabilities({
    required this.available,
    required this.english,
    required this.tamil,
  });

  final bool available;
  final bool english;
  final bool tamil;

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
  NativeSpeechOutputController({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = 'com.inschemes.app/speech_output';
  final MethodChannel _channel;
  final Map<String, Completer<bool>> _utterances = {};
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
      final utteranceId = await _channel.invokeMethod<String>('speak', {
        'text': text.trim(),
        'languageTag': languageTag,
      });
      if (utteranceId == null) return false;
      final completer = Completer<bool>();
      _utterances[utteranceId] = completer;
      return await completer.future.timeout(
        const Duration(seconds: 15),
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
    }
  }

  @override
  Future<void> stop() async {
    if (_disposed) return;
    for (final completer in _utterances.values) {
      if (!completer.isCompleted) completer.complete(false);
    }
    _utterances.clear();
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
