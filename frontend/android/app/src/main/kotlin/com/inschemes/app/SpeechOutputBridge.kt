package com.inschemes.app

import android.app.Activity
import android.media.AudioAttributes
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.speech.tts.Voice
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
    private var initializationFinished = false
    private var disposed = false
    private val pendingCapabilities = mutableListOf<MethodChannel.Result>()
    private val mainHandler = Handler(Looper.getMainLooper())
    private val initializationTimeout = Runnable {
        if (disposed || initializationFinished) return@Runnable
        initializationFinished = true
        initialized = false
        flushPendingCapabilities(null)
    }

    init {
        channel.setMethodCallHandler(this)
        textToSpeech = TextToSpeech(activity.applicationContext, this)
        mainHandler.postDelayed(initializationTimeout, 5_000)
    }

    override fun onInit(status: Int) {
        if (disposed) return
        mainHandler.removeCallbacks(initializationTimeout)
        initializationFinished = true
        initialized = status == TextToSpeech.SUCCESS
        val engine = textToSpeech
        engine?.setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ASSISTANT)
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                .build(),
        )
        engine?.setOnUtteranceProgressListener(
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
        flushPendingCapabilities(engine)
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
        if (!initializationFinished) {
            pendingCapabilities.add(result)
            return
        }
        result.success(capabilityMap(textToSpeech))
    }

    private fun capabilityMap(engine: TextToSpeech?): Map<String, Any?> {
        if (!initialized || engine == null) {
            return mapOf(
                "available" to false,
                "english" to false,
                "tamil" to false,
                "englishVoice" to null,
                "tamilVoice" to null,
            )
        }
        val englishLocale = Locale("en", "IN")
        val tamilLocale = Locale("ta", "IN")
        return mapOf(
            "available" to true,
            "english" to supports(engine, englishLocale),
            "tamil" to supports(engine, tamilLocale),
            "englishVoice" to bestVoice(engine, englishLocale)?.name,
            "tamilVoice" to bestVoice(engine, tamilLocale)?.name,
        )
    }

    private fun flushPendingCapabilities(engine: TextToSpeech?) {
        val capabilities = capabilityMap(engine)
        pendingCapabilities.forEach { it.success(capabilities) }
        pendingCapabilities.clear()
    }

    private fun speak(call: MethodCall, result: MethodChannel.Result) {
        val engine = textToSpeech
        val text = call.argument<String>("text")?.trim().orEmpty()
        val languageTag = call.argument<String>("languageTag") ?: "en-IN"
        val voiceStyle = call.argument<String>("voiceStyle") ?: "natural"
        if (!initialized || engine == null) {
            result.error("unavailable", "Text-to-speech is not ready.", null)
            return
        }
        if (text.isEmpty()) {
            result.error("empty_text", "Speech text cannot be empty.", null)
            return
        }

        val requestedLocale = Locale.forLanguageTag(languageTag)
        val locale = if (requestedLocale.language == "ta") {
            Locale("ta", "IN")
        } else {
            Locale("en", "IN")
        }
        if (!supports(engine, locale) || !applyVoice(engine, locale)) {
            result.error("language_unavailable", "$languageTag text-to-speech is unavailable.", null)
            return
        }
        applyProsody(engine, locale, voiceStyle)

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

    private fun applyVoice(engine: TextToSpeech, locale: Locale): Boolean {
        val voice = bestVoice(engine, locale)
        if (voice != null && engine.setVoice(voice) == TextToSpeech.SUCCESS) {
            return true
        }
        return engine.setLanguage(locale) >= TextToSpeech.LANG_AVAILABLE
    }

    /** Chooses a reliable installed voice before considering network voices. */
    private fun bestVoice(engine: TextToSpeech, locale: Locale): Voice? {
        val matching = engine.voices.orEmpty()
            .filter { voice ->
                voice.locale.language.equals(locale.language, ignoreCase = true) &&
                    !voice.features.contains(TextToSpeech.Engine.KEY_FEATURE_NOT_INSTALLED)
            }
        if (matching.isEmpty()) return null
        val embeddedHumanQuality = matching.filter { voice ->
            !voice.isNetworkConnectionRequired && voice.quality >= Voice.QUALITY_NORMAL
        }
        val pool = embeddedHumanQuality.ifEmpty { matching }
        return pool.maxWithOrNull(
            compareBy<Voice> { voiceScore(it, locale) }
                .thenByDescending { it.name },
        )
    }

    private fun voiceScore(voice: Voice, locale: Locale): Int {
        val exactCountry = voice.locale.country.equals(locale.country, ignoreCase = true)
        return (voice.quality * 10) -
            voice.latency +
            (if (exactCountry) 1_000 else 0) +
            (if (voice.isNetworkConnectionRequired) 0 else 1_500)
    }

    private fun applyProsody(engine: TextToSpeech, locale: Locale, voiceStyle: String) {
        val clearStyle = voiceStyle.equals("clear", ignoreCase = true) ||
            voiceStyle.equals("cedar", ignoreCase = true)
        val isTamil = locale.language == "ta"
        val rate = when {
            clearStyle && isTamil -> 0.84f
            clearStyle -> 0.90f
            isTamil -> 0.88f
            else -> 0.94f
        }
        val pitch = if (clearStyle) 0.97f else 1.02f
        engine.setSpeechRate(rate)
        engine.setPitch(pitch)
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
        mainHandler.removeCallbacks(initializationTimeout)
        initialized = false
        initializationFinished = true
        flushPendingCapabilities(null)
        channel.setMethodCallHandler(null)
        textToSpeech?.stop()
        textToSpeech?.shutdown()
        textToSpeech = null
    }
}
