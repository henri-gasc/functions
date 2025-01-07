#!/usr/bin/env bash

get_size() {
	to_do="$@"
	if [ "${to_do}" == "" ]; then
		to_do="."
	fi
	du -shck ${to_do} | tail -n 1 | cut -f 1
}

clean() {
	if [ "$2" != "--quiet" ]; then
		if [ "$1" == "." ]; then
			echo $(basename "${PWD}")
		else
			echo "$1"
		fi
	fi
	before="$(get_size)"
	git clean -dfx
	git gc --aggressive --prune=now
	git submodule foreach "clean_git . --quiet"
	git repack -Ad --depth=4095 --window=5000
	after="$(get_size)"
	if [ "$2" != "--quiet" ]; then
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

dir_to_do=""
silent="not_quiet"
for d in "$@"; do
	if [ "$d" == "--quiet" ]; then
		silent="quiet"
	elif [ "$d" == "." ]; then
		dir_to_do+=" ${PWD}"
	else
		dir_to_do+=" ${d}"
	fi
done

base_path="${PWD}"

if [[ "${dir_to_do}" == "" ]]; then
	if [ "${GITDIR}" == "" ]; then
		echo "The GITDIR env variable is empty. Please set it to point somewhere"
		exit 1
	fi
	dir_to_do="${GITDIR}"
else
	dir_to_do="${dir_to_do:1}"
fi

if [ "${silent}" == "not_quiet" ]; then
	before_g=$(get_size "${dir_to_do}")
fi
for d in "${dir_to_do}"; do
	if [ "$d" == "--quiet" ]; then continue; fi
	loop "$d" "--${silent}"
done
if [ "${silent}" == "not_quiet" ]; then
	after_g=$(get_size "${dir_to_do}")
	echo "Saved $((${before_g} - ${after_g}))k (${before_g}k -> ${after_g})k"
fi

builtin cd "${base_path}"
