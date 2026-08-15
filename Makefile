include bin/build/make/help.mak
include bin/build/make/ruby.mak
include bin/build/make/git.mak
include bin/build/make/claude.mak
include bin/build/make/codex.mak

# Lint all shell scripts.
scripts-lint:
	@shellcheck afctl $$(grep -Il '^#!/usr/bin/env bash' libexec/* lib/*)
