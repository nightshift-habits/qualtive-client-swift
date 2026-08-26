#!/bin/bash
# Format Swift files with swift-format after an agent file edit.

PATH="/usr/bin:/bin:/opt/homebrew/bin:/usr/local/bin:${PATH:-}"

input=$(cat)
file_path=$(
  printf '%s\n' "$input" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("file_path") or "")' 2>/dev/null
) || exit 0

[[ -n "$file_path" ]] || exit 0
[[ "$file_path" == /* ]] || file_path="$PWD/$file_path"
[[ -f "$file_path" ]] || exit 0
[[ "$file_path" == *.swift ]] || exit 0

config="${PWD}/.swift-format"
if [[ -f "$config" ]]; then
  swift format --in-place --configuration "$config" "$file_path" || true
else
  swift format --in-place "$file_path" || true
fi

exit 0
