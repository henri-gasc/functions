#!/bin/bash

line_screen="$(ps -u $USER -o pid,cmd | rg 'swayidle' | rg 'dpms')"
if [ "${line_screen}" == "" ]; then
  echo -e "󱎬\nBlank screen deactivated\ndeactivate"
else
  echo -e "󱎫\nBlank screen activated\nactivate"
fi
