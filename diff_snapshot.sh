#!/bin/bash

# Copy-paste of the functions in btrfs_snapshot.sh
line_is_correct() {
	grep -E '\$\(|<\(|`' <(echo "$1") >/dev/null
	if [[ $? == 0 ]]; then
		echo "false"
	else
		echo "true"
	fi
}
source_variable_if_correct() {
	line_to_source="$(grep $1 $2)"
	status=$(line_is_correct "${line_to_source}")
	if [[ "${status}" == "true" ]]; then
		source <(echo "${line_to_source}")
	fi
}

# First argument, folder to get the list of files from
# Second argument, file to put the list in
search_and_replace() {
	IGNORE_DIRS=""
	source_variable_if_correct "IGNORE_DIRS=\'" "${HOME}/.config/snapshot"

	tmp_file="/tmp/snapshot_tmp_file"
	rm "${tmp_file}"
	if [ -f "$2" ] && [ "$2" != "/tmp/current" ]; then
		echo "$1 is already done"
	else
		rg --files -uuu "$1" -g '!\.cache' -g '!\.git' > "${tmp_file}"
		echo "  Done searching"
		sed -e "s#^$1/#/#g" "${tmp_file}" -i
		echo "  Done replacing in ${tmp_file}"
		if [[ IGNORE_DIRS != "" ]]; then
			forbidden="$(echo $IGNORE_DIRS | sed -e 's/ /\|/g')"
			rg -v "${forbidden}" "${tmp_file}" > "${tmp_file}_filter_again"
			mv "${tmp_file}_filter_again" "${tmp_file}"
		fi
		sort -o "${tmp_file}" "${tmp_file}"
		echo "  Done sorting"
		mv "${tmp_file}" "$2"
	fi
}

if [ "$3" != "" ]; then
	echo "You put more than 2 folder to compare"
	exit 1
elif [ ! -d "$1" ]; then
	echo "$1 does not exist or is not a directory"
	exit 2
elif [ "$2" != "" ] && [ ! -d "$2" ]; then
	echo "$2 does not exist or is not a directory"
	exit 2
elif [ "$1" == "$2" ]; then
	echo "The two folders you want to compare are the same"
	exit 3
fi

if [ "$2" == "" ]; then
	first_folder="${HOME}"
	out_1="/tmp/current"
else
	first_folder="$2"
	out_1="/tmp/snapshot_$(basename ${first_folder})"
fi

second_folder="$1"
out_2="/tmp/snapshot_$(basename ${second_folder})"

filter() {
	rg -v '/CachedData/|/Cache_Data/|/\.config/VSCodium/|/\.vscode-oss/extensions/' | \
	rg -v '/__pycache__/|/\.mypy_cache/|/venv/|/.env/' | \
	rg -v '/node_modules/|/\.npm/' | \
	rg -v '/\.cargo/advisory-db/|/\.cargo/registry/|/\.cargo/git/' | \
	rg -v '/\.wine/|/\.julia/|/\.nuget/|/\.mapscii/|/\.m2/repository/|/\.docker/' | \
	rg -v '/\.local/share/Trash/|/\.local/share/okular/' | \
	rg -v '/\.local/share/nvim/|/\.local/share/zed|/\.local/share/Steam' | \
	rg -v '/\.mozilla/|/\.thunderbird/|/RecentDocuments/' | \
	rg -v '/\.config/Signal/attachments/' | \
	rg -v '/\.config/libreoffice/' | \
	rg -v '/target/build|/target/release/|/target/debug/|/build/' | \
	rg -v '/\.local/state/' | \
	rg -v '/mangas/.*/[0-9]*' | \
	rg -v '/Documents/Gentoo/gentoo/|/Documents/Gentoo/GURU/' | \
	rg -v '/tmp/'
}

echo "Doing ${first_folder}"
search_and_replace "${first_folder}" "${out_1}"
echo "Doing ${second_folder}"
search_and_replace "${second_folder}" "${out_2}"

echo "Now diffing"
diff "${out_2}" "${out_1}" > /tmp/diff

echo "In ${second_folder} but not in ${first_folder}:"
rg "^< " /tmp/diff --no-line-number | filter
echo "In ${first_folder} but not in ${second_folder}:"
rg "^> " /tmp/diff --no-line-number | filter
