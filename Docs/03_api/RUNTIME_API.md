# NarrRail Runtime API (`NR-GD-003-01`)

This document defines the current public runtime API surface for game-side integration.

## Primary Runtime Class

- Class: `NarrRailSession`
- Script: `res://addons/narrrail/runtime/narrrail_session.gd`
- Type: `RefCounted`

## Story Resource Resolution

- Class: `NarrRailStoryResourceLoader`
- Script: `res://addons/narrrail/runtime/story_resource_loader.gd`

### `resolve_story_path(story_name_or_path: String, registry_path: String = "") -> String`

Resolve a story identifier to a loadable resource path.

Resolution order:
- explicit `res://` or `user://` paths are returned directly
- synced story registry at `<narrrail/story_resource_root>/story_registry.tres`
- optional project alias map in `narrrail/story_aliases`
- directory scanning fallback for editor compatibility

The story sync workflow generates `story_registry.tres` as a normal project resource so exported builds can resolve synced stories without relying on runtime directory scans.

### `load_story(path: String) -> Dictionary`

Loads either an explicit story path or a story identifier such as `train_story`. Identifier loading uses `resolve_story_path()` first, then loads the resolved `NarrRailStoryResource`.

## Lifecycle Methods

### `start(story_data: Dictionary, initial_variables: Dictionary = {}) -> void`

Initialize session state and enter `meta.entryNodeId`.

Behavior:
- validates story shape/refs before runtime flow
- initializes variables from `variables[]`
- applies matching values from `initial_variables` after defaults are initialized
- emits initial `line_changed` or `choices_changed` depending on first node

Failure:
- emits `error_raised(message)` and moves to terminal/error state

### `next() -> void`

Advance current runtime state.

Behavior:
- `Dialogue`: resolve edge and enter next node
- `MultiDialogue`: advance one line; after last line, leave via edges
- `End`: no-op terminal behavior

Guardrails:
- if waiting for choice, calling `next()` emits `error_raised`

### `choose(index: int) -> void`

Select an option when in `Choice` state.

Behavior:
- validates index
- applies `choiceMode` semantics (`SinglePass`, `ExhaustiveUntilComplete`)
- transitions to selected target

Failure:
- emits `error_raised(message)`

### `pause() -> void`

Pause automatic runtime progression while the session is running.

When called from an `event_emitted` handler for a standalone `EmitEvent` node, the session remains on that event node and does not follow outgoing edges until `resume()` is called. This is a generic control API; the runtime does not interpret event types such as `delay`, `audio.play`, or `inventory.add_item`.

Failure:
- emits `error_raised(message)` if called outside `running` state

### `resume() -> void`

Resume a paused session.

If the pause happened on a standalone `EmitEvent` node, `resume()` continues by evaluating that node's outgoing edges. This lets game code implement events such as timed waits without hardcoding event semantics into the NarrRail runtime.

### `get_state() -> Dictionary`

Returns current runtime snapshot:
- `state`
- `currentNodeId`
- `pausedEventNodeId`
- `currentLineIndex`
- `choices`
- `variables`
- `events`
- `exhaustedChoiceTargets`
- `exhaustiveChoiceStack`
- `trace`

### `get_variable_snapshot() -> Dictionary`

Returns a duplicate of the current variable map. `NarrRailOutlineRunner` uses this to carry shared values between story sessions.

### `set_trace_enabled(enabled: bool) -> void`

Enable or disable runtime trace logging. Trace logging is disabled by default.

### `set_trace_level(level: int) -> void`

Set the maximum trace level:
- `0` - errors only
- `1` - info
- `2` - debug

### `get_trace_records() -> Array`

Return accumulated structured trace records.

### `create_save_snapshot() -> Dictionary`

Export a versioned save snapshot for the current session.

The snapshot includes:
- `saveSchemaVersion`
- story identity (`schemaVersion`, `storyId`)
- current state and node position
- current line index
- variables
- emitted event history
- exhaustive-choice runtime bookkeeping

The snapshot does not embed full story data. Game code should store the story path or resource ID alongside the snapshot.

### `restore_save_snapshot(story_data: Dictionary, snapshot: Dictionary) -> bool`

Restore a session from a snapshot using the supplied story data.

Behavior:
- validates save schema version and story identity
- validates the supplied story data before applying runtime state
- restores variables, event history, current node, line index, paused event continuation, choices, and exhaustive-choice bookkeeping
- emits the current presentation signal after restore (`line_changed`, `choices_changed`, or `ended`)

Failure:
- emits `error_raised(message)`
- returns `false`

Game-side save files should usually store:

```gdscript
{
    "storyPath": "res://sample/stories/demo.nrstory",
    "snapshot": session.create_save_snapshot()
}
```

## Signals (Callback/Event Subscription)

### `line_changed(payload: Dictionary)`

Payload fields:
- `nodeId: String`
- `lineIndex: int`
- `speakerId: String`
- `textKey: String`

### `choices_changed(choices: Array)`

Emitted when a choice node is entered with available options.

### `ended()`

Emitted on terminal completion.

### `error_raised(message: String)`

Emitted on validation/runtime transition errors.

### `variable_changed(payload: Dictionary)`

Emitted when `Set/Add/Subtract` mutates variable state.

### `event_emitted(payload: Dictionary)`

Emitted when an `EmitEvent` action or standalone `EmitEvent` node is executed.

Payload fields:
- `nodeId: String`
- `phase: String` - `enter`, `exit`, or `node`
- `eventType: String` - structured event type
- `params: Dictionary` - structured event params, or `{}`

The runtime forwards event data only. Gameplay-specific meanings such as inventory, audio, or scene changes belong in game code.

Use `NarrRailEventRouter` when you want story events to trigger engine behavior directly:

```gdscript
var router := NarrRailEventRouter.new()
router.register_type("inventory.add_item", Callable(self, "_on_inventory_add_item"))
session.event_emitted.connect(router.dispatch)
```

You can also consume structured events directly:

```gdscript
session.event_emitted.connect(func(payload: Dictionary):
	match String(payload.get("eventType", "")):
		"inventory.add_item":
			var params := payload.get("params", {})
			# game-specific handling
)
```

Example project-side delay handler:

```gdscript
router.register_type("delay", Callable(self, "_on_delay_event"))

func _on_delay_event(payload: Dictionary) -> void:
	var params: Dictionary = payload.get("params", {})
	var seconds := float(params.get("time", 0.0))
	session.pause()
	await get_tree().create_timer(maxf(seconds, 0.0)).timeout
	session.resume()
```

### `trace_logged(payload: Dictionary)`

Emitted when trace logging is enabled and the runtime records a trace event.

Common payload fields:
- `eventType: String`
- `level: int`
- `storyId: String`
- `state: String`
- `nodeId: String`

Common `eventType` values:
- `session_start`
- `session_restore`
- `node_enter`
- `line`
- `choices`
- `transition`
- `variable`
- `event`
- `ended`
- `error`

## Minimal Integration Example

```gdscript
var session_script: Script = load("res://addons/narrrail/runtime/narrrail_session.gd")
var session: RefCounted = session_script.new()

session.line_changed.connect(func(payload: Dictionary):
    print("line", payload)
)
session.choices_changed.connect(func(choices: Array):
    print("choices", choices)
)
session.error_raised.connect(func(message: String):
    push_error(message)
)

session.start(story_dict)
# session.next()
# session.choose(0)
```

## Outline Runtime

- Class: `NarrRailOutlineRunner`
- Script: `res://addons/narrrail/runtime/narrrail_outline_runner.gd`
- Type: `RefCounted`

`NarrRailOutlineRunner` executes a `.nroutline` graph and delegates each `Story` node to an internal `NarrRailSession`.

### `start(outline_data: Dictionary, story_library: Dictionary, initial_variables: Dictionary = {}) -> void`

Starts the outline at `meta.entryNodeId`.

`story_library` maps `storyId` to one of:
- a parsed story `Dictionary`
- a story resource path `String`
- a `NarrRailStoryResource`

The runner passes the shared variable snapshot into every story session. Variables changed by one story are available to later outline Branch nodes and later stories that define matching variables.

### `next() -> void`

Forwards to the active story session. If the active story ends, the runner returns to the outline graph and continues to the next outline node.

### `choose(index: int) -> void`

Forwards a choice selection to the active story session.

### `advance_time(delta_seconds: float) -> void`

Forwards choice timer time to the active story session.

### `pause() -> void`

Forwards to the active story session. Used by project-side event handlers that need to delay story progression while running through an outline.

### `resume() -> void`

Forwards to the active story session.

### `get_state() -> Dictionary`

Returns:
- `state`
- `currentOutlineNodeId`
- `activeStoryId`
- `activeStoryState`
- `variables`
- `error`

### Outline Signals

- `outline_node_entered(payload: Dictionary)`
- `outline_branch_matched(payload: Dictionary)`
- `line_changed(payload: Dictionary)`
- `choices_changed(choices: Array)`
- `variable_changed(payload: Dictionary)`
- `event_emitted(payload: Dictionary)`
- `choice_timer_changed(payload: Dictionary)`
- `choice_timed_out(payload: Dictionary)`
- `ended()`
- `error_raised(message: String)`

Forwarded story payloads include `outlineNodeId` and `storyId` where applicable.

## Sample References

- `res://sample/scripts/demo_ui.gd`
