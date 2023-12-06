#!/bin/bash

bright=$(cat /sys/class/backlight/intel_backlight/brightness)
new_bright=$((bright+$1*1000))
echo $new_bright > /sys/class/backlight/intel_backlight/brightness

