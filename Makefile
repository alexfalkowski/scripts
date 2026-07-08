.PHONY: update-submodule

include bin/build/make/help.mak
include bin/build/make/ruby.mak
include bin/build/make/git.mak
include bin/build/make/claude.mak
include bin/build/make/codex.mak

# Lint all shell scripts.
scripts-lint:
	@shellcheck clean create-ci deps load lsp rotate-ci rotate-oauth-ci update update-bundler update-ci update-docker-dep update-root update-ruby update-ruby-dep update-service update-service-dep update-submodule lib/dirs.sh lib/slugs.sh lib/version.sh
