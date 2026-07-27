import sys
import unittest
from pathlib import Path
from types import SimpleNamespace


sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

from ai4bharat_asr import coerce_transcript  # noqa: E402


class AI4BharatASRTests(unittest.TestCase):
    def test_coerce_plain_transcript(self) -> None:
        self.assertEqual(coerce_transcript("  தமிழ்  "), "தமிழ்")

    def test_coerce_hypothesis_transcript(self) -> None:
        self.assertEqual(
            coerce_transcript(SimpleNamespace(text="காலை உணவு")), "காலை உணவு"
        )


if __name__ == "__main__":
    unittest.main()
