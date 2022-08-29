PREFIX="$(HOME)/.local/bin"

install:
	chmod +x *.sh
	for f in *.sh; do \
		cp $$f "$(PREFIX)/$$(echo $$f | sed 's/\.sh//')"; \
	done
