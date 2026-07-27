from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

from demo_engine import DemoKnowledgeBase


if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")


def evaluate_result(
    result_path: Path,
    expected: dict[str, str],
    knowledge: DemoKnowledgeBase,
) -> list[dict[str, Any]]:
    data = json.loads(result_path.read_text(encoding="utf-8"))
    model = data.get("model") or data.get("engine") or result_path.stem
    evaluations: list[dict[str, Any]] = []
    for condition_name, condition in data["conditions"].items():
        items: list[dict[str, Any]] = []
        for item in condition["items"]:
            match = knowledge.match(item["transcript"])
            predicted = match.scheme_id if match else None
            expected_scheme = expected[item["id"]]
            items.append(
                {
                    "id": item["id"],
                    "expected_scheme_id": expected_scheme,
                    "predicted_scheme_id": predicted,
                    "correct": predicted == expected_scheme,
                    "score": round(match.score, 4) if match else 0.0,
                    "transcript": item["transcript"],
                }
            )
        evaluations.append(
            {
                "result_file": result_path.name,
                "model": model,
                "condition": condition_name,
                "intent_accuracy": round(
                    sum(item["correct"] for item in items) / len(items), 4
                ),
                "no_match_count": sum(
                    item["predicted_scheme_id"] is None for item in items
                ),
                "items": items,
            }
        )
    return evaluations


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Evaluate downstream scheme matching for ASR result files."
    )
    parser.add_argument("--phrases", type=Path, required=True)
    parser.add_argument("--knowledge", type=Path, required=True)
    parser.add_argument("--results", type=Path, nargs="+", required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    phrases = json.loads(args.phrases.read_text(encoding="utf-8"))
    expected = {item["id"]: item["scheme_id"] for item in phrases["items"]}
    knowledge = DemoKnowledgeBase(args.knowledge)
    evaluations: list[dict[str, Any]] = []
    for result_path in args.results:
        evaluations.extend(evaluate_result(result_path, expected, knowledge))

    output = {
        "evaluation": "scheme-intent-after-asr",
        "synthetic": True,
        "content_status": knowledge.content_status,
        "results": evaluations,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(output, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(output, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
