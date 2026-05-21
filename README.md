# Scripts Toolbox

Utility scripts for running repeatable maintenance across multiple repositories (Ruby, Go, and services).

Most scripts are wrappers around `make` targets in the target repository.

## Contents

- [What this repo contains](#what-this-repo-contains)
- [Prerequisites](#prerequisites)
- [Quick start](#quick-start)
- [Directory sets used by bulk scripts](#directory-sets-used-by-bulk-scripts)
- [Common workflows](#common-workflows)
- [Script reference](#script-reference)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## What this repo contains

Top-level scripts:

- `deps`: install/update shared Go developer tools.
- `lsp`: run Ruby LSP (runs `make dep` first).
- `update`: run bulk actions over a directory set (`ruby`, `go`, `services`, `all`).
- `update-service`: run bulk actions over the `services` set only.
- `update-ruby`: run Ruby-related bulk actions over the `services` and `ruby` sets.
- `update-bundler`: install a Bundler version and run follow-up make targets.
- `update-ci`: update CircleCI image tags to latest published Docker Hub tags.
- `update-docker-dep`: bump a package in the local `alexfalkowski/docker` repo.
- `update-root`: bump `alexfalkowski/root` in the local `alexfalkowski/docker` repo.
- `update-go-dep`: update outdated Go dependencies using make targets.
- `update-ruby-dep`: update Ruby dependencies using make targets.
- `update-service-dep`: bump `github.com/alexfalkowski/go-service/v2` in service repos.
- `update-submodule`: update this repo as a submodule in a target repo.
- `load`: run local HTTP/gRPC load tests for specific services.

## Prerequisites

Base requirements:

- `bash`
- `git`
- `make`

Additional requirements by script:

- `deps`: `go`
- `lsp`: `ruby`, `bundler`
- `update-go-dep`: `ruby`
- `update-docker-dep`: `awk`, `sed`
- `update-root`: `awk`
- `update-ci`: `curl`, `jq`, `sed`
- `load`: `vegeta`, `ghz`

Notes:

- Bulk scripts (`update`, `update-service`, `update-ruby`) call other scripts by command name (for example `update-ci`) after `cd` into target repos. Add this repo to `PATH` so those commands resolve correctly.
- Many scripts assume target repositories provide specific `make` targets (for example `dep`, `latest`, `ready`, `new-*`).

## Quick start

1. Clone this repository.
2. Install prerequisites.
3. Add this repository to `PATH`.

Example (`zsh`/`bash`):

```bash
export PATH="/path/to/this/repo:$PATH"
```

Run a basic check:

```bash
make scripts-lint
```

`scripts-lint` requires `shellcheck`.

## Directory sets used by bulk scripts

`update`, `update-service`, and `update-ruby` read directories from [`lib/dirs.sh`](lib/dirs.sh).

Defined arrays:

- `ruby`
- `go`
- `services`
- `all` (concatenation of the three above)

Current defaults include paths under `$HOME/code/...`. Update them to match your machine.

## Common workflows

### Weekly dependency maintenance (all repos)

```bash
./deps
./update all dep
./update all done
```

Use this when you want a broad dependency refresh across your configured `ruby`, `go`, and `services` sets.

### Refresh CircleCI images in service repos

```bash
./update services ci
./update services done
```

This updates `alexfalkowski/*` image tags in service repo CircleCI configs, then runs each repo's `make done`.

### Bump `go-service` dependency in all services

```bash
./update-service new svc v2.3.4 "upgrade go-service"
./update-service done
```

Replace `v2.3.4` and description as needed.

### Bump `bin` submodule across all configured repos

```bash
./update all submodule svc "bump bin submodule"
./update all done
```

This runs submodule updates in each configured repo and finalizes with `make done`.

### Upgrade Bundler in Ruby and service repos

```bash
./update-ruby all bundler 2.5.6 "upgrade bundler"
./update-ruby all done
```

### Upgrade Bundler in one target repo

Run this from inside the target repo:

```bash
update-bundler 2.5.6 "upgrade bundler"
make done
```

### Local load test cycle

```bash
./load http standort
./load grpc standort
./load http bezeichner
./load grpc bezeichner
```

Run once local services are up on the ports defined in [`load`](load).

## Script reference

### `deps`

Install pinned Go tools:

```bash
./deps
```

Current tool list is defined directly in [`deps`](deps).

### `lsp`

Run Ruby LSP in the current repository:

```bash
./lsp
```

Behavior:

- Runs `make dep` first.
- If `test/Gemfile` exists, runs `bundle exec ruby-lsp` inside `test/`.
- Otherwise runs from repository root.

### `update`

Run an action across one directory set.

Syntax:

```bash
./update <dirs> <action> [args...]
```

`<dirs>`:

- `ruby`
- `go`
- `services`
- `all`

`<action>`:

- `latest`: `make latest`
- `purge`: `make purge`
- `dep`: `make dep`
- `done`: `make done`
- `ci`: `update-ci`
- `submodule`: `update-submodule <kind> <desc>`

Examples:

```bash
./update go dep
./update all latest
./update services ci
./update all submodule svc "bump bin submodule"
```

### `update-service`

Run service-specific dependency actions across the `services` list.

Syntax:

```bash
./update-service <action> [args...]
```

Actions:

- `new`: `update-service-dep <kind> <version> <desc>`
- `done`: `make done`

Examples:

```bash
./update-service new svc v2.3.4 "upgrade go-service"
./update services dep
./update services ci
```

### `update-ruby`

Run Ruby-specific dependency actions across the `services` and `ruby` lists.

Syntax:

```bash
./update-ruby <dirs> <action> [args...]
```

`<dirs>`:

- `ruby`
- `services`
- `all` (services and Ruby repos)

Actions:

- `new`: `update-ruby-dep <kind> <desc>`
- `done`: `make done`
- `bundler`: `update-bundler <version> <desc>`

Examples:

```bash
./update-ruby all new test "update ruby dependencies"
./update-ruby services bundler 2.5.6 "upgrade bundler"
./update-ruby all done
```

### `update-bundler`

Run inside a target repository.

Syntax:

```bash
update-bundler <version> <desc>
```

Example:

```bash
update-bundler 2.5.6 "upgrade bundler"
```

Behavior:

- `make name=deps new-test`
- Installs Bundler version:
  - in `test/` when `test/Gemfile` exists
  - otherwise in repo root
- Runs follow-up make target:
  - `make submodule ruby-update-bundler` (test setup)
  - or `make submodule update-bundler`
- Finalizes with `make msg="upgraded bundler to <version>" desc="<desc>" ready`

### `update-ci`

Run inside a target repository with CircleCI config.

```bash
update-ci
```

Behavior:

- `make name=ci new-build`
- Reads latest tags for these Docker images from Docker Hub:
  - `alexfalkowski/go`
  - `alexfalkowski/release`
  - `alexfalkowski/ruby`
  - `alexfalkowski/k8s`
  - `alexfalkowski/docker`
- Updates either:
  - `.circleci/continue_config.yml` (preferred when present), or
  - `.circleci/config.yml`
- Finalizes with `make msg="use latest published images" ready`

Tag handling detail:

- Tags are version-sorted and the highest tag is selected.
- The last dot segment is stripped before writing (example: `1.2.3` becomes `1.2`).

### `update-go-dep`

Run inside a target repository.

```bash
update-go-dep
```

Behavior:

- If `test/Gemfile` exists:
  - reads modules from `make go-outdated-dep`
  - updates each with `make module=<module> go-update-dep`
- Otherwise:
  - reads modules from `make outdated-dep`
  - updates each with `make module=<module> update-dep`

### `update-ruby-dep`

Run inside a target repository.

Syntax:

```bash
update-ruby-dep <kind> <desc>
```

Example:

```bash
update-ruby-dep test "update ruby dependencies"
```

Behavior:

- Exits successfully when no `Gemfile` is found.
- `make name=deps new-<kind>`
- Runs follow-up make target:
  - `make submodule go-dep ruby-update-all-dep` when `test/Gemfile` exists
  - `make submodule go-dep update-all-dep` when root `Gemfile` exists
- `make msg="updated ruby dependencies" desc="<desc>" ready`

### `update-docker-dep`

Update a package in `$HOME/code/docker/<kind>/Dockerfile`.

Syntax:

```bash
update-docker-dep <kind> <package> <version>
```

Example:

```bash
update-docker-dep k8s doctl 1.155.0
```

Behavior:

- Changes to `$HOME/code/docker`
- `make name=<kind> new-feature`
- Updates the first `<package> <version>` occurrence in `<kind>/Dockerfile`
  where `<package>` can also be a slash-delimited segment of a tool path
  and `<version>` can be an `ENV` variable reference
- Bumps `<kind>/Makefile` `VERSION`:
  - major image version when the package major version changes
  - minor image version otherwise
- Finalizes with `make msg="updated <package> to <version>" ready`

### `update-root`

Update `alexfalkowski/root` in every matching `$HOME/code/docker/**/Dockerfile`.

Syntax:

```bash
update-root <version>
```

Example:

```bash
update-root 3.9
```

Behavior:

- Changes to `$HOME/code/docker`
- Starts a dependency feature workflow with `make name=deps new-feature`
- Finds Dockerfiles with a `FROM alexfalkowski/root:<old>` line
- Updates matching `FROM alexfalkowski/root:<old>` lines to `FROM alexfalkowski/root:<version>`
- Bumps the `VERSION` in the Makefile beside each matching Dockerfile
- Uses a major image version bump when the root major version changes
- Uses a minor image version bump otherwise
- Exits with an error if no matching Dockerfiles are found
- Finalizes once with `make msg="updated root to <version>" ready`

### `update-service-dep`

Run inside a service repository.

Syntax:

```bash
update-service-dep <kind> <version> <desc>
```

Example:

```bash
update-service-dep svc v2.3.4 "upgrade go-service"
```

Behavior:

- `make name=deps new-<kind>`
- `make module=github.com/alexfalkowski/go-service/v2@<version> go-get`
- `make submodule go-dep ruby-update-all-dep`
- `make msg="upgraded github.com/alexfalkowski/go-service/v2 to <version>" desc="<desc>" ready`

### `update-submodule`

Run inside a repository that includes `github.com/alexfalkowski/bin` as a submodule.

Syntax:

```bash
update-submodule <kind> <desc>
```

Example:

```bash
update-submodule svc "bump bin submodule"
```

Behavior:

- `make name=deps new-<kind>`
- `make update-submodule`
- `make msg="upgraded github.com/alexfalkowski/bin" desc="<desc>" ready`

### `load`

Run local HTTP or gRPC load tests for `standort` and `bezeichner`.

Syntax:

```bash
./load <kind> <service>
```

- `<kind>`: `http` or `grpc`
- `<service>`: `standort` or `bezeichner`

Examples:

```bash
./load http standort
./load grpc standort
./load http bezeichner
./load grpc bezeichner
```

Current endpoints and payloads:

- HTTP `standort`:
  - URL: `http://localhost:11002/standort.v2.Service/GetLocation`
  - Body file: `data/standort.json`
  - Output report binary: `data/standort.bin`
- HTTP `bezeichner`:
  - URL: `http://localhost:11001/bezeichner.v1.Service/GenerateIdentifiers`
  - Body file: `data/bezeichner.json`
  - Output report binary: `data/bezeichner.bin`
- gRPC `standort`:
  - Target: `localhost:12002`
  - Call: `standort.v2.Service/GetLocation`
  - Payload: `{ "ip": "92.211.2.113" }`
- gRPC `bezeichner`:
  - Target: `localhost:12001`
  - Call: `bezeichner.v1.Service/GenerateIdentifiers`
  - Payload: `{ "application": "ulid", "count": 10 }`

## Troubleshooting

`command not found` for helper scripts:

- Ensure this repository is on `PATH`.
- Or call scripts with explicit path from this repo.

Bulk scripts skip or fail in repos:

- Verify paths in [`lib/dirs.sh`](lib/dirs.sh).
- Verify required `make` targets exist in those repos.

`update-ci` in-place edit problems on macOS:

- BSD `sed -i` differs from GNU `sed -i`.
- Run in Linux/WSL or adapt the script for macOS `sed` behavior.

## License

See [`LICENSE`](LICENSE).
