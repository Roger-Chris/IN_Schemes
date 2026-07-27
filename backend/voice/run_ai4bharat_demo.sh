#!/usr/bin/env bash
set -euo pipefail

VOICE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON="$HOME/.venvs/in-schemes-ai4bharat/bin/python"
APP="$VOICE_DIR/src/demo_ai4bharat_app.py"
export PATH="$HOME/.local/ffmpeg-n7.1/bin:$PATH"
SERVICE="in-schemes-ai4bharat-demo.service"

run_demo() {
  exec "$PYTHON" "$APP" \
    --device cuda \
    --decoder ctc \
    --host 127.0.0.1 \
    --port 7861
}

case "${1:-}" in
--background)
  if systemctl --user status "$SERVICE" >/dev/null 2>&1; then
    systemctl --user restart "$SERVICE"
  else
    systemd-run --user --unit="${SERVICE%.service}" \
      /usr/bin/bash "$VOICE_DIR/run_ai4bharat_demo.sh" --service
  fi
  systemctl --user is-active "$SERVICE"
  exit 0
  ;;
--stop)
  systemctl --user stop "$SERVICE"
  exit 0
  ;;
--status)
  systemctl --user status "$SERVICE" --no-pager
  exit 0
  ;;
--service | "") ;;
*)
  echo "usage: $0 [--background|--stop|--status|--service]" >&2
  exit 2
  ;;
esac

run_demo
