package com.inschemes.app

import android.app.Activity
import android.os.Bundle
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale
import java.util.UUID

class SpeechOutputBridge(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, TextToSpeech.OnInitListener {
    companion object {
        private const val CHANNEL = "com.inschemes.app/speech_output"
    }

    private val channel = MethodChannel(messenger, CHANNEL)
    private var textToSpeech: TextToSpeech? = null
    private var initialized = false
    private var disposed = false

    init {
        channel.setMethodCallHandler(this)
        textToSpeech = TextToSpeech(activity.applicationContext, this)
    }

    override fun onInit(status: Int) {
        if (disposed) return
        initialized = status == TextToSpeech.SUCCESS
        textToSpeech?.setOnUtteranceProgressListener(
            object : UtteranceProgressListener() {
                override fun onStart(utteranceId: String?) {
                    emit("started", utteranceId)
                }

                override fun onDone(utteranceId: String?) {
                    emit("completed", utteranceId)
                }

                @Deprecated("Deprecated in Java")
                override fun onError(utteranceId: String?) {
                    emit("error", utteranceId)
                }

                override fun onError(utteranceId: String?, errorCode: Int) {
                    emit("error", utteranceId, errorCode)
                }
            },
        )
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (disposed && call.method != "dispose") {
            result.error("disposed", "Speech output is disposed.", null)
            return
        }
        when (call.method) {
            "capabilities" -> capabilities(result)
            "speak" -> speak(call, result)
            "stop" -> {
                textToSpeech?.stop()
                result.success(null)
            }
            "dispose" -> {
                dispose()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun capabilities(result: MethodChannel.Result) {
        val engine = textToSpeech
        if (!initialized || engine == null) {
            result.success(
                mapOf(
                    "available" to false,
                    "english" to false,
                    "tamil" to false,
                ),
            )
            return
        }
        result.success(
            mapOf(
                "available" to true,
                "english" to supports(engine, Locale("en", "IN")),
                "tamil" to supports(engine, Locale("ta", "IN")),
            ),
        )
    }

    private fun speak(call: MethodCall, result: MethodChannel.Result) {
        val engine = textToSpeech
        val text = call.argument<String>("text")?.trim().orEmpty()
        val languageTag = call.argument<String>("languageTag") ?: "en-IN"
        if (!initialized || engine == null) {
            result.error("unavailable", "Text-to-speech is not ready.", null)
            return
        }
        if (text.isEmpty()) {
            result.error("empty_text", "Speech text cannot be empty.", null)
            return
        }

        val locale = Locale.forLanguageTag(languageTag)
        if (!supports(engine, locale) || engine.setLanguage(locale) < TextToSpeech.LANG_AVAILABLE) {
            result.error("language_unavailable", "$languageTag text-to-speech is unavailable.", null)
            return
        }

        val utteranceId = UUID.randomUUID().toString()
        val status = engine.speak(text, TextToSpeech.QUEUE_FLUSH, Bundle(), utteranceId)
        if (status == TextToSpeech.ERROR) {
            result.error("speak_failed", "Text-to-speech could not start.", null)
            return
        }
        result.success(utteranceId)
    }

    private fun supports(engine: TextToSpeech, locale: Locale): Boolean {
        return engine.isLanguageAvailable(locale) >= TextToSpeech.LANG_AVAILABLE
    }

    private fun emit(event: String, utteranceId: String?, errorCode: Int? = null) {
        activity.runOnUiThread {
            if (disposed) return@runOnUiThread
            channel.invokeMethod(
                "speechEvent",
                mapOf(
                    "event" to event,
                    "utteranceId" to utteranceId,
                    "errorCode" to errorCode,
                ),
            )
        }
    }

    fun dispose() {
        if (disposed) return
        disposed = true
        initialized = false
        channel.setMethodCallHandler(null)
        textToSpeech?.stop()
        textToSpeech?.shutdown()
        textToSpeech = null
    }
}
