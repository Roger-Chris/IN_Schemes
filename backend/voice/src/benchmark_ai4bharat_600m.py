from __future__ import annotations

import argparse
import json
import platform
import sys
from pathlib import Path
from typing import Any

import psutil

from ai4bharat_600m_asr import AI4BharatMultilingualASR
from benchmark_metrics import aggregate, audio_duration_seconds


if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")


def run(args: argparse.Namespace) -> dict[str, Any]:
    manifest = json.loads(args.audio_manifest.read_text(encoding="utf-8"))
    audio_root = args.audio_manifest.parent
    process = psutil.Process()
    runtime = AI4BharatMultilingualASR(
        device=args.device,
        language="ta",
        decoder=args.decoders[0],
        cache_dir=args.cache_dir,
        offline=not args.allow_download,
    )
    rss_after_load_mb = process.memory_info().rss / 1024 / 1024
    first_audio = audio_root / manifest["items"][0]["audio_path"]

    conditions: dict[str, Any] = {}
    for decoder in args.decoders:
        runtime.set_decoder(decoder)
        _, warmup_ms = runtime.transcribe_one(first_audio)

        items: list[dict[str, Any]] = []
        paths: list[Path] = []
        for item in manifest["items"]:
            audio_path = audio_root / item["audio_path"]
            paths.append(audio_path)
            duration = audio_duration_seconds(audio_path)
            transcript, latency_ms = runtime.transcribe_one(audio_path)
            items.append(
                {
                    "id": item["id"],
                    "reference_text": item["reference_text"],
                    "transcript": transcript,
                    "audio_seconds": round(duration, 3),
                    "latency_ms": round(latency_ms, 3),
                    "real_time_factor": round(latency_ms / 1000 / duration, 4),
                }
            )

        loop_outputs, loop_ms = runtime.transcribe_batch(paths)
        total_audio = sum(item["audio_seconds"] for item in items)
        conditions[decoder] = {
            "warmup_ms": round(warmup_ms, 3),
            "sequential": aggregate(items),
            "throughput_loop": {
                "native_batching": False,
                "item_count": len(paths),
                "wall_ms": round(loop_ms, 3),
                "real_time_factor": round(loop_ms / 1000 / total_audio, 4),
                "audio_seconds_per_wall_second": round(
                    total_audio / (loop_ms / 1000), 3
                ),
                "transcripts": loop_outputs,
            },
            "items": items,
        }

    torch = runtime.torch
    return {
        "benchmark": "in-schemes-tamil-voice",
        "engine": "AI4Bharat IndicConformer 600M Multilingual ONNX",
        "device": args.device,
        "torch_version": torch.__version__,
        "cuda_device": (
            torch.cuda.get_device_name(0) if args.device == "cuda" else None
        ),
        "model_load_ms": round(runtime.model_load_ms, 3),
        "rss_after_model_load_mb": round(rss_after_load_mb, 3),
        "rss_after_benchmark_mb": round(
            process.memory_info().rss / 1024 / 1024, 3
        ),
        "runtime": runtime.runtime_details(),
        "host": {
            "platform": platform.platform(),
            "processor": platform.processor(),
            "physical_cpu_cores": psutil.cpu_count(logical=False),
            "logical_cpu_cores": psutil.cpu_count(logical=True),
            "memory_gb": round(psutil.virtual_memory().total / 1024**3, 3),
        },
        "audio_dataset": {
            "dataset_id": manifest["dataset_id"],
            "synthetic": manifest["synthetic"],
            "voice": manifest["voice"],
            "item_count": len(manifest["items"]),
        },
        "conditions": conditions,
        "interpretation_limits": [
            "Synthetic TTS does not represent rural accents, microphones, or noise.",
            "This GPU desktop result does not predict Android latency.",
            "The published ONNX wrapper does not implement native batching.",
            "The public checkpoint has no supported runtime hotword injection path.",
        ],
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Benchmark the pinned AI4Bharat 600M multilingual ONNX model."
    )
    parser.add_argument("--audio-manifest", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument(
        "--decoders", nargs="+", choices=("ctc", "rnnt"), default=("ctc", "rnnt")
    )
    parser.add_argument("--device", choices=("cuda", "cpu"), default="cuda")
    parser.add_argument(
        "--cache-dir", type=Path, default=Path.home() / ".cache/in-schemes-hf/hub"
    )
    parser.add_argument("--allow-download", action="store_true")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    result = run(args)
    args.output.write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
