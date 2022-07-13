#!/usr/bin/env bash

pull_if_git_repo() {
    git rev-parse 2>/dev/null
    if [ $? -eq 0 ]; then
        trash=`git stash && git clean -d -f`
        git fetch
        git pull
        git submodule update --recursive
    fi
}

loop() {
    pull_if_git_repo
    for d in $(ls -d -- */); do
        builtin cd "$d"
        git rev-parse 2>/dev/null
        if [ $? -eq 0 ]; then loop
        else
            echo "git pull $d"
            tag=$(git describe --tags --abbrev=0) 2>/dev/null
            pull_if_git_repo
            new_tag=$(git describe --tags --abbrev=0) 2>/dev/null
            if [ $? -eq 0 ] && [ $new_tag != $tag ]; then
                echo "$d : $tag -> $new_tag" >> ../repoUpdated.txt
            fi
            builtin cd ".."
            echo ""
        fi
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
    touch "repoUpdated.txt"
    loop
    if [ "$(cat repoUpdated.txt)" == "" ]; then
        echo "No update were detected"
    else
        echo "The following repositories were updated:"
        cat repoUpdated.txt
        rm repoUpdated.txt
    fi
fi
