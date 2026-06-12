# AGENTS.md

This file gives AI coding agents and contributors the repository-level operating rules for `NarrRail-Godot-Plugin`.

## Project

`NarrRail-Godot-Plugin` is a Godot plugin/runtime for NarrRail `.nrstory` files. The plugin handles import, validation, resource generation, runtime story execution, choices, variables, conditions, actions, and sample UI integration.

The `.nrstory` schema and semantics are compatibility-critical. Treat the external NarrRail spec, plus the mirrored docs under `Docs/`, as the source of truth for behavior.

## Repository Layout

- `narrrail-plugin/` - plugin source loaded by Godot as `res://addons/narrrail`
- `narrrail-plugin/runtime/` - runtime model, story loading, and session state machine
- `narrrail-plugin/importer/` - `.nrstory` parsing, validation, and import integration
- `narrrail-plugin/editor/` - editor-side repository sync tooling
- `narrrail-host-project/` - sample Godot host project and test runners
- `narrrail-host-project/tests/` - conformance and sync tests
- `Docs/` - architecture, runtime format, API, and integration docs

The host project is expected to expose the plugin through:

```sh
mkdir -p narrrail-host-project/addons
ln -s ../../narrrail-plugin narrrail-host-project/addons/narrrail
```

## Development Rules

- Keep core runtime behavior in plugin code, not sample scenes or ad-hoc editor wiring.
- Preserve deterministic `.nrstory` semantics: node progression, branch selection, variable mutations, and emitted event order must remain stable for identical input.
- Keep runtime, importer, editor sync, samples, and docs concerns separate.
- Follow existing GDScript style and Godot resource patterns.
- Make focused changes only; avoid unrelated refactors during feature or bug-fix work.
- Do not introduce new dependencies unless the need is clear and documented.
- Do not commit, tag, rebase, reset, or delete user work unless explicitly asked.

## Validation

Use the Godot host project for verification.

Run conformance tests after runtime, parser, validator, or story semantics changes:

```sh
godot --headless --path narrrail-host-project --script res://tests/conformance/conformance_runner.gd
```

Run sync tests after editor repository sync, generated resource, or global config changes:

```sh
godot --headless --path narrrail-host-project --script res://tests/sync_repository_runner.gd
```

Run a basic project load check after plugin registration or project setup changes:

```sh
godot --headless --path narrrail-host-project --quit-after 1
```

If `godot` is unavailable locally, report that explicitly and list the commands that still need to be run.

## Documentation

Update docs when behavior, public API, file format support, setup steps, or sample usage changes.

Relevant references:

- `README.md` - setup, workflow, and high-level feature list
- `Docs/01_architecture/AGENTS.md` - detailed architecture and agent policy
- `Docs/01_architecture/TASK_PLAN.md` - milestone/task status and evidence
- `Docs/02_runtime/SCRIPT_FORMAT.md` - `.nrstory` format details
- `Docs/03_api/RUNTIME_API.md` - runtime API contract
- `Docs/03_api/UI_INTEGRATION_GUIDE.md` - UI integration guidance

## Definition of Done

A change is complete when:

- the requested behavior is implemented
- relevant tests or checks have been run, or the inability to run them is reported
- conformance impact is considered for runtime semantics changes
- docs are updated when interfaces or behavior changed
- unrelated user changes are preserved

