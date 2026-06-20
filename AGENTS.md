# AGENTS.md

## Shared guidance

Use `bin/AGENTS.md` for shared skills and cross-repository defaults.

## Scope

This guide applies to the repository root.

Treat `bin/` as vendored shared tooling. Do not edit files under `bin/` unless
the task is explicitly about shared `bin` tooling or bumping that submodule to a
new version.

## Repo Rules

- Prefer small, compatibility-preserving changes. Most top-level scripts are
  wrappers used across multiple repositories.
- Use the root `Makefile` as the preferred command surface for repeatable
  setup, validation, submodule, and Git workflow tasks. Run `make` or
  `make help` to discover the available targets.
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

- Bundler upgrades are handled by `update-ruby <dirs> bundler <version> <desc>`;
  `update-service` only handles service dependency bumps and `done`.
- `update-ci` edits CircleCI config in the target repo in place.
- `create-ci` makes live CircleCI API calls and triggers a pipeline.
- `clean` removes `test/vendor` and `vendor` before rerunning `make dep`.
- `load` assumes the local services are already running on the hard-coded ports
  in `load`.

## Verification

Use the smallest relevant repository-defined check after changes:

- `make scripts-lint` for shell changes
- `make lint` for Ruby changes
- `make sec` when security-related targets or dependencies are touched
- README example spot checks when documentation changes command usage
