PREFIX="$(HOME)/.local/bin"

install:
	chmod +x *.sh
	chmod +x *.py
	for f in *.sh; do \
		cp $$f "$(PREFIX)/$$(echo $$f | sed 's/\.sh//')"; \
	done
	for f in *.py; do \
		cp $$f "$(PREFIX)/$$(echo $$f | sed 's/\.py//')"; \
	done
