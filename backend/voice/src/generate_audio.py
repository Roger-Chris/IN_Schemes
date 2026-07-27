from __future__ import annotations

import argparse
import asyncio
import hashlib
import json
import sys
import time
from pathlib import Path
from typing import Any

import edge_tts


if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


async def generate(args: argparse.Namespace) -> None:
    source: dict[str, Any] = json.loads(args.input.read_text(encoding="utf-8"))
    args.output.mkdir(parents=True, exist_ok=True)
    generated: list[dict[str, Any]] = []

    for item in source["items"][: args.limit or None]:
        output_file = args.output / f"{item['id']}.mp3"
        started = time.perf_counter()
        communicator = edge_tts.Communicate(
            text=item["reference_text"],
            voice=args.voice,
            rate=args.rate,
        )
        await communicator.save(str(output_file))
        generated.append(
            {
                "id": item["id"],
                "scheme_id": item["scheme_id"],
                "reference_text": item["reference_text"],
                "audio_path": output_file.name,
                "sha256": sha256_file(output_file),
                "bytes": output_file.stat().st_size,
                "generation_ms": round((time.perf_counter() - started) * 1000, 3),
            }
        )

    manifest = {
        "dataset_id": source["dataset_id"],
        "locale": source["locale"],
        "synthetic": True,
        "tts_provider": "Microsoft Edge online TTS",
        "voice": args.voice,
        "rate": args.rate,
        "items": generated,
    }
    (args.output / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(manifest, ensure_ascii=False, indent=2))


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate synthetic Tamil benchmark audio."
    )
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--voice", default="ta-IN-PallaviNeural")
    parser.add_argument("--rate", default="+0%")
    parser.add_argument("--limit", type=int, default=0)
    return parser.parse_args()


if __name__ == "__main__":
    asyncio.run(generate(parse_args()))
