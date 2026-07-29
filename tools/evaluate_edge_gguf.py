"""Run the held-out parser suite against the final quantized Ollama model."""

from __future__ import annotations

import argparse
import json
import urllib.request

from evaluate_edge_parser import CASES, parse_json
from train_edge_parser import SYSTEM_PROMPT


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", default="namma-edge-parser-v1")
    parser.add_argument("--endpoint", default="http://127.0.0.1:11434/api/generate")
    args = parser.parse_args()

    passed = 0
    for index, case in enumerate(CASES, start=1):
        prompt = (
            f"<|im_start|>system\n{SYSTEM_PROMPT}<|im_end|>\n"
            f"<|im_start|>user\n{case.statement}<|im_end|>\n"
            "<|im_start|>assistant\n<think>\n\n</think>\n\n"
        )
        body = json.dumps(
            {
                "model": args.model,
                "prompt": prompt,
                "raw": True,
                "stream": False,
                "options": {
                    "num_ctx": 1536,
                    "num_predict": 192,
                    "temperature": 0,
                    "seed": 7,
                },
            }
        ).encode("utf-8")
        request = urllib.request.Request(
            args.endpoint,
            data=body,
            headers={"Content-Type": "application/json"},
        )
        with urllib.request.urlopen(request, timeout=90) as response:
            generated = json.load(response)["response"]

        ok = False
        try:
            decoded = parse_json(generated)
            actual_facts = {
                item.get("key"): str(item.get("value"))
                for item in decoded.get("facts", [])
                if isinstance(item, dict) and not item.get("negated", False)
            }
            ok = (
                decoded.get("language") == case.language
                and case.concept in decoded.get("concepts", [])
                and all(
                    actual_facts.get(key) == value
                    for key, value in case.facts.items()
                )
            )
        except (TypeError, ValueError, json.JSONDecodeError):
            decoded = generated
        passed += int(ok)
        print(
            json.dumps(
                {"case": index, "ok": ok, "output": decoded},
                ensure_ascii=False,
            )
        )

    print(f"RESULT {passed}/{len(CASES)}")
    raise SystemExit(0 if passed == len(CASES) else 1)


if __name__ == "__main__":
    main()
