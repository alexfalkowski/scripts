# AGENTS.md

## Shared guidance

Use `bin/AGENTS.md` for shared skills and cross-repository defaults.

## Accepted design

Read the [accepted-design index](docs/agents/accepted-design.md) and the relevant
area files before proposing a change or recording a finding or audit entry.
Apply each decision within its documented scope and record new owner-accepted
decisions in the relevant area file.

## Scope

This guide applies to the repository root.

Treat `bin/` as vendored shared tooling. Do not edit files under `bin/` unless
the task is explicitly about shared `bin` tooling or bumping that submodule to a
new version.

## Repo Rules

- Prefer small, compatibility-preserving changes.
- Use the root `Makefile` as the preferred command surface for repeatable
  setup, validation, submodule, and Git workflow tasks. Run `make` or
  `make help` to discover the available targets.
- Place `# shellcheck` directives immediately after `#!/usr/bin/env bash`.
  Preserve inline Bash `readonly` assignments; when ShellCheck reports `SC2155`,
  add a suppression rather than splitting declaration and assignment.

## Verification

Use the smallest relevant repository-defined check after changes:

- `make scripts-lint` for shell changes
- `make lint` for Ruby changes
- `make sec` when security-related targets or dependencies are touched
- README example spot checks when documentation changes command usage
