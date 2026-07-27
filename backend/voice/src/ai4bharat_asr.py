from __future__ import annotations

import time
from pathlib import Path
from typing import Any, Sequence


AI4BHARAT_MODEL_SHA256 = (
    "40a6fce3374ceb67daa2a071e92f0948c51c6a95b734d4881a3bcfe0b1bed32a"
)


def coerce_transcript(value: Any) -> str:
    """Normalize the different return shapes used by NeMo transcription APIs."""
    if isinstance(value, tuple):
        value = value[0]
    if isinstance(value, list):
        if not value:
            return ""
        value = value[0]
    if hasattr(value, "text"):
        value = value.text
    return str(value).strip()


class AI4BharatTamilASR:
    """Thin inference-only wrapper around AI4Bharat's hybrid Tamil checkpoint."""

    def __init__(self, model_path: Path, device: str = "cuda") -> None:
        import torch
        from nemo.collections.asr.models import EncDecHybridRNNTCTCBPEModel

        if device == "cuda" and not torch.cuda.is_available():
            raise RuntimeError("CUDA was requested but is not available")

        self.torch = torch
        self.device = device
        self.model_path = model_path.resolve()
        started = time.perf_counter()
        self.model = EncDecHybridRNNTCTCBPEModel.restore_from(
            restore_path=str(self.model_path),
            map_location=device,
        )
        self.model.eval()
        self.model.to(device)
        self.model_load_ms = (time.perf_counter() - started) * 1000
        self.decoder = "rnnt"

    def set_decoder(self, decoder: str) -> None:
        if decoder not in {"ctc", "rnnt"}:
            raise ValueError("decoder must be 'ctc' or 'rnnt'")
        self.model.change_decoding_strategy(decoder_type=decoder, lang_id="ta")
        self.decoder = decoder

    def transcribe_batch(
        self,
        audio_paths: Sequence[str | Path],
        batch_size: int = 1,
    ) -> tuple[list[str], float]:
        paths = [str(Path(path).resolve()) for path in audio_paths]
        if self.device == "cuda":
            self.torch.cuda.synchronize()
        started = time.perf_counter()
        outputs = self.model.transcribe(
            paths,
            batch_size=batch_size,
            language_id="ta",
            verbose=False,
        )
        if self.device == "cuda":
            self.torch.cuda.synchronize()
        elapsed_ms = (time.perf_counter() - started) * 1000

        if isinstance(outputs, tuple):
            outputs = outputs[0]
        return [coerce_transcript(item) for item in outputs], elapsed_ms

    def transcribe_one(self, audio_path: str | Path) -> tuple[str, float]:
        outputs, elapsed_ms = self.transcribe_batch([audio_path], batch_size=1)
        return outputs[0], elapsed_ms

    def gpu_memory(self) -> dict[str, float]:
        if self.device != "cuda":
            return {}
        return {
            "allocated_mb": round(
                self.torch.cuda.memory_allocated() / 1024 / 1024, 3
            ),
            "reserved_mb": round(
                self.torch.cuda.memory_reserved() / 1024 / 1024, 3
            ),
            "peak_allocated_mb": round(
                self.torch.cuda.max_memory_allocated() / 1024 / 1024, 3
            ),
        }
