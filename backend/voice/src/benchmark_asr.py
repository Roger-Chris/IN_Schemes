from __future__ import annotations

import argparse
import json
import os
import platform
import statistics
import sys
import time
import unicodedata
import wave
from pathlib import Path
from typing import TYPE_CHECKING, Any, Iterable

if TYPE_CHECKING:
    from faster_whisper import WhisperModel


if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")


def normalize_text(value: str) -> str:
    normalized = unicodedata.normalize("NFC", value).casefold().strip()
    characters: list[str] = []
    for character in normalized:
        category = unicodedata.category(character)
        if category[0] in {"L", "M", "N"}:
            characters.append(character)
        else:
            characters.append(" ")
    return " ".join("".join(characters).split())


def edit_distance(reference: list[str], hypothesis: list[str]) -> int:
    previous = list(range(len(hypothesis) + 1))
    for reference_item in reference:
        current = [previous[0] + 1]
        for index, hypothesis_item in enumerate(hypothesis, start=1):
            current.append(
                min(
                    current[-1] + 1,
                    previous[index] + 1,
                    previous[index - 1]
                    + (0 if reference_item == hypothesis_item else 1),
                )
            )
        previous = current
    return previous[-1]


def percentile(values: list[float], percentile_value: float) -> float:
    ordered = sorted(values)
    position = (len(ordered) - 1) * percentile_value
    lower = int(position)
    upper = min(lower + 1, len(ordered) - 1)
    fraction = position - lower
    return ordered[lower] + (ordered[upper] - ordered[lower]) * fraction


def audio_duration_seconds(path: Path) -> float:
    if path.suffix.casefold() == ".wav":
        with wave.open(str(path), "rb") as audio_file:
            return audio_file.getnframes() / audio_file.getframerate()

    import av

    with av.open(str(path)) as container:
        if container.duration is not None:
            return float(container.duration / av.time_base)
        stream = container.streams.audio[0]
        if stream.duration is None:
            raise ValueError(f"cannot determine duration for {path}")
        return float(stream.duration * stream.time_base)


def transcribe_one(
    model: WhisperModel,
    audio_path: Path,
    hotwords: str | None,
) -> tuple[str, float, str, float]:
    started = time.perf_counter()
    segments, info = model.transcribe(
        str(audio_path),
        language="ta",
        task="transcribe",
        beam_size=1,
        condition_on_previous_text=False,
        vad_filter=False,
        hotwords=hotwords,
    )
    text = " ".join(segment.text.strip() for segment in segments).strip()
    elapsed_seconds = time.perf_counter() - started
    return text, elapsed_seconds, info.language, info.language_probability


def aggregate(items: list[dict[str, Any]]) -> dict[str, Any]:
    latencies_ms = [item["latency_ms"] for item in items]
    total_audio = sum(item["audio_seconds"] for item in items)
    total_wall = sum(item["latency_ms"] for item in items) / 1000
    reference_characters = 0
    character_errors = 0
    reference_words = 0
    word_errors = 0

    for item in items:
        reference = normalize_text(item["reference_text"])
        hypothesis = normalize_text(item["transcript"])
        reference_chars = list(reference.replace(" ", ""))
        hypothesis_chars = list(hypothesis.replace(" ", ""))
        reference_tokens = reference.split()
        hypothesis_tokens = hypothesis.split()
        reference_characters += len(reference_chars)
        character_errors += edit_distance(reference_chars, hypothesis_chars)
        reference_words += len(reference_tokens)
        word_errors += edit_distance(reference_tokens, hypothesis_tokens)

    return {
        "utterance_count": len(items),
        "audio_seconds": round(total_audio, 3),
        "wall_seconds": round(total_wall, 3),
        "latency_p50_ms": round(percentile(latencies_ms, 0.50), 3),
        "latency_p95_ms": round(percentile(latencies_ms, 0.95), 3),
        "latency_mean_ms": round(statistics.fmean(latencies_ms), 3),
        "real_time_factor": round(total_wall / total_audio, 4),
        "audio_seconds_per_wall_second": round(total_audio / total_wall, 3),
        "utterances_per_second": round(len(items) / total_wall, 3),
        "character_error_rate": round(character_errors / reference_characters, 4),
        "word_error_rate": round(word_errors / reference_words, 4),
        "exact_match_rate": round(
            sum(
                normalize_text(item["reference_text"])
                == normalize_text(item["transcript"])
                for item in items
            )
            / len(items),
            4,
        ),
    }


def load_hotwords(vocab_manifest_path: Path) -> tuple[dict[str, Any], str]:
    manifest = json.loads(vocab_manifest_path.read_text(encoding="utf-8"))
    hotwords_path = vocab_manifest_path.parent / "hotwords.txt"
    return manifest, hotwords_path.read_text(encoding="utf-8").strip()


def run(args: argparse.Namespace) -> dict[str, Any]:
    import psutil
    from faster_whisper import WhisperModel

    audio_manifest = json.loads(args.audio_manifest.read_text(encoding="utf-8"))
    vocab_manifest, hotwords = load_hotwords(args.vocab_manifest)
    audio_root = args.audio_manifest.parent
    process = psutil.Process(os.getpid())

    load_started = time.perf_counter()
    model = WhisperModel(
        args.model,
        device="cpu",
        compute_type=args.compute_type,
        cpu_threads=args.threads,
        download_root=str(args.model_cache),
    )
    model_load_ms = (time.perf_counter() - load_started) * 1000
    rss_after_load = process.memory_info().rss

    first_audio = audio_root / audio_manifest["items"][0]["audio_path"]
    warmup_started = time.perf_counter()
    transcribe_one(model, first_audio, None)
    warmup_ms = (time.perf_counter() - warmup_started) * 1000

    conditions: dict[str, Any] = {}
    for condition, condition_hotwords in (
        ("baseline", None),
        ("vocabulary_prompt", hotwords),
    ):
        outputs: list[dict[str, Any]] = []
        for item in audio_manifest["items"]:
            audio_path = audio_root / item["audio_path"]
            duration = audio_duration_seconds(audio_path)
            transcript, elapsed, language, probability = transcribe_one(
                model,
                audio_path,
                condition_hotwords,
            )
            outputs.append(
                {
                    "id": item["id"],
                    "reference_text": item["reference_text"],
                    "transcript": transcript,
                    "audio_seconds": round(duration, 3),
                    "latency_ms": round(elapsed * 1000, 3),
                    "real_time_factor": round(elapsed / duration, 4),
                    "detected_language": language,
                    "language_probability": round(probability, 4),
                }
            )
        conditions[condition] = {
            "summary": aggregate(outputs),
            "items": outputs,
        }

    return {
        "benchmark": "in-schemes-tamil-voice",
        "model": args.model,
        "compute_type": args.compute_type,
        "threads": args.threads,
        "model_load_ms": round(model_load_ms, 3),
        "warmup_transcription_ms": round(warmup_ms, 3),
        "rss_after_model_load_mb": round(rss_after_load / 1024 / 1024, 3),
        "rss_after_benchmark_mb": round(process.memory_info().rss / 1024 / 1024, 3),
        "host": {
            "platform": platform.platform(),
            "processor": platform.processor(),
            "physical_cpu_cores": psutil.cpu_count(logical=False),
            "logical_cpu_cores": psutil.cpu_count(logical=True),
            "memory_gb": round(psutil.virtual_memory().total / 1024**3, 3),
        },
        "audio_dataset": {
            "dataset_id": audio_manifest["dataset_id"],
            "synthetic": audio_manifest["synthetic"],
            "voice": audio_manifest["voice"],
            "item_count": len(audio_manifest["items"]),
        },
        "vocabulary": {
            "version": vocab_manifest["version"],
            "phrase_count": vocab_manifest["phrase_count"],
            "token_count": vocab_manifest["token_count"],
            "production_approved": vocab_manifest["production_approved"],
        },
        "conditions": conditions,
        "interpretation_limits": [
            "Synthetic TTS does not represent rural accents, microphones, or noise.",
            "Desktop CPU results do not predict Android latency.",
            "Whisper hotwords bias decoding but do not enforce a Vosk-style grammar.",
        ],
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Benchmark offline Tamil ASR latency and throughput."
    )
    parser.add_argument("--model", default="tiny")
    parser.add_argument("--compute-type", default="int8")
    parser.add_argument("--threads", type=int, default=8)
    parser.add_argument("--audio-manifest", type=Path, required=True)
    parser.add_argument("--vocab-manifest", type=Path, required=True)
    parser.add_argument("--model-cache", type=Path, default=Path("voice/.cache/models"))
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    if args.threads < 1:
        raise SystemExit("--threads must be at least 1")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.model_cache.mkdir(parents=True, exist_ok=True)
    result = run(args)
    args.output.write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
