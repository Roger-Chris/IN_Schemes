"""Merge the accepted LoRA adapter into a portable FP16 base model."""

from __future__ import annotations

import argparse
from pathlib import Path

import torch
from peft import PeftModel
from transformers import AutoModelForCausalLM, AutoTokenizer


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", default="Qwen/Qwen3-0.6B")
    parser.add_argument(
        "--adapter",
        default="artifacts/edge-parser-v4/adapter",
    )
    parser.add_argument(
        "--output",
        default="artifacts/edge-parser-v4/merged-fp16",
    )
    args = parser.parse_args()

    output = Path(args.output)
    tokenizer = AutoTokenizer.from_pretrained(args.model)
    base = AutoModelForCausalLM.from_pretrained(
        args.model,
        dtype=torch.float16,
        device_map="cpu",
        low_cpu_mem_usage=True,
    )
    adapted = PeftModel.from_pretrained(base, args.adapter)
    merged = adapted.merge_and_unload(safe_merge=True)
    merged.save_pretrained(
        output,
        safe_serialization=True,
        max_shard_size="2GB",
    )
    tokenizer.save_pretrained(output)
    print(f"Saved portable FP16 model to {output}")


if __name__ == "__main__":
    main()
