#!/bin/bash

line_screen="$(ps -u $USER -o pid,cmd | rg 'swayidle' | rg 'dpms')"
if [ "${line_screen}" == "" ]; then
  swayidle -w timeout 60 'pidof vlc mpv mpvpaper ncmpcpp || hyprctl dispatch dpms off' resume 'hyprctl dispatch dpms on' &
else
  kill "$(echo ${line_screen} | cut -f 1 -d ' ')"
fi
