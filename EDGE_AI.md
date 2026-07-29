# Namma Edge AI

The assistant uses a task-specific, quantized Qwen3 0.6B parser on supported
Android devices. The model extracts intent and unconfirmed eligibility facts;
the existing deterministic matcher remains authoritative for scheme ranking,
hard exclusions, follow-up selection, and recommendation explanations.

## Runtime contract

- Model: `namma-edge-parser-v1-q4-k-m.gguf`
- Base model: `Qwen/Qwen3-0.6B` (Apache-2.0)
- Size: `396704544` bytes (about 378 MiB)
- SHA-256: `6a1cd4ba12d7a45c6a4d87fc821e15915dc0408d57b0a19f546c035c59cc9cd4`
- Android baseline: API 26, ARM64/NEON, CPU inference, 1,536-token context
- Safety fallback: devices with less than 850 MiB free RAM, an unsupported ABI,
  a missing/corrupt model, timeout, or malformed JSON use the lightweight local
  matcher instead.

Statements and generated facts stay in memory and are not persisted or logged.
The SLM performs no network requests after installation. Android speech
recognition remains device/service dependent and may use the network; this model
pack does not replace speech-to-text.

## Reproduce the model

The training set is generated from reviewed templates and contains no user
transcripts.

```powershell
python tools/train_edge_parser.py --full-precision-base --steps 70 --output artifacts/edge-parser-v4
python tools/evaluate_edge_parser.py --adapter artifacts/edge-parser-v4/adapter
python tools/export_edge_parser.py
```

Convert the merged Hugging Face checkpoint with llama.cpp, quantize it to
`Q4_K_M`, then run `tools/evaluate_edge_gguf.py` against the final artifact.
Large model/checkpoint files are intentionally excluded by `.gitignore`.

## Distribution

New installations expect the verified model at:

`https://github.com/Roger-Chris/IN_Schemes/releases/download/edge-ai-v1/namma-edge-parser-v1-q4-k-m.gguf`

Upload the exact file and hash above to the `edge-ai-v1` release before enabling
the download control for production users. The downloader supports resume,
checks the exact byte count and SHA-256, and atomically installs the verified
file into app-private storage.

`llama_flutter_android` 0.2.6 omits its dynamically linked OpenMP runtime. The
Android app build copies the matching ARM64 `libomp.so` from the configured NDK
into generated JNI assets; no NDK binary is committed to the repository.
