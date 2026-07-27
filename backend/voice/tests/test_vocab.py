import json
import sys
import tempfile
import unittest
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

from build_vocab import build_payload, normalize_text, write_artifacts  # noqa: E402


class VocabularyTests(unittest.TestCase):
    def test_normalization_preserves_tamil_marks_and_removes_punctuation(self) -> None:
        self.assertEqual(
            normalize_text("  மகளிர்—உரிமைத் தொகை!  "),
            "மகளிர் உரிமைத் தொகை",
        )

    def test_duplicate_aliases_for_one_scheme_are_deduplicated(self) -> None:
        payload = build_payload(
            {
                "items": [
                    {
                        "scheme_id": "one",
                        "reference_text": "நான் முதல்வன்",
                        "aliases": ["நான் முதல்வன்!"],
                    }
                ]
            },
            "test",
        )
        self.assertEqual(payload["phrase_count"], 1)

    def test_cross_scheme_normalized_collision_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "multiple schemes"):
            build_payload(
                {
                    "items": [
                        {
                            "scheme_id": "one",
                            "reference_text": "காலை உணவு",
                            "aliases": [],
                        },
                        {
                            "scheme_id": "two",
                            "reference_text": "காலை—உணவு",
                            "aliases": [],
                        },
                    ]
                },
                "test",
            )

    def test_artifacts_are_byte_for_byte_reproducible(self) -> None:
        source = {
            "dataset_id": "test",
            "locale": "ta-IN",
            "items": [
                {
                    "scheme_id": "one",
                    "reference_text": "முதியோர் ஓய்வூதியம்",
                    "aliases": ["muthiyor oyvoothiyam"],
                }
            ],
        }
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            source_path = root / "source.json"
            source_path.write_text(json.dumps(source), encoding="utf-8")
            first = root / "first"
            second = root / "second"
            write_artifacts(source_path, first, "test")
            write_artifacts(source_path, second, "test")
            self.assertEqual(
                (first / "manifest.json").read_bytes(),
                (second / "manifest.json").read_bytes(),
            )
            self.assertEqual(
                (first / "grammar.json").read_bytes(),
                (second / "grammar.json").read_bytes(),
            )


if __name__ == "__main__":
    unittest.main()
