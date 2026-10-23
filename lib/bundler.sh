#!/usr/bin/env bash

# Install latest Bundler in user gems and update the lock with the given Make target.
# Use installed Bundler when Homebrew removed the previously locked version.
update_bundler() {
  local target=$1

  gem install bundler --user-install

  BUNDLE_VERSION=system make "$target"
}
