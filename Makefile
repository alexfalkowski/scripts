include bin/build/make/help.mak
include bin/build/make/ruby.mak
include bin/build/make/git.mak

# Lint all scripts.
scripts-lint:
	@shellcheck ruby-* update-*
