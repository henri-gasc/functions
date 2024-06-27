#!/usr/bin/env bash

if [ "${GITDIR}" == "" ]; then
	echo "The GITDIR env variable is empty. Please set it to point somewhere"
	exit 1
fi

update_file="${GITDIR}/repoUpdated.txt"
abandonned_file="${GITDIR}/repoProbablyAbandonned.txt"

pull_git_repo() {
    trash=`git stash && git clean -d -f`
    git fetch
    git pull
    git submodule update --recursive
}

update_git_repo() {
	now=$(date -u +%s)
	last_commit=$(git log -1 --format=%ct)
	if [ ! -f ".git/FETCH_HEAD" ]; then
		last_fetch=0
	else
		last_fetch=$(stat -c %Y .git/FETCH_HEAD)
	fi
	okay=""
	# If last commit is less than a week ago, then fetch
	if [ $((now - last_commit)) -lt 604800 ]; then
		okay="yes"
	# else if last commit is less than 30 days old, and last fetch is more than a week ago, also fetch
	elif [ $((now - last_commit)) -lt 2592000 ] && [ $((now - last_fetch)) -gt 604800 ]; then
		okay="yes"
	# else, if the last commit is more than a year old, add the repo to probably abandonned
	elif [ $((now - last_commit)) -gt 31536000 ]; then
		echo "$1" >> "${abandonned_file}"
	# If last commit more than 1 month, and last fetch too, fetch
	elif [ $((now - last_commit)) -gt 2592000 ] && [ $((now - last_fetch)) -gt 2592000 ]; then
		okay="yes"
	fi
	if [ "${okay}" == "" ]; then
		return
	fi

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

if [ -f "${abandonned_file}" ]; then
	rm "${abandonned_file}"
fi
if [[ "$1" == "." ]]; then
	loop "."
	builtin cd "${start_folder}"
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

if [ -f "${abandonned_file}" ]; then
	echo "Use 'cat ${abandonned_file}' to see the list of repositories that were not updated in the last year"
fi
