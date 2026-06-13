# TASK_PLAN.md

This document tracks work breakdown, status, and Definition of Done (DoD) for `NarrRail.Godot`.

## Status Legend

- [ ] Not started
- [~] In progress
- [x] Done
- [!] Blocked

---

## Milestone M1 - Runtime Core

### NR-GD-001-01 Runtime Data Model
- Status: [x]
- Goal: Define runtime data structures for nodes/edges/choices/variables/events.
- DoD:
  - [x] Data model supports all required node types.
  - [x] Serialization/deserialization contract documented.
  - [x] Unit tests cover core model constraints.

### NR-GD-001-02 Story Session State Machine
- Status: [x]
- Goal: Implement Start/Next/Choose/Stop flow with deterministic transitions.
- DoD:
  - [x] Supports linear dialogue and branching choice flow.
  - [x] Handles terminal states correctly.
  - [x] Transition errors return actionable diagnostics.
  - [x] Tests cover happy path + invalid transition cases.

### NR-GD-001-03 Condition Evaluation
- Status: [x]
- Goal: Evaluate branch conditions against variable state.
- DoD:
  - [x] Bool/Int/Float/String comparisons supported per spec.
  - [x] Invalid expressions produce clear errors.
  - [x] Tests cover condition truth table and edge cases and are run in Godot.

### NR-GD-001-04 Action Execution
- Status: [x]
- Goal: Execute node actions (set variable, emit event, jump behavior support if needed).
- DoD:
  - [x] Variable mutation semantics match spec.
  - [x] Event emission order deterministic and testable.
  - [x] Tests cover multiple chained actions.

---

## Milestone M2 - Import & Validation

### NR-GD-002-01 `.nrstory` Parser
- Status: [x]
- Goal: Parse script file into internal runtime model.
- DoD:
  - [x] Parse success for valid sample scripts.
  - [x] Structured error output for invalid scripts.
  - [x] Version/schema field captured.

### NR-GD-002-02 Asset/Resource Integration
- Status: [x]
- Goal: Map parsed story data into Godot-friendly resources/classes.
- DoD:
  - [x] Load path supports runtime consumption.
  - [x] Reimport/update behavior is stable.
  - [x] Minimal sample scene demonstrates loading and execution.

### NR-GD-002-03 Validation Pipeline
- Status: [x]
- Goal: Implement static validation (broken links, duplicate IDs, orphan nodes).
- DoD:
  - [x] Validation report includes location + fix suggestion.
  - [x] Can run validation without entering runtime play flow.
  - [x] Tests include invalid fixtures with expected diagnostics.

### NR-GD-002-04 External Story Repository Sync
- Status: [x]
- Goal: Sync external `.nrstory` repositories into generated Godot resources.
- DoD:
  - [x] Recursively scans an external repository and preserves relative subdirectories under `res://narrrail_stories/<repo_name>/`.
  - [x] Generates `.tres` resources without copying source `.nrstory` files into the Godot project.
  - [x] Supports both story files and `meta.configType: GlobalConfig`.
  - [x] Optional `git pull --ff-only` can run before sync.
  - [x] Stale generated resources under the managed target can be deleted after editor confirmation.
  - [x] Headless sync test covers creation, GlobalConfig generation, source path retention, and stale deletion.

---

## Milestone M3 - API & Integration

### NR-GD-003-01 Public Runtime API
- Status: [x]
- Goal: Expose stable API for game-side integration.
- DoD:
  - [x] Session lifecycle APIs documented.
  - [x] Callback/event subscription mechanism provided.
  - [x] API usage example in sample project.

### NR-GD-003-02 UI Integration Helpers
- Status: [x]
- Goal: Provide helper interfaces for dialogue UI and choices.
- DoD:
  - [x] Clean separation between runtime and UI.
  - [x] Choice rendering/selection integration example provided.
  - [x] No gameplay logic hardcoded in sample UI layer.

---

## Milestone M4 - Debugging Tooling

### NR-GD-004-01 Runtime Trace Logging
- Status: [x]
- Goal: Structured logs for node transitions, variable changes, emitted events.
- DoD:
  - [x] Logs can be toggled by level.
  - [x] Includes story/session/node context fields.
  - [x] Debug output useful for repro steps.

### NR-GD-004-02 In-Game Debug Overlay (Optional)
- Status: [x]
- Goal: Optional debug UI for current node, variables, and recent events.
- DoD:
  - [x] Can be enabled/disabled at runtime.
  - [x] Does not affect production flow when disabled.
  - [x] Basic usability validated in sample.

---

## Milestone M5 - Save/Load

### NR-GD-005-01 Session Snapshot Model
- Status: [x]
- Goal: Define save payload for session position + variables + essential history.
- DoD:
  - [x] Snapshot schema documented and versioned.
  - [x] Backward compatibility strategy defined.

### NR-GD-005-02 Save/Load API
- Status: [x]
- Goal: Implement export/import of session state.
- DoD:
  - [x] Restore returns identical continuation behavior.
  - [x] Corrupted/incompatible save handling is safe.
  - [x] Tests verify resume equivalence.

---

## Milestone M6 - Conformance & Quality Gate

### NR-GD-006-01 Conformance Test Suite
- Status: [x]
- Goal: Build cross-engine golden cases for semantic parity.
- DoD:
  - [x] Includes linear, branching, variable, event scenarios.
  - [x] Expected node/event/variable outputs defined.
  - [x] Test runner or reproducible manual protocol documented.

### NR-GD-006-02 Performance Baseline
- Status: [x]
- Goal: Establish initial runtime performance targets.
- DoD:
  - [x] Baseline scenarios documented (small/medium/large story).
  - [x] Key metrics recorded (load time, transition cost).
  - [x] Known bottlenecks listed.

---

## Change Log (Task-Level)

> Record task completion evidence here.

- 2026-05-25 - `NR-GD-001-01` - Done by: `agent` - Evidence: Added `addons/narrrail/runtime/story_model.gd` (minimal schema checks: required roots, entry existence, duplicate nodeId, edge refs).
- 2026-05-25 - `NR-GD-001-02` - Done by: `agent + user validation` - Evidence: Added `addons/narrrail/runtime/narrrail_session.gd`; user runtime log confirms `start -> next -> choice -> choose -> end` flow.
- 2026-05-25 - `NR-GD-002-01` - Done by: `agent` - Evidence: Added `addons/narrrail/importer/nrstory_loader.gd` with YAML-first parsing and JSON fallback; sample file `sample/stories/demo.nrstory` loads in demo UI.
- 2026-05-25 - `NR-GD-002-02` - Done by: `agent` - Evidence: Added `addons/narrrail/importer/nrstory_import_plugin.gd` + `addons/narrrail/narrrail_story_resource.gd`; plugin registers `.nrstory` importer and creates imported `.res` resource.
- 2026-05-25 - `NR-GD-003-01` - Done by: `agent` - Evidence: Session API exposed (`start`, `next`, `choose`, `get_state`) with signals (`line_changed`, `choices_changed`, `ended`, `error_raised`).
- 2026-05-25 - `NR-GD-003-02` - Done by: `agent + user validation` - Evidence: Added visual sample scene `sample/scenes/demo_ui.tscn` and script `sample/scripts/demo_ui.gd`; user confirmed UI flow works.
- 2026-05-25 - `NR-GD-001-03` - Done by: `agent` - Evidence: Added variable initialization, edge condition evaluation, and choice availability filtering in `narrrail_session.gd`; added Godot conformance fixtures/runner under `narrrail-host-project/tests/conformance/`; ran `godot --headless --path narrrail-host-project --script res://tests/conformance/conformance_runner.gd` with `[NarrRail][Conformance] PASS`.
- 2026-05-25 - `NR-GD-001-04` - Done by: `agent` - Evidence: Added `enterActions`/`exitActions` execution, variable mutation, `event_emitted`/`variable_changed` signals, event snapshots, and `Jump` node support in `narrrail_session.gd`; added conformance fixtures for action chains, jump action ordering, and invalid action variables; ran `godot --headless --path narrrail-host-project --script res://tests/conformance/conformance_runner.gd` with `[NarrRail][Conformance] PASS`.
- 2026-05-25 - `NR-GD-001-02` - Update by: `agent` - Evidence: Added `MultiDialogue` runtime progression (`lineIndex`, one `Next` per line, exit after final line) plus conformance fixtures for valid/invalid `MultiDialogue`; ran `godot --headless --path narrrail-host-project --script res://tests/conformance/conformance_runner.gd` with `[NarrRail][Conformance] PASS`.
- 2026-05-25 - `NR-GD-001-02` - Update by: `agent` - Evidence: Added `Choice.choiceMode=ExhaustiveUntilComplete` support with per-choice-node exhausted target tracking, hidden selected choices, and completion target transition; added valid/invalid conformance fixtures; ran `godot --headless --path narrrail-host-project --script res://tests/conformance/conformance_runner.gd` with `[NarrRail][Conformance] PASS`.
- 2026-05-25 - `NR-GD-001-02` - Fix by: `agent` - Evidence: Updated `ExhaustiveUntilComplete` to maintain a runtime return frame so branches that end at `End` or have no outgoing edge return to the source Choice until all options are exhausted; added `choice_exhaustive_terminal_return.nrstory`; verified `撫物語.nrstory` returns to the source Choice with 4 options remaining after the first branch; ran conformance with `[NarrRail][Conformance] PASS`.
- 2026-05-26 - `NR-GD-002-01` - Update by: `agent + user validation` - Evidence: Upgraded `nrstory_loader.gd` to return structured diagnostics (`severity/code/path/message/line`), added schemaVersion guardrail (`SUPPORTED_SCHEMA_VERSION=1`, reject future versions, warn on old versions), and wired diagnostics formatting into importer/UI; user headless run reports `[NarrRail][Conformance] PASS`.
- 2026-05-26 - `NR-GD-002-03` - Update by: `agent` - Evidence: Added independent static validation pipeline `addons/narrrail/importer/nrstory_validator.gd` (duplicate node IDs, broken edge refs, invalid choice targets, orphan node warnings) and integrated it into loader flow without entering runtime play state.
- 2026-05-26 - `NR-GD-002-03` - Update by: `agent` - Evidence: Added invalid fixtures (`invalid_parser_missing_fields.nrstory`, `invalid_validator_refs.nrstory`) and conformance assertions for expected diagnostic codes in `tests/conformance/conformance_runner.gd`.
- 2026-05-26 - `NR-GD-002-02` - Update by: `agent` - Evidence: Updated sample UI loader path to prefer imported `.nrstory` Resource (`story_data`) via `load(path)` and fallback to direct parse only if import path is unavailable.
- 2026-05-26 - `NR-GD-003-02` - Update by: `agent` - Evidence: Added standalone VN-style player scene `sample/scenes/vn_player.tscn` and controller `sample/scripts/vn_player.gd` (speaker/text display, click-to-next, dynamic choices, configurable `story_path` in Inspector).
- 2026-05-26 - `NR-GD-003-02` - Update by: `agent + user` - Evidence: Added typewriter effect in `sample/scripts/vn_player.gd` with click-to-skip-current-line behavior before advancing `next()`.
- 2026-05-26 - `NR-GD-002-02` - Done by: `agent` - Evidence: Added reimport stability protocol doc `Docs/02_runtime/REIMPORT_STABILITY.md` and confirmed sample runtime consumption path prioritizes imported resource.
- 2026-05-26 - `NR-GD-003-01` - Done by: `agent` - Evidence: Added runtime API documentation `Docs/03_api/RUNTIME_API.md` (lifecycle methods, signals, usage examples).
- 2026-05-26 - `NR-GD-003-02` - Done by: `agent` - Evidence: Added UI integration guideline `Docs/03_api/UI_INTEGRATION_GUIDE.md` and aligned standalone VN sample behavior.
- 2026-06-03 - `NR-GD-002-04` - Done by: `agent` - Evidence: Added `editor/story_repository_sync.gd`, `NarrRailGlobalConfigResource`, editor menu action `NarrRail Sync Stories`, and headless sync runner `tests/sync_repository_runner.gd`; ran `godot --headless --path narrrail-host-project --script res://tests/sync_repository_runner.gd` with `[NarrRail][SyncRepository] PASS`.
- 2026-06-13 - `NR-GD-005-01` / `NR-GD-005-02` - Done by: `agent` - Evidence: Added versioned session save snapshots and restore API in `narrrail_session.gd`; sample `demo_ui` and `vn_player` save/load `user://narrrail_demo_save.json`; conformance runner covers waiting-choice and MultiDialogue resume; ran `godot --headless --path narrrail-host-project --script res://tests/conformance/conformance_runner.gd` with `[NarrRail][Conformance] PASS`.
- 2026-06-13 - `NR-GD-005-02` - Fix by: `agent` - Evidence: Added cross-story restore coverage and `tests/save_load_smoke_runner.gd` for the sample UI flow `load story A -> save -> load story B -> load save`; read-save path now loads strictly instead of falling back to demo data; ran smoke with `[NarrRail][SaveLoadSmoke] PASS`.
- 2026-06-13 - `NR-GD-001-01` / `NR-GD-004-01` / `NR-GD-004-02` / `NR-GD-006-01` - Done by: `agent` - Evidence: Added standalone `EmitEvent` node runtime support and conformance fixture, structured trace logging API/signal, and optional `vn_player` debug overlay; ran conformance with `[NarrRail][Conformance] PASS`.
- 2026-06-13 - `NR-GD-002-03` - Done by: `agent` - Evidence: Static validator diagnostics now include `suggestion` alongside `path`; invalid fixture tests assert fix suggestions for validator errors; ran conformance with `[NarrRail][Conformance] PASS`.
- 2026-06-13 - `NR-GD-006-02` - Done by: `agent` - Evidence: Added `tests/performance_baseline_runner.gd` and `Docs/02_runtime/PERFORMANCE_BASELINE.md`; runner reports load/start/transition timings for fixture and synced-resource scenarios; ran with `[NarrRail][PerformanceBaseline] PASS`.

- YYYY-MM-DD - `NR-GD-XXX-YY` - Done by: `<name/agent>` - Evidence: `<PR/commit/test output>`

---

## Global Definition of Done

A task can be marked **Done** only if:

1. Acceptance criteria are met.
2. Relevant tests were added/updated and passed.
3. Conformance impact was checked (or explicitly N/A with reason).
4. Documentation was updated for behavior/API changes.
5. No unrelated breaking changes were introduced.

---
