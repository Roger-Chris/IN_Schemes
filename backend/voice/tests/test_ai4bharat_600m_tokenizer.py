import json
import sys
import tempfile
import unittest
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

from analyze_ai4bharat_600m_tokenizer import analyze  # noqa: E402


class AI4Bharat600MTokenizerTests(unittest.TestCase):
    def test_detects_compatible_vocab_plus_blank(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            model = root / "vocab.json"
            public = root / "tokenizer.vocab"
            model.write_text(
                json.dumps({"ta": ["<unk>", "▁த", "|"]}, ensure_ascii=False),
                encoding="utf-8",
            )
            public.write_text("<unk>\t0\n▁த\t-1\n", encoding="utf-8")
            result = analyze(model, public)
            self.assertTrue(result["lexical_ids_exact_match"])
            self.assertEqual(result["model_appended_tokens"], ["|"])


if __name__ == "__main__":
    unittest.main()
