PREFIX = $(HOME)/.local/bin

install:
	chmod +x *_git.sh
	cp update_git.sh $(PREFIX)/update_git
	cp clean_git.sh $(PREFIX)/clean_git
