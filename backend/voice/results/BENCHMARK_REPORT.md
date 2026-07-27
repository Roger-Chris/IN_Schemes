# Tamil voice benchmark — initial desktop baseline

- Date: 2026-07-22
- Host: AMD Ryzen 7 8845HS, 8 physical / 16 logical cores, 15.3 GiB RAM
- Runtime: Windows, CPU INT8, 8 inference threads
- Audio: 8 synthetic Tamil utterances, 24.096 seconds total
- Voice: `ta-IN-PallaviNeural`
- Vocabulary: 32 phrases, 70 unique tokens

## Scope and interpretation

This run measures cached model load, post-utterance transcription latency, and
sequential CPU throughput. It does not measure microphone capture, streaming
partial-result latency, rural accents, background noise, or Android performance.
The fixture is suitable for regression and model comparison, not a production
accuracy claim.

Vosk's official catalog has no Tamil model at the time of this run. The test uses
multilingual Whisper via faster-whisper. Its hotwords bias the decoder but are
not equivalent to Vosk's constrained runtime grammar.

## Vocabulary build

| Metric | Result |
|---|---:|
| Source items | 8 |
| Normalized phrases | 32 |
| Unique tokens | 70 |
| Mean build time, 500 runs | 3.136 ms |
| P50 build time | 2.980 ms |
| P95 build time | 4.714 ms |
| Maximum build time | 10.660 ms |
| Reproducibility/collision tests | Pass |

Vocabulary generation is negligible relative to inference. Review quality,
normalization collisions, and acoustic-model coverage are the real constraints.

## ASR results

| Model / condition | Cached load | P50 | P95 | RTF | Audio throughput | CER | WER | Exact |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Tiny INT8 baseline | 1.22 s | 397 ms | 434 ms | 0.131 | 7.65× | 41.2% | 90.2% | 0% |
| Tiny INT8 + vocabulary | 1.22 s | 414 ms | 6,113 ms | 0.502 | 1.99× | 27.1% | 65.9% | 12.5% |
| Base INT8 baseline | 1.40 s | 765 ms | 835 ms | 0.251 | 3.99× | 29.4% | 87.8% | 0% |
| Base INT8 + vocabulary | 1.40 s | 806 ms | 992 ms | 0.276 | 3.62× | 18.0% | 46.3% | 25% |

`RTF` is processing seconds divided by audio seconds; lower is better. Audio
throughput is audio seconds processed per wall-second; higher is better.

Approximate cached model sizes are 74.6 MiB for Tiny and 141.0 MiB for Base.
Observed process RSS after each benchmark was 146.8 MiB and 179.8 MiB,
respectively.

## Outcome

Base INT8 with vocabulary prompting is the strongest tested configuration. It
meets a provisional desktop P95 compute-latency gate of one second and remains
3.62 times faster than real time. The vocabulary improves CER by 38.9% relative
and WER by 47.2% relative compared with the same model without prompting.

Tiny is faster and smaller, but its vocabulary-prompt run produced a repeatable
9.14-second decode outlier on one 2.69-second utterance. It should not be chosen
for interactive use without a decoder timeout and fallback.

No configuration passes a reasonable production quality gate yet. Base plus
vocabulary still has 46.3% WER on clean synthetic speech, and the benchmark has
no rural/noisy/code-mixed coverage.

## Recommended next experiment

1. Replace synthetic-only evaluation with a consented, locked Tamil corpus that
   includes rural accents, low-cost microphones, noise, and Tanglish/code mixing.
2. Benchmark quantized multilingual whisper.cpp in an Android release build on
   the agreed low-end target phone.
3. Enforce an end-of-speech decode deadline and fall back to text/no-match rather
   than allowing a long decoder loop.
4. Evaluate region-scoped prompt sets and prompt-size caps; do not load the full
   statewide vocabulary into every request.
5. Decide whether to replace the Vosk assumption or fund creation of a compatible
   Tamil acoustic/language model. Runtime vocabulary generation alone cannot add
   Tamil acoustic support.
