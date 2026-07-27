from __future__ import annotations

import importlib.util
import os
import time
from pathlib import Path
from typing import Any, Sequence


AI4BHARAT_600M_REPOSITORY = "ai4bharat/indic-conformer-600m-multilingual"
AI4BHARAT_600M_REVISION = "e9b71b369c048e2c6b634d4c131061c34e441179"
DEFAULT_HF_CACHE = Path.home() / ".cache/in-schemes-hf/hub"


def validate_decode_args(language: str, decoder: str) -> None:
    if language != "ta":
        raise ValueError("this IN Schemes wrapper currently supports Tamil ('ta')")
    if decoder not in {"ctc", "rnnt"}:
        raise ValueError("decoder must be 'ctc' or 'rnnt'")


def directory_size(path: Path) -> int:
    return sum(item.stat().st_size for item in path.rglob("*") if item.is_file())


class AI4BharatMultilingualASR:
    """Pinned, inference-only wrapper for AI4Bharat's 600M ONNX model."""

    def __init__(
        self,
        *,
        device: str = "cuda",
        language: str = "ta",
        decoder: str = "ctc",
        cache_dir: Path = DEFAULT_HF_CACHE,
        offline: bool = True,
    ) -> None:
        validate_decode_args(language, decoder)
        if device not in {"cuda", "cpu"}:
            raise ValueError("device must be 'cuda' or 'cpu'")

        # The upstream ONNX wrapper selects providers by torch CUDA visibility.
        # Set this before importing torch so a CPU benchmark is deterministic.
        if device == "cpu":
            os.environ["CUDA_VISIBLE_DEVICES"] = ""

        import torch
        import torchaudio
        from huggingface_hub import snapshot_download

        if device == "cuda" and not torch.cuda.is_available():
            raise RuntimeError("CUDA was requested but is not available")

        self.torch = torch
        self.torchaudio = torchaudio
        self.device = device
        self.language = language
        self.decoder = decoder
        self.cache_dir = cache_dir.expanduser().resolve()

        started = time.perf_counter()
        self.snapshot_path = Path(
            snapshot_download(
                repo_id=AI4BHARAT_600M_REPOSITORY,
                revision=AI4BHARAT_600M_REVISION,
                cache_dir=str(self.cache_dir),
                local_files_only=offline,
            )
        ).resolve()
        module = self._load_pinned_module(self.snapshot_path / "model_onnx.py")
        config = module.IndicASRConfig(ts_folder=str(self.snapshot_path))
        self.model = module.IndicASRModel(config)
        self.model.eval()
        self.model_load_ms = (time.perf_counter() - started) * 1000

        encoder_session = self.model.models["encoder"]
        self.execution_providers = list(encoder_session.get_providers())
        expected = "CUDAExecutionProvider" if device == "cuda" else "CPUExecutionProvider"
        if expected not in self.execution_providers:
            raise RuntimeError(
                f"requested {device}, but ONNX Runtime loaded {self.execution_providers}"
            )

    @staticmethod
    def _load_pinned_module(module_path: Path) -> Any:
        if not module_path.exists():
            raise FileNotFoundError(f"missing pinned model code: {module_path}")
        module_name = f"ai4bharat_600m_{AI4BHARAT_600M_REVISION[:12]}"
        spec = importlib.util.spec_from_file_location(module_name, module_path)
        if spec is None or spec.loader is None:
            raise RuntimeError(f"cannot import model code from {module_path}")
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module

    def set_decoder(self, decoder: str) -> None:
        validate_decode_args(self.language, decoder)
        self.decoder = decoder

    def _load_waveform(self, audio_path: str | Path) -> Any:
        waveform, sample_rate = self.torchaudio.load(str(Path(audio_path).resolve()))
        if waveform.shape[0] > 1:
            waveform = waveform.mean(dim=0, keepdim=True)
        if sample_rate != 16_000:
            waveform = self.torchaudio.functional.resample(
                waveform, sample_rate, 16_000
            )
        return waveform

    def transcribe_one(self, audio_path: str | Path) -> tuple[str, float]:
        if self.device == "cuda":
            self.torch.cuda.synchronize()
        started = time.perf_counter()
        waveform = self._load_waveform(audio_path)
        with self.torch.inference_mode():
            transcript = self.model(waveform, self.language, self.decoder)
        if self.device == "cuda":
            self.torch.cuda.synchronize()
        elapsed_ms = (time.perf_counter() - started) * 1000
        return str(transcript).strip(), elapsed_ms

    def transcribe_batch(
        self, audio_paths: Sequence[str | Path]
    ) -> tuple[list[str], float]:
        # The published 600M ONNX wrapper explicitly has no native batching.
        started = time.perf_counter()
        transcripts = [self.transcribe_one(path)[0] for path in audio_paths]
        return transcripts, (time.perf_counter() - started) * 1000

    def runtime_details(self) -> dict[str, Any]:
        return {
            "repository": AI4BHARAT_600M_REPOSITORY,
            "revision": AI4BHARAT_600M_REVISION,
            "snapshot_path": str(self.snapshot_path),
            "snapshot_bytes": directory_size(self.snapshot_path),
            "execution_providers": self.execution_providers,
            "native_batching": False,
        }
