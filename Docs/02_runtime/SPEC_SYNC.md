# SPEC_SYNC.md

Define how `.nrstory` specification and runtime semantics are synchronized into `NarrRail.Godot`, so contributors/AI agents always implement against authoritative rules.

---

## 1) Purpose

This document prevents spec drift and implementation guessing by defining:

- where the authoritative `.nrstory` spec lives
- how this repository mirrors/consumes that spec
- what to do when spec is unclear or conflicts are found

---

## 2) Authoritative Sources

## 2.1 Primary source (authoritative)
- `NarrRail` ecosystem runtime spec:
  - `Docs/02_runtime/SCRIPT_FORMAT.md` (authoritative semantics & schema)
  - Related architecture/runtime docs where applicable

## 2.2 Local mirror in this repo
- Mirror path in this repository:
  - `Docs/02_runtime/SCRIPT_FORMAT.md`
  - Related docs under `Docs/02_runtime/` and `Docs/01_architecture/` (if copied)

> Rule: Local mirror is for implementation convenience.  
> If conflict exists, resolve against authoritative source first, then update mirror.

---

## 3) Sync Strategy

## 3.1 When to sync
Sync spec mirror when any of these happens:

1. Upstream `.nrstory` schema changes.
2. Runtime semantics change (node progression, condition/action behavior, event order, save/load fields).
3. New node types/fields/operators are introduced.
4. Ambiguity is clarified in upstream docs/issues.

## 3.2 Sync cadence
- Minimum: before each milestone implementation start.
- Recommended: on every upstream spec-tagged change.

## 3.3 Sync process (required steps)
1. Pull latest authoritative docs.
2. Update local mirror files.
3. Add/update `spec_version` marker (see section 4).
4. Re-run conformance tests.
5. Record sync evidence in changelog (section 9).

---

## 4) Versioning & Traceability

Maintain explicit version markers in this repo:

- `spec_name`: `.nrstory`
- `spec_version`: e.g. `v1`
- `synced_from`: source repository/path/commit/tag
- `synced_at`: date (UTC+0 preferred)

Recommended location:
- table in this file

Example:

| field         | value                                      |
|---------------|--------------------------------------------|
| spec_name     | .nrstory                                   |
| spec_version  | v1                                         |
| synced_from   | NarrRail@`<commit-or-tag>`                |
| synced_at     | 2026-05-25                                 |
| notes         | Added Choice fallback clarification         |

---

## 5) Implementation Contract (Must Follow)

Any parser/runtime/importer change must satisfy:

1. Conforms to mirrored `SCRIPT_FORMAT.md`.
2. No silent reinterpretation of existing fields.
3. Unknown/unsupported constructs fail with actionable diagnostics.
4. Deterministic behavior for identical input + choice decisions.
5. Compatibility impact documented.

---

## 6) Unknown / Ambiguous Spec Handling

If any requirement is unclear:

1. **Stop implementation for the ambiguous part.**
2. Create a “Spec Clarification” entry (template below).
3. Continue only on unambiguous scope.

Do **not** guess semantics for:
- operator precedence
- missing-field defaults
- event ordering
- branch conflict resolution
- save/load compatibility semantics

## 6.1 Clarification template

```md
## Spec Clarification Request - <ID>

- Area: (parser/runtime/condition/action/save-load)
- File/Section: `Docs/02_runtime/SCRIPT_FORMAT.md#...`
- Current ambiguity:
- Candidate interpretations:
  1) ...
  2) ...
- Impact:
- Proposed temporary behavior (if any):
- Decision by:
- Decision date:
```

---

## 7) Conformance Requirements

Every spec sync or runtime semantic change must validate with conformance scenarios:

- linear story progression
- branching choice with conditions
- variable set/update behavior
- event emission ordering
- terminal/end node behavior
- invalid script diagnostics

Test evidence should include:

- input script case name
- expected vs actual node trace
- expected vs actual variable snapshot
- expected vs actual emitted events

---

## 8) File Ownership & Change Scope

Preferred ownership boundaries:

- `runtime/` - execution semantics
- `importer/` - parse/map/validate
- `tests/conformance/` - golden cases
- `Docs/` - mirrored spec and sync records

Do not mix large unrelated refactors with spec sync updates.

---

## 9) Sync Changelog

Record each sync operation.

## YYYY-MM-DD - SPEC SYNC
- Source: `<repo/path@commit-or-tag>`
- Updated files:
  - `Docs/02_runtime/SCRIPT_FORMAT.md`
  - `Docs/02_runtime/SPEC_SYNC.md` (if version/sync table is updated)
  - `tests/conformance/...` (if any)
- Semantic changes:
  - ...
- Compatibility impact:
  - None / Backward compatible / Breaking (details)
- Validation evidence:
  - command:
  - result:

---

## 10) PR Checklist (Spec-related Changes)

- [ ] I updated local spec mirror files from authoritative source.
- [ ] `spec_version` and `synced_from` are updated.
- [ ] Conformance tests were run and evidence attached.
- [ ] Compatibility impact is documented.
- [ ] Ambiguities are captured as clarification items (if any).

---

## 11) AI Agent Guardrail

Agents must not start implementation if spec authority is missing.

Required first-step behavior:

1. Read `Docs/02_runtime/SCRIPT_FORMAT.md`.
2. Produce:
   - field schema summary
   - runtime semantics summary
   - ambiguity list
3. Ask for clarification on ambiguities before coding affected parts.

If this file or spec mirror is missing, agent should return:
`BLOCKED: Missing authoritative .nrstory spec mirror; please provide source doc/path.`

---
