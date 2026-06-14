# Release Checklist

Use this checklist before publishing a GitHub release.

## Version

- [ ] Update `narrrail/plugin.cfg` version if needed.
- [ ] Update `CHANGELOG.md`.
- [ ] Update `RELEASE_NOTES_vX.Y.Z.md`.
- [ ] Confirm `README.md` install instructions mention `addons/narrrail`.

## Validation

Run from the repository root:

```sh
godot --headless --path narrrail-host-project --script res://tests/conformance/conformance_runner.gd
godot --headless --path narrrail-host-project --script res://tests/save_load_smoke_runner.gd
godot --headless --path narrrail-host-project --script res://tests/performance_baseline_runner.gd
godot --headless --path narrrail-host-project --script res://tests/sync_repository_runner.gd
godot --headless --path narrrail-host-project --quit-after 1
```

Record the result in the release notes.

## Package

```sh
bash tools/package_release.sh 0.1.0
```

Expected artifact:

```text
dist/narrrail-godot-plugin-v0.1.0.zip
```

Sanity check the artifact by extracting it and confirming it contains:

```text
narrrail/
README.md
LICENSE
CHANGELOG.md
RELEASE_NOTES.md
```

## GitHub Release

- [ ] Create tag, for example `v0.1.0`.
- [ ] Mark as pre-release while the plugin is below `1.0.0`.
- [ ] Paste release notes from `RELEASE_NOTES_v0.1.0.md`.
- [ ] Upload `dist/narrrail-godot-plugin-v0.1.0.zip`.
- [ ] Confirm the release page shows the MIT license.

