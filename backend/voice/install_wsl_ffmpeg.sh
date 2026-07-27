#!/usr/bin/env bash
set -euo pipefail

ARCHIVE_NAME="ffmpeg-n7.1-latest-linux64-gpl-7.1.tar.xz"
ARCHIVE="$HOME/.cache/$ARCHIVE_NAME"
CHECKSUMS="$HOME/.cache/ffmpeg-builds-checksums.sha256"
INSTALL_DIR="$HOME/.local/ffmpeg-n7.1"
BASE_URL="https://github.com/BtbN/FFmpeg-Builds/releases/download/latest"

mkdir -p "$HOME/.cache" "$INSTALL_DIR"
curl -L --fail --retry 3 -o "$ARCHIVE" "$BASE_URL/$ARCHIVE_NAME"
curl -L --fail --retry 3 -o "$CHECKSUMS" "$BASE_URL/checksums.sha256"

expected="$(grep " $ARCHIVE_NAME" "$CHECKSUMS" | awk '{print $1}')"
actual="$(sha256sum "$ARCHIVE" | awk '{print $1}')"
if [[ -z "$expected" || "$expected" != "$actual" ]]; then
  echo "FFmpeg checksum verification failed" >&2
  exit 1
fi

tar -xJf "$ARCHIVE" --strip-components=1 -C "$INSTALL_DIR"
"$INSTALL_DIR/bin/ffmpeg" -version | head -n 1
"$INSTALL_DIR/bin/ffprobe" -version | head -n 1
echo "SHA256=$actual"
