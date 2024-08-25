#!/bin/bash

snapshot_user() {
	NOW=$(date +"%Y-%m-%d_%H:%M:%S")

	user_dir="$1"
	path_config="${user_dir}/.config/snapshot"

	DIR_TO_SAVE="${user_dir}"
	DIR_SNAPSHOT="$2"
	IGNORE_DIRS=""

	# Customize things (read from config)

	if [[ -f "${DIR_SNAPSHOT}/.no" ]]; then
		echo "Not saving user ${back_user}"
		return
	fi

	if [[ ! -d "${DIR_SNAPSHOT}" ]]; then
		mkdir -p "${DIR_SNAPSHOT}"
	fi

	SNAPSHOT_PATH="${DIR_SNAPSHOT}/backup_${NOW}"

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

l_u="root $(ls /home)"

for back_user in $(echo -e "${l_u// /\\n}" | sort -u); do
	# Default path
	user_path="/home/${back_user}"
	if [[ "${back_user}" == "root" ]]; then
		user_path="/root"
	fi
	snapshot_dir="${user_path}/.cache/snapshots"

	snapshot_user "${user_path}" "${snapshot_dir}"
done
