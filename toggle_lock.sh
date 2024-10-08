#!/bin/bash

line_lock="$(ps -u $USER -o pid,cmd | rg 'swayidle' | rg 'lock')"
if [ "${line_lock}" == "" ]; then
  swayidle timeout 300 '${HOME}/.local/bin/wayland_lock.sh' &
else
  kill "$(echo ${line_lock} | cut -f 1 -d ' ')"
fi
