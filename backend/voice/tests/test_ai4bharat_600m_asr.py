import sys
import tempfile
import unittest
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

from ai4bharat_600m_asr import directory_size, validate_decode_args  # noqa: E402


class AI4Bharat600MASRTests(unittest.TestCase):
    def test_accepts_supported_tamil_decoders(self) -> None:
        validate_decode_args("ta", "ctc")
        validate_decode_args("ta", "rnnt")

    def test_rejects_unsupported_language(self) -> None:
        with self.assertRaisesRegex(ValueError, "Tamil"):
            validate_decode_args("hi", "ctc")

    def test_rejects_unknown_decoder(self) -> None:
        with self.assertRaisesRegex(ValueError, "decoder"):
            validate_decode_args("ta", "beam")

    def test_directory_size_counts_nested_assets(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "nested").mkdir()
            (root / "a.bin").write_bytes(b"123")
            (root / "nested/b.bin").write_bytes(b"4567")
            self.assertEqual(directory_size(root), 7)


if __name__ == "__main__":
    unittest.main()
