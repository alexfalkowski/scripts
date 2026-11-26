# Accepted design for AI sessions

Part of the [accepted-design index](../accepted-design.md).

## Launch configuration and shared skills

`config/ai.yml` owns the launcher's model, reasoning level, and prompt preamble.
Explicit kind entries take precedence. A kind with a matching directory in
`bin/skills/` can use `kinds.default`, so new shared skills work without their
own launcher configuration. Kinds with `preamble: "-"` send the prompt directly
and reject scope and confidence flags.

`afctl ai skills` and `afctl ai help <kind>` read display metadata from the
vendored shared skills. Session launches run in the caller's working directory,
where the selected skill must already be available to the provider.

[Launcher](../../../libexec/ai) · [Launch configuration](../../../config/ai.yml)

## Ledger ownership

The ledger-owning implement or fix skill defines the scoped ledger path in its
`ledger.yaml` contract. Normal skill prompts pass the scope and leave ledger
resolution to that skill. `afctl ai ledger <kind>` reads the same contract to
display the selected scope's ledger or a single entry.

[Launcher](../../../libexec/ai) · [Example ledger contract](../../../bin/skills/code-issues-implement/ledger.yaml)
