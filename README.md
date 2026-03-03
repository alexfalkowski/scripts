# Scripts

This repository is a small toolbox of automation scripts used across multiple projects (Ruby, Go, and services). Most scripts are thin wrappers around `make` targets in the *target project*.

> These scripts assume you have a local checkout layout that matches `lib/dirs.sh` (see **Directory sets** below). If your projects live elsewhere, update `lib/dirs.sh` accordingly.

## What’s in here

### Top-level scripts

- `deps` — install/update common Go-based developer tools (linters, test helpers, language servers).
- `lsp` — run Ruby LSP (ensures dependencies are up to date first).
- `update` — run bulk actions across a configurable set of repositories (ruby/go/services/all).
- `update-bundler` — bump Bundler in a repository and run the appropriate follow-up `make` targets.
- `update-ci` — bump CI Docker image tags in CircleCI config to latest published versions.
- `update-go-dep` — update outdated Go dependencies by invoking `make` targets.
- `update-service` — run bulk actions across “services” repositories only.
- `update-service-dep` — bump `github.com/alexfalkowski/go-service/v2` in a service repo and run follow-up targets.
- `update-submodule` — bump this repo as a git submodule in another repo and run follow-up targets.
- `load` — run local load tests (HTTP via `vegeta`, gRPC via `ghz`).

## Prerequisites

### Required on all platforms

- **Git**
- **Make**
- **Bash** (the scripts use `#!/usr/bin/env bash`)
- **Go** (used by `deps`, and often by target repos’ `make` targets)
- **Ruby** (used by `update-go-dep` and by Ruby-related workflows)
- **Bundler** (used by `lsp` and `update-bundler`)
- **curl** + **jq** (used by `update-ci`)
- **sed** (used by `update-ci`)
- **vegeta** (HTTP load tests via `load`)
- **ghz** (gRPC load tests via `load`)

### Platform notes

#### Windows
These scripts are written for Bash. Use one of:
- **WSL2** (recommended): Ubuntu + `make`, `git`, `curl`, `jq`, `sed`, `go`, `ruby`
- **Git Bash** may work for some scripts, but `sed -i` behavior differs and may break `update-ci`.

#### macOS
Install dependencies via Homebrew (examples; adjust versions as needed):
- `brew install go ruby make jq vegeta ghz`

#### Linux (Debian/Ubuntu)
Install typical deps:
- `sudo apt-get install -y build-essential git curl jq sed`
- Install Go/Ruby via your preferred method (package manager, asdf, mise, etc.)

## Directory sets (important)

Bulk update scripts read repo locations from `lib/dirs.sh`:

- `ruby` — array of Ruby-oriented repos
- `go` — array of Go libraries/tools repos
- `services` — array of service repos
- `all` — concatenation of the above

Current defaults in `lib/dirs.sh` (edit to match your machine):
- `ruby`: `~/code/alexfalkowski.github.io`, `~/code/nonnative`
- `go`: `~/code/go-service`, `~/code/go-signal`, `~/code/go-sync`, `~/code/gocovmerge`, `~/code/infraops`, `~/code/tausch`, `~/code/go-health`
- `services`: `~/code/go-client-template`, `~/code/go-service-template`, `~/code/bezeichner`, `~/code/migrieren`, `~/code/standort`, `~/code/status`, `~/code/web`, `~/code/go-monolith`

## Installation / setup

1. Clone this repo somewhere on your machine.
2. Ensure the prerequisites above are installed and available in `PATH`.
3. (Optional but recommended) Add this repo to your `PATH` so you can run scripts from anywhere, e.g.:

- macOS/Linux (Bash):
  - Add to `~/.bashrc` or `~/.zshrc`:
    - `export PATH="/path/to/this/repo:$PATH"`

On Windows, prefer WSL and update your shell profile accordingly.

## Usage

All scripts are intended to be run from the root of this repo unless otherwise noted.

To see if everything is in good shape, you can lint scripts (requires `shellcheck` and the included Makefile wiring):
- `make scripts-lint`

### `deps` — install common Go tools

Installs a curated set of Go tools with pinned versions.

Currently installed:
- `gocovmerge`
- `govulncheck`
- `gotestsum`
- `fieldalignment`
- `goda`
- `air`
- `protobuf-language-server`

Example:
- `./deps`

Notes:
- Requires Go configured correctly (`go env GOPATH`, `GOBIN` or default `~/go/bin`).
- After running, ensure your Go bin directory is on `PATH` so the installed tools are usable.

### `lsp` — run Ruby LSP

Runs `make dep` first, then launches `ruby-lsp` via Bundler.

Example:
- `./lsp`

Behavior:
- If a repo has Ruby under `test/` (i.e. `test/Gemfile` exists), it runs `bundle exec ruby-lsp` inside `test/`.
- Otherwise it runs from the repo root.

Prereqs:
- Ruby + Bundler
- The current directory should be a repo that has the expected `make dep` target and Ruby LSP configured.

### `update` — bulk actions across repo sets

Runs a chosen action across a chosen directory set.

Syntax:
- `./update <dirs> <action> [args...]`

Where:
- `<dirs>` is one of: `ruby`, `go`, `services`, `all`
- `<action>` is one of:
  - `latest` — `make latest`
  - `purge` — `make purge`
  - `dep` — `make dep`
  - `done` — `make done`
  - `ci` — `update-ci`
  - `bundler` — `update-bundler <version> <desc>`
  - `submodule` — `update-submodule <kind> <desc>`

Examples:
- Update dependencies in all Go repos:
  - `./update go dep`

- Run “latest” across everything:
  - `./update all latest`

- Update CircleCI images across all service repos:
  - `./update services ci`

- Upgrade bundler to `2.5.6` across ruby repos with a changelog/PR description:
  - `./update ruby bundler 2.5.6 "routine upgrade"`

- Update this repo as a submodule across all repos (kind is passed through to `make new-<kind>`):
  - `./update all submodule svc "bump bin submodule"`

### `update-service` — bulk actions across services only

Same concept as `update`, but hard-coded to the `services` set.

Syntax:
- `./update-service <action> [args...]`

Actions:
- `new` — runs `update-service-dep <kind> <version> <desc>` in each service repo
- `latest` — `make latest`
- `purge` — `make purge`
- `dep` — `make dep`
- `bundler` — `update-bundler "svc" <version> <desc>` (see note below)
- `submodule` — `update-submodule <kind> <desc>`
- `ci` — `update-ci`
- `done` — `make done`

Examples:
- Bump `go-service` to a specific version across services:
  - `./update-service new svc v2.3.4 "upgrade go-service"`

- Run dependency update across all services:
  - `./update-service dep`

Note:
- The current `bundler` action passes `"svc"` as the first argument to `update-bundler`, so `update-bundler` will attempt to install Bundler version `svc` and treat the provided version as the description. If that is not intended, adjust the script.

### `update-bundler` — upgrade bundler in a target repo

This script is designed to be run **inside a target repo** that has the expected `make` targets.

Syntax:
- `update-bundler <version> <desc>`

Example (from inside a repo that uses these conventions):
- `update-bundler 2.5.6 "upgrade bundler"`

Behavior (high-level):
- Creates a new “deps” test branch/work area: `make name=deps new-test`
- Installs Bundler with the requested version
- If `test/Gemfile` exists:
  - `gem install bundler -v <version>` in `test/`
  - `make submodule ruby-update-bundler`
- Otherwise:
  - `gem install bundler -v <version>` in repo root
  - `make submodule update-bundler`
- Finalizes with: `make msg="upgraded bundler to <version>" desc="<desc>" ready`

### `update-ci` — bump CircleCI Docker image tags

Updates `alexfalkowski/*` image tags in CircleCI config to the latest tags on Docker Hub.

Run from inside a repo that contains either:
- `.circleci/continue_config.yml`, or
- `.circleci/config.yml`

Example:
- `update-ci`

Prereqs:
- `curl`, `jq`, `sed`
- Network access to Docker Hub

Behavior (high-level):
- Creates a build work area: `make name=ci new-build`
- Looks up the latest published tags for:
  - `alexfalkowski/go`
  - `alexfalkowski/release`
  - `alexfalkowski/ruby`
  - `alexfalkowski/k8s`
  - `alexfalkowski/docker`
- Rewrites those tags in the CircleCI config file
- Finalizes with: `make msg="use latest published images" ready`

Tag note:
- The script removes the last dot segment from tags (e.g. `1.2.3` -> `1.2`) before writing them.

Cross-platform note:
- `sed -i` differs across platforms. Prefer running via Linux/WSL if you hit issues.

### `update-go-dep` — update outdated Go modules

Ruby script that shells out to `make` to find and update outdated deps.

Example:
- `update-go-dep`

Behavior:
- If `test/Gemfile` exists:
  - `make go-outdated-dep`
  - For each module, `make module=<m> go-update-dep`
- Otherwise:
  - `make outdated-dep`
  - For each module, `make module=<m> update-dep`

This expects those targets to exist in the target repo.

### `update-service-dep` — bump `go-service` dependency in a service repo

Run from inside a service repo.

Syntax:
- `update-service-dep <kind> <version> <desc>`

Example:
- `update-service-dep svc v2.3.4 "upgrade go-service"`

Behavior:
- Creates a new work branch/work area (`make name=deps new-<kind>`)
- Runs `make module=github.com/alexfalkowski/go-service/v2@<version> go-get`
- Then runs follow-ups: `make submodule go-dep ruby-update-all-dep`
- Finalizes via `make ... ready`

### `update-submodule` — bump this repo as a submodule in another repo

Run from inside a repo that consumes `github.com/alexfalkowski/bin` as a git submodule.

Syntax:
- `update-submodule <kind> <desc>`

Example:
- `update-submodule svc "upgrade bin submodule"`

Behavior:
- Creates a new work branch/work area (`make name=deps new-<kind>`)
- Runs `make update-submodule`
- Finalizes with `make ... ready`

### `load` — local load tests

Runs pre-canned HTTP (vegeta) and gRPC (ghz) load tests against local service endpoints.

Syntax:
- `./load <kind> <service>`

Where:
- `<kind>` is `http` or `grpc`
- `<service>` is `standort` or `bezeichner`

Example:
- HTTP load test:
  - `./load http standort`
- gRPC load test:
  - `./load grpc standort`

HTTP behavior:
- POST to `http://localhost:11000/<service>.<version>.Service/<Method>`
- Uses `data/<service>.json` as body
- Saves a binary report to `data/<service>.bin`
- Prints a vegeta report summary

gRPC behavior:
- Uses `ghz` against `localhost:12000`
- Default settings: `-n 2000 -c 20`
- `standort` sends `{ "ip": "92.211.2.113" }`
- `bezeichner` sends `{ "application": "ulid", "count": 10 }`

Before running:
- Ensure the service is running locally at the expected address.
- Update the telemetry config section in `load` if you need it for your setup.

## Troubleshooting

### “command not found”
- Ensure this repo (or its scripts) are on your `PATH`, or run scripts with `./script-name`.
- Ensure Go/Ruby tools install locations are on `PATH` (e.g. `~/go/bin`).

### Bulk updates don’t touch any repos
- Verify `lib/dirs.sh` points to real directories on your machine.

### `update-ci` breaks on macOS `sed`
- Prefer GNU sed (`gsed`) or run via Linux/WSL, since in-place editing flags differ.

## License

See `LICENSE`.
