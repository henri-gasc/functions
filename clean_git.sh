#!/usr/bin/env bash

clean() {
    git rev-parse 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "$1"
        before=$(du -sh)
        git gc --aggressive
        after=$(du -sh)
        echo "$1: ${before%	*} -> ${after%	*}"
        builtin cd ".."
        echo ""
    else
        loop
    fi
}

loop() {
    clean
    for d in $(ls -d -- */); do
        builtin cd "$d"
        clean
        builtin cd ".."
    done
}

builtin cd "$GITDIR"
if [ "$@" != "" ]; then
    for d in "$@"; do
        builtin cd "$d"
        loop
        builtin cd ".."
    done
else
    loop
fi
