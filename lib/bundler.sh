#!/usr/bin/env bash

# Install Bundler in user gems and update the lock with the given Make target.
# Extra arguments go to gem install; without extra arguments, install the latest.
# Use installed Bundler when Homebrew removed the previously locked version.
update_bundler() {
  local target=$1
  local dir=.

  if [ -f test/Gemfile ]; then
    dir="test"
  fi

  (cd "$dir" && gem install bundler --user-install "${@:2}")

  BUNDLE_VERSION=system make "$target"
}
