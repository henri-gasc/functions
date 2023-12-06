#!/bin/sh

file="/var/log/emerge.log"
#file="/mnt/foo/var/log/emerge.log"
#file="/mnt/stable_stage3/var/log/emerge.log"

message="$(qlop -rvCH -f ${file} 2>&1 | head -n 1)"
error='qlop: insufficient privileges for full /proc access, running merges are based on heuristics'

if [ "${message}" == "${error}" ] || [ "${message}" == "" ]; then
  echo "Not currently emerging"
else
  eme_count=$(echo "${message}" | cut -d '(' -f 2 | cut -d ')' -f 1 | sed -e 's/of/\//g')
  eme_name=$(echo "${message}" | cut -d ' ' -f 3 | sed -e 's/\.\.\.//g')
  if [ "${eme_count}" == "${message}" ]; then
    eme_time=$(echo "${message}" | cut -d '+' -f 2)
    echo "${eme_name} is over by ${eme_time}"
  else
    eme_time=$(echo "${message}" | cut -d ')' -f 2 | cut -d '(' -f 1 | sed -r -e 's/ hours?/h/g' -e 's/ minutes?/m/g' -e 's/, [0-9]* seconds?//g')
    echo "${eme_count}, ${eme_name},${eme_time}"
  fi
fi
