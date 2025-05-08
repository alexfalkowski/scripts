include bin/build/make/help.mak
include bin/build/make/git.mak

# Lint all scripts.
scripts-lint:
	shellcheck install-* ruby-* update-*

# Run all linters.
lint: scripts-lint
