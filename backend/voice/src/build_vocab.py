from __future__ import annotations

import argparse
import hashlib
import json
import statistics
import sys
import tempfile
import time
import unicodedata
from pathlib import Path
from typing import Any


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


def canonical_json(value: Any) -> bytes:
    return (
        json.dumps(
            value,
            ensure_ascii=False,
            sort_keys=True,
            separators=(",", ":"),
        )
        + "\n"
    ).encode("utf-8")


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def percentile(values: list[float], percentile_value: float) -> float:
    ordered = sorted(values)
    if not ordered:
        return 0.0
    position = (len(ordered) - 1) * percentile_value
    lower = int(position)
    upper = min(lower + 1, len(ordered) - 1)
    fraction = position - lower
    return ordered[lower] + (ordered[upper] - ordered[lower]) * fraction


def build_payload(source: dict[str, Any], version: str) -> dict[str, Any]:
    phrase_owners: dict[str, set[str]] = {}
    item_count = 0

    for item in source.get("items", []):
        item_count += 1
        scheme_id = str(item["scheme_id"])
        candidates = [item["reference_text"], *item.get("aliases", [])]
        for candidate in candidates:
            normalized = normalize_text(str(candidate))
            if not normalized:
                continue
            phrase_owners.setdefault(normalized, set()).add(scheme_id)

    collisions = {
        phrase: sorted(owners)
        for phrase, owners in phrase_owners.items()
        if len(owners) > 1
    }
    if collisions:
        raise ValueError(
            "normalized phrases map to multiple schemes: "
            + json.dumps(collisions, ensure_ascii=False, sort_keys=True)
        )

    phrases = sorted(phrase_owners)
    tokens = sorted({token for phrase in phrases for token in phrase.split()})
    grammar = [*phrases, "[unk]"]

    return {
        "version": version,
        "dataset_id": source.get("dataset_id"),
        "locale": source.get("locale", "ta-IN"),
        "synthetic": bool(source.get("synthetic", False)),
        "production_approved": bool(source.get("production_approved", False)),
        "item_count": item_count,
        "phrase_count": len(phrases),
        "token_count": len(tokens),
        "phrases": phrases,
        "tokens": tokens,
        "grammar": grammar,
    }


def write_artifacts(
    source_path: Path,
    output_path: Path,
    version: str,
) -> dict[str, Any]:
    source_bytes = source_path.read_bytes()
    source = json.loads(source_bytes.decode("utf-8"))
    payload = build_payload(source, version)

    grammar_bytes = canonical_json(payload["grammar"])
    vocabulary_bytes = ("\n".join(payload["tokens"]) + "\n").encode("utf-8")
    phrases_bytes = ("\n".join(payload["phrases"]) + "\n").encode("utf-8")
    hotwords_bytes = (", ".join(payload["phrases"]) + "\n").encode("utf-8")

    manifest = {
        "artifact_type": "voice_vocabulary",
        "version": version,
        "dataset_id": payload["dataset_id"],
        "locale": payload["locale"],
        "synthetic": payload["synthetic"],
        "production_approved": payload["production_approved"],
        "item_count": payload["item_count"],
        "phrase_count": payload["phrase_count"],
        "token_count": payload["token_count"],
        "source_sha256": sha256_bytes(source_bytes),
        "files": {
            "grammar.json": {
                "sha256": sha256_bytes(grammar_bytes),
                "bytes": len(grammar_bytes),
            },
            "vocabulary.txt": {
                "sha256": sha256_bytes(vocabulary_bytes),
                "bytes": len(vocabulary_bytes),
            },
            "phrases.txt": {
                "sha256": sha256_bytes(phrases_bytes),
                "bytes": len(phrases_bytes),
            },
            "hotwords.txt": {
                "sha256": sha256_bytes(hotwords_bytes),
                "bytes": len(hotwords_bytes),
            },
        },
    }

    output_path.mkdir(parents=True, exist_ok=True)
    (output_path / "grammar.json").write_bytes(grammar_bytes)
    (output_path / "vocabulary.txt").write_bytes(vocabulary_bytes)
    (output_path / "phrases.txt").write_bytes(phrases_bytes)
    (output_path / "hotwords.txt").write_bytes(hotwords_bytes)
    (output_path / "manifest.json").write_bytes(canonical_json(manifest))
    return manifest


def benchmark_build(
    source_path: Path,
    version: str,
    iterations: int,
) -> dict[str, float | int]:
    durations_ms: list[float] = []
    for _ in range(iterations):
        with tempfile.TemporaryDirectory(prefix="in-schemes-voice-vocab-") as temp_dir:
            started = time.perf_counter()
            write_artifacts(source_path, Path(temp_dir), version)
            durations_ms.append((time.perf_counter() - started) * 1000)

    return {
        "iterations": iterations,
        "mean_ms": round(statistics.fmean(durations_ms), 3),
        "p50_ms": round(percentile(durations_ms, 0.50), 3),
        "p95_ms": round(percentile(durations_ms, 0.95), 3),
        "max_ms": round(max(durations_ms), 3),
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build a deterministic Tamil scheme vocabulary artifact."
    )
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--benchmark-iterations", type=int, default=1)
    parser.add_argument("--report", type=Path)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    if args.benchmark_iterations < 1:
        raise SystemExit("--benchmark-iterations must be at least 1")

    started = time.perf_counter()
    manifest = write_artifacts(args.input, args.output, args.version)
    write_ms = (time.perf_counter() - started) * 1000
    benchmark = benchmark_build(
        args.input,
        args.version,
        args.benchmark_iterations,
    )
    result = {
        "output": str(args.output),
        "write_ms": round(write_ms, 3),
        "manifest": manifest,
        "benchmark": benchmark,
    }
    rendered = json.dumps(result, ensure_ascii=False, indent=2) + "\n"
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(rendered, encoding="utf-8")
    print(rendered, end="")


if __name__ == "__main__":
    main()
