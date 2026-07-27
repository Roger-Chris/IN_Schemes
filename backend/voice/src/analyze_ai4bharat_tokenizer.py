from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any

import sentencepiece as spm


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_phrases(path: Path) -> list[str]:
    data = json.loads(path.read_text(encoding="utf-8"))
    phrases: list[str] = []
    for item in data["items"]:
        phrases.append(item["reference_text"])
        phrases.extend(item["aliases"])
    return phrases


def analyze_model(model_path: Path, phrases: list[str]) -> dict[str, Any]:
    processor = spm.SentencePieceProcessor(model_file=str(model_path))
    items: list[dict[str, Any]] = []
    total_pieces = 0
    unknown_pieces = 0
    native_total_pieces = 0
    native_unknown_pieces = 0
    native_phrase_count = 0
    for phrase in phrases:
        pieces = processor.encode(phrase, out_type=str)
        ids = processor.encode(phrase, out_type=int)
        unknowns = sum(token_id == processor.unk_id() for token_id in ids)
        total_pieces += len(pieces)
        unknown_pieces += unknowns
        if any("\u0b80" <= character <= "\u0bff" for character in phrase):
            native_phrase_count += 1
            native_total_pieces += len(pieces)
            native_unknown_pieces += unknowns
        items.append(
            {
                "text": phrase,
                "pieces": pieces,
                "piece_ids": ids,
                "piece_count": len(pieces),
                "unknown_count": unknowns,
            }
        )
    return {
        "path": str(model_path),
        "sha256": sha256(model_path),
        "piece_vocabulary_size": processor.get_piece_size(),
        "phrase_count": len(phrases),
        "total_pieces": total_pieces,
        "mean_pieces_per_phrase": round(total_pieces / len(phrases), 3),
        "unknown_pieces": unknown_pieces,
        "unknown_piece_rate": round(unknown_pieces / total_pieces, 6),
        "tamil_script_phrase_count": native_phrase_count,
        "tamil_script_unknown_pieces": native_unknown_pieces,
        "tamil_script_unknown_piece_rate": round(
            native_unknown_pieces / native_total_pieces, 6
        ),
        "items": items,
    }


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Measure Tamil domain-phrase coverage for AI4Bharat tokenizers."
    )
    parser.add_argument("--phrases", type=Path, required=True)
    parser.add_argument("--embedded-model", type=Path, required=True)
    parser.add_argument("--public-model", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    phrases = load_phrases(args.phrases)
    embedded = analyze_model(args.embedded_model, phrases)
    public = analyze_model(args.public_model, phrases)
    positional_mismatches = 0
    for embedded_item, public_item in zip(embedded["items"], public["items"]):
        positional_mismatches += sum(
            left != right
            for left, right in zip(
                embedded_item["piece_ids"], public_item["piece_ids"]
            )
        )
        positional_mismatches += abs(
            len(embedded_item["piece_ids"]) - len(public_item["piece_ids"])
        )

    result = {
        "analysis": "ai4bharat-tamil-tokenizer-domain-coverage",
        "embedded": embedded,
        "public_repository": public,
        "same_model_sha256": embedded["sha256"] == public["sha256"],
        "piece_id_mismatches_across_phrases": positional_mismatches,
        "integration_warning": (
            "Tokenizer IDs are model parameters. Never replace the checkpoint's "
            "embedded tokenizer unless the output layers are retrained or remapped."
        ),
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
