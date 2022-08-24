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
                loop "$d"
            fi
        done
    fi
    builtin cd ".."
}

builtin cd "$GITDIR"
if [[ "$@" == "" ]]; then
    before_g="$(du -sh . | cut -f 1)"
    loop "."
    after_g="$(du -sh . | cut -f 1)"
else
    before_g="$(du -shc $@ | tail -n 1 | cut -f 1)"
    for d in "$@"; do
        loop "$d"
    done
    after_g="$(du -shc $@ | tail -n 1 | cut -f 1)"
fi
echo "From $before_g to $after_g"
