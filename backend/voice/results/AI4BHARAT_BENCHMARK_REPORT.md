# AI4Bharat Tamil desktop benchmark

Date: 2026-07-22
Fixture: 8 synthetic Tamil scheme questions, 24.096 seconds total
Host: Ryzen 7 8845HS, RTX 4060 Laptop GPU, 16 GB system RAM
Checkpoint: `indicconformer_stt_ta_hybrid_rnnt_large.nemo`
Checkpoint size: 523,192,320 bytes (499 MiB)
Checkpoint SHA-256: `40a6fce3374ceb67daa2a071e92f0948c51c6a95b734d4881a3bcfe0b1bed32a`

## Result

AI4Bharat CTC is the best desktop-demo configuration. On CUDA it reached 89 ms
mean / 111 ms P95 ASR latency, 33.8x real-time sequential throughput, and 50.8x
batched throughput. RNNT reduced CER from 13.7% to 12.4% and WER from 22.0% to
19.5%, but was about 2.5x slower, so the live demo uses CTC.

| Engine | Device | Decoder | P50 ms | P95 ms | Realtime throughput | CER | WER | Intent accuracy |
|---|---|---|---:|---:|---:|---:|---:|---:|
| Whisper Base INT8 + vocabulary | CPU | beam 1 | 806 | 992 | 3.62x | 18.0% | 46.3% | 100% |
| AI4Bharat IndicConformer | CPU | CTC greedy | 243 | 269 | 12.51x | 13.7% | 22.0% | 100% |
| AI4Bharat IndicConformer | CUDA | CTC greedy | 89 | 111 | 33.77x | 13.7% | 22.0% | 100% |
| AI4Bharat IndicConformer | CUDA | RNNT greedy batch | 213 | 266 | 13.67x | 12.4% | 19.5% | 100% |

These numbers are directional. The audio is clean synthetic TTS, not field speech,
and the CPU measurements use different runtimes (Windows CTranslate2 versus WSL
PyTorch/NeMo). Intent accuracy uses the current synthetic 8-scheme matcher.

## Runtime cost

- Model load: 23.9–25.5 seconds.
- Process RSS after load: about 1.6 GiB on CUDA and 1.9 GiB on CPU.
- CUDA peak allocated memory: about 805 MiB; reserved memory: about 924 MiB.
- First-ever CTC call incurred a 14.3-second compile/JIT warm-up. With its cache
  populated, live-demo warm-up was 0.93 seconds.
- Live server test: exact marriage-assistance transcription in 62.6 ms; total
  response 1.36 seconds, of which online Tamil TTS consumed 1.29 seconds.

The checkpoint is therefore a strong desktop/server evaluator, but its memory and
startup profile do not qualify it as the first low-end Android runtime without
quantization, export, and on-device profiling.

## Tamil tokenizer finding

Both the checkpoint and AI4Bharat's public `ta_256` repository tokenizer contain
256 pieces and encode all Tamil-script benchmark phrases with a 0% unknown-piece
rate. The unknown pieces in the aggregate report are from Romanized aliases.

However, the public tokenizer is not byte-identical to the checkpoint tokenizer:
their SHA-256 hashes differ and the phrase analysis found 294 token-ID mismatches.
Tokenizer IDs are tied to the model output layers, so replacing the embedded
tokenizer would corrupt decoding. For domain vocabulary, keep the embedded
tokenizer and use supported CTC beam hotwords/language-model biasing, or retrain
the tokenizer and output heads together.

## Observed safety error

For the health-insurance sample, both decoders changed `வேண்டும்` (needed) to
`வேண்டாம்` (not needed). A low WER does not make this safe to answer blindly.
Production routing must detect negation/polarity-sensitive fields and ask for
confirmation or fall back to a verified source.

## Artifacts

- `ai4bharat-tamil-ctc-cuda.json`
- `ai4bharat-tamil-rnnt-cuda.json`
- `ai4bharat-tamil-ctc-cpu.json`
- `ai4bharat-tokenizer.json`
- `intent-comparison.json`

The gated AI4Bharat 600M multilingual ONNX repository was subsequently authorized,
revision-pinned, and benchmarked. See `AI4BHARAT_600M_BENCHMARK_REPORT.md` for the
new model's substantially improved accuracy, tokenizer compatibility result, and
live port 7862 deployment.
