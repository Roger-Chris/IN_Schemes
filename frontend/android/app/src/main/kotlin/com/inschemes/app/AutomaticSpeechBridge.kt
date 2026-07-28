package com.inschemes.app

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

/**
 * App-specific SpeechRecognizer bridge for Android 14's runtime language
 * detection and switching APIs. Each recognition session owns its listener so
 * delayed callbacks can never be attributed to a newer Flutter session.
 */
class AutomaticSpeechBridge(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    companion object {
        private const val METHOD_CHANNEL = "com.inschemes.app/automatic_speech"
        private const val EVENT_CHANNEL = "com.inschemes.app/automatic_speech_events"
        private const val MAX_LISTENING_MILLIS = 30_000L
        private val ALLOWED_LANGUAGES = arrayListOf("en-IN", "ta-IN")
    }

    private val methodChannel = MethodChannel(messenger, METHOD_CHANNEL)
    private val eventChannel = EventChannel(messenger, EVENT_CHANNEL)
    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null
    private var recognizer: SpeechRecognizer? = null
    private var activeSessionId: Int? = null
    private var timeout: Runnable? = null

    init {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "capabilities" -> result.success(capabilities())
            "start" -> start(call, result)
            "stop" -> {
                stop()
                result.success(null)
            }
            "cancel" -> {
                cancelCurrent()
                result.success(null)
            }
            "dispose" -> {
                disposeRecognizer()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun capabilities(): Map<String, Any?> {
        val recognitionAvailable = SpeechRecognizer.isRecognitionAvailable(activity)
        val automaticSupported =
            recognitionAvailable && Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE
        val reason = when {
            !recognitionAvailable -> "Voice recognition is not available on this device."
            Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE ->
                "Automatic language detection requires Android 14 or newer."
            else -> null
        }
        return mapOf(
            "available" to recognitionAvailable,
            "automaticLanguageDetection" to automaticSupported,
            "apiLevel" to Build.VERSION.SDK_INT,
            "reason" to reason,
        )
    }

    private fun start(call: MethodCall, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            result.error(
                "automatic_language_unsupported",
                "Automatic language detection requires Android 14 or newer.",
                null,
            )
            return
        }
        if (!SpeechRecognizer.isRecognitionAvailable(activity)) {
            result.error(
                "recognizer_unavailable",
                "Voice recognition is not available on this device.",
                null,
            )
            return
        }
        if (activity.checkSelfPermission(Manifest.permission.RECORD_AUDIO) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            result.error(
                "permission_denied",
                "Microphone permission is needed for voice search.",
                null,
            )
            return
        }

        val sessionId = call.argument<Int>("sessionId")
        if (sessionId == null) {
            result.error("invalid_session", "A session id is required.", null)
            return
        }
        val preferredLocale = normalizeInitialLocale(call.argument<String>("preferredLocale"))

        cancelCurrent()
        val sessionRecognizer = SpeechRecognizer.createSpeechRecognizer(activity)
        recognizer = sessionRecognizer
        activeSessionId = sessionId
        sessionRecognizer.setRecognitionListener(SessionListener(sessionId, preferredLocale))

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(
                RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM,
            )
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, preferredLocale)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 5)
            // The A059 recognizer otherwise endpoints before users finish a
            // natural Tamil sentence or even have time to begin speaking.
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, 2_500L)
            putExtra(
                RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS,
                1_000L,
            )
            putExtra(
                RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS,
                1_600L,
            )
            putExtra(RecognizerIntent.EXTRA_ENABLE_LANGUAGE_DETECTION, true)
            putExtra(
                RecognizerIntent.EXTRA_ENABLE_LANGUAGE_SWITCH,
                RecognizerIntent.LANGUAGE_SWITCH_QUICK_RESPONSE,
            )
            putStringArrayListExtra(
                RecognizerIntent.EXTRA_LANGUAGE_DETECTION_ALLOWED_LANGUAGES,
                ArrayList(ALLOWED_LANGUAGES),
            )
            putStringArrayListExtra(
                RecognizerIntent.EXTRA_LANGUAGE_SWITCH_ALLOWED_LANGUAGES,
                ArrayList(ALLOWED_LANGUAGES),
            )
        }

        try {
            sessionRecognizer.startListening(intent)
            scheduleTimeout(sessionId)
            result.success(mapOf("started" to true, "sessionId" to sessionId))
        } catch (error: RuntimeException) {
            disposeSession(sessionId)
            result.error(
                "recognizer_start_failed",
                error.message ?: "Voice recognition could not start.",
                null,
            )
        }
    }

    private fun normalizeInitialLocale(requested: String?): String {
        val normalized = requested?.replace('_', '-')
        if (normalized?.startsWith("ta", ignoreCase = true) == true) return "ta-IN"
        if (normalized?.startsWith("en", ignoreCase = true) == true) return "en-IN"
        return if (Locale.getDefault().language == "ta") "ta-IN" else "en-IN"
    }

    private fun scheduleTimeout(sessionId: Int) {
        clearTimeout()
        timeout = Runnable {
            if (activeSessionId == sessionId) recognizer?.stopListening()
        }.also { mainHandler.postDelayed(it, MAX_LISTENING_MILLIS) }
    }

    private fun clearTimeout() {
        timeout?.let(mainHandler::removeCallbacks)
        timeout = null
    }

    private fun stop() {
        clearTimeout()
        recognizer?.stopListening()
    }

    private fun cancelCurrent() {
        clearTimeout()
        activeSessionId = null
        recognizer?.cancel()
        recognizer?.destroy()
        recognizer = null
    }

    private fun disposeSession(sessionId: Int) {
        if (activeSessionId != sessionId) return
        clearTimeout()
        activeSessionId = null
        recognizer?.destroy()
        recognizer = null
    }

    private fun disposeRecognizer() {
        cancelCurrent()
    }

    fun dispose() {
        disposeRecognizer()
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        eventSink = null
    }

    private fun isActive(sessionId: Int): Boolean = activeSessionId == sessionId

    private fun emit(sessionId: Int, type: String, values: Map<String, Any?> = emptyMap()) {
        if (!isActive(sessionId)) return
        eventSink?.success(mapOf("sessionId" to sessionId, "type" to type) + values)
    }

    private inner class SessionListener(
        private val sessionId: Int,
        initialLanguage: String,
    ) : RecognitionListener {
        private var detectedLanguage: String? = initialLanguage

        override fun onReadyForSpeech(params: Bundle?) {
            emit(sessionId, "status", mapOf("status" to "listening"))
        }

        override fun onBeginningOfSpeech() {
            emit(sessionId, "status", mapOf("status" to "listening"))
        }

        override fun onRmsChanged(rmsdB: Float) {
            emit(sessionId, "level", mapOf("level" to rmsdB.toDouble()))
        }

        override fun onBufferReceived(buffer: ByteArray?) = Unit

        override fun onEndOfSpeech() {
            emit(sessionId, "status", mapOf("status" to "processing"))
        }

        override fun onError(error: Int) {
            if (!isActive(sessionId)) return
            val code = errorCode(error)
            val automaticUnavailable =
                error == SpeechRecognizer.ERROR_LANGUAGE_NOT_SUPPORTED ||
                    error == SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE
            emit(
                sessionId,
                "error",
                mapOf(
                    "code" to code,
                    "message" to errorMessage(error),
                    "automaticUnavailable" to automaticUnavailable,
                ),
            )
            disposeSession(sessionId)
        }

        override fun onResults(results: Bundle?) {
            emitResult(results, finalResult = true)
            emit(sessionId, "status", mapOf("status" to "done"))
            disposeSession(sessionId)
        }

        override fun onPartialResults(partialResults: Bundle?) {
            emitResult(partialResults, finalResult = false)
        }

        override fun onEvent(eventType: Int, params: Bundle?) = Unit

        override fun onLanguageDetection(results: Bundle) {
            val language = results.getString(SpeechRecognizer.DETECTED_LANGUAGE) ?: return
            detectedLanguage = language
            emit(sessionId, "language", mapOf("language" to language))
        }

        private fun emitResult(bundle: Bundle?, finalResult: Boolean) {
            val transcripts = bundle
                ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                .orEmpty()
            val transcript = selectTranscript(transcripts)
            if (transcript.isEmpty()) return
            emit(
                sessionId,
                "result",
                mapOf("transcript" to transcript, "final" to finalResult),
            )
        }

        private fun selectTranscript(transcripts: List<String>): String {
            if (detectedLanguage?.startsWith("ta", ignoreCase = true) == true) {
                // Some recognizers retain an English-biased first hypothesis
                // after switching. Prefer an available Tamil-script candidate.
                transcripts.firstOrNull { candidate ->
                    candidate.any { character -> character.code in 0x0B80..0x0BFF }
                }?.let { return it }
            }
            return transcripts.firstOrNull().orEmpty()
        }
    }

    private fun errorCode(error: Int): String = when (error) {
        SpeechRecognizer.ERROR_AUDIO -> "audio"
        SpeechRecognizer.ERROR_CLIENT -> "client"
        SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "permission_denied"
        SpeechRecognizer.ERROR_LANGUAGE_NOT_SUPPORTED -> "language_not_supported"
        SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE -> "language_unavailable"
        SpeechRecognizer.ERROR_NETWORK, SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "network"
        SpeechRecognizer.ERROR_NO_MATCH -> "no_match"
        SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "recognizer_busy"
        SpeechRecognizer.ERROR_SERVER, SpeechRecognizer.ERROR_SERVER_DISCONNECTED -> "server"
        SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "speech_timeout"
        else -> "unknown"
    }

    private fun errorMessage(error: Int): String = when (error) {
        SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS ->
            "Microphone permission is needed for voice search."
        SpeechRecognizer.ERROR_LANGUAGE_NOT_SUPPORTED,
        SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE ->
            "Automatic English/Tamil detection is unavailable because a language model is missing or unsupported."
        SpeechRecognizer.ERROR_NETWORK,
        SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Check your connection and try voice search again."
        SpeechRecognizer.ERROR_NO_MATCH -> "I could not hear a clear phrase. Tap the microphone to try again."
        SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Voice recognition is busy. Please try again."
        SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "I did not hear anything. Tap the microphone to try again."
        else -> "Voice recognition could not continue. Please try again."
    }
}
