include bin/build/make/help.mak
include bin/build/make/git.mak

# Lint all scripts.
scripts-lint:
	shellcheck install-* load ruby-* update-*

# Run all linters.
lint: scripts-lint

# Load test bezeichner.
load-bezeichner:
	./load bezeichner

# Load test standort.
load-standort:
	./load standort

# Load test all sites.
load: load-bezeichner load-standort