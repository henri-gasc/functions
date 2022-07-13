#!/usr/bin/env bash

clean() {
    echo "$1"
    before=$(du -sh)
    git gc --aggressive
    after=$(du -sh)
    echo "$1: ${before%	*} -> ${after%	*}"
    echo ""
}

loop() {
    builtin cd "$1"
    git rev-parse 2>/dev/null
    if [ $? -eq 0 ]; then
        clean "$1"
    else
        for d in $(find . -mindepth 1 -maxdepth 1 -type d); do
            if [ "$d" != "./.git" ]; then
                builtin cd "$d"
                clean "$d"
                builtin cd ".."
            fi
        done
    fi
    builtin cd ".."
}

builtin cd "$GITDIR"
if [[ "$@" == "" ]]; then
    loop "."
else
    for d in "$@"; do
        loop "$d"
    done
fi
