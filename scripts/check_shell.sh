#!/usr/bin/env bash
set -euo pipefail

shell_files=()
while IFS= read -r shell_file; do
  shell_files+=("$shell_file")
done < <(git ls-files '*.sh' '*.bash' '*.zsh')

if ((${#shell_files[@]} == 0)); then
  echo "shellcheck skipped: no tracked shell scripts"
  exit 0
fi

for shell_file in "${shell_files[@]}"; do
  bash -n "$shell_file"
done

shellcheck "${shell_files[@]}"
