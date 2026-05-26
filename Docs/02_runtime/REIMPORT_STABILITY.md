# Reimport Stability Verification (`NR-GD-002-02`)

This document defines a repeatable protocol to verify `.nrstory` reimport/update behavior is stable in Godot.

## Scope

- Import path: `res://*.nrstory` -> imported Resource (`story_data` payload)
- Runtime consumption path: sample UI loads imported resource first, then optional direct parse fallback
- Expected stability:
  - no editor crash
  - imported resource updates after source file change
  - runtime view reflects latest content after reload

## Preconditions

1. Plugin enabled: `Project Settings > Plugins > NarrRail`
2. Story file exists: `res://sample/stories/demo.nrstory`
3. Demo scene exists: `res://sample/scenes/vn_player.tscn`

## Protocol

### Step A - Baseline import

1. Open `demo.nrstory`.
2. Ensure it contains a known first line text (e.g. `你好，今天一起去散步吗？`).
3. In FileSystem, right-click `demo.nrstory` -> `Reimport`.
4. Run `vn_player.tscn`.

Expected:
- Status shows `Loaded imported: res://sample/stories/demo.nrstory`.
- First displayed line matches baseline text.

### Step B - Update source and reimport

1. Edit first dialogue `textKey` in `demo.nrstory` to a clearly different text (e.g. `这是重导入后的新文本`).
2. Save file.
3. Right-click `demo.nrstory` -> `Reimport`.
4. In running scene, click `Reload`.

Expected:
- No import errors in Output.
- First displayed line updates to new text.
- No stale content from previous import remains.

### Step C - Structural validation error path

1. Introduce an invalid reference (e.g. choice target to missing node).
2. Reimport.

Expected:
- Import fails with structured diagnostics (code/path/message).
- Editor remains responsive.
- Fix file and reimport recovers normal loading.

## Result Template

```md
## Reimport Verification Result - YYYY-MM-DD

- Operator:
- Godot version:
- Story file:

### A) Baseline import
- Result: Pass/Fail
- Notes:

### B) Update and reimport
- Result: Pass/Fail
- Notes:

### C) Invalid -> recover
- Result: Pass/Fail
- Notes:

Overall: Pass/Fail
```

## Current Status

- Protocol documented and reproducible.
- Final pass/fail record should be appended after local run evidence is captured.
