# NarrRail Godot Plugin v0.1.0

First public preview release of the NarrRail Godot runtime plugin.

## Install

1. Download `narrrail-godot-plugin-v0.1.0.zip`.
2. Extract it.
3. Copy the `narrrail/` folder into your Godot project:

```text
your-project/addons/narrrail/
```

4. Open Godot and enable:

```text
Project > Project Settings > Plugins > NarrRail
```

## Highlights

- Import `.nrstory` files as Godot resources.
- Sync an external NarrRail story repository into generated `.tres` resources.
- Run story sessions with dialogue, multi-dialogue, choices, jumps, variables, conditions, events, and endings.
- Save and restore runtime sessions with snapshot APIs.
- Subscribe to runtime signals for UI integration.
- Use optional trace logging for debugging.

## Verified

Validated with Godot `4.6.3` using:

```sh
godot --headless --path narrrail-host-project --script res://tests/conformance/conformance_runner.gd
godot --headless --path narrrail-host-project --script res://tests/save_load_smoke_runner.gd
godot --headless --path narrrail-host-project --script res://tests/performance_baseline_runner.gd
godot --headless --path narrrail-host-project --script res://tests/sync_repository_runner.gd
godot --headless --path narrrail-host-project --quit-after 1
```

## Preview Caveat

This is a `0.1.0` preview release. The plugin is usable, but API and `.nrstory` compatibility details may still change before `1.0.0`.

