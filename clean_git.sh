#!/usr/bin/env bash

get_size() {
    du -shck . | tail -n 1 | cut -f 1
}

clean() {
	if [ "$1" == "." ]; then
		echo "$(basename ${PWD})"
	else
		echo "$1"
	fi
    before="$(get_size)"
    git clean -dfx
	git gc --aggressive --prune=now
    git submodule foreach clean_git .
    git repack -Ad --depth=4095 --window=5000
    after="$(get_size)"
    echo "$1: ${before}k -> ${after}k"
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
    if [[ "$1" != "." ]]; then
        builtin cd ".."
    fi
}

if [[ "$@" == "" ]]; then
    base_path="$(pwd)"
    builtin cd "${GITDIR}"
    before_g="$(get_size)"
    loop "."
    after_g="$(get_size)"
    builtin cd "${base_path}"
else
    before_g="$(get_size)"
    for d in "$@"; do
        loop "$d"
    done
    after_g="$(get_size)"
fi
echo "Saved $((${before_g} - ${after_g}))k (${before_g}k -> ${after_g})k"
