#!/usr/bin/env bash

clean() {
    echo "$1"
    before="$(du -sh . | cut -f 1)"
    git gc --aggressive
    after="$(du -sh . | cut -f 1)"
    echo "$1: $before -> $after"
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
    before="$(du -sh . | cut -f 1)"
    loop "."
    after="$(du -sh . | cut -f 1)"
else
    before="$(du -shc $@ | tail -n 1 | cut -f 1)"
    for d in "$@"; do
        loop "$d"
    done
    after="$(du -shc $@ | tail -n 1 | cut -f 1)"
fi
echo "From $before to $after"
