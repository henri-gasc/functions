#!/bin/bash

line_lock="$(ps -u $USER -o pid,cmd | rg 'swayidle' | rg 'lock')"
if [ "${line_lock}" == "" ]; then
  echo -e "󰍹\nScreen lock deactivated\ndeactivate"
else
  echo -e "󰷛\nScreen lock activated\nactivate"
fi
