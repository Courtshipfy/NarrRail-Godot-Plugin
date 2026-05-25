# AI_BRIEF.md

Use this brief at the start of every new AI coding session to restore project context quickly and consistently.

---

## 1) Project Context

- Project: `NarrRail.Godot`
- Type: Godot plugin/runtime for NarrRail `.nrstory`
- Primary goal: deterministic story execution compatible with NarrRail semantics
- Reference governance: `AGENTS.md` (must follow)

---

## 2) Hard Constraints (Must Follow)

1. Core runtime logic must be implemented in plugin code (GDScript/C#), not scene-level ad-hoc wiring.
2. `.nrstory` semantics must remain compatible with NarrRail spec/runtime.
3. Do not perform destructive git actions unless explicitly requested.
4. Do not introduce unrelated refactors.
5. If behavior changes, update docs and tests accordingly.

---

## 3) Current Task

> Replace this section each time.

- Task ID: `NR-GD-XXX-YY`
- Objective:
- In scope:
- Out of scope:
- Target files/directories:
- Acceptance criteria:

---

## 4) Technical References

- `AGENTS.md`
- `README.md`
- `Docs/` (architecture/spec/task docs)
- `tests/conformance/` cases (if present)

If a reference is missing, report what is missing and proceed with best available context.

---

## 5) Execution Instructions for AI Agent

1. First read relevant files and confirm understanding.
2. Propose a short implementation plan.
3. Implement focused changes only.
4. Add/update tests relevant to changed behavior.
5. Run validation commands and report exact results.
6. Summarize:
   - what changed
   - why it changed
   - validation evidence
   - follow-up risks/todos

---

## 6) Output Format Requirements

The final response should include:

- **Summary of changes**
- **Files touched**
- **Validation run** (commands + pass/fail)
- **Known limitations / follow-up**

Do not claim tests passed unless actually executed.

---

## 7) Optional Session Variables

> Fill when needed.

- Engine version: `Godot X.Y`
- Language mode: `GDScript` / `C#` / `Mixed`
- Performance focus: `Yes/No`
- Compatibility mode: `Strict/Relaxed` (default: `Strict`)

---
