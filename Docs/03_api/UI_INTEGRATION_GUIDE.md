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

- Purpose: debug-friendly loading and story selection
- Features:
  - selectable story path
  - imported-resource-first loading
  - diagnostics status rendering

### `vn_player.gd`

- Purpose: standalone VN interaction scene
- Features:
  - speaker + body text presentation
  - click-to-advance
  - dynamic choice buttons
  - inspector-configured `story_path`
  - typewriter effect with click-to-skip-current-line

## What UI Should Avoid

- hardcoding node progression rules
- mutating runtime internals directly
- relying on node IDs for visual state logic

## Extension Hooks

- Replace `textKey` display with localization lookup table.
- Add portrait/avatar binding by `speakerId`.
- Add backlog/history using `line_changed` records.
- Add voice playback triggers via `event_emitted`.

## QA Checklist

- [ ] Clicking during typewriter completes current line first
- [ ] Clicking after full line advances to next state
- [ ] Choice state disables accidental `next()` input
- [ ] Invalid story shows actionable error status
- [ ] Reload keeps same `story_path` and restarts cleanly
