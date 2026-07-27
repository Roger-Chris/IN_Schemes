# AI4Bharat 600M multilingual Tamil desktop benchmark

Date: 2026-07-22
Fixture: 8 synthetic Tamil scheme questions, 24.096 seconds total
Host: Ryzen 7 8845HS, RTX 4060 Laptop GPU, WSL2
Repository: `ai4bharat/indic-conformer-600m-multilingual`
Pinned revision: `e9b71b369c048e2c6b634d4c131061c34e441179`
Snapshot size: 2,556,509,799 bytes (2.38 GiB)

## Outcome

The 600M RNNT decoder is the best live-desktop configuration. It reduced WER to
4.88%, kept P95 ASR latency below 300 ms on the synthetic fixture, and preserved
100% downstream scheme-intent accuracy. CTC has a lower warmed median and higher
steady-state throughput, but its first encounters with new input shapes caused a
541 ms P95. RNNT was both more accurate and more predictable, so port 7862 uses
RNNT.

| Engine | Decoder | P50 ms | P95 ms | Sequential realtime | CER | WER | Exact text | Intent accuracy |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| Tamil-only 499 MiB NeMo | CTC | 89 | 111 | 33.77x | 13.73% | 21.95% | 12.5% | 100% |
| Tamil-only 499 MiB NeMo | RNNT | 213 | 266 | 13.67x | 12.42% | 19.51% | 12.5% | 100% |
| 600M multilingual ONNX | CTC | 140 | 541 | 11.03x | 1.96% | 7.32% | 62.5% | 100% |
| 600M multilingual ONNX | RNNT | 228 | 292 | 12.75x | 1.63% | 4.88% | 75.0% | 100% |

The published ONNX wrapper does not implement native batching. After all fixture
shapes were warmed, the CTC throughput loop reached 22.05x real time and RNNT
reached 12.38x real time. These are clean synthetic-TTS results, not field-speech
or Android performance claims.

## Runtime and live HTTP test

- Model/session load: 4.60 seconds in the benchmark process.
- Process RSS: 963 MiB after load and 1,686 MiB after both decoder runs.
- Execution providers: CUDA first, CPU fallback available.
- Cold smoke phrase: exact transcription in 1.84 seconds.
- Warm live Gradio request: exact transcription in 311 ms; intent match 3 ms;
  cached TTS 13 ms; internal total 328 ms; client-observed upload/queue round trip
  890 ms.
- Uncached online Tamil TTS added about 1.08 seconds on the first live request.

## Tamil tokenizer compatibility

The public AI4Bharat `ta_256/tokenizer.vocab` is byte-for-byte compatible with
the 600M model's Tamil lexical vocabulary: all IDs 0-255 match and their canonical
SHA-256 is `8a20f4a1e690fa2a268085b841d888dd418eede10baa052481987a9c6c164225`.
The ONNX model appends `|` as the CTC blank token at ID 256.

This makes the public tokenizer useful for a mobile decoder and offline vocabulary
inspection. It does not make arbitrary vocabulary edits safe: changing a piece or
ID still requires corresponding output-head retraining or a deliberate remap.
This compatibility applies to the 600M multilingual model; the older Tamil-only
checkpoint's embedded token IDs did not match the public tokenizer.

## Production interpretation

The 600M model is the current desktop/server teacher baseline, not yet the Android
shipping artifact. Its 2.38 GiB snapshot and roughly 1 GiB-plus process footprint
are too large for a low-end-device commitment without graph pruning, quantization,
and real-device profiling. Negation and eligibility-critical utterances still need
confirmation safeguards even though this fixture no longer reproduced the older
model's `வேண்டும்`/`வேண்டாம்` polarity error.

## Artifacts

- `ai4bharat-600m-multilingual-onnx-cuda.json`
- `ai4bharat-600m-tokenizer.json`
- `intent-ai4bharat-600m.json`
