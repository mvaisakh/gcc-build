#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0

set -Eeuo pipefail

CUR_DIR="${1:-$(pwd)}"
X86S="$(command -v strip || true)"
A64S="$(command -v aarch64-linux-gnu-strip || true)"
A32S="$(command -v arm-linux-gnu-strip || true)"

if [ ! -d "$CUR_DIR" ]; then
  echo "error: directory not found: $CUR_DIR" >&2
  exit 1
fi

if [ -z "$X86S" ] || [ -z "$A64S" ] || [ -z "$A32S" ]; then
  echo "error: one or more architecture strip utilities are missing" >&2
  echo "Install binutils for x86/aarch64/arm targets before running this script." >&2
  exit 1
fi

find "$CUR_DIR" -type f -exec file {} \; > .file-idx

while IFS= read -r file; do
  [ -n "$file" ] || continue
  if echo "$file" | grep -Eq 'x86.*not strip|x86.*not stripped'; then
    "$X86S" "$file"
  fi
done < <(grep 'x86' .file-idx | grep 'not strip' | grep -v 'relocatable' | tr ':' ' ' | awk '{print $1}')

while IFS= read -r file; do
  [ -n "$file" ] || continue
  "$A64S" "$file"
done < <(grep 'ARM' .file-idx | grep 'aarch64' | grep 'not strip' | grep -v 'relocatable' | tr ':' ' ' | awk '{print $1}')

while IFS= read -r file; do
  [ -n "$file" ] || continue
  "$A32S" "$file"
done < <(grep 'ARM' .file-idx | grep '32.bit' | grep 'not strip' | grep -v 'relocatable' | tr ':' ' ' | awk '{print $1}')

rm -f .file-idx
