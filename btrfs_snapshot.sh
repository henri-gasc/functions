#!/bin/bash
NOW=$(date +"%Y-%m-%d_%H:%M:%S")

snapshot_path="/home/gasc/.cache/snapshots"
if [ ! -e "${snapshot_path}" ]; then
  mkdir -p "${snapshot_path}"
fi
 
/sbin/btrfs subvolume snapshot /home/gasc "${snapshot_path}/backup_${NOW}"

# To make sure they are removed. (They should already be empty, but want to make sure)
rm -rf "${snapshot_path}/backup_${NOW}/.cache/snapshots"
