#!/usr/bin/env bash
set -euo pipefail

VOICE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UV_ENV="$HOME/.venvs/uv-bootstrap"
UV="$UV_ENV/bin/uv"
HF_CLI_ENV="$HOME/.venvs/hf-cli"
HF="$HF_CLI_ENV/bin/hf"
ASR_ENV="$HOME/.venvs/in-schemes-ai4bharat-600m"
HF_CACHE="$HOME/.cache/in-schemes-hf/hub"
MODEL_REPOSITORY="ai4bharat/indic-conformer-600m-multilingual"
MODEL_REVISION="e9b71b369c048e2c6b634d4c131061c34e441179"

if [[ ! -x "$UV" ]]; then
  python3 -m venv "$UV_ENV"
  "$UV_ENV/bin/python" -m pip install --disable-pip-version-check uv==0.8.4
fi

if [[ ! -x "$HF" ]]; then
  python3 -m venv "$HF_CLI_ENV"
  "$HF_CLI_ENV/bin/python" -m pip install --disable-pip-version-check \
    huggingface-hub==1.24.0
fi

if ! "$HF" auth whoami --format quiet >/dev/null 2>&1; then
  echo "Hugging Face authentication is required for the gated 600M model." >&2
  echo "Run: $HF auth login" >&2
  echo "Approve the browser device flow, then rerun this setup script." >&2
  exit 3
fi

"$UV" python install 3.10
if [[ ! -x "$ASR_ENV/bin/python" ]]; then
  "$UV" venv "$ASR_ENV" --python 3.10
fi
"$UV" pip install --python "$ASR_ENV/bin/python" \
  --index-url https://download.pytorch.org/whl/cu121 \
  torch==2.4.1 torchaudio==2.4.1
"$UV" pip install --python "$ASR_ENV/bin/python" \
  -r "$VOICE_DIR/requirements-ai4bharat-600m.txt"

if [[ ! -x "$HOME/.local/ffmpeg-n7.1/bin/ffmpeg" ]] || \
   [[ ! -x "$HOME/.local/ffmpeg-n7.1/bin/ffprobe" ]]; then
  bash "$VOICE_DIR/install_wsl_ffmpeg.sh"
fi
mkdir -p "$HF_CACHE"
"$HF" download "$MODEL_REPOSITORY" \
  --revision "$MODEL_REVISION" \
  --cache-dir "$HF_CACHE"

SITE_PACKAGES="$ASR_ENV/lib/python3.10/site-packages"
CUDA_LIBRARY_PATH="$SITE_PACKAGES/torch/lib"
for component_dir in "$SITE_PACKAGES"/nvidia/*/lib; do
  CUDA_LIBRARY_PATH="$CUDA_LIBRARY_PATH:$component_dir"
done
export LD_LIBRARY_PATH="$CUDA_LIBRARY_PATH${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

"$ASR_ENV/bin/python" - <<'PY'
import onnxruntime
import torch

providers = onnxruntime.get_available_providers()
assert torch.cuda.is_available(), "Torch cannot see CUDA"
assert "CUDAExecutionProvider" in providers, providers
print(torch.__version__, torch.cuda.get_device_name(0), providers)
PY

"$ASR_ENV/bin/python" -m pip check
