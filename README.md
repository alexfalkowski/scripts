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
- [Command reference](#command-reference)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## 📦 What this repo contains

Run commands through `afctl`; their implementations live in `libexec/`.

Commands:

- `afctl ai`: start Codex or Claude with a kind-specific model, reasoning level, and prompt preamble.
- `afctl clean`: remove dependency vendor directories and rerun `make dep`.
- `afctl completion zsh`: print the zsh completion script for sourcing from shell startup.
- `afctl create-ci`: create/configure a CircleCI project and trigger its first pipeline.
- `afctl deps`: install the managed Homebrew prerequisites and update shared Go developer tools.
- `afctl help` (also `afctl -h` or `afctl --help`): list the commands available in this checkout.
- `afctl load`: run local HTTP/gRPC load tests for specific services.
- `afctl lsp`: run Ruby LSP after `make dep`.
- `afctl rotate-ci`: rotate GitHub OAuth CircleCI triggers for slugs in `lib/slugs.sh`.
- `afctl rotate-oauth-ci`: rotate one GitHub OAuth CircleCI trigger.
- `afctl update`: run bulk actions over a directory set (`ruby`, `go`, `services`, `all`).
- `afctl update-buf`: run Buf-related bulk actions over configured repository sets.
- `afctl update-buf-dep`: update pinned Buf remote plugins and regenerate outputs.
- `afctl update-bundler`: install a Bundler version and run follow-up make targets.
- `afctl update-ci`: update CircleCI image tags to latest published Docker Hub tags.
- `afctl update-docker-dep`: bump a package in the local `alexfalkowski/docker` repo.
- `afctl update-go-dep`: update outdated Go dependencies using make targets.
- `afctl update-root`: bump `alexfalkowski/root` in the local `alexfalkowski/docker` repo.
- `afctl update-ruby`: run Ruby-related bulk actions over the `services` and `ruby` sets.
- `afctl update-ruby-dep`: update Ruby dependencies using make targets.
- `afctl update-service`: run service-specific bulk actions over the `services` set only.
- `afctl update-service-dep`: bump `github.com/alexfalkowski/go-service/v2` in service repos.
- `afctl update-submodule`: update this repo as a submodule in a target repo.

## ✅ Prerequisites

On macOS or Linux with [Homebrew](https://brew.sh/), install the managed
command-line prerequisites and pinned Go developer tools:

```bash
./afctl deps
```

`afctl deps` reads the repository's [`Brewfile`](Brewfile). It includes both
optional AI provider CLIs; remove the `codex` or `claude-code@latest` cask
entry before running the command if you use only one.

For the GNU `sed` and `sort` behavior used by `update-ci` and
`update-docker-dep`, put Homebrew's GNU tool directories before the system
tools on `PATH` (for example, in `~/.zshrc`):

```bash
export PATH="$(brew --prefix coreutils)/libexec/gnubin:$(brew --prefix gnu-sed)/libexec/gnubin:$PATH"
```

Ruby dependencies remain managed by the existing `Gemfile`; run `make dep`
after installing the Brewfile prerequisites.

> [!IMPORTANT]
> Bulk commands (`afctl update`, `afctl update-buf`, `afctl update-service`, `afctl update-ruby`, and `afctl rotate-ci`) invoke their helpers by command name after changing directories or iterating configured slugs. `afctl` adds `libexec/` to `PATH` for those invocations.

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
3. Add this repository to `PATH` so `afctl` is available.

Example (`zsh`/`bash`):

```bash
export PATH="/path/to/this/repo:$PATH"
```

For zsh completion, add this to `~/.zshrc`:

```zsh
source <(afctl completion zsh)
```

The generated script initializes `compinit` itself when needed and discovers the
available `afctl` commands from executable files in `libexec/`.

> [!TIP]
> From a shell already inside this repository, `export PATH="$(pwd):$PATH"` is
> the shortest way to make `afctl` available.

The root `Makefile` includes shared make fragments from the `bin` submodule, so
initialize the submodule before running `make` targets in this repository.

Verify the command dispatcher before running a maintenance action:

```bash
afctl help
```

If you have not added the repository to `PATH`, run the same command from the
repository root as `./afctl help`. The list is generated from executable files
in `libexec/`, so it is the authoritative command catalog for this checkout.

## 🧪 Make targets and validation

Run `make` or `make help` to print the authoritative target catalog. Prefer
these Make targets for repeatable setup, validation, submodule, and Git workflow
tasks. The root `Makefile` includes shared `help.mak`, `ruby.mak`, `git.mak`,
`claude.mak`, and `codex.mak` fragments from the nested `bin` submodule.
`claude.mak` and `codex.mak` add the `claude-init` and `codex-init` targets
that symlink the shared `bin/skills` and permission profiles into this
repository for each assistant.

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

`update`, `update-buf`, `update-service`, and `update-ruby` read directories from
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
`update-buf-dep`, `update-ci`, `update-bundler`, `update-ruby-dep`, `update-service-dep`,
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
afctl deps
afctl update all dep
afctl update all done
```

Use this when you want a broad dependency refresh across your configured `ruby`,
`go`, and `services` sets.

### 🧹 Reinstall dependencies in all configured repos

```bash
afctl update all clean
afctl update all done
```

> [!CAUTION]
> `clean` removes `test/vendor` and `vendor` in each target repository before it
> reruns `make dep`.

### 🏗️ Refresh CircleCI images in service repos

```bash
afctl update services ci
afctl update services done
```

This updates `alexfalkowski/*` image tags in service repo CircleCI configs, then
runs each repo's `make done`.

> [!WARNING]
> `update-ci` calls Docker Hub and edits the target repo's CircleCI config in
> place. It uses GNU `sed -i` and `sort --version-sort`; macOS BSD tools may
> need adaptation.

### 🧩 Bump `go-service` dependency in all services

```bash
afctl update-service new svc v2.3.4
afctl update-service done
```

Replace `v2.3.4` as needed.

### 📌 Bump `bin` submodule across all configured repos

```bash
afctl update all submodule svc "bump bin submodule"
afctl update all done
```

This runs submodule updates in each configured repo and finalizes with
`make done`.

### 💎 Upgrade Bundler in Ruby and service repos

```bash
afctl update-ruby all bundler <version> "upgrade bundler"
afctl update-ruby all done
```

Replace `<version>` with the Bundler version you intend to roll out.

### 🧬 Update Buf remote plugins

```bash
afctl update-buf all new svc "update Buf dependencies"
afctl update-buf all done
```

This only updates repositories with a Buf-enabled Makefile and pinned remote
plugins in `buf.gen.yaml`.

### 💠 Upgrade Bundler in one target repo

Run this from inside the target repo:

```bash
afctl update-bundler <version> "upgrade bundler"
make done
```

Replace `<version>` with the Bundler version you intend to roll out.

### 🔐 Create a CircleCI project

```bash
afctl create-ci my-repo-name
```

> [!WARNING]
> `create-ci` makes live CircleCI API calls, creates a checkout key, writes a
> `CODECOV_TOKEN` env var, and triggers a `master` pipeline.

### 🔄 Rotate CircleCI GitHub OAuth triggers

```bash
DRY_RUN=1 afctl rotate-ci
afctl rotate-ci
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
afctl load http standort
afctl load grpc standort
afctl load http bezeichner
afctl load grpc bezeichner
```

Run these only after local services are listening on the ports defined in
[`afctl load`](afctl).

## 📚 Command reference

### 🧹 `afctl clean`

Run inside a target repository:

```bash
afctl clean
```

Behavior:

- Removes `test/vendor` when it exists.
- Removes `vendor` when it exists.
- Runs `make dep`.

### 🤖 `afctl ai`

Start an interactive Codex or Claude session for a configured kind.

Syntax:

```bash
afctl ai <codex|claude> <kind> [-s <scope>] [-c <confidence>] [-e <effort>] [-f <file>] [-a] [--] [prompt...]
afctl ai <codex|claude> version
afctl ai ledger <kind> [-s <scope>] [<ledger-id>]
afctl ai skills
afctl ai help <kind>
```

Examples:

```bash
afctl ai codex code "add a cache for this request"
afctl ai claude test-gaps-find "focus on the command-line interface"
afctl ai codex test-gaps-find -s lib "focus on the command-line interface"
afctl ai codex test-gaps-find -s lib -c 95% "focus on the command-line interface"
afctl ai codex test-gaps-find -s lib --reasoning high "focus on the command-line interface"
afctl ai codex code -a "add a cache for this request"
afctl ai codex code-issues-implement -s lib ISSUE-1
afctl ai ledger code-issues-implement -s lib
afctl ai ledger code-issues-implement -s lib ISSUE-12
afctl ai skills
afctl ai help doc-gaps-fix
afctl ai codex code --file prompts/cache.md
afctl ai codex code -- "-s this is a literal prompt"
afctl ai codex version
afctl ai claude version
```

The model, reasoning level, and prompt preamble are configured in
[`config/ai.yml`](config/ai.yml), read with `yq`. Find/audit and
implement/fix skills have separate model profiles. The current find and
implement entries under `kinds` look like this:

```yaml
kinds:
  test-gaps-find:
    codex:
      model: gpt-5.6-sol
      reasoning: high
    claude:
      model: eu.anthropic.claude-opus-5
      effort: high
    preamble: with agents and a goal
  test-gaps-implement:
    codex:
      model: gpt-5.6-terra
      reasoning: high
    claude:
      model: eu.anthropic.claude-sonnet-5
      effort: high
    preamble: with agents and a goal
```

Use the explicit `*-find` / `*-implement` names for code, feature, project,
reliability, and test gaps; use `doc-gaps-audit` / `doc-gaps-fix` for
documentation. `code`, `research`, and `question` have no injected preamble
(`preamble: "-"`) and are not `bin` skills, so each always needs its own
`kinds` entry. Any other kind that has no entry of its own falls back to
`kinds.default` as long as a matching `bin/skills/<kind>` directory exists.
Add a kind-specific entry only to override the default model, reasoning, or
preamble for that skill.

Use `afctl ai skills` for a concise list of the shared skills available through the
current `bin` submodule. The list uses each skill's shared display metadata.
Use `afctl ai help <kind>` for the skill's launch syntax, shared guidance, configured
Codex and Claude models, and ledger ownership when applicable.
Use `afctl ai <codex|claude> version` to print the selected provider CLI's own
version, bypassing kind configuration and skill invocation.

Each configured skill kind starts with `$<kind>` for Codex or `/<kind>` for
Claude, followed by `in <scope>`, an optional `with >= <confidence> confidence`,
and its find or generic preamble. The scope defaults to `.` and can be
overridden with `-s <scope>` (or the long-form alias `--scope <scope>`).
Confidence is omitted by default, preserving the shared `>= 90%` minimum, and
can be overridden with `-c <confidence>` (or `--confidence <confidence>`),
such as `95%`. The configured reasoning level can be overridden for one run
with `-e <effort>`, `--effort <effort>`, or `--reasoning <effort>`. Use `-a`
(or `--auto`) to enable the selected provider's automatic approval mode for one
run. Codex gets `--ask-for-approval never`, which suppresses approval prompts
while retaining the configured named permission profile. Claude gets
`--permission-mode auto`. Use `--` before the prompt when it begins with `-s`, `--scope`, `-c`,
`--confidence`, `-e`, `--effort`, `--reasoning`, `-f`, `--file`, `-a`, or
`--auto`. Use `-f <file>` (or `--file <file>`) to read a multiline
prompt from a readable regular file. The file path is relative to the current
directory, and a file prompt cannot be combined with inline prompt words. A
`preamble: "-"` entry remains unscoped and rejects scope and confidence
options. The selected skill must already be available in the repository where
you run `afctl ai`.

Ledger-owning implement/fix skills use `ledger.yaml` to map the selected scope
to a canonical ledger path. The skill resolves that path when needed; normal
`afctl ai` prompts do not repeat it.

Use `afctl ai ledger <kind> [-s <scope>] [<ledger-id>]` to render a skill's scoped
ledger with `glow`. The scope defaults to `.`, and the kind must be the
ledger-owning implement/fix skill with a readable `ledger.yaml` contract. For
example, `afctl ai ledger code-issues-implement -s lib` renders `lib/ISSUES.md`,
while `afctl ai ledger code-issues-implement -s lib ISSUE-12` renders only the
`ISSUE-12` entry. The ID must use the selected skill's configured prefix and a
numeric suffix.

To work on an existing entry, start an implement/fix session with that explicit
skill and ledger ID, such as `afctl ai codex code-issues-implement -s lib ISSUE-1`.
For a same-prefix batch, use `ISSUE-1/2/3`. The selected skill resolves the
ledger and owns the batch's sequential validation and stop behavior.

### ⌨️ `afctl completion`

Print a completion script for a supported shell.

```zsh
source <(afctl completion zsh)
```

The generated zsh completion discovers the executable `libexec` commands in
the current `afctl` checkout and completes documented argument values.

### 🚀 `afctl create-ci`

Create and initialize a CircleCI project.

Syntax:

```bash
afctl create-ci <repo-name>
```

Behavior:

- Creates `github/alexfalkowski/<repo-name>` in CircleCI.
- Adds a user checkout key.
- Adds `CODECOV_TOKEN` as a CircleCI environment variable.
- Triggers a `master` pipeline.

### 🛠️ `afctl deps`

Install the Brewfile prerequisites and pinned Go tools:

```bash
afctl deps
```

Homebrew dependencies are defined in [`Brewfile`](Brewfile); pinned Go tools
are defined directly in [`libexec/deps`](libexec/deps).

### 📈 `afctl load`

Run local HTTP or gRPC load tests for `standort` and `bezeichner`.

Run this command from the repository root. It reads request payloads from
`data/*.json` and writes HTTP report binaries to `data/*.bin` relative to the
current directory.

Syntax:

```bash
afctl load <kind> <service>
```

- `<kind>`: `http` or `grpc`
- `<service>`: `standort` or `bezeichner`

Examples:

```bash
afctl load http standort
afctl load grpc standort
afctl load http bezeichner
afctl load grpc bezeichner
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

### 💬 `afctl lsp`

Run Ruby LSP in the current repository:

```bash
afctl lsp
```

Behavior:

- Runs `make dep` first.
- If `test/Gemfile` exists, runs `bundle exec ruby-lsp` inside `test/`.
- Otherwise runs from repository root.

### 🔄 `afctl rotate-ci`

Rotate GitHub OAuth CircleCI triggers for every project slug in
[`lib/slugs.sh`](lib/slugs.sh).

```bash
afctl rotate-ci
```

Behavior:

- Reads `CIRCLECI_API_TOKEN`.
- Iterates the `slugs` array from `lib/slugs.sh`.
- Calls `afctl rotate-oauth-ci "$CIRCLECI_API_TOKEN" "$slug"` for each slug.

> [!CAUTION]
> Without `DRY_RUN=1`, each `afctl rotate-oauth-ci` call deletes an existing trigger
> before creating its replacement.

### 🔁 `afctl rotate-oauth-ci`

Rotate one GitHub OAuth CircleCI trigger.

Syntax:

```bash
afctl rotate-oauth-ci <circleci-token> <project-slug>
```

Example:

```bash
DRY_RUN=1 afctl rotate-oauth-ci "$CIRCLECI_API_TOKEN" gh/alexfalkowski/bin
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

### 📦 `afctl update`

Run an action across one directory set.

Syntax:

```bash
afctl update <dirs> <action> [args...]
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
- `clean`: `afctl clean`
- `done`: `make done`
- `ci`: `afctl update-ci`
- `submodule`: `afctl update-submodule <kind> <desc>`

Examples:

```bash
afctl update go dep
afctl update all latest
afctl update all clean
afctl update services ci
afctl update all submodule svc "bump bin submodule"
```

### 🧩 `afctl update-service`

Run service-specific dependency actions across the `services` list.

Syntax:

```bash
afctl update-service <action> [args...]
```

Actions:

- `new`: `afctl update-service-dep <kind> <version>`
- `done`: `make done`

Examples:

```bash
afctl update-service new svc v2.3.4
afctl update-service done
```

### 💎 `afctl update-ruby`

Run Ruby-specific dependency actions across the `services` and `ruby` lists.

Syntax:

```bash
afctl update-ruby <dirs> <action> [args...]
```

`<dirs>`:

- `ruby`
- `services`
- `all` (services and Ruby repos)

Actions:

- `new`: `afctl update-ruby-dep <kind> <desc>`
- `done`: `make done`
- `bundler`: `afctl update-bundler <version> <desc>`

Examples:

```bash
afctl update-ruby all new test "update ruby dependencies"
afctl update-ruby services bundler 2.5.6 "upgrade bundler"
afctl update-ruby all done
```

### 🧬 `afctl update-buf`

Run Buf dependency actions across configured repositories.

Syntax:

```bash
afctl update-buf <dirs> <action> [args...]
```

`<dirs>`:

- `ruby`
- `go`
- `services`
- `all`

Actions:

- `new`: `afctl update-buf-dep <kind> <desc>`
- `done`: `make done`

Examples:

```bash
afctl update-buf all new svc "update Buf dependencies"
afctl update-buf all done
```

### 🧬 `afctl update-buf-dep`

Run inside a target repository.

Syntax:

```bash
afctl update-buf-dep <kind> <desc>
```

Example:

```bash
afctl update-buf-dep svc "update Buf dependencies"
```

Behavior:

- Finds each `Makefile` that includes `bin/build/make/buf.mak`, including
  relative-path variants.
- Skips the repository when no matching directory contains `buf.gen.yaml` with
  a pinned `buf.build/...:<version>` remote plugin.
- Resolves each pinned remote plugin to its latest Buf version without writing
  generated output during resolution.
- Starts `make name=deps new-<kind>` only when a plugin version changes.
- Updates `buf.gen.yaml`, then runs `make -C <dir> update-all-dep` and
  `make -C <dir> generate` for every changed Buf directory.
- Finalizes with
  `make msg="updated buf dependencies" desc="<desc>" ready`.

### 💠 `afctl update-bundler`

Run inside a target repository.

Syntax:

```bash
afctl update-bundler <version> <desc>
```

Example:

```bash
afctl update-bundler 2.5.6 "upgrade bundler"
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

### 🏗️ `afctl update-ci`

Run inside a target repository with CircleCI config.

```bash
afctl update-ci
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

### 🧬 `afctl update-go-dep`

Run inside a target repository.

```bash
afctl update-go-dep
```

Behavior:

- If `test/Gemfile` exists:
  - reads modules from `make go-outdated-dep`
  - updates each with `make module=<module> go-update-dep`
- Otherwise:
  - reads modules from `make outdated-dep`
  - updates each with `make module=<module> update-dep`

### 💍 `afctl update-ruby-dep`

Run inside a target repository.

Syntax:

```bash
afctl update-ruby-dep <kind> <desc>
```

Example:

```bash
afctl update-ruby-dep test "update ruby dependencies"
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

### 🧱 `afctl update-docker-dep`

Update a package in `$HOME/code/docker/<kind>/Dockerfile`, or in every matching
Dockerfile.

Syntax:

```bash
afctl update-docker-dep <kind|all> <package> <version>
```

Example:

```bash
afctl update-docker-dep k8s doctl 1.155.0
afctl update-docker-dep all trivy 0.72.0
afctl update-docker-dep root ruby 4.0.6
```

Behavior:

- Changes to `$HOME/code/docker`.
- Starts `make name=<kind> new-feature` for a single image kind, or starts
  `make name=deps new-feature` once before the first changed Dockerfile when
  `<kind>` is `all`.
- Reads `<kind>/Dockerfile` and `<kind>/Makefile`, or every matching
  `Dockerfile` and sibling `Makefile` when `<kind>` is `all`.
- Finds the first `FROM <package>:<version>`, `install-image-tool`, or
  `install-go-tool` entry matching `<package>` in each Dockerfile.
- Updates either:
  - the version tag after a matching `FROM` image, preserving a suffix such as
    `-slim-trixie` when `<version>` is a bare version
  - the direct version token after the matched tool path
  - the referenced `ENV` value when the version token is a shell variable
- Bumps each updated image `Makefile` `VERSION`:
  - major image version when the package major version changes
  - minor image version otherwise
- Exits with an error if no matching package is found.
- Exits with an error if a matching image `Makefile` has no `VERSION`.
- Exits with an error if every matching package is already on `<version>`.
- Finalizes with `make msg="updated <package> to <version>" ready`.

### 🌱 `afctl update-root`

Update `alexfalkowski/root` in every matching `$HOME/code/docker/**/Dockerfile`.

Syntax:

```bash
afctl update-root <version>
```

Example:

```bash
afctl update-root 3.9
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
- Exits with an error if a matching image `Makefile` has no `VERSION`.
- Exits with an error if every matching Dockerfile is already on `<version>`.
- Finalizes once with `make msg="updated root to <version>" ready`.

### 🧩 `afctl update-service-dep`

Run inside a service repository.

Syntax:

```bash
afctl update-service-dep <kind> <version>
```

Example:

```bash
afctl update-service-dep svc v2.3.4
```

Behavior:

- Runs `make name=deps new-<kind>`.
- Runs `make module=github.com/alexfalkowski/go-service/v2@<version> go-get`.
- Runs `make submodule go-dep ruby-update-all-dep`.
- Finalizes with
  `make msg="upgraded github.com/alexfalkowski/go-service/v2 to <version>" desc="https://github.com/alexfalkowski/go-service/releases/tag/<version>" ready`.

### 📌 `afctl update-submodule`

Run inside a repository that includes `github.com/alexfalkowski/bin` as a
submodule.

Syntax:

```bash
afctl update-submodule <kind> <desc>
```

Example:

```bash
afctl update-submodule svc "bump bin submodule"
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
