# Performance Baseline

This document records the first reproducible runtime performance gate for `NarrRail.Godot`.

## Runner

Run from the repository root:

```sh
godot --headless --path narrrail-host-project --script res://tests/performance_baseline_runner.gd
```

The runner reports:

- `load_usec` - story/resource loading time
- `start_usec` - `NarrRailSession.start(story)` time
- `transition_usec` - bounded `next()` / `choose(0)` progression time
- `events` - number of presentation events observed during the bounded run

## Baseline Scenarios

- `small_fixture` - small linear/condition fixture
- `choice_fixture` - exhaustive choice fixture
- `synced_story` - generated `.tres` story resource, skipped when the local synced test repo is absent

## Current Policy

This baseline is a smoke-quality gate, not a hard performance budget yet.

Use it to:

- catch extreme regressions in load/start/transition paths
- compare future parser/importer/runtime changes against stable scenarios
- record numbers in task evidence when performance-sensitive changes land

Hard budgets should be added only after representative small/medium/large production stories are available.

