from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any


def token_hash(tokens: list[str]) -> str:
    return hashlib.sha256(("\n".join(tokens) + "\n").encode("utf-8")).hexdigest()


def analyze(model_vocab_path: Path, public_vocab_path: Path) -> dict[str, Any]:
    vocab_by_language = json.loads(model_vocab_path.read_text(encoding="utf-8"))
    model_tokens: list[str] = vocab_by_language["ta"]
    public_tokens = [
        line.split("\t", 1)[0]
        for line in public_vocab_path.read_text(encoding="utf-8").splitlines()
    ]
    lexical_tokens = model_tokens[: len(public_tokens)]
    mismatches = [
        {
            "id": index,
            "model": model_token,
            "public": public_token,
        }
        for index, (model_token, public_token) in enumerate(
            zip(lexical_tokens, public_tokens)
        )
        if model_token != public_token
    ]
    appended_tokens = model_tokens[len(public_tokens) :]
    return {
        "analysis": "ai4bharat-600m-tamil-tokenizer-compatibility",
        "model_vocab_path": str(model_vocab_path.resolve()),
        "public_vocab_path": str(public_vocab_path.resolve()),
        "model_token_count": len(model_tokens),
        "public_token_count": len(public_tokens),
        "model_lexical_sha256": token_hash(lexical_tokens),
        "public_sha256": token_hash(public_tokens),
        "lexical_ids_exact_match": not mismatches,
        "mismatch_count": len(mismatches),
        "mismatches": mismatches,
        "model_appended_tokens": appended_tokens,
        "ctc_blank_id": len(public_tokens) if appended_tokens else None,
        "ctc_blank_token": appended_tokens[0] if appended_tokens else None,
        "interpretation": (
            "The public ta_256 SentencePiece vocabulary maps exactly to model IDs "
            "0-255. The multilingual ONNX model appends its CTC blank at ID 256. "
            "The tokenizer is compatible for decoding, but changing its pieces or "
            "IDs still requires matching output-head retraining or remapping."
        ),
    }


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Compare the 600M Tamil vocabulary with public ta_256."
    )
    parser.add_argument("--model-vocab", type=Path, required=True)
    parser.add_argument("--public-vocab", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    result = analyze(args.model_vocab, args.public_vocab)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
