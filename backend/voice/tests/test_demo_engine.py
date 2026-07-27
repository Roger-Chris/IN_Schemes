import json
import sys
import tempfile
import unittest
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

from demo_engine import DemoKnowledgeBase, normalize_text, similarity  # noqa: E402


class DemoEngineTests(unittest.TestCase):
    def test_noisy_tamil_transcript_still_matches(self) -> None:
        self.assertGreater(
            similarity(
                "மகலிர் உரிமை தொகை பத்தி சொல்லுங்க",
                "மகளிர் உரிமைத் தொகை பற்றி சொல்லுங்கள்",
            ),
            0.55,
        )

    def test_knowledge_base_returns_best_scheme(self) -> None:
        payload = {
            "content_status": "test",
            "schemes": [
                {
                    "id": "women",
                    "title": "மகளிர் உரிமைத் தொகை",
                    "aliases": ["பெண்களுக்கான உதவி"],
                    "answer": "women answer",
                },
                {
                    "id": "farmer",
                    "title": "உழவர் பாதுகாப்புத் திட்டம்",
                    "aliases": ["விவசாய உதவி"],
                    "answer": "farmer answer",
                },
            ],
        }
        with tempfile.TemporaryDirectory() as temp_dir:
            data_path = Path(temp_dir) / "schemes.json"
            data_path.write_text(
                json.dumps(payload, ensure_ascii=False), encoding="utf-8"
            )
            match = DemoKnowledgeBase(data_path).match("உழவர் பாதுகாப்பு பயன் என்ன")
            self.assertIsNotNone(match)
            self.assertEqual(match.scheme_id, "farmer")

    def test_unrelated_question_is_rejected(self) -> None:
        payload = {
            "content_status": "test",
            "schemes": [
                {
                    "id": "women",
                    "title": "மகளிர் உரிமைத் தொகை",
                    "aliases": [],
                    "answer": "answer",
                }
            ],
        }
        with tempfile.TemporaryDirectory() as temp_dir:
            data_path = Path(temp_dir) / "schemes.json"
            data_path.write_text(
                json.dumps(payload, ensure_ascii=False), encoding="utf-8"
            )
            self.assertIsNone(DemoKnowledgeBase(data_path).match("இன்று மழை வருமா"))

    def test_normalization_handles_colloquial_punctuation(self) -> None:
        self.assertEqual(
            normalize_text("திட்டம்—பற்றி, சொல்லுங்க!"),
            "திட்டம் பற்றி சொல்லுங்க",
        )


if __name__ == "__main__":
    unittest.main()
