#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <scale> [wow2_dir]" >&2
  exit 1
fi

scale="$1"
wow2_dir="${2:-$HOME/.wine/drive_c/Program Files (x86)/WoW2}"
wtf_dir="$wow2_dir/WTF"
autoexec_file="$wtf_dir/autoexec.wtf"
tmp_file="$(mktemp)"

case "$scale" in
  ''|*[!0-9.]*)
    echo "Scale must be a decimal number." >&2
    rm -f "$tmp_file"
    exit 1
    ;;
esac

mkdir -p "$wtf_dir"

if [[ -f "$autoexec_file" ]]; then
  grep -vi '^[[:space:]]*scaleui[[:space:]]' "$autoexec_file" > "$tmp_file" || true
else
  : > "$tmp_file"
fi

printf 'scaleui %s\n' "$scale" >> "$tmp_file"
mv "$tmp_file" "$autoexec_file"

echo "Wrote 'scaleui $scale' to $autoexec_file"
