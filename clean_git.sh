#!/usr/bin/env bash

get_size() {
	du -shck . | tail -n 1 | cut -f 1
}

clean() {
	silent="no"
	if [ "$1" == "--quiet" ] || [ "$2" == "--quiet" ]; then
		silent="yes"
	fi
	if [ "${silent}" == "no" ]; then
		if [ "$1" == "." ]; then
			echo "$(basename ${PWD})"
		else
			echo "$1"
		fi
	fi
	before="$(get_size)"
	git clean -dfx
	git gc --aggressive --prune=now
	git submodule foreach clean_git . --quiet
	git repack -Ad --depth=4095 --window=5000
	after="$(get_size)"
	if [ "${silent}" == "no" ]; then
		echo "$1: ${before}k -> ${after}k"
		echo ""
	fi
}

loop() {
	builtin cd "$1"
	git rev-parse 2>/dev/null
	if [ $? -eq 0 ]; then
		clean "$@"
	else
		for d in $(find . -mindepth 1 -maxdepth 1 -type d); do
			if [ "$d" != "./.git" ]; then
				loop "$d" "$2"
			fi
		done
	fi
	if [[ "$1" != "." ]]; then
		builtin cd ".."
	fi
}

if [[ "$@" == "" ]]; then
	if [ "${GITDIR}" == "" ]; then
		echo "The GITDIR env variable is empty. Please set it to point somewhere"
		exit 1
	fi

	base_path="$(pwd)"
	builtin cd "${GITDIR}"
	before_g="$(get_size)"
	loop "."
	after_g="$(get_size)"
	builtin cd "${base_path}"
else
	before_g="$(get_size)"
	silent="no"
	for d in "$@"; do
		if [ "$d" == "--quiet" ]; then silent="yes"; fi
	done

	for d in "$@"; do
		if [ "$d" == "--quiet" ]; then continue; fi
		if [ "${silent}" == "no" ]; then
			loop "$d"
		else
			loop "$d" --quiet
		fi
	done
	after_g="$(get_size)"
fi
echo "Saved $((${before_g} - ${after_g}))k (${before_g}k -> ${after_g})k"
