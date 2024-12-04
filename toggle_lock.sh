#!/bin/bash

line_lock="$(ps -u $USER -o pid,cmd | rg 'swayidle' | rg 'lock')"
if [ "${line_lock}" == "" ]; then
  swayidle timeout 300 'hyprlock' &
else
  kill "$(echo ${line_lock} | cut -f 1 -d ' ')"
fi
