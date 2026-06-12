extends SceneTree

const DEMO_UI_SCENE := "res://sample/scenes/demo_ui.tscn"
const STORY_A := "res://tests/conformance/choice_availability_bool.nrstory"
const STORY_B := "res://tests/conformance/condition_int_branch.nrstory"
const SYNCED_STORY_A := "res://narrrail_stories/NarrRailEditor-TestRepo/Stories/蜗物语.tres"
const SYNCED_STORY_B := "res://narrrail_stories/NarrRailEditor-TestRepo/Stories/伤物语.tres"
const SAVE_PATH := "user://narrrail_demo_save.json"

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await _run_ui_story_switch_save_load("fixtures", STORY_A, STORY_B)
	if ResourceLoader.exists(SYNCED_STORY_A) and ResourceLoader.exists(SYNCED_STORY_B):
		await _run_ui_story_switch_save_load("synced resources", SYNCED_STORY_A, SYNCED_STORY_B)
	_finish()

func _run_ui_story_switch_save_load(label: String, story_a: String, story_b: String) -> void:
	var scene: PackedScene = load(DEMO_UI_SCENE)
	if scene == null:
		_failures.append("Failed to load demo UI scene")
		return

	var ui := scene.instantiate()
	root.add_child(ui)
	await process_frame

	ui.call("_load_story_path", story_a)
	ui.call("_on_next_pressed")
	_record_state_if_failed(ui, "%s before save" % label, "waiting_choice")
	ui.call("_on_save_pressed")

	ui.call("_load_story_path", story_b)
	ui.call("_on_next_pressed")

	ui.call("_on_load_save_pressed")
	var session: RefCounted = ui.get("_session")
	if session == null:
		_failures.append("%s: session missing after load save" % label)
	else:
		var state: Dictionary = session.get_state()
		_expect_equal("%s restored state" % label, state.get("state", ""), "waiting_choice")
		if state.get("state", "") != "waiting_choice":
			var status_label: Label = ui.get_node("Panel/Margin/VBox/BottomBar/StatusLabel")
			_failures.append("%s restored status=%s node=%s" % [
				label,
				status_label.text,
				String(state.get("currentNodeId", ""))
			])
		if story_a == STORY_A:
			_expect_equal("%s restored node" % label, state.get("currentNodeId", ""), "N_Choice")
			_expect_equal("%s restored choices" % label, state.get("choices", []).size(), 1)

		var path_edit: LineEdit = ui.get_node("Panel/Margin/VBox/StoryBar/PathEdit")
		_expect_equal("%s restored path edit" % label, path_edit.text, story_a)

	ui.queue_free()
	var absolute_save_path := ProjectSettings.globalize_path(SAVE_PATH)
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(absolute_save_path)

func _record_state_if_failed(ui: Node, label: String, expected_state: String) -> void:
	var session: RefCounted = ui.get("_session")
	if session == null:
		_failures.append("%s: session missing" % label)
		return
	var state: Dictionary = session.get_state()
	if state.get("state", "") == expected_state:
		return
	var status_label: Label = ui.get_node("Panel/Margin/VBox/BottomBar/StatusLabel")
	_failures.append("%s expected=%s actual=%s status=%s node=%s" % [
		label,
		expected_state,
		String(state.get("state", "")),
		status_label.text,
		String(state.get("currentNodeId", ""))
	])

func _finish() -> void:
	if _failures.is_empty():
		print("[NarrRail][SaveLoadSmoke] PASS")
		quit(0)
	else:
		for failure in _failures:
			push_error("[NarrRail][SaveLoadSmoke] %s" % failure)
		quit(1)

func _expect_equal(label: String, actual, expected) -> void:
	if actual != expected:
		_failures.append("%s expected=%s actual=%s" % [label, str(expected), str(actual)])
