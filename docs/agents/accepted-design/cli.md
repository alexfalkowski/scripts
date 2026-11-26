# Accepted design for the CLI

Part of the [accepted-design index](../accepted-design.md).

## Command dispatch

`afctl` is the supported entry point for the toolbox. Subcommand implementations
live in `libexec/`. The dispatcher prepends that directory to `PATH` so bulk
commands can change into target repositories and still call helpers such as
`update-ci`, `update-bundler`, and `update-submodule` by name. Preserve command
names and argument order unless the task explicitly requires changing them.

[Dispatcher](../../../afctl) · [Bulk update commands](../../../libexec/update)

## Help and completion

`afctl help <command>` and the command's `--help` and `-h` forms read the same
command section from the README. Preserve the `afctl <command>` heading format
when editing the command reference. Help runs before dispatch so maintainers
can check prerequisites and side effects before running a command.

`afctl completion zsh` prints the completion script with the checkout's
absolute path embedded so it can discover commands after shell startup from any
working directory.

[Dispatcher](../../../afctl) · [README](../../../README.md) ·
[Zsh completion](../../../config/completions.zsh)
