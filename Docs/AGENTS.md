# AGENTS.md

This file defines how AI coding agents and human contributors should work in this repository.

## 1) Project Identity

**Project name:** NarrRail.Godot  
**Goal:** Implement a Godot runtime plugin for NarrRail story scripts (`.nrstory`) with deterministic execution behavior consistent with the existing NarrRail ecosystem.

This repository focuses on **Godot-side runtime/integration/debug tooling**.  
It is **not** the source of truth for story schema design.

---

## 2) Core Architecture Rules (Mandatory)

### 2.1 Runtime logic must live in code, not editor wiring
Core execution logic must be implemented in plugin code (GDScript/C#), including:

- state machine progression
- condition evaluation
- variable mutation
- branching and jump resolution
- save/load core logic (when implemented)

Do **not** move core logic into scene-level ad-hoc visual wiring.

### 2.2 `.nrstory` semantic compatibility is mandatory
Behavior must stay compatible with NarrRail script semantics:

- same node progression rules
- same condition/action semantics
- same deterministic outcomes for identical input

If behavior differs from existing NarrRail spec/runtime, document it and treat as a compatibility issue.

### 2.3 Separation of concerns
- **Runtime module:** execution engine, data model, APIs
- **Importer/parser:** `.nrstory` parsing + validation + mapping
- **Debug utilities:** runtime inspection, tracing, diagnostics
- **Samples:** usage only, not the implementation source

---

## 3) Source of Truth & Spec Policy

## 3.1 Single source of truth
The `.nrstory` schema/spec is defined externally (or in `/Docs` mirror).  
Implementation must follow spec first, engine adaptation second.

## 3.2 Version compatibility
When schema/version handling is introduced:

- keep backward compatibility where possible
- clearly mark breaking changes
- provide migration notes
- never silently reinterpret script semantics

---

## 4) Development Workflow

1. Read task scope and acceptance criteria.
2. Locate relevant runtime/importer/debug code.
3. Implement minimal, focused changes.
4. Add/update tests (unit/integration/conformance).
5. Run validations and record results.
6. Update docs for any behavior/interface change.

Do not perform unrelated refactors during feature/fix tasks unless required for correctness.

---

## 5) Task Management

Use structured task IDs (example):
- `NR-GD-001-*` Runtime Core
- `NR-GD-002-*` Import/Parser
- `NR-GD-003-*` Debugger
- `NR-GD-004-*` Save/Load
- `NR-GD-005-*` API & Integration

Each task should include:
- objective
- constraints
- definition of done (DoD)
- test evidence

---

## 6) Coding Standards

- Follow existing repository style and naming conventions.
- Prefer small, explicit functions over hidden side effects.
- Add comments only for non-obvious intent or constraints.
- Avoid introducing new dependencies unless justified.
- Preserve deterministic behavior in runtime decisions.

---

## 7) Validation & Testing Requirements

## 7.1 Minimum validation before completion
For any runtime behavior change, run at least:

- targeted tests around changed code
- at least one conformance scenario (`.nrstory`)
- basic sample run (if available)

## 7.2 Conformance-first principle
Cross-engine consistency is critical.  
Given the same `.nrstory` and inputs, expected outputs should match NarrRail semantics:

- visited node sequence
- branch selection behavior
- final variable state
- emitted event order

If mismatch is found, report explicitly with repro case.

---

## 8) Documentation Update Policy

When changing behavior/interfaces, update corresponding docs:

- README usage snippets
- runtime/API docs
- compatibility or migration notes
- task plan progress (if used)

Do not leave behavior changes undocumented.

---

## 9) Safety & Git Rules

Never do destructive operations unless explicitly requested:

- no hard reset/rebase rewrites without approval
- no deleting user-authored work to silence errors
- no secret/key hardcoding

Do not commit or tag releases unless explicitly asked.

---

## 10) AI Agent Operating Instructions

When acting as an AI coding agent:

1. Be precise and minimally invasive.
2. Gather context from repository files before editing.
3. State assumptions clearly when uncertain.
4. Prefer root-cause fixes over surface patches.
5. Report exactly what changed and how it was validated.
6. If tests cannot run, explain why and what remains to verify.

For large tasks, decompose into independent subtasks and keep write scopes non-overlapping.

---

## 11) Recommended Repository Layout (Guideline)

- `/addons/narrrail/` or equivalent plugin root
- `/runtime/` execution core
- `/importer/` script import/parse/validate
- `/debug/` debug tooling
- `/samples/` demo scenes/projects
- `/tests/` unit + integration + conformance
- `/Docs/` architecture/spec mirrors/plans

(Exact paths may differ; keep the separation clear.)

---

## 12) Definition of Done (Global)

A task is done only when:

- implementation satisfies acceptance criteria
- tests relevant to the change pass
- conformance impact is checked
- docs/task status are updated where required
- no unrelated behavior regressions introduced intentionally

---
