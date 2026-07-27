#!/usr/bin/env bash
set -euo pipefail

VOICE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UV_ENV="$HOME/.venvs/uv-bootstrap"
UV="$UV_ENV/bin/uv"
ASR_ENV="$HOME/.venvs/in-schemes-ai4bharat"
MODEL_DIR="$VOICE_DIR/.cache/ai4bharat-models"
MODEL_NAME="indicconformer_stt_ta_hybrid_rnnt_large.nemo"
MODEL_PATH="$MODEL_DIR/$MODEL_NAME"
MODEL_URL="https://objectstore.e2enetworks.net/indicconformer/models/$MODEL_NAME"
MODEL_SHA256="40a6fce3374ceb67daa2a071e92f0948c51c6a95b734d4881a3bcfe0b1bed32a"

if [[ ! -x "$UV" ]]; then
  python3 -m venv "$UV_ENV"
  "$UV_ENV/bin/python" -m pip install --disable-pip-version-check uv==0.8.4
fi

"$UV" python install 3.10
if [[ ! -x "$ASR_ENV/bin/python" ]]; then
  "$UV" venv "$ASR_ENV" --python 3.10
fi
"$UV" pip install --python "$ASR_ENV/bin/python" \
  --index-url https://download.pytorch.org/whl/cu121 \
  torch==2.4.1 torchaudio==2.4.1
"$UV" pip install --python "$ASR_ENV/bin/python" \
  -r "$VOICE_DIR/requirements-ai4bharat.txt"

bash "$VOICE_DIR/install_wsl_ffmpeg.sh"
mkdir -p "$MODEL_DIR"
if [[ ! -f "$MODEL_PATH" ]]; then
  curl -L --fail --retry 3 -o "$MODEL_PATH.part" "$MODEL_URL"
  actual="$(sha256sum "$MODEL_PATH.part" | awk '{print $1}')"
  if [[ "$actual" != "$MODEL_SHA256" ]]; then
    echo "AI4Bharat model checksum verification failed: $actual" >&2
    exit 1
  fi
  mv "$MODEL_PATH.part" "$MODEL_PATH"
fi

actual="$(sha256sum "$MODEL_PATH" | awk '{print $1}')"
if [[ "$actual" != "$MODEL_SHA256" ]]; then
  echo "Existing AI4Bharat model has an unexpected checksum: $actual" >&2
  exit 1
fi

"$ASR_ENV/bin/python" -c \
  "import torch, nemo; print(torch.__version__, torch.cuda.is_available(), nemo.__version__)"
