#!/usr/bin/env bash

# First argument is the directory to commit in
git_directory="$1"

if [[ "$git_directory" == "" ]]; then
	echo "No directory given"
	exit
fi
if [[ "$(git rev-parse)" != "" ]]; then
	echo "Not a git directory"
	exit
fi

# Second argument is optional, the commit message
message="$2"
if [[ "${message}" == "" ]]; then
	message="Automated commit $(date -u +%F)"
fi


builtin cd "$git_directory"

if [[ -z "$(git status --porcelain=v1 2>/dev/null)" ]]; then
	echo "Not changes found"
	exit
fi

git commit -am "${message}"
