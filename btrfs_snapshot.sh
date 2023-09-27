#!/bin/bash

l_u="$(users)"

for back_user in $(echo -e "${l_u// /\\n}" | sort -u); do
  NOW=$(date +"%Y-%m-%d_%H:%M:%S")
  snapshot_path="/home/${back_user}/.cache/snapshots"
  if test -e "${snapshot_path}/.no"; then
    echo "Not saving user ${back_user}"
    continue
  fi
  if test ! -e "${snapshot_path}"; then
    mkdir -p "${snapshot_path}"
  fi
 
  /sbin/btrfs subvolume snapshot /home/${back_user} "${snapshot_path}/backup_${NOW}"

  # To make sure they are removed. (They should already be empty, but want to make sure)
  rm -rf "${snapshot_path}/backup_${NOW}/.cache/snapshots"
done
