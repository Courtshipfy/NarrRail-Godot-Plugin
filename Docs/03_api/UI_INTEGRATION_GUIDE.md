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
- Add voice playback or gameplay triggers via `NarrRailEventRouter`.
- Store game-specific metadata alongside `create_save_snapshot()` output.
- Subscribe to `trace_logged` when a richer external debug console is needed.

## Event Routing

Use `NarrRailEventRouter` when story events should execute Godot behavior directly instead of being inspected through logs.

```gdscript
var event_router := NarrRailEventRouter.new()

func _ready() -> void:
	event_router.register_type("inventory.add_item", Callable(self, "_on_inventory_add_item"))
	session.event_emitted.connect(event_router.dispatch)
```

For events that should delay node progression, keep the event meaning in project code and use the runtime's generic pause/resume API:

```gdscript
func _ready() -> void:
	event_router.register_type("delay", Callable(self, "_on_delay_event"))
	session.event_emitted.connect(event_router.dispatch)

func _on_delay_event(payload: Dictionary) -> void:
	var params: Dictionary = payload.get("params", {})
	var seconds := float(params.get("time", 0.0))
	session.pause()
	await get_tree().create_timer(maxf(seconds, 0.0)).timeout
	session.resume()
```

Story-side event nodes use structured `eventType` + optional `params`:

```yaml
- nodeId: N_Event
  nodeType: EmitEvent
  eventType: inventory.add_item
  params:
    itemId: key
    count: 1
```

Delay event example used by the sample project:

```yaml
- nodeId: N_Delay
  nodeType: EmitEvent
  eventType: delay
  params:
    time: 1.0
```

## QA Checklist

- [ ] Next advances to the next runtime state
- [ ] Choice state disables accidental `next()` input
- [ ] Invalid story shows actionable error status
- [ ] Reload keeps same `story_path` and restarts cleanly
- [ ] Save/load restores the same story path and current presentation state
- [ ] Outline selection can run Story, Branch, fallback, and End nodes through the same UI
