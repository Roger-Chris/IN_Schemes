# Voice benchmark lab

This directory isolates the offline Tamil speech experiment from the broader
backend. It measures three separate concerns:

1. deterministic scheme-vocabulary compilation;
2. CPU transcription latency and sequential throughput;
3. transcription quality with and without vocabulary prompting.

## Important limitation

Vosk does not currently publish an official Tamil model. The benchmark therefore
uses multilingual Whisper through `faster-whisper` as an executable CPU baseline.
The generated `grammar.json` is still Vosk-compatible, but it cannot be tested
against Tamil Vosk until a compatible dynamic-graph acoustic model is obtained or
trained. Whisper hotwords are a prompt bias, not a hard grammar constraint.

The included phrases and generated speech are synthetic benchmark fixtures. They
are not reviewed government content and must not be published as production data.

## Setup

```powershell
python -m venv .venv-voice
.\.venv-voice\Scripts\python -m pip install -r voice\requirements.txt
```

## Build and test the vocabulary

```powershell
.\.venv-voice\Scripts\python voice\src\build_vocab.py `
  --input voice\data\benchmark_phrases.json `
  --output voice\artifacts\vocab-2026.07.1 `
  --version 2026.07.1 `
  --benchmark-iterations 500 `
  --report voice\results\vocab-build.json

.\.venv-voice\Scripts\python -m unittest discover -s voice\tests -v
```

## Generate synthetic Tamil speech

This step uses Microsoft Edge's online Tamil TTS voice, so it requires network
access. It creates local benchmark fixtures only.

```powershell
.\.venv-voice\Scripts\python voice\src\generate_audio.py `
  --input voice\data\benchmark_phrases.json `
  --output voice\data\generated_audio
```

## Run an ASR benchmark

Model weights are downloaded to the ignored `voice/.cache/models` directory on
first use.

```powershell
.\.venv-voice\Scripts\python voice\src\benchmark_asr.py `
  --model tiny `
  --audio-manifest voice\data\generated_audio\manifest.json `
  --vocab-manifest voice\artifacts\vocab-2026.07.1\manifest.json `
  --output voice\results\tiny-int8.json
```

Use `--model base` to test the next quality/latency tier. Results from this
desktop are directional; the Android release build must be benchmarked on the
agreed low-end target device before making a product latency commitment.

## Run the live microphone demo

```powershell
.\.venv-voice\Scripts\python voice\src\demo_app.py
```

Open `http://127.0.0.1:7860`, record a Tamil question, then select
**கேள்வியை அறிந்து பதில் சொல்லு**. ASR and matching run locally; spoken response
generation uses online Edge TTS. The displayed answer is synthetic demo content,
not authoritative government guidance.

## AI4Bharat IndicConformer desktop comparison

The reproducible AI4Bharat runtime is isolated in Ubuntu/WSL because the official
AI4Bharat NeMo fork targets an older dependency stack. From PowerShell:

```powershell
wsl -d Ubuntu -- bash voice/setup_ai4bharat_wsl.sh
wsl -d Ubuntu -- bash voice/run_ai4bharat_demo.sh --background
```

Open `http://127.0.0.1:7861` for the AI4Bharat CTC/CUDA demo. The existing
Whisper demo remains on port 7860. Use `--status` or `--stop` with the launcher
to inspect or stop its WSL user service.

The full benchmark outcome and tokenizer compatibility finding are in
`voice/results/AI4BHARAT_BENCHMARK_REPORT.md`. Model files, extracted tokenizers,
FFmpeg, and virtual environments stay in ignored caches and are not committed.

## AI4Bharat 600M multilingual ONNX comparison

This gated model uses a separate WSL runtime and a revision-pinned Hugging Face
snapshot. First accept the repository conditions in your Hugging Face account,
then run:

```powershell
wsl -d Ubuntu -- bash voice/setup_ai4bharat_600m_wsl.sh
wsl -d Ubuntu -- bash voice/run_ai4bharat_600m_demo.sh --background
```

If setup reports that authentication is missing, run the displayed `hf auth login`
command and approve its browser device flow. Open `http://127.0.0.1:7862` for the
600M RNNT/CUDA demo. Ports 7860 and 7861 remain the Whisper and Tamil-only
AI4Bharat comparisons.

Benchmark details are in
`voice/results/AI4BHARAT_600M_BENCHMARK_REPORT.md`. The public `ta_256`
SentencePiece vocabulary exactly matches this model's Tamil IDs 0-255; the model
adds the CTC blank at ID 256.
