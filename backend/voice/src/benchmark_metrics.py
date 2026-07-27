from __future__ import annotations

import statistics
import unicodedata
from pathlib import Path
from typing import Any

import av


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
    with av.open(str(path)) as container:
        if container.duration is not None:
            return float(container.duration / av.time_base)
        stream = container.streams.audio[0]
        if stream.duration is None:
            raise ValueError(f"cannot determine duration for {path}")
        return float(stream.duration * stream.time_base)


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
