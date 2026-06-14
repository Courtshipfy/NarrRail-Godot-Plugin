# Changelog

## v0.1.0 - 2026-06-14

Initial public preview release of the NarrRail Godot plugin.

### Added

- `.nrstory` import as Godot resources.
- External story repository sync into generated `.tres` resources.
- Runtime support for `Dialogue`, `MultiDialogue`, `Choice`, `Jump`, `SetVariable`, `Condition`, `EmitEvent`, and `End`.
- Variable defaults for `Bool`, `Int`, `Float`, and `String`.
- Condition evaluation with `All` logic and comparison operators.
- `enterActions` / `exitActions` support for `Set`, `Add`, `Subtract`, and `EmitEvent`.
- Save/load snapshot API via `create_save_snapshot()` and `restore_save_snapshot(story_data, snapshot)`.
- Runtime signals for line, choices, end, errors, variables, events, and trace logs.
- Optional runtime trace logging.
- Optional debug overlay in the `vn_player` sample.
- GlobalConfig variable merge for synced story resources.
- Headless conformance, sync, save/load smoke, and performance baseline runners.

### Notes

- Verified with Godot `4.6.3`.
- Public API is usable but still preview-stage; breaking changes may happen before `1.0.0`.

