#!/usr/bin/env bash

update_file="${GITDIR}/repoUpdated.txt"

pull_git_repo() {
    trash=`git stash && git clean -d -f`
    git fetch
    git pull
    git submodule update --recursive
}

update_git_repo() {
	echo "git pull $1"
	tag="$(git describe --tags $(git rev-list --tags --max-count=1) 2>/dev/null)"
	pull_git_repo
	new_tag="$(git describe --tags $(git rev-list --tags --max-count=1) 2>/dev/null)"
	if [ $? -eq 0 ] && [ "$new_tag" != "$tag" ]; then
		echo "$d : $tag -> $new_tag" >> "${update_file}"
	fi
	echo ""
}

loop() {
    git rev-parse 2>/dev/null
    if [ $? -eq 0 ]; then
		update_git_repo "$(basename ${PWD})"
    else
        for d in $(find . -mindepth 1 -maxdepth 1 -type d); do
            builtin cd "$d"
            git rev-parse 2>/dev/null
            if [ $? -eq 0 ]; then
				detached="$(git status | rg 'detached')"
				if [ "${detached}" != "" ]; then
					branch_name="$(git remote show origin | sed -n '/HEAD branch/s/.*: //p')"
					echo "Going to ${branch_name}"
					trash=`git checkout "${branch_name}"`
				fi
				update_git_repo "$d"
            else
                loop
            fi
            builtin cd ".."
        done
    fi
}

start_folder="$(pwd)"

if [[ "$1" == "." ]]; then
	builtin cd "${start_folder}"
	loop "."
	builtin cd "${GITDIR}"
elif [[ "$@" != "" ]]; then
    for d in "$@"; do
        builtin cd "$d"
        loop "$d"
        builtin cd ".."
    done
else
	builtin cd "${GITDIR}"
    loop
	builtin cd "${start_folder}"
fi
if [ ! -f "${update_file}" ]; then
    echo "No update were detected"
else
    echo "The following repositories were updated:"
    cat "${update_file}"
    rm "${update_file}"
fi
