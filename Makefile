.PHONY: update-submodule

include bin/build/make/help.mak
include bin/build/make/ruby.mak
include bin/build/make/git.mak

# Lint all scripts.
scripts-lint:
	@shellcheck deps lsp update update-bundler update-docker-dep update-root create-ci update-ci update-service update-service-dep update-ruby update-ruby-dep update-submodule lib/dirs.sh lib/version.sh
