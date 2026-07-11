# 🧰 Scripts Toolbox

Utility scripts for running repeatable maintenance across multiple repositories
(Ruby, Go, Docker images, CircleCI projects, and services).

> [!NOTE]
> Most scripts are thin wrappers around `make` targets in the target repository.
> They are intended for a local maintainer workflow, not as general-purpose CLIs.

## 🗂️ Contents

- [What this repo contains](#what-this-repo-contains)
- [Prerequisites](#prerequisites)
- [Quick start](#quick-start)
- [Make targets and validation](#make-targets-and-validation)
- [Directory sets used by bulk scripts](#directory-sets-used-by-bulk-scripts)
- [Workflow side effects](#workflow-side-effects)
- [Common workflows](#common-workflows)
- [Script reference](#script-reference)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## 📦 What this repo contains

Top-level scripts:

- `ai`: start Codex or Claude with a kind-specific model, reasoning level, and prompt preamble.
- `clean`: remove dependency vendor directories and rerun `make dep`.
- `create-ci`: create/configure a CircleCI project and trigger its first pipeline.
- `deps`: install/update shared Go developer tools.
- `load`: run local HTTP/gRPC load tests for specific services.
- `lsp`: run Ruby LSP after `make dep`.
- `rotate-ci`: rotate GitHub OAuth CircleCI triggers for slugs in `lib/slugs.sh`.
- `rotate-oauth-ci`: rotate one GitHub OAuth CircleCI trigger.
- `update`: run bulk actions over a directory set (`ruby`, `go`, `services`, `all`).
- `update-bundler`: install a Bundler version and run follow-up make targets.
- `update-ci`: update CircleCI image tags to latest published Docker Hub tags.
- `update-docker-dep`: bump a package in the local `alexfalkowski/docker` repo.
- `update-go-dep`: update outdated Go dependencies using make targets.
- `update-root`: bump `alexfalkowski/root` in the local `alexfalkowski/docker` repo.
- `update-ruby`: run Ruby-related bulk actions over the `services` and `ruby` sets.
- `update-ruby-dep`: update Ruby dependencies using make targets.
- `update-service`: run service-specific bulk actions over the `services` set only.
- `update-service-dep`: bump `github.com/alexfalkowski/go-service/v2` in service repos.
- `update-submodule`: update this repo as a submodule in a target repo.

## ✅ Prerequisites

Base requirements:

- `bash`
- `git`
- `make`

Additional requirements by script:

- `ai`: `yq`, plus Codex CLI (`codex`) and/or Claude Code (`claude`), depending
  on the selected provider
- `create-ci`: `curl`, `CIRCLECI_API_TOKEN`, `CODECOV_TOKEN`
- `deps`: `go`
- `load`: `vegeta`, `ghz`
- `lsp`: `ruby`, `bundler`
- `rotate-ci`: `curl`, `jq`, `CIRCLECI_API_TOKEN`
- `rotate-oauth-ci`: `curl`, `jq`
- `update-bundler` and the `update-ruby ... bundler` action: `ruby`, RubyGems
  (`gem`)
- `update-ci`: `curl`, `jq`, GNU `sed`, GNU `sort`
- `update-docker-dep`: `awk`, GNU `sed`
- `update-go-dep`: `ruby`
- `update-root`: `awk`, `find`

> [!IMPORTANT]
> Bulk scripts (`update`, `update-service`, `update-ruby`, and `rotate-ci`) call
> other scripts by command name after changing directories or iterating configured
> slugs. Add this repository to `PATH` so those commands resolve correctly.

Many scripts assume target repositories provide specific `make` targets, such as
`dep`, `latest`, `purge`, `ready`, `done`, or `new-*`.

## 🚀 Quick start

1. Clone this repository with submodules, or initialize the submodule after
   cloning:

   ```bash
   git submodule sync
   git submodule update --init
   ```

   The nested `bin` submodule uses the SSH URL
   `git@github.com:alexfalkowski/bin.git`, so this step requires GitHub SSH
   access or a local Git URL override.

2. Install the prerequisites for the scripts you plan to run.
3. Add this repository to `PATH`.

Example (`zsh`/`bash`):

```bash
export PATH="/path/to/this/repo:$PATH"
```

> [!TIP]
> From a shell already inside this repository, `export PATH="$(pwd):$PATH"` is
> the shortest way to make the helper scripts available to bulk workflows.

The root `Makefile` includes shared make fragments from the `bin` submodule, so
initialize the submodule before running `make` targets in this repository.

## 🧪 Make targets and validation

Run `make` or `make help` to print the authoritative target catalog. Prefer
these Make targets for repeatable setup, validation, submodule, and Git workflow
tasks. The root `Makefile` includes shared `help.mak`, `ruby.mak`, and
`git.mak` fragments from the nested `bin` submodule.

For local CI parity, run the same checks as the CircleCI lint job:

```bash
make dep
make clean-dep
make scripts-lint
make lint
make sec
```

`scripts-lint` requires `shellcheck`. `lint` runs RuboCop, and `sec` runs the
repository Trivy scan through the shared `bin` submodule.

## 🧭 Directory sets used by bulk scripts

`update`, `update-service`, and `update-ruby` read directories from
[`lib/dirs.sh`](lib/dirs.sh).

Defined arrays:

- `ruby`
- `go`
- `services`
- `all` (concatenation of the three above)

Current defaults are maintainer-local paths under `$HOME/code/...`.

> [!IMPORTANT]
> Treat `lib/dirs.sh` as the configured repository set for this checkout. Change
> it only when intentionally changing which local repositories these bulk
> scripts operate on.

## ⚠️ Workflow side effects

Bulk scripts run their actions inside every configured target repository. When
a script finalizes with `make ready`, the shared Git workflow commits all
changes, force-pushes the current branch with a lease, opens a GitHub PR, and
enables auto squash-merge. This applies directly or transitively to
`update-ci`, `update-bundler`, `update-ruby-dep`, `update-service-dep`,
`update-docker-dep`, `update-root`, and `update-submodule`.

`done` actions run `make done` in each target repository. That shared workflow
checks out `master`, pulls, updates submodules, then deletes the branch that was
current before `done` started.

CircleCI also has remote side effects after the lint job passes. Non-`master`
branches run `make sync push`; `master` runs `version` and `package` with the
`gh` context.

## 🔁 Common workflows

### 🗓️ Weekly dependency maintenance (all repos)

```bash
./deps
./update all dep
./update all done
```

Use this when you want a broad dependency refresh across your configured `ruby`,
`go`, and `services` sets.

### 🧹 Reinstall dependencies in all configured repos

```bash
./update all clean
./update all done
```

> [!CAUTION]
> `clean` removes `test/vendor` and `vendor` in each target repository before it
> reruns `make dep`.

### 🏗️ Refresh CircleCI images in service repos

```bash
./update services ci
./update services done
```

This updates `alexfalkowski/*` image tags in service repo CircleCI configs, then
runs each repo's `make done`.

> [!WARNING]
> `update-ci` calls Docker Hub and edits the target repo's CircleCI config in
> place. It uses GNU `sed -i` and `sort --version-sort`; macOS BSD tools may
> need adaptation.

### 🧩 Bump `go-service` dependency in all services

```bash
./update-service new svc v2.3.4
./update-service done
```

Replace `v2.3.4` as needed.

### 📌 Bump `bin` submodule across all configured repos

```bash
./update all submodule svc "bump bin submodule"
./update all done
```

This runs submodule updates in each configured repo and finalizes with
`make done`.

### 💎 Upgrade Bundler in Ruby and service repos

```bash
./update-ruby all bundler <version> "upgrade bundler"
./update-ruby all done
```

Replace `<version>` with the Bundler version you intend to roll out.

### 💠 Upgrade Bundler in one target repo

Run this from inside the target repo:

```bash
update-bundler <version> "upgrade bundler"
make done
```

Replace `<version>` with the Bundler version you intend to roll out.

### 🔐 Create a CircleCI project

```bash
create-ci my-repo-name
```

> [!WARNING]
> `create-ci` makes live CircleCI API calls, creates a checkout key, writes a
> `CODECOV_TOKEN` env var, and triggers a `master` pipeline.

### 🔄 Rotate CircleCI GitHub OAuth triggers

```bash
DRY_RUN=1 rotate-ci
rotate-ci
```

Use `DRY_RUN=1` first to print the DELETE/POST requests without changing
CircleCI triggers.

### 📈 Local load test cycle

Run the load test cycle from this repository root. The service commands read
the config files under [`config/`](config/) and `load` reads and writes the
payload/report files under [`data/`](data/) relative to the current directory.

Start the services first:

```bash
~/code/standort/standort server -i file:config/standort.yml
~/code/bezeichner/bezeichner server -i file:config/bezeichner.yml
```

Then run the load tests:

```bash
./load http standort
./load grpc standort
./load http bezeichner
./load grpc bezeichner
```

Run these only after local services are listening on the ports defined in
[`load`](load).

## 📚 Script reference

### 🧹 `clean`

Run inside a target repository:

```bash
clean
```

Behavior:

- Removes `test/vendor` when it exists.
- Removes `vendor` when it exists.
- Runs `make dep`.

### 🤖 `ai`

Start an interactive Codex or Claude session for a configured kind.

Syntax:

```bash
ai <codex|claude> <kind> [prompt...]
```

Examples:

```bash
ai codex code "add a cache for this request"
ai claude test-gaps "focus on the command-line interface"
```

The model, reasoning level, and prompt preamble are configured in
[`config/ai.yml`](config/ai.yml), read with `yq`. Each entry under `kinds`
looks like this:

```yaml
kinds:
  test-gaps:
    codex:
      model: gpt-5.6-sol
      reasoning: max
    claude:
      model: opus
      effort: xhigh
    preamble: Inspect this repository with agents and a goal.
```

`code` has no injected preamble (`preamble: "-"`) and is not a `bin` skill, so
it always needs its own entry. Any other kind that has no entry of its own
falls back to `kinds.default` as long as a matching `bin/skills/<kind>`
directory exists, so new shared skills work with `ai` without editing this
file. Add a kind-specific entry only to override the default model,
reasoning, or preamble for that skill.

Each configured kind starts with `$<kind>` for Codex or `/<kind>` for Claude,
followed by its preamble and then the optional prompt. The selected skill must
already be available in the repository where you run `ai`.

### 🚀 `create-ci`

Create and initialize a CircleCI project.

Syntax:

```bash
create-ci <repo-name>
```

Behavior:

- Creates `github/alexfalkowski/<repo-name>` in CircleCI.
- Adds a user checkout key.
- Adds `CODECOV_TOKEN` as a CircleCI environment variable.
- Triggers a `master` pipeline.

### 🛠️ `deps`

Install pinned Go tools:

```bash
./deps
```

Current tool list is defined directly in [`deps`](deps).

### 📈 `load`

Run local HTTP or gRPC load tests for `standort` and `bezeichner`.

Run this command from the repository root. It reads request payloads from
`data/*.json` and writes HTTP report binaries to `data/*.bin` relative to the
current directory.

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

Load profile:

- HTTP uses `vegeta attack -duration=30s`.
- gRPC uses `ghz --insecure -n 2000 -c 20`.

### 💬 `lsp`

Run Ruby LSP in the current repository:

```bash
./lsp
```

Behavior:

- Runs `make dep` first.
- If `test/Gemfile` exists, runs `bundle exec ruby-lsp` inside `test/`.
- Otherwise runs from repository root.

### 🔄 `rotate-ci`

Rotate GitHub OAuth CircleCI triggers for every project slug in
[`lib/slugs.sh`](lib/slugs.sh).

```bash
rotate-ci
```

Behavior:

- Reads `CIRCLECI_API_TOKEN`.
- Iterates the `slugs` array from `lib/slugs.sh`.
- Calls `rotate-oauth-ci "$CIRCLECI_API_TOKEN" "$slug"` for each slug.

> [!CAUTION]
> Without `DRY_RUN=1`, each `rotate-oauth-ci` call deletes an existing trigger
> before creating its replacement.

### 🔁 `rotate-oauth-ci`

Rotate one GitHub OAuth CircleCI trigger.

Syntax:

```bash
rotate-oauth-ci <circleci-token> <project-slug>
```

Example:

```bash
DRY_RUN=1 rotate-oauth-ci "$CIRCLECI_API_TOKEN" gh/alexfalkowski/bin
```

Optional environment variables:

- `CIRCLECI_API_ROOT`: override the CircleCI API root.
- `PIPELINE_DEFINITION_ID`: choose a pipeline definition when auto-detection is
  not enough.
- `TRIGGER_ID`: choose a trigger when more than one GitHub OAuth trigger exists.
- `DRY_RUN`: print the planned DELETE/POST requests without changing triggers.

Behavior:

- Finds the CircleCI project UUID from the human project slug.
- Finds a `github_oauth` pipeline definition and trigger.
- Recreates the trigger from its existing payload.
- Prints the new trigger JSON and ID.

### 📦 `update`

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
- `clean`: `clean`
- `done`: `make done`
- `ci`: `update-ci`
- `submodule`: `update-submodule <kind> <desc>`

Examples:

```bash
./update go dep
./update all latest
./update all clean
./update services ci
./update all submodule svc "bump bin submodule"
```

### 🧩 `update-service`

Run service-specific dependency actions across the `services` list.

Syntax:

```bash
./update-service <action> [args...]
```

Actions:

- `new`: `update-service-dep <kind> <version>`
- `done`: `make done`

Examples:

```bash
./update-service new svc v2.3.4
./update-service done
```

### 💎 `update-ruby`

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

### 💠 `update-bundler`

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

- Runs `make name=deps new-test`.
- Installs the requested Bundler version:
  - in `test/` when `test/Gemfile` exists
  - otherwise in repo root
- Runs the follow-up make target:
  - `make submodule ruby-update-bundler` when `test/Gemfile` exists
  - `make submodule update-bundler` otherwise
- Finalizes with `make msg="upgraded bundler to <version>" desc="<desc>" ready`.

### 🏗️ `update-ci`

Run inside a target repository with CircleCI config.

```bash
update-ci
```

Behavior:

- Runs `make name=ci new-build`.
- Reads latest tags for these Docker images from Docker Hub:
  - `alexfalkowski/go`
  - `alexfalkowski/release`
  - `alexfalkowski/ruby`
  - `alexfalkowski/k8s`
  - `alexfalkowski/docker`
- Updates either:
  - `.circleci/continue_config.yml` when present
  - `.circleci/config.yml` otherwise
- Finalizes with `make msg="use latest published images" ready`.

Tag handling detail:

- Tags are version-sorted and the highest tag is selected.
- The last dot segment is stripped before writing; for example, `1.2.3` becomes
  `1.2`.

### 🧬 `update-go-dep`

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

### 💍 `update-ruby-dep`

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
- When `test/Gemfile` exists:
  - runs `make name=deps new-<kind>`
  - runs `make submodule ruby-update-all-dep`
- When root `Gemfile` exists:
  - runs `make name=deps new-<kind>`
  - runs `make submodule update-all-dep`
- Finalizes with `make msg="updated ruby dependencies" desc="<desc>" ready`.

### 🧱 `update-docker-dep`

Update a package in `$HOME/code/docker/<kind>/Dockerfile`, or in every matching
Dockerfile.

Syntax:

```bash
update-docker-dep <kind|all> <package> <version>
```

Example:

```bash
update-docker-dep k8s doctl 1.155.0
update-docker-dep all trivy 0.72.0
```

Behavior:

- Changes to `$HOME/code/docker`.
- Starts `make name=<kind> new-feature` for a single image kind, or starts
  `make name=deps new-feature` once before the first changed Dockerfile when
  `<kind>` is `all`.
- Reads `<kind>/Dockerfile` and `<kind>/Makefile`, or every matching
  `Dockerfile` and sibling `Makefile` when `<kind>` is `all`.
- Finds the first `install-image-tool` or `install-go-tool` entry matching
  `<package>` in each Dockerfile.
- Updates either:
  - the direct version token after the matched tool path
  - the referenced `ENV` value when the version token is a shell variable
- Bumps each updated image `Makefile` `VERSION`:
  - major image version when the package major version changes
  - minor image version otherwise
- Exits with an error if no matching package is found.
- Exits with an error if a matching image `Makefile` has no `VERSION`.
- Exits with an error if every matching package is already on `<version>`.
- Finalizes with `make msg="updated <package> to <version>" ready`.

### 🌱 `update-root`

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

- Changes to `$HOME/code/docker`.
- Starts a dependency feature workflow with `make name=deps new-feature`.
- Finds Dockerfiles with a `FROM alexfalkowski/root:<old>` line.
- Updates matching `FROM alexfalkowski/root:<old>` lines to
  `FROM alexfalkowski/root:<version>`.
- Bumps the `VERSION` in the Makefile beside each matching Dockerfile.
- Uses a major image version bump when the root major version changes.
- Uses a minor image version bump otherwise.
- Exits with an error if no matching Dockerfiles are found.
- Exits with an error if every matching Dockerfile is already on `<version>`.
- Finalizes once with `make msg="updated root to <version>" ready`.

### 🧩 `update-service-dep`

Run inside a service repository.

Syntax:

```bash
update-service-dep <kind> <version>
```

Example:

```bash
update-service-dep svc v2.3.4
```

Behavior:

- Runs `make name=deps new-<kind>`.
- Runs `make module=github.com/alexfalkowski/go-service/v2@<version> go-get`.
- Runs `make submodule go-dep ruby-update-all-dep`.
- Finalizes with
  `make msg="upgraded github.com/alexfalkowski/go-service/v2 to <version>" desc="https://github.com/alexfalkowski/go-service/releases/tag/<version>" ready`.

### 📌 `update-submodule`

Run inside a repository that includes `github.com/alexfalkowski/bin` as a
submodule.

Syntax:

```bash
update-submodule <kind> <desc>
```

Example:

```bash
update-submodule svc "bump bin submodule"
```

Behavior:

- Runs `make name=deps new-<kind>`.
- Runs `make update-submodule`.
- Finalizes with
  `make msg="upgraded github.com/alexfalkowski/bin" desc="<desc>" ready`.

## 🧯 Troubleshooting

### 🧰 `command not found` for helper scripts

- Ensure this repository is on `PATH`.
- Or call scripts with an explicit path from this repo.

### 🗃️ Bulk scripts skip or fail in repos

- Verify paths in [`lib/dirs.sh`](lib/dirs.sh).
- Verify required `make` targets exist in those repos.

### 🏗️ GNU tool problems on macOS

- `update-ci` uses GNU `sed -i` and `sort --version-sort`.
- `update-docker-dep` uses GNU `sed -i -E` with a `0,/.../` address.
- BSD `sed` and `sort` differ from those GNU behaviors.
- Run in Linux/WSL or adapt the script for macOS GNU coreutils.

### 🔐 CircleCI API failures

- Verify `CIRCLECI_API_TOKEN` is set and has access to the target projects.
- For `create-ci`, verify `CODECOV_TOKEN` is set before creating the project.
- For trigger rotation, run with `DRY_RUN=1` first to verify project slugs,
  pipeline definition IDs, and trigger IDs.

## 📄 License

See [`LICENSE`](LICENSE).
