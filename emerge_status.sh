#!/bin/sh

arguments="--skip-file --fakeroots /mnt/foo /mnt/stable_stage3 / --show-root"
echo "$(gls ${arguments} --read-ninja | head -n 1)"
echo "$(gls ${arguments} --all | tail -n 1)"
