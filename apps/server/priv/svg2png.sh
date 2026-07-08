#!/usr/bin/env bash

# usage: svg2png.sh <in-svg-path> <out-png-path> <zoom-factor>

set -Eeuo pipefail

timeout_cmd=()

if which timeout 2>/dev/null; then
    if timeout --help 2>&1 | grep BusyBox >/dev/null; then
        timeout_cmd=(timeout -s KILL 15)
    else
        timeout_cmd=(timeout -k 5 10)
    fi
elif which gtimeout 2>/dev/null; then
    timeout_cmd=(gtimeout -k 5 10)
fi

"${timeout_cmd[@]}" rsvg-convert -z "$3" -o "$2" "$1"

out=$2

if which pngquant 2>/dev/null; then
    echo "Optimizing PNG with pngquant..."
    pngquant 24 -o "${out}.q" "$out"
    mv "${out}.q" "$out"
fi

echo "Done."
