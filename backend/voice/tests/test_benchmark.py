import sys
import tempfile
import unittest
import wave
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

from benchmark_asr import aggregate, audio_duration_seconds  # noqa: E402


class BenchmarkTests(unittest.TestCase):
    def test_audio_duration_uses_seconds(self) -> None:
        sample_rate = 16_000
        with tempfile.TemporaryDirectory() as temp_dir:
            audio_path = Path(temp_dir) / "one-second.wav"
            with wave.open(str(audio_path), "wb") as output:
                output.setnchannels(1)
                output.setsampwidth(2)
                output.setframerate(sample_rate)
                output.writeframes(b"\x00\x00" * sample_rate)

            self.assertAlmostEqual(audio_duration_seconds(audio_path), 1.0, places=3)

    def test_aggregate_reports_real_time_throughput(self) -> None:
        summary = aggregate(
            [
                {
                    "reference_text": "காலை உணவு",
                    "transcript": "காலை உணவு",
                    "audio_seconds": 2.0,
                    "latency_ms": 500.0,
                }
            ]
        )
        self.assertEqual(summary["real_time_factor"], 0.25)
        self.assertEqual(summary["audio_seconds_per_wall_second"], 4.0)
        self.assertEqual(summary["character_error_rate"], 0.0)
        self.assertEqual(summary["word_error_rate"], 0.0)


if __name__ == "__main__":
    unittest.main()
