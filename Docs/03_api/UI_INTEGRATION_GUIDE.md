# UI Integration Guide (`NR-GD-003-02`)

Guidelines for integrating `NarrRailSession` into VN-style UI while preserving runtime/UI separation.

## Separation Rules

- Runtime owns story semantics and transitions.
- UI owns rendering, animation, input timing, and presentation.
- UI must not reimplement branching semantics.

## Recommended UI Flow

1. Create session.
2. Subscribe to runtime signals.
3. Render payload in UI.
4. Map user input to `next()` / `choose(index)`.

## Current Sample Implementations

### `demo_ui.gd`

- Purpose: debug-friendly story and outline loading
- Features:
  - selectable story path
  - synced outline resource selection
  - imported-resource-first loading
  - diagnostics status rendering
  - save/load buttons using `user://narrrail_demo_save.json`
  - speaker + body text presentation
  - dynamic choice buttons

## What UI Should Avoid

- hardcoding node progression rules
- mutating runtime internals directly
- relying on node IDs for visual state logic

## Extension Hooks

- Replace `textKey` display with localization lookup table.
- Add portrait/avatar binding by `speakerId`.
- Add backlog/history using `line_changed` records.
- Add voice playback triggers via `event_emitted`.
- Store game-specific metadata alongside `create_save_snapshot()` output.
- Subscribe to `trace_logged` when a richer external debug console is needed.

## QA Checklist

- [ ] Next advances to the next runtime state
- [ ] Choice state disables accidental `next()` input
- [ ] Invalid story shows actionable error status
- [ ] Reload keeps same `story_path` and restarts cleanly
- [ ] Save/load restores the same story path and current presentation state
- [ ] Outline selection can run Story, Branch, fallback, and End nodes through the same UI
