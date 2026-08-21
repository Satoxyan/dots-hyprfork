#!/usr/bin/env bash
for cmd in "$@"; do
    [[ -z "$cmd" ]] && continue
    command -v "${cmd%% *}" >/dev/null 2>&1 || continue
    exec $cmd
done