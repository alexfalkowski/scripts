# Accepted design for repository maintenance

Part of the [accepted-design index](../accepted-design.md).

## Repository and Make target ownership

Bulk updates operate in maintainer-local checkouts selected by `lib/dirs.sh`.
Change those paths only when the task changes which repositories the toolbox
operates on. Actions run from the target repository, where they can call its
Make targets such as `dep`, `done`, `latest`, `purge`, `new-*`, and `ready`.

[Directory sets](../../../lib/dirs.sh) · [Bulk update commands](../../../libexec/update)

## Update and pull request workflow

Update helpers that use the shared PR workflow delegate branch creation to
`make new-*` and publication to `make ready`. The latter commits all changes,
force-pushes with a lease, opens a PR, and enables auto squash-merge. Where
supported, `--no-pr` skips branch creation and publication so maintainers can
inspect or combine updates on the current branch while dependency downloads,
submodule updates, and generation still run. Bulk commands forward the flag to
the underlying helpers.

`afctl update-go-dep` with no arguments updates dependencies on the current
branch. Supplying `<kind> <desc>` opts into the PR workflow, subject to
`--no-pr`.

[Shared flag parsing](../../../lib/update.sh) · [Go updater](../../../libexec/update-go-dep) ·
[Shared Git targets](../../../bin/build/make/git.mak)

## Service and Bundler updates

`afctl update-service new <kind> <version>` updates `go-service`, then updates
Bundler before refreshing Ruby test dependencies. The Bundler helper installs
Bundler in user gems and sets `BUNDLE_VERSION=system` for the lockfile update
target so a missing previously locked executable does not prevent the upgrade.
Use `afctl update-ruby <dirs> bundler <version> <desc>` for a standalone Bundler
upgrade.

[Service updater](../../../libexec/update-service-dep) ·
[Bundler helper](../../../lib/bundler.sh) · [Bulk Ruby updater](../../../libexec/update-ruby)

## CircleCI and local tools

`afctl update-ci` edits the target repository's CircleCI configuration in place.
It prefers `.circleci/continue_config.yml` when present and otherwise updates
`.circleci/config.yml`. `afctl create-ci` provisions a project through the live
CircleCI API and triggers a pipeline on `master`.

`afctl clean` removes `test/vendor` and `vendor` before running `make dep`.
`afctl load` uses fixed loopback ports and expects the maintainer to start the
selected service before running the load test.

[CI updater](../../../libexec/update-ci) · [CI project setup](../../../libexec/create-ci) ·
[Dependency cleanup](../../../libexec/clean) · [Local load test](../../../libexec/load)
