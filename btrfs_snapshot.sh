#!/bin/bash

# Script takes one argument
# To run this script every day, you should put the following
# in /etc/anacrontab (without the comment obviously):
# 1 1 make_snapshots /usr/local/bin/btrfs_snapshot

# First argument is the line to verify
line_is_correct() {
	grep -E '\$\(|<\(|`' <(echo "$1") >/dev/null
	if [[ $? == 0 ]]; then
		echo "false"
	else
		echo "true"
	fi
}

# First argument is the what to search to be able to source the variable
# Second argument is the config path
source_variable_if_correct() {
	line_to_source="$(grep $1 $2)"
	status=$(line_is_correct "${line_to_source}")
	if [[ "${status}" == "true" ]]; then
		source <(echo "${line_to_source}")
	fi
}

snapshot_user() {
	NOW=$(date +"%Y-%m-%d_%H:%M:%S")

	user_dir="$1"
	path_config="${user_dir}/.config/snapshot"

	DIR_TO_SAVE="${user_dir}"
	DIR_SNAPSHOTS="$2"
	IGNORE_DIRS=""

	# Customize things (read from config)
	if [[ -f "${path_config}" ]]; then
		source_variable_if_correct "DIR_TO_SAVE=\'" "${path_config}"
		source_variable_if_correct "DIR_SNAPSHOTS=\'" "${path_config}"
		source_variable_if_correct "IGNORE_DIRS=\'" "${path_config}"
	fi

	# Do not save if we are told not to
	if [[ -f "${DIR_SNAPSHOTS}/.no" ]]; then
		echo "Not saving user ${back_user}"
		return
	fi

	if [[ ! -d "${DIR_SNAPSHOTS}" ]]; then
		mkdir -p "${DIR_SNAPSHOTS}"
	fi

	SNAPSHOT_PATH="${DIR_SNAPSHOTS}/backup_${NOW}"

	echo "Saving ${DIR_TO_SAVE} to ${SNAPSHOT_PATH}"
	/usr/bin/btrfs subvolume snapshot "${DIR_TO_SAVE}" "${SNAPSHOT_PATH}"

	# Remove directory to ignore
	if [[ "${IGNORE_DIRS}" != "" ]]; then
		IFS=' ' read -a array <<< "${IGNORE_DIRS}"
		for d in "${array[@]}"; do
			rm -rf "${SNAPSHOT_PATH}/$d"
		done
	fi

	# To make sure we have no nested snapshots, they are removed.
	# (It should already be empty, but I want to make sure).
	rm -rf "${SNAPSHOT_PATH}/.cache/snapshots"
}

# Take as argument the name of the user to run this script for,
# or _all if we should run the script for all users.
# Default to the user currently runing the script
if [[ "$1" == "_all" ]]; then
	l_u="root $(ls /home)"
elif [[ "$1" != "" ]]; then
	l_u="$1"
else
	l_u="${USER}"
fi

for back_user in $(echo -e "${l_u// /\\n}" | sort -u); do
	# Default path
	user_path="/home/${back_user}"
	if [[ "${back_user}" == "root" ]]; then
		user_path="/root"
	fi
	snapshot_dir="${user_path}/.cache/snapshots"

	snapshot_user "${user_path}" "${snapshot_dir}"
done
