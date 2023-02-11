#!/usr/bin/env bash

pull_git_repo() {
    trash=`git stash && git clean -d -f`
    git fetch
    git pull
    git submodule update --recursive
}

loop() {
    git rev-parse 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "git pull $1"
        pull_git_repo
    else
        for d in $(find . -mindepth 1 -maxdepth 1 -type d); do
            builtin cd "$d"
            git rev-parse 2>/dev/null
            if [ $? -eq 0 ]; then
                echo "git pull $d"
                tag=$(git describe --tags $(git rev-list --tags --max-count=1) 2>/dev/null)
                pull_git_repo
                new_tag=$(git describe --tags $(git rev-list --tags --max-count=1) 2>/dev/null)
                if [ $? -eq 0 ] && [ "$new_tag" != "$tag" ]; then
                    echo "$d : $tag -> $new_tag" >> $GITDIR/../repoUpdated.txt
                fi
                echo ""
            else
                loop
            fi
            builtin cd ".."
        done
    fi
}

builtin cd "$GITDIR"
if [[ "$@" != "" ]]; then
    for d in "$@"; do
        builtin cd "$d"
        loop "$d"
        builtin cd ".."
    done
else
    touch "../repoUpdated.txt"
    loop
    if [ "$(cat ../repoUpdated.txt)" == "" ]; then
        echo "No update were detected"
    else
        echo "The following repositories were updated:"
        cat ../repoUpdated.txt
        rm ../repoUpdated.txt
    fi
fi
