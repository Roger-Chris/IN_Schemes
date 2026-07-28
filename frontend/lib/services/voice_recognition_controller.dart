import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

typedef VoiceStatusCallback = void Function(String status);
typedef VoiceResultCallback = void Function(VoiceRecognitionResult result);
typedef VoiceSoundLevelCallback = void Function(double level);
typedef VoiceLanguageCallback = void Function(String language);
typedef VoiceErrorCallback = void Function(VoiceRecognitionError error);

class VoiceRecognitionCapabilities {
  const VoiceRecognitionCapabilities({
    required this.available,
    required this.automaticLanguageDetection,
    this.reason,
  });

  final bool available;
  final bool automaticLanguageDetection;
  final String? reason;
}

class VoiceRecognitionResult {
  const VoiceRecognitionResult({
    required this.transcript,
    required this.isFinal,
  });

  final String transcript;
  final bool isFinal;
}

class VoiceRecognitionError {
  const VoiceRecognitionError({
    required this.code,
    required this.message,
    this.automaticUnavailable = false,
  });

  final String code;
  final String message;
  final bool automaticUnavailable;
}

abstract class VoiceRecognitionController {
  bool get isListening;

  Future<VoiceRecognitionCapabilities> initialize({
    required VoiceStatusCallback onStatus,
    required VoiceResultCallback onResult,
    required VoiceSoundLevelCallback onSoundLevel,
    required VoiceLanguageCallback onLanguage,
    required VoiceErrorCallback onError,
  });

  /// A null [localeId] requests automatic English/Tamil switching. Supplying a
  /// locale explicitly starts the compatibility recognizer for that language.
  Future<void> listen({String? localeId});

  Future<void> stop();

  Future<void> cancel();

  Future<void> dispose();
}

/// Uses the Android 14 native bridge for automatic English/Tamil switching and
/// keeps speech_to_text as the permission and compatibility implementation.
class AutomaticVoiceRecognitionController
    implements VoiceRecognitionController {
  static const MethodChannel _methodChannel = MethodChannel(
    'com.inschemes.app/automatic_speech',
  );
  static const EventChannel _eventChannel = EventChannel(
    'com.inschemes.app/automatic_speech_events',
  );

  final SpeechToText _fallback = SpeechToText();
  StreamSubscription<dynamic>? _nativeEvents;
  VoiceStatusCallback _onStatus = (_) {};
  VoiceResultCallback _onResult = (_) {};
  VoiceSoundLevelCallback _onSoundLevel = (_) {};
  VoiceLanguageCallback _onLanguage = (_) {};
  VoiceErrorCallback _onError = (_) {};
  VoiceRecognitionCapabilities? _capabilities;
  bool _automaticAvailable = false;
  bool _usingNative = false;
  bool _disposed = false;
  bool _isListening = false;
  int _sessionId = 0;

  @override
  bool get isListening => _isListening;

  @override
  Future<VoiceRecognitionCapabilities> initialize({
    required VoiceStatusCallback onStatus,
    required VoiceResultCallback onResult,
    required VoiceSoundLevelCallback onSoundLevel,
    required VoiceLanguageCallback onLanguage,
    required VoiceErrorCallback onError,
  }) async {
    _onStatus = onStatus;
    _onResult = onResult;
    _onSoundLevel = onSoundLevel;
    _onLanguage = onLanguage;
    _onError = onError;

    final existing = _capabilities;
    if (existing != null) return existing;

    final fallbackAvailable = await _fallback.initialize(
      onStatus: _handleFallbackStatus,
      onError: (error) {
        if (_usingNative || _disposed) return;
        _isListening = false;
        _onError(
          VoiceRecognitionError(
            code: error.errorMsg,
            message: error.errorMsg == 'error_permission'
                ? 'Microphone permission is needed for voice search.'
                : 'I could not hear you. Tap the microphone to try again.',
          ),
        );
      },
    );

    if (!fallbackAvailable) {
      var hasPermission = false;
      try {
        hasPermission = await _fallback.hasPermission;
      } on Exception {
        // Treat an inaccessible permission state as unavailable recognition.
      }
      return _capabilities = VoiceRecognitionCapabilities(
        available: false,
        automaticLanguageDetection: false,
        reason: hasPermission
            ? 'Voice recognition is not available on this device.'
            : 'Microphone permission is needed for voice search.',
      );
    }

    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return _capabilities = const VoiceRecognitionCapabilities(
        available: true,
        automaticLanguageDetection: false,
        reason:
            'Automatic English/Tamil detection is available on Android 14 or newer.',
      );
    }

    try {
      _nativeEvents ??= _eventChannel.receiveBroadcastStream().listen(
        _handleNativeEvent,
        onError: (_) {
          if (_disposed || !_usingNative) return;
          const reason =
              'Automatic language detection stopped. Choose English or Tamil to continue.';
          _markAutomaticUnavailable(reason);
          _isListening = false;
          _onError(
            const VoiceRecognitionError(
              code: 'native_event_error',
              message: reason,
              automaticUnavailable: true,
            ),
          );
        },
      );
      final response = await _methodChannel.invokeMapMethod<String, dynamic>(
        'capabilities',
      );
      final available = response?['available'] == true;
      _automaticAvailable =
          available && response?['automaticLanguageDetection'] == true;
      return _capabilities = VoiceRecognitionCapabilities(
        available: available,
        automaticLanguageDetection: _automaticAvailable,
        reason: response?['reason'] as String?,
      );
    } on PlatformException catch (error) {
      return _capabilities = VoiceRecognitionCapabilities(
        available: true,
        automaticLanguageDetection: false,
        reason:
            error.message ??
            'Automatic language detection is unavailable on this device.',
      );
    } on MissingPluginException {
      return _capabilities = const VoiceRecognitionCapabilities(
        available: true,
        automaticLanguageDetection: false,
        reason: 'Automatic language detection is unavailable on this device.',
      );
    }
  }

  @override
  Future<void> listen({String? localeId}) async {
    if (_disposed) return;
    final capabilities = _capabilities;
    if (capabilities == null || !capabilities.available) {
      _onError(
        const VoiceRecognitionError(
          code: 'recognizer_unavailable',
          message: 'Voice recognition is not available on this device.',
        ),
      );
      return;
    }

    await cancel();
    final currentSession = ++_sessionId;
    if (_automaticAvailable && localeId == null) {
      _usingNative = true;
      try {
        await _methodChannel.invokeMethod<void>('start', {
          'sessionId': currentSession,
          'preferredLocale': _preferredAutomaticLocale,
        });
        if (_sessionId != currentSession || _disposed) return;
        _isListening = true;
        return;
      } on PlatformException catch (error) {
        if (_sessionId != currentSession || _disposed) return;
        _usingNative = false;
        _isListening = false;
        final automaticUnavailable = const {
          'automatic_language_unsupported',
          'recognizer_unavailable',
          'language_not_supported',
          'language_unavailable',
        }.contains(error.code);
        if (automaticUnavailable) {
          _markAutomaticUnavailable(
            error.message ??
                'Automatic language detection is unavailable on this device.',
          );
        }
        _onError(
          VoiceRecognitionError(
            code: error.code,
            message:
                error.message ??
                'Automatic language detection could not start. Please try again.',
            automaticUnavailable: automaticUnavailable,
          ),
        );
        return;
      }
    }

    _usingNative = false;
    _isListening = true;
    await _fallback.listen(
      onResult: _handleFallbackResult,
      onSoundLevelChange: _onSoundLevel,
      listenOptions: SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
        listenMode: ListenMode.search,
        autoPunctuation: true,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        localeId: await _localeIdFor(localeId ?? 'en-IN'),
      ),
    );
  }

  String get _preferredAutomaticLocale {
    final language = PlatformDispatcher.instance.locale.languageCode;
    return language == 'ta' ? 'ta-IN' : 'en-IN';
  }

  Future<String?> _localeIdFor(String requested) async {
    final normalizedRequested = requested.toLowerCase().replaceAll('_', '-');
    final requestedLanguage = normalizedRequested.split('-').first;
    try {
      final locales = await _fallback.locales();
      for (final locale in locales) {
        final normalized = locale.localeId.toLowerCase().replaceAll('_', '-');
        if (normalized == normalizedRequested) return locale.localeId;
      }
      for (final locale in locales) {
        final normalized = locale.localeId.toLowerCase().replaceAll('_', '-');
        if (normalized.startsWith('$requestedLanguage-')) {
          return locale.localeId;
        }
      }
    } on Exception {
      // The platform default is safer than failing the compatibility session.
    }
    return null;
  }

  void _handleFallbackResult(SpeechRecognitionResult result) {
    if (_disposed || _usingNative) return;
    _onResult(
      VoiceRecognitionResult(
        transcript: result.recognizedWords,
        isFinal: result.finalResult,
      ),
    );
  }

  void _handleFallbackStatus(String status) {
    if (_disposed || _usingNative) return;
    _isListening = status == SpeechToText.listeningStatus;
    _onStatus(status);
  }

  void _handleNativeEvent(dynamic rawEvent) {
    if (_disposed || !_usingNative || rawEvent is! Map) return;
    final event = Map<Object?, Object?>.from(rawEvent);
    final eventSession = event['sessionId'];
    if (eventSession is! int || eventSession != _sessionId) return;
    switch (event['type']) {
      case 'status':
        final status = event['status'];
        if (status is! String) return;
        _isListening = status == 'listening' || status == 'processing';
        _onStatus(status);
      case 'result':
        final transcript = event['transcript'];
        if (transcript is! String) return;
        _onResult(
          VoiceRecognitionResult(
            transcript: transcript,
            isFinal: event['final'] == true,
          ),
        );
      case 'level':
        final level = event['level'];
        if (level is num) _onSoundLevel(level.toDouble());
      case 'language':
        final language = event['language'];
        if (language is String) _onLanguage(language);
      case 'error':
        _isListening = false;
        final automaticUnavailable = event['automaticUnavailable'] == true;
        if (automaticUnavailable) {
          _markAutomaticUnavailable(
            event['message'] as String? ??
                'Automatic language detection is unavailable on this device.',
          );
        }
        _onError(
          VoiceRecognitionError(
            code: event['code'] as String? ?? 'unknown',
            message:
                event['message'] as String? ??
                'Voice recognition could not continue. Please try again.',
            automaticUnavailable: automaticUnavailable,
          ),
        );
    }
  }

  void _markAutomaticUnavailable(String reason) {
    _automaticAvailable = false;
    final current = _capabilities;
    if (current == null) return;
    _capabilities = VoiceRecognitionCapabilities(
      available: current.available,
      automaticLanguageDetection: false,
      reason: reason,
    );
  }

  @override
  Future<void> stop() async {
    if (_disposed) return;
    if (_usingNative) {
      await _methodChannel.invokeMethod<void>('stop');
    } else {
      await _fallback.stop();
    }
    _isListening = false;
  }

  @override
  Future<void> cancel() async {
    if (_disposed) return;
    _sessionId++;
    _isListening = false;
    if (_usingNative) {
      try {
        await _methodChannel.invokeMethod<void>('cancel');
      } on MissingPluginException {
        // Compatibility-only platforms do not register the native channel.
      }
    } else {
      await _fallback.cancel();
    }
    _usingNative = false;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    await cancel();
    _disposed = true;
    await _nativeEvents?.cancel();
    _nativeEvents = null;
    try {
      await _methodChannel.invokeMethod<void>('dispose');
    } on MissingPluginException {
      // Compatibility-only platforms do not register the native channel.
    }
  }
}
