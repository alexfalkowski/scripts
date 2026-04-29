# AGENTS.md

## Shared Skill

Use the shared `coding-standards` skill from `bin/skills/coding-standards` for code changes, bug fixes, refactors, reviews, tests, linting, documentation, PR summaries, commits, Makefile changes, CI validation, and verification.

## Scope

This guide applies to the repository root.

Treat `bin/` as read-only in this repo. Do not edit files under `bin/` unless
the task is explicitly to bump or update that submodule to a new version.

## Repo Rules

- Prefer small, compatibility-preserving changes. Most top-level scripts are
  wrappers used across multiple repositories.
- `update` and `update-service` use repository lists from `lib/dirs.sh`. Those
  paths are machine-specific; do not rewrite them unless the task is to change
  the configured repo sets.
- Bulk scripts `cd` into other repositories and invoke helpers such as
  `update-ci`, `update-bundler`, and `update-submodule` by command name. Keep
  this repo on `PATH` when validating those flows.
- Many actions assume the target repo exposes `make` targets like `dep`,
  `done`, `latest`, `purge`, `ready`, or `new-*`.
- Avoid changing script names or argument order unless the task explicitly
  requires it.

## Known Gotchas

- `update-service bundler` currently calls `update-bundler "svc" "$2" "$3"`,
  so it passes `"svc"` where a Bundler version is expected.
- `update-ci` edits CircleCI config in the target repo in place.
- `create-ci` makes live CircleCI API calls and triggers a pipeline.
- `clean` removes `test/vendor` and `vendor` before rerunning `make dep`.
- `load` assumes the local services are already running on the hard-coded ports
  in `load`.

## Verification

Use the smallest relevant check set after changes:

- `make scripts-lint` for shell changes
- `make lint` for Ruby changes
- `make sec` when security-related targets or dependencies are touched
- manual spot checks for script usage documented in `README.md`
