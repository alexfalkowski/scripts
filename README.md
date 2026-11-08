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
- `afctl deps`: install the managed Homebrew prerequisites, user Bundler, and shared Go developer tools.
- `afctl done`: complete the current repository workflow through `make done`.
- `afctl help` (also `afctl -h` or `afctl --help`): list commands and common examples; add a command name for its usage and prerequisites.
- `afctl load`: run local HTTP/gRPC load tests for specific services.
- `afctl lsp`: run Ruby LSP after `make dep`.
- `afctl repos`: clone every non-archived `alexfalkowski` repo into `~/code`, or run `make latest` for ones already checked out there.
- `afctl rotate-ci`: rotate GitHub OAuth CircleCI triggers for slugs in `lib/slugs.sh`.
- `afctl rotate-oauth-ci`: rotate one GitHub OAuth CircleCI trigger.
- `afctl update`: run bulk actions over a directory set (`ruby`, `go`, `services`, `tooling`, `all`).
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

The Brewfile includes the Docker CLI and the Buildx and Compose plugins. Docker
targets also require a running Docker engine. If Docker cannot find a plugin,
follow Homebrew's plugin directory instructions for
[Buildx](https://formulae.brew.sh/formula/docker-buildx) or
[Compose](https://formulae.brew.sh/formula/docker-compose).

It also includes `doctl`, `helm`, and `kubescape` for the Kubernetes operator
workflows in `infraops`.

For the GNU `sed` and `sort` behavior used by `update-ci` and
`update-docker-dep`, put Homebrew's GNU tool directories before the system
tools on `PATH` (for example, in `~/.zshrc`):

```bash
export PATH="$(brew --prefix coreutils)/libexec/gnubin:$(brew --prefix gnu-sed)/libexec/gnubin:$PATH"
```

`afctl deps` also installs Bundler in RubyGems' user gem directory so Homebrew
Ruby upgrades do not remove it. Ruby dependencies remain managed by the existing
`Gemfile`; run `make dep` after installing the Brewfile prerequisites.

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
afctl help update
afctl ai --help
```

If you have not added the repository to `PATH`, run the same command from the
repository root as `./afctl help`. The list is generated from executable files
in `libexec/`, so it is the authoritative command catalog for this checkout.

Use `afctl help <command>` or `afctl <command> --help` (also `-h`) to see
arguments, examples, and prerequisites without running the command. These pages
come from the command reference below and need no provider CLI, credentials, or
network access. For example, `afctl create-ci --help` only displays help.

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
- `tooling` (`scripts`)
- `all` (concatenation of the four above)

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
`update-docker-dep`, `update-root`, and `update-submodule`. It also applies to
`update-go-dep` when `<kind> <desc>` is supplied without `--no-pr`.

`update-ci`, `update-submodule`, `update-service-dep`, `update-ruby-dep`,
`update-docker-dep`, `update-go-dep`, `update-root`, `update-bundler`, and `update-buf-dep`
accept `--no-pr`.
This skips both the `new-*` branch workflow and `make ready`: updates run on
the current branch and leave changes uncommitted, without pushing or opening
a PR. Dependency downloads, Bundler installation, submodule updates, and
generation still run as usual. `update-docker-dep` and `update-root` still operate in
`$HOME/code/docker`.

Keep any required positional arguments, including `<kind>` and `<desc>`, when
using `--no-pr`. The flag can appear before or after them; use `--` to keep
subsequent arguments literal. Bulk update actions forward arguments after the
action to their helpers:

```bash
afctl update-ci --no-pr
afctl update services ci --no-pr
afctl update-ruby all new test "update ruby dependencies" --no-pr
```

`update-go-dep` preserves its argument-free update-only behavior. Supplying
`<kind> <desc>` opts into the branch and PR workflow; `--no-pr` skips that
workflow even when those arguments are supplied.

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
`go`, `services`, and `tooling` sets.

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
afctl update-service new build v2.3.4
afctl update-service done
```

Replace `v2.3.4` as needed. This also installs the latest Bundler in RubyGems'
user gem directory and updates the Bundler lock and Ruby test dependencies in
each service repository.

### 📌 Bump `bin` submodule across all configured repos

```bash
afctl update all submodule build "bump bin submodule"
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
afctl update-buf all new build "update Buf dependencies"
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
[`libexec/load`](libexec/load).

## 📚 Command reference

In syntax lines, `<name>` is a required argument, `[name]` is optional, and
`...` means multiple arguments are accepted. Replace placeholders with your own
values; do not type the angle brackets. Quote descriptions and prompts that
contain spaces. Versions in the examples illustrate the syntax; choose the
version you intend to install.

For updates that take a branch `<kind>`, it selects the target repository's
`new-<kind>` Make target. Common kinds are `build`, `docs`, `feature`, `fix`,
`refactor`, and `test`; `svc` requires the target to expose `new-svc`.
`update-docker-dep` takes an image kind instead.
`<desc>` is the PR description. Without `--no-pr`, these update workflows can
create a branch, commit, push, open a PR, and enable auto-merge through
`make ready`. With `--no-pr`, they leave updates uncommitted on the current
branch; downloads and generation still run. See [Workflow side effects](#workflow-side-effects).

### ❓ `afctl help`

Show the command catalog, or usage, prerequisites, and examples for one command:

```bash
afctl help [<command>]
```

Examples:

```bash
afctl help
afctl help update-ruby
afctl update-ruby --help
afctl update-ruby -h
```

The last three commands show the same help page. Help reads this checkout's
README with `awk` and does not execute the selected command. Run it from any
directory once `afctl` is on `PATH`. `afctl ai help <kind>` shows the additional
guidance and configuration for a particular skill.

### 🧹 `afctl clean`

Before running: change to a target repository that exposes `make dep` and has
its dependency tools installed (for example, Ruby and Bundler for a Ruby repo).
Dependency installation may need network access.

Example:

```bash
afctl clean
```

Behavior:

- Removes `test/vendor` when it exists.
- Removes `vendor` when it exists.
- Runs `make dep`.

### ✅ `afctl done`

Before running: change to a target repository with `make done`, Git remote
access, and an initialized `bin` submodule if its Makefile uses shared tooling.

Example:

```bash
afctl done
```

Runs the repository's `make done` workflow.

> [!CAUTION]
> This checks out `master`, pulls and updates submodules, then force-deletes the branch that was current when the command started.

### 🤖 `afctl ai`

Start an interactive Codex or Claude session for a configured kind.

Before running: install `yq` and the selected provider CLI, configure that
provider's authentication, and change to the repository you want to work on.
For skill kinds, that repository must make the shared skill available (for
example through `make codex-init` or `make claude-init` when exposed there).
Ledger display also needs `glow` and an existing scoped ledger file.

Interactive Codex sessions, including resumed sessions, use `--no-alt-screen`
to preserve terminal scrollback on Linux and macOS. Claude sessions set
`CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1` for the same reason.

Syntax:

```bash
afctl ai <codex|claude> <kind> [-s <scope>] [-c <confidence>] [-e <effort>] [-f <file>] [-r <id>] [-a] [--print] [--] [prompt...]
afctl ai <codex|claude> version
afctl ai ledger <kind> [-s <scope>] [<ledger-id>]
afctl ai skills
afctl ai help <kind>
```

Examples:

```bash
afctl ai codex code "add a cache for this request"
# Find issues in lib/, then implement an entry recorded by that skill.
afctl ai codex code-issues-find -s lib "check argument handling"
afctl ai codex code-issues-implement -s lib ISSUE-1
# Read the ledger or get help before starting a session.
afctl ai ledger code-issues-implement -s lib
afctl ai help code-issues-implement
afctl ai claude test-gaps-find "focus on the command-line interface"
afctl ai codex test-gaps-find -s lib "focus on the command-line interface"
afctl ai codex test-gaps-find -s lib -c 95% "focus on the command-line interface"
afctl ai codex test-gaps-find -s lib --reasoning high "focus on the command-line interface"
afctl ai codex code -a "add a cache for this request"
afctl ai ledger code-issues-implement -s lib ISSUE-12
afctl ai skills
afctl ai help doc-gaps-fix
afctl ai codex code --file prompts/cache.md
afctl ai codex code -- "-s this is a literal prompt"
afctl ai claude question --print "respond with the current branch"
afctl ai claude question --resume <session-id> --print "what remains?"
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
      model: gpt-6.1-sol
      reasoning: high
    claude:
      model: eu.anthropic.claude-opus-5-5
      effort: high
    preamble: with agents and a goal
  test-gaps-implement:
    codex:
      model: gpt-6.1-sol
      reasoning: high
    claude:
      model: eu.anthropic.claude-sonnet-5-5
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
`--confidence`, `-e`, `--effort`, `--reasoning`, `-f`, `--file`, `-r`,
`--resume`, `-a`, `--auto`, or `--print`. Use `-f <file>` (or `--file <file>`) to read a multiline
prompt from a readable regular file. The file path is relative to the current
directory, and a file prompt cannot be combined with inline prompt words. A
session can be continued with `-r <id>` (or `--resume <id>`); its configured
model, effort, prompt construction, and other compatible `afctl ai` flags still
apply. Use `--print` to send the prompt, write only the final provider response
to standard output, and exit. It uses Claude's print mode and Codex's
non-interactive mode.
Codex does not support `--auto` in its non-interactive mode, so that combination
is rejected. A `preamble: "-"` entry remains unscoped and rejects scope and
confidence options. The selected skill must already be available in the
repository where you run `afctl ai`.

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

Before running: use zsh with `afctl` on `PATH`. Add the following example to
`~/.zshrc`, then start a new shell or run it in the current shell:

```zsh
source <(afctl completion zsh)
```

The generated zsh completion discovers the executable `libexec` commands in
the current `afctl` checkout and completes documented argument values.
For example, type `afctl help ` or `afctl update ` and press Tab to discover
commands or directory sets.

### 🚀 `afctl create-ci`

Create and initialize a CircleCI project.

Before running: have `curl`, network access to CircleCI, and exported
`CIRCLECI_API_TOKEN` and `CODECOV_TOKEN` values. The repository name belongs to
`alexfalkowski`; pass only its name, not a URL or owner/name pair.

Syntax:

```bash
afctl create-ci <repo-name>
```

Example (creates remote resources and starts a pipeline):

```bash
afctl create-ci my-repo-name
```

Behavior:

- Creates `github/alexfalkowski/<repo-name>` in CircleCI.
- Adds a user checkout key.
- Adds `CODECOV_TOKEN` as a CircleCI environment variable.
- Triggers a `master` pipeline.

### 🛠️ `afctl deps`

Before running: install Homebrew and make `brew` available on `PATH`. This
command needs network access and installs the packages listed in this
checkout's `Brewfile`, including Ruby, Go, and the optional AI CLIs.

Install the Brewfile prerequisites, Bundler, and pinned Go tools:

```bash
afctl deps
```

Homebrew dependencies are defined in [`Brewfile`](Brewfile). Bundler is installed
in RubyGems' user gem directory; pinned Go tools are defined directly in
[`libexec/deps`](libexec/deps).

### 📈 `afctl load`

Run local HTTP or gRPC load tests for `standort` and `bezeichner`.

Before running: install `vegeta` for HTTP or `ghz` for gRPC. Start the selected
service first: `standort` uses HTTP port 11002 and gRPC port 12002;
`bezeichner` uses HTTP port 11001 and gRPC port 12001. The HTTP payload files
must exist under `data/`. See the local load test workflow for service startup
examples.

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

Before running: change to a repository with `make dep` and Ruby/Bundler
installed. Its root or `test/Gemfile` must include `ruby-lsp`.

Run Ruby LSP in the current repository:

```bash
afctl lsp
```

Behavior:

- Runs `make dep` first.
- If `test/Gemfile` exists, runs `bundle exec ruby-lsp` inside `test/`.
- Otherwise runs from repository root.

### 📁 `afctl repos`

Clone every non-archived `alexfalkowski` repo into `~/code`, or bring an
already-checked-out one up to date:

```bash
afctl repos
```

Behavior:

- Lists `alexfalkowski` repos with `gh repo list` and filters out archived ones.
- For each repo not present at `~/code/<name>`, runs `gh repo clone` with an
  explicit SSH URL (`git@github.com:alexfalkowski/<name>.git`) and initializes
  submodules recursively. Submodules use their configured URLs.
- For each repo already present at `~/code/<name>`, runs `make latest` there.

> [!IMPORTANT]
> Requires an authenticated `gh` (`gh auth login`) and GitHub SSH access for
> cloning. `make latest` assumes the target repository provides that Make target.

### 🔄 `afctl rotate-ci`

Rotate GitHub OAuth CircleCI triggers for every project slug in
[`lib/slugs.sh`](lib/slugs.sh).

Before running: install `curl` and `jq`, export `CIRCLECI_API_TOKEN`, and verify
the configured project slugs. Even with `DRY_RUN=1`, this makes authenticated
CircleCI GET requests; it skips the DELETE/POST requests.

Examples:

```bash
DRY_RUN=1 afctl rotate-ci
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

Before running: install `curl` and `jq`, and have a CircleCI API token and the
project slug (for example, `gh/alexfalkowski/bin`). The example uses an already
exported token. `DRY_RUN=1` still reads CircleCI state over the network.

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

Before running: check the selected paths in `lib/dirs.sh`; every repository
must exist locally and expose the chosen action's Make targets. Run from any
directory. `latest`, `done`, and submodule actions need Git remote access;
`ci` needs `curl`, `jq`, GNU `sed`, GNU `sort`, and Docker Hub access.
The `dep` and `clean` actions need each repository's dependency tools.

Syntax:

```bash
afctl update <dirs> <action> [args...]
```

`<dirs>`:

- `ruby`
- `go`
- `services`
- `tooling`
- `all`

`<action>`:

- `latest`: `make latest`
- `purge`: `make purge`
- `dep`: `make dep`
- `clean`: `afctl clean`
- `done`: `make done`
- `ci`: `afctl update-ci`
- `submodule`: `afctl update-submodule <kind> <desc>`

For `submodule`, `<kind>` selects `make new-<kind>` (for example, `build`) and
`<desc>` is a quoted PR description. `ci` and `submodule` accept `--no-pr` to
leave updates uncommitted on current branches. Otherwise they run `make ready`
to publish PRs and enable auto-merge. `done` pulls `master` and deletes the
previous branch; `purge` deletes local branches except `master` and prunes
stale remote-tracking refs.

Examples:

```bash
afctl update go dep
afctl update tooling dep
afctl update all latest
afctl update all clean
afctl update services ci
afctl update services ci --no-pr
afctl update all submodule build "bump bin submodule"
afctl update all submodule build "bump bin submodule" --no-pr
```

### 🧩 `afctl update-service`

Run service-specific dependency actions across the `services` list.

Before running: check the `services` paths in `lib/dirs.sh`. Each must be a
service repository with Go, Ruby/Bundler, and the shared service Make targets.
Updates download dependencies and, by default, publish PRs through `make ready`.

Syntax:

```bash
afctl update-service <action> [args...]
```

Actions:

- `new`: `afctl update-service-dep <kind> <version>`
- `done`: `make done`

For `new`, `<kind>` selects `make new-<kind>` (for example, `build`), and
`<version>` is the `go-service/v2` module version, including its `v` prefix.
This also upgrades Bundler and Ruby test dependencies. `--no-pr` leaves
updates uncommitted on current branches. `done` pulls `master` and deletes
the previously checked-out branch in each repository.

Examples:

```bash
afctl update-service new build v2.3.4
afctl update-service new build v2.3.4 --no-pr
afctl update-service done
```

### 💎 `afctl update-ruby`

Run Ruby-specific dependency actions across the `services` and `ruby` lists.

Before running: check the selected paths in `lib/dirs.sh`. Each repository
needs Ruby/Bundler, a root or `test/Gemfile`, and the corresponding shared Ruby
Make targets. Updates require dependency downloads and, by default, GitHub PR
access for `make ready`.

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

For `new`, `<kind>` selects `make new-<kind>` (for example, `test`). For
`bundler`, `<version>` is the Bundler version without a `v` prefix. Both need
a quoted `<desc>` and accept `--no-pr` to leave updates uncommitted.
Here `all` means Ruby and service repos only. `done` pulls `master` and
deletes the previously checked-out branch in each repository.

Examples:

```bash
afctl update-ruby all new test "update ruby dependencies"
afctl update-ruby services bundler 2.5.6 "upgrade bundler"
afctl update-ruby services bundler 2.5.6 "upgrade bundler" --no-pr
afctl update-ruby all done
```

### 🧬 `afctl update-buf`

Run Buf dependency actions across configured repositories.

Before running: check paths in `lib/dirs.sh` and install `buf`, `rg`, `yq`,
`curl`, and `jq`. Updates need access to Buf's registry. Matching repositories
need a Makefile including `bin/build/make/buf.mak`, a `buf.gen.yaml` with
pinned remote plugins, and the `update-all-dep` and `generate` targets.

Syntax:

```bash
afctl update-buf <dirs> <action> [args...]
```

`<dirs>`:

- `ruby`
- `go`
- `services`
- `tooling`
- `all`

Actions:

- `new`: `afctl update-buf-dep <kind> <desc>`
- `done`: `make done`

For `new`, `<kind>` selects `make new-<kind>` (for example, `build`) and
`<desc>` is the quoted PR description. By default updates publish PRs through
`make ready`; `--no-pr` leaves updates uncommitted. `done` pulls `master`
and deletes the previously checked-out branch in each configured repository.

Examples:

```bash
afctl update-buf all new build "update Buf dependencies"
afctl update-buf all new build "update Buf dependencies" --no-pr
afctl update-buf all done
```

### 🧬 `afctl update-buf-dep`

Before running: change to a target repository with a Makefile including
`bin/build/make/buf.mak`, `buf.gen.yaml` with pinned remote plugins, and the
`update-all-dep` and `generate` targets. Install `buf`, `rg`, `yq`, `curl`,
and `jq`, with network access to Buf's registry.

`<kind>` selects `make new-<kind>` (for example, `build`); `<desc>` is the
quoted PR description. `--no-pr` skips branch creation and `make ready`,
leaving updates uncommitted. Otherwise the workflow publishes a PR and
enables auto-merge through `make ready`.

Syntax:

```bash
afctl update-buf-dep <kind> <desc> [--no-pr]
```

Example:

```bash
afctl update-buf-dep build "update Buf dependencies"
afctl update-buf-dep build "update Buf dependencies" --no-pr
```

Behavior without `--no-pr`:

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

Before running: change to a target repository with Ruby/Bundler, a root or
`test/Gemfile`, and the shared `submodule` and `update-bundler` (or
`ruby-update-bundler`) Make targets. Installing Bundler needs network access.

`<version>` has no `v` prefix; `<desc>` is the quoted PR description.
`--no-pr` leaves updates uncommitted on the current branch; otherwise the
workflow uses `new-test` and publishes a PR through `make ready`.

Syntax:

```bash
afctl update-bundler <version> <desc> [--no-pr]
```

Example:

```bash
afctl update-bundler 2.5.6 "upgrade bundler"
afctl update-bundler 2.5.6 "upgrade bundler" --no-pr
```

Behavior without `--no-pr`:

- Runs `make name=deps new-test`.
- Runs `make submodule`.
- Installs the requested Bundler version in RubyGems' user gem directory.
  The installation runs from `test/` when `test/Gemfile` exists, otherwise
  from the repo root.
- Runs the follow-up make target:
  - `BUNDLE_VERSION=system make ruby-update-bundler` when `test/Gemfile` exists
  - `BUNDLE_VERSION=system make update-bundler` otherwise
- The temporary `BUNDLE_VERSION=system` override uses installed Bundler even
  when Homebrew removed the previously locked executable.
- Finalizes with `make msg="upgraded bundler to <version>" desc="<desc>" ready`.

### 🏗️ `afctl update-ci`

Before running: change to a target repository with `.circleci/config.yml`
or `.circleci/continue_config.yml`. Install `curl`, `jq`, GNU `sed`, and GNU
`sort`, with network access to Docker Hub. The default workflow also needs
`make new-build`, `make ready`, and GitHub access to publish a PR and enable
auto-merge. `--no-pr` leaves the config edits uncommitted on the current branch.

Syntax:

```bash
afctl update-ci [--no-pr]
```

Example:

```bash
afctl update-ci --no-pr
```

Behavior without `--no-pr`:

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

Before running: change to a Go repository with Ruby (this helper is written
in Ruby), Go, and the `outdated-dep` and `update-dep` Make targets. Service
repos with `test/Gemfile` use `go-outdated-dep` and `go-update-dep` instead.
Dependency updates need network access.

Optional `<kind>` selects `make new-<kind>` (for example, `build`) and
`<desc>` is the quoted PR description; supply both together to publish a PR
through `make ready`. Omit both, or use `--no-pr`, to leave updates uncommitted.

Syntax:

```bash
afctl update-go-dep [<kind> <desc>] [--no-pr]
```

Examples:

```bash
afctl update-go-dep
afctl update-go-dep build "update Go dependencies"
afctl update-go-dep build "update Go dependencies" --no-pr
```

Behavior:

- With no positional arguments, updates on the current branch and leaves
  changes uncommitted, preserving the existing behavior.
- With `<kind> <desc>`, starts `make name=deps new-<kind>` and finalizes with
  `make msg="updated go dependencies" desc="<desc>" ready`.
- `--no-pr` skips branch creation and `ready`, whether or not positional
  arguments are supplied. Flags can precede or follow the positional
  arguments; `--` keeps subsequent arguments literal.
- Rejects incomplete or extra positional arguments before running Make targets.
- Exits successfully without creating a branch or PR when the initial lookup
  finds no outdated modules.
- After branch creation, resolves outdated modules again against the updated
  `master` base before applying updates.
- If `test/Gemfile` exists:
  - reads modules from `make go-outdated-dep`
  - updates each with `make module=<module> go-update-dep`
- Otherwise:
  - reads modules from `make outdated-dep`
  - updates each with `make module=<module> update-dep`

### 💍 `afctl update-ruby-dep`

Before running: change to a repository with Ruby/Bundler, a root or
`test/Gemfile`, and the shared Ruby Make targets. This downloads gems and
also upgrades Bundler. Repositories without a Gemfile are skipped.

`<kind>` selects `make new-<kind>` (for example, `test`); `<desc>` is the
quoted PR description. `--no-pr` leaves updates uncommitted; otherwise the
workflow publishes a PR and enables auto-merge through `make ready`.

Syntax:

```bash
afctl update-ruby-dep <kind> <desc> [--no-pr]
```

Example:

```bash
afctl update-ruby-dep test "update ruby dependencies"
afctl update-ruby-dep test "update ruby dependencies" --no-pr
```

Behavior without `--no-pr`:

- Exits successfully when no `Gemfile` is found.
- When `test/Gemfile` exists:
  - runs `make name=deps new-<kind>`
  - runs `make submodule`
  - installs the latest Bundler in RubyGems' user gem directory and runs
    `BUNDLE_VERSION=system make ruby-update-bundler` to refresh `test/Gemfile.lock`
  - runs `make ruby-update-all-dep`
- When root `Gemfile` exists:
  - runs `make name=deps new-<kind>`
  - runs `make submodule`
  - installs the latest Bundler in RubyGems' user gem directory and runs
    `BUNDLE_VERSION=system make update-bundler` to refresh `Gemfile.lock`
  - runs `make update-all-dep`
- Finalizes with `make msg="updated ruby dependencies" desc="<desc>" ready`.

### 🧱 `afctl update-docker-dep`

Update a package in `$HOME/code/docker/<kind>/Dockerfile`, or in every matching
Dockerfile.

Before running: have the Docker repository checked out at `$HOME/code/docker`.
Matching Dockerfiles must have a sibling Makefile with `VERSION`. Use GNU
`sed` on `PATH`. `<kind>` is an image directory such as `k8s`, not a branch
kind; `<package>` must match an existing image or tool entry.
`--no-pr` leaves edits uncommitted; otherwise the workflow uses `new-feature`
and publishes a PR through `make ready`, requiring GitHub access.

Syntax:

```bash
afctl update-docker-dep <kind|all> <package> <version> [--no-pr]
```

Example:

```bash
afctl update-docker-dep k8s doctl 1.155.0
afctl update-docker-dep all trivy 0.72.0
afctl update-docker-dep root ruby 4.0.6
afctl update-docker-dep k8s doctl 1.155.0 --no-pr
```

Behavior without `--no-pr`:

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

Before running: have that Docker repository checked out, with an
`alexfalkowski/root:<version>` base image in matching Dockerfiles and a
`VERSION` in each sibling Makefile.
`--no-pr` leaves edits uncommitted; otherwise the workflow uses `new-feature`
and publishes a PR through `make ready`, requiring GitHub access.

Syntax:

```bash
afctl update-root <version> [--no-pr]
```

Example:

```bash
afctl update-root 3.9
afctl update-root 3.9 --no-pr
```

Behavior without `--no-pr`:

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

Before running: change to a service repository with Go, Ruby/Bundler,
`test/Gemfile`, and the shared Go and Ruby Make targets. This downloads
dependencies and upgrades Bundler and Ruby test dependencies as well as
`go-service/v2`.

`<kind>` selects `make new-<kind>` (for example, `build`); `<version>` is the
Go module version including its `v` prefix. `--no-pr` leaves updates
uncommitted; otherwise the workflow publishes a PR through `make ready`.

Syntax:

```bash
afctl update-service-dep <kind> <version> [--no-pr]
```

Example:

```bash
afctl update-service-dep build v2.3.4
afctl update-service-dep build v2.3.4 --no-pr
```

Behavior without `--no-pr`:

- Runs `make name=deps new-<kind>`.
- Runs `make module=github.com/alexfalkowski/go-service/v2@<version> go-get`.
- Runs `make submodule go-dep` to update Go dependencies.
- Installs the latest Bundler in RubyGems' user gem directory, then runs
  `BUNDLE_VERSION=system make ruby-update-bundler` to update `test/Gemfile.lock`
  even when Homebrew removed the previously locked Bundler version.
- Runs `make ruby-update-all-dep` to update Ruby test dependencies.
- Finalizes with
  `make msg="upgraded github.com/alexfalkowski/go-service/v2 to <version>" desc="https://github.com/alexfalkowski/go-service/releases/tag/<version>" ready`.

### 📌 `afctl update-submodule`

Before running: change to a repository that includes `github.com/alexfalkowski/bin`
as an initialized submodule and exposes `make update-submodule`. Updating
submodules needs access to their Git remotes.

`<kind>` selects `make new-<kind>` (for example, `build`); `<desc>` is the
quoted PR description. `--no-pr` leaves updates uncommitted; otherwise the
workflow publishes a PR and enables auto-merge through `make ready`.

Syntax:

```bash
afctl update-submodule <kind> <desc> [--no-pr]
```

Example:

```bash
afctl update-submodule build "bump bin submodule"
afctl update-submodule build "bump bin submodule" --no-pr
```

Behavior without `--no-pr`:

- Runs `make name=deps new-<kind>`.
- Runs `make update-submodule`.
- Finalizes with
  `make msg="upgraded github.com/alexfalkowski/bin" desc="<desc>" ready`.

## 🧯 Troubleshooting

### 💎 Bundler version and gem specification mismatch

Homebrew Ruby upgrades can leave an earlier `gem update --system` installation
in the persistent `site_ruby` directory while replacing Bundler's default gem
specification. They also remove Bundler installations from Homebrew's shared
gem directory (see the [Ruby formula](https://github.com/Homebrew/homebrew-core/blob/main/Formula/r/ruby.rb)).
This can produce an error saying the running Bundler version
does not match its installed specification.

Install the affected project's `BUNDLED WITH` version from `Gemfile.lock` (or
`test/Gemfile.lock`) in the user gem directory, then rerun the project's
dependency target. For a service locked to Bundler 4.0.22, run from its root:

```bash
gem install bundler -v 4.0.22 --user-install
make ruby-dep
```

Use `make dep` for a repository with a root `Gemfile`. The Homebrew `bundle`
and `bundler` executables discover user-installed Bundler through RubyGems;
changing `PATH` is not required for these commands with the default gem paths.
If you override `GEM_PATH`, include the directory reported by
`gem environment user_gemhome`.

Use `afctl deps` to update Homebrew-managed Ruby and bootstrap Bundler, and
`afctl update-bundler` for subsequent Bundler upgrades. Both install Bundler
with `--user-install`, keeping it outside Homebrew's cleanup path. Avoid
`gem update --system` with Homebrew Ruby; let Homebrew manage RubyGems.
Reinstall user gems after changing Ruby's major or minor version, since each
Ruby API version has its own user gem directory.

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
