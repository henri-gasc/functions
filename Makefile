PREFIX="$(HOME)/.local/bin"
PREFIX_SYSTEM="/usr/local/bin"

default: install

system_sh:
	cp btrfs_snapshot.sh $(PREFIX_SYSTEM)/btrfs_snapshot
	cp clean_git.sh $(PREFIX_SYSTEM)/clean_git
	cp update_git.sh $(PREFIX_SYSTEM)/update_git
	cp launch_steam.sh $(PREFIX_SYSTEM)/launch_steam
	cp commit_daily.sh $(PREFIX_SYSTEM)/commit_daily
	cp grimblast.sh $(PREFIX_SYSTEM)/grimblast

local_sh:
	cp change_brightness.sh $(PREFIX)/change_brightness
	cp diff_snapshot.sh $(PREFIX)/diff_snapshot
	cp emerge_status.sh $(PREFIX)/emerge_status
	cp get_lock.sh $(PREFIX)/get_lock
	cp get_screen.sh $(PREFIX)/get_screen
	cp toggle_screen.sh $(PREFIX)/toggle_screen
	cp toggle_screen.sh $(PREFIX)/toggle_screen
	cp take_screenshot.sh $(PREFIX)/take_screenshot
	cp git-fetch-allbranches.sh $(PREFIX)/git-fetch-allbranches

local_python:
	cp pyebuild.py $(PREFIX)/pyebuild
	cp unicode_picker.py $(PREFIX)/unicode_picker

install: exec system_sh local_sh local_python

exec:
	chmod +x *.sh
	chmod +x *.py
