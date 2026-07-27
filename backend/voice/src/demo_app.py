from __future__ import annotations

import argparse
import asyncio
import hashlib
import json
import os
import sys
import time
from pathlib import Path
from typing import Any

import edge_tts
import gradio as gr
from faster_whisper import WhisperModel

from demo_engine import DemoKnowledgeBase, NO_MATCH_ANSWER


if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_KNOWLEDGE = REPOSITORY_ROOT / "voice/data/demo_schemes.json"
DEFAULT_HOTWORDS = (
    REPOSITORY_ROOT / "voice/artifacts/vocab-2026.07.1/hotwords.txt"
)
DEFAULT_MODEL_CACHE = REPOSITORY_ROOT / "voice/.cache/models"
DEFAULT_TTS_CACHE = REPOSITORY_ROOT / "voice/.cache/demo-responses"


class VoiceAssistant:
    def __init__(
        self,
        knowledge_path: Path = DEFAULT_KNOWLEDGE,
        hotwords_path: Path = DEFAULT_HOTWORDS,
        model_cache: Path = DEFAULT_MODEL_CACHE,
        model_name: str = "base",
        threads: int = 8,
        tts_voice: str = "ta-IN-PallaviNeural",
    ) -> None:
        self.knowledge = DemoKnowledgeBase(knowledge_path)
        self.hotwords = hotwords_path.read_text(encoding="utf-8").strip()
        self.model_name = model_name
        self.tts_voice = tts_voice
        self.tts_cache = DEFAULT_TTS_CACHE
        self.tts_cache.mkdir(parents=True, exist_ok=True)
        model_cache.mkdir(parents=True, exist_ok=True)

        started = time.perf_counter()
        self.model = WhisperModel(
            model_name,
            device="cpu",
            compute_type="int8",
            cpu_threads=threads,
            download_root=str(model_cache),
        )
        self.model_load_ms = (time.perf_counter() - started) * 1000

    def transcribe(self, audio_path: str) -> tuple[str, float]:
        started = time.perf_counter()
        segments, _ = self.model.transcribe(
            audio_path,
            language="ta",
            task="transcribe",
            beam_size=1,
            condition_on_previous_text=False,
            vad_filter=True,
            vad_parameters={"min_silence_duration_ms": 300},
            hotwords=self.hotwords,
        )
        transcript = " ".join(segment.text.strip() for segment in segments).strip()
        return transcript, (time.perf_counter() - started) * 1000

    async def _write_tts(self, text: str, output_path: Path) -> None:
        communicator = edge_tts.Communicate(text=text, voice=self.tts_voice)
        await communicator.save(str(output_path))

    def synthesize(self, text: str) -> tuple[str | None, float, str | None]:
        digest = hashlib.sha256(
            f"{self.tts_voice}\n{text}".encode("utf-8")
        ).hexdigest()[:24]
        output_path = self.tts_cache / f"{digest}.mp3"
        started = time.perf_counter()
        try:
            if not output_path.exists():
                asyncio.run(self._write_tts(text, output_path))
            return str(output_path), (time.perf_counter() - started) * 1000, None
        except Exception as error:  # UI must still return text if online TTS fails.
            return None, (time.perf_counter() - started) * 1000, str(error)

    def respond(
        self,
        audio_path: str | None,
    ) -> tuple[str, str, str, str | None, dict[str, Any]]:
        request_started = time.perf_counter()
        if not audio_path:
            return (
                "",
                "முதலில் மைக்ரோஃபோனில் தமிழில் பேசுங்கள்.",
                "ஒலி இல்லை",
                None,
                {"error": "NO_AUDIO"},
            )

        transcript, asr_ms = self.transcribe(audio_path)
        match_started = time.perf_counter()
        match = self.knowledge.match(transcript)
        match_ms = (time.perf_counter() - match_started) * 1000

        if match:
            answer = match.answer
            match_label = f"{match.title} — பொருத்தம் {match.score:.1%}"
            match_score = round(match.score, 4)
        else:
            answer = NO_MATCH_ANSWER
            match_label = "பொருத்தமான திட்டம் கிடைக்கவில்லை"
            match_score = 0.0

        speech_path, tts_ms, tts_error = self.synthesize(answer)
        metrics = {
            "model": f"faster-whisper-{self.model_name}-int8",
            "asr_ms": round(asr_ms, 1),
            "intent_match_ms": round(match_ms, 1),
            "tts_ms": round(tts_ms, 1),
            "total_ms": round((time.perf_counter() - request_started) * 1000, 1),
            "match_score": match_score,
            "content_status": self.knowledge.content_status,
            "tts_online": True,
        }
        if tts_error:
            metrics["tts_error"] = tts_error
        return transcript, answer, match_label, speech_path, metrics


def build_demo(assistant: VoiceAssistant) -> gr.Blocks:
    with gr.Blocks(title="நம்ம திட்டம் — தமிழ் குரல் சோதனை") as demo:
        gr.Markdown(
            """
            # நம்ம திட்டம் — தமிழ் குரல் சோதனை

            மைக்ரோஃபோனை அழுத்தி ஒரு திட்டத்தைப் பற்றி தமிழில் கேளுங்கள்.
            உதாரணம்: **“மகளிர் உரிமைத் தொகை பற்றி சொல்லுங்கள்”**

            > இது செயற்கைத் தரவுடன் இயங்கும் தொழில்நுட்ப டெமோ. பதில்கள் அதிகாரப்பூர்வ அரசு வழிகாட்டல் அல்ல.
            """
        )
        microphone = gr.Audio(
            sources=["microphone", "upload"],
            type="filepath",
            format="wav",
            label="தமிழில் பேசுங்கள்",
        )
        submit = gr.Button("கேள்வியை அறிந்து பதில் சொல்லு", variant="primary")
        transcript = gr.Textbox(label="கண்டறிந்த தமிழ்", interactive=False)
        answer = gr.Textbox(label="டெமோ பதில்", interactive=False, lines=3)
        matched = gr.Textbox(label="கண்டறிந்த திட்டம்", interactive=False)
        spoken_answer = gr.Audio(
            label="பேசப்பட்ட பதில்",
            format="mp3",
            autoplay=True,
        )
        metrics = gr.JSON(label="நேர அளவுகள்")
        submit.click(
            fn=assistant.respond,
            inputs=[microphone],
            outputs=[transcript, answer, matched, spoken_answer, metrics],
            show_progress="full",
        )
    return demo


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run the Tamil voice demo.")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=7860)
    parser.add_argument("--model", default="base")
    parser.add_argument("--threads", type=int, default=8)
    parser.add_argument("--smoke-audio", type=Path)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    assistant = VoiceAssistant(model_name=args.model, threads=args.threads)
    print(
        f"Loaded faster-whisper-{args.model}-int8 in "
        f"{assistant.model_load_ms:.1f} ms"
    )
    if args.smoke_audio:
        result = assistant.respond(str(args.smoke_audio))
        print(
            json.dumps(
                {
                    "transcript": result[0],
                    "answer": result[1],
                    "match": result[2],
                    "spoken_answer": result[3],
                    "metrics": result[4],
                },
                ensure_ascii=False,
                indent=2,
            )
        )
        return

    demo = build_demo(assistant)
    demo.queue(default_concurrency_limit=1).launch(
        server_name=args.host,
        server_port=args.port,
        share=False,
        show_error=True,
        allowed_paths=[str(assistant.tts_cache.resolve())],
    )


if __name__ == "__main__":
    main()
