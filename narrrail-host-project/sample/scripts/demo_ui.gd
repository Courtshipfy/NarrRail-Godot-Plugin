extends Control

const SESSION_SCRIPT := "res://addons/narrrail/runtime/narrrail_session.gd"
const OUTLINE_RUNNER_SCRIPT := "res://addons/narrrail/runtime/narrrail_outline_runner.gd"
const STORY_RESOURCE_LOADER_SCRIPT := "res://addons/narrrail/runtime/story_resource_loader.gd"
const OUTLINE_RESOURCE_LOADER_SCRIPT := "res://addons/narrrail/runtime/outline_resource_loader.gd"
const STORY_DIR := "res://sample/stories"
const SYNCED_STORY_ROOT := "res://narrrail_stories"
const DEFAULT_STORY_PATH := "res://sample/stories/demo.nrstory"
const SAVE_PATH := "user://narrrail_demo_save.json"

@onready var story_option: OptionButton = $Panel/Margin/VBox/StoryBar/StoryOption
@onready var path_edit: LineEdit = $Panel/Margin/VBox/StoryBar/PathEdit
@onready var load_button: Button = $Panel/Margin/VBox/StoryBar/LoadButton
@onready var refresh_button: Button = $Panel/Margin/VBox/StoryBar/RefreshButton
@onready var save_button: Button = $Panel/Margin/VBox/BottomBar/SaveButton
@onready var load_save_button: Button = $Panel/Margin/VBox/BottomBar/LoadSaveButton
@onready var speaker_label: Label = $Panel/Margin/VBox/SpeakerLabel
@onready var text_label: Label = $Panel/Margin/VBox/TextLabel
@onready var choices_box: VBoxContainer = $Panel/Margin/VBox/ChoicesBox
@onready var next_button: Button = $Panel/Margin/VBox/BottomBar/NextButton
@onready var status_label: Label = $Panel/Margin/VBox/BottomBar/StatusLabel

var _session: RefCounted
var _story_paths: Array[String] = []
var _story_labels: Dictionary = {}
var _choice_timer_label: Label
var _current_mode := "story"

func _ready() -> void:
	next_button.pressed.connect(_on_next_pressed)
	load_button.pressed.connect(_on_load_pressed)
	refresh_button.pressed.connect(_on_refresh_pressed)
	save_button.pressed.connect(_on_save_pressed)
	load_save_button.pressed.connect(_on_load_save_pressed)
	story_option.item_selected.connect(_on_story_selected)
	path_edit.text_submitted.connect(func(_text: String) -> void:
		_on_load_pressed()
	)

	_refresh_story_list()
	set_process(true)
	_load_path(_selected_or_default_path())

func _create_session() -> bool:
	var session_script: Script = load(SESSION_SCRIPT)
	if session_script == null:
		_push_status("Failed to load session script")
		return false

	_session = session_script.new()
	_session.line_changed.connect(_on_line_changed)
	_session.choices_changed.connect(_on_choices_changed)
	_session.choice_timer_changed.connect(_on_choice_timer_changed)
	_session.choice_timed_out.connect(_on_choice_timed_out)
	_session.ended.connect(_on_ended)
	_session.error_raised.connect(_on_error)
	return true

func _create_outline_runner() -> bool:
	var runner_script: Script = load(OUTLINE_RUNNER_SCRIPT)
	if runner_script == null:
		_push_status("Failed to load outline runner script")
		return false

	_session = runner_script.new()
	_session.outline_node_entered.connect(_on_outline_node_entered)
	_session.outline_branch_matched.connect(_on_outline_branch_matched)
	_session.line_changed.connect(_on_line_changed)
	_session.choices_changed.connect(_on_choices_changed)
	_session.choice_timer_changed.connect(_on_choice_timer_changed)
	_session.choice_timed_out.connect(_on_choice_timed_out)
	_session.ended.connect(_on_ended)
	_session.error_raised.connect(_on_error)
	return true

func _load_path(path: String) -> void:
	if _is_outline_path(path):
		_load_outline_path(path)
	else:
		_load_story_path(path)

func _load_story_path(path: String) -> void:
	_clear_story_view()
	_current_mode = "story"
	if path.strip_edges().is_empty():
		_push_status("Empty story path")
		return

	path_edit.text = path
	if not _create_session():
		return

	var story := _load_story_from_path_or_fallback(path)
	_session.start(story)
	if _session.get_state().get("state", "") != "ended":
		_push_status("Running: %s" % path)

func _load_outline_path(path: String) -> void:
	_clear_story_view()
	_current_mode = "outline"
	if path.strip_edges().is_empty():
		_push_status("Empty outline path")
		return

	path_edit.text = path
	if not _create_outline_runner():
		return

	var outline := _load_outline_strict(path)
	if outline.is_empty():
		return

	var story_library := _build_story_library()
	_session.start(outline, story_library)
	if _session.get_state().get("state", "") != "ended":
		_push_status("Running outline: %s" % path)

func _load_story_from_path_or_fallback(path: String) -> Dictionary:
	var result := _load_story_result(path)
	if not result.get("ok", false):
		_push_status("Load failed, fallback: %s" % _format_diagnostics(result))
		return _build_demo_story()

	var diagnostics: Array = result.get("diagnostics", [])
	if not diagnostics.is_empty():
		_push_status("Loaded with diagnostics: %s" % _format_diagnostics(result))
	else:
		_push_status("Loaded: %s" % path)

	return result.get("story", {})

func _load_story_strict(path: String) -> Dictionary:
	var result := _load_story_result(path)
	if not result.get("ok", false):
		_push_status("Load failed: %s" % _format_diagnostics(result))
		return {}

	var diagnostics: Array = result.get("diagnostics", [])
	if not diagnostics.is_empty():
		_push_status("Loaded with diagnostics: %s" % _format_diagnostics(result))
	else:
		_push_status("Loaded: %s" % path)
	return result.get("story", {})

func _load_story_result(path: String) -> Dictionary:
	var loader_script: Script = load(STORY_RESOURCE_LOADER_SCRIPT)
	if loader_script == null:
		return {"ok": false, "story": {}, "error": "Story resource loader missing", "diagnostics": []}

	var result: Dictionary = loader_script.call("load_story", path)
	return result

func _load_outline_strict(path: String) -> Dictionary:
	var loader_script: Script = load(OUTLINE_RESOURCE_LOADER_SCRIPT)
	if loader_script == null:
		_push_status("Outline resource loader missing")
		return {}

	var result: Dictionary = loader_script.call("load_outline", path)
	if not result.get("ok", false):
		_push_status("Outline load failed: %s" % _format_diagnostics(result))
		return {}

	var diagnostics: Array = result.get("diagnostics", [])
	if not diagnostics.is_empty():
		_push_status("Outline loaded with diagnostics: %s" % _format_diagnostics(result))
	else:
		_push_status("Outline loaded: %s" % path)
	return result.get("outline", {})

func _refresh_story_list() -> void:
	_story_paths.clear()
	_story_labels.clear()
	story_option.clear()

	_collect_local_story_files()
	_collect_synced_story_resources(SYNCED_STORY_ROOT)

	_story_paths.sort()
	if _story_paths.is_empty():
		_story_paths.append(DEFAULT_STORY_PATH)
		_story_labels[DEFAULT_STORY_PATH] = "Local: %s" % DEFAULT_STORY_PATH.get_file()

	for path in _story_paths:
		story_option.add_item(String(_story_labels.get(path, path.get_file())))
		story_option.set_item_metadata(story_option.item_count - 1, path)

	var selected_index := _story_paths.find(path_edit.text)
	if selected_index < 0:
		selected_index = max(_story_paths.find(DEFAULT_STORY_PATH), 0)
	story_option.select(selected_index)
	path_edit.text = _story_paths[selected_index]

func _collect_local_story_files() -> void:
	var dir := DirAccess.open(STORY_DIR)
	if dir == null:
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and (file_name.ends_with(".nrstory") or file_name.ends_with(".nroutline") or file_name.ends_with(".nrrail")):
			var path := "%s/%s" % [STORY_DIR, file_name]
			_story_paths.append(path)
			_story_labels[path] = "Local Outline: %s" % file_name if _is_outline_path(path) else "Local: %s" % file_name
		file_name = dir.get_next()
	dir.list_dir_end()

func _collect_synced_story_resources(root: String) -> void:
	var dir := DirAccess.open(root)
	if dir == null:
		return

	dir.list_dir_begin()
	var name := dir.get_next()
	while not name.is_empty():
		var path := "%s/%s" % [root, name]
		if dir.current_is_dir():
			if not name.begins_with("."):
				_collect_synced_story_resources(path)
		elif name.ends_with(".tres") or name.ends_with(".res"):
			if _is_story_resource(path):
				_story_paths.append(path)
				_story_labels[path] = _synced_story_label(path)
			elif _is_outline_resource(path):
				_story_paths.append(path)
				_story_labels[path] = _synced_outline_label(path)
		name = dir.get_next()
	dir.list_dir_end()

func _is_story_resource(path: String) -> bool:
	var resource := ResourceLoader.load(path)
	if resource == null:
		return false
	if not _has_property(resource, "story_data"):
		return false
	var story_data = resource.get("story_data")
	return typeof(story_data) == TYPE_DICTIONARY and not (story_data as Dictionary).is_empty()

func _is_outline_resource(path: String) -> bool:
	var resource := ResourceLoader.load(path)
	if resource == null:
		return false
	if not _has_property(resource, "outline_data"):
		return false
	var outline_data = resource.get("outline_data")
	return typeof(outline_data) == TYPE_DICTIONARY and not (outline_data as Dictionary).is_empty()

func _has_property(resource: Resource, property_name: String) -> bool:
	for property in resource.get_property_list():
		if String((property as Dictionary).get("name", "")) == property_name:
			return true
	return false

func _synced_story_label(path: String) -> String:
	var relative := path.trim_prefix(SYNCED_STORY_ROOT + "/")
	return "Synced: %s" % relative.trim_suffix(".tres").trim_suffix(".res")

func _synced_outline_label(path: String) -> String:
	var relative := path.trim_prefix(SYNCED_STORY_ROOT + "/")
	return "Synced Outline: %s" % relative.trim_suffix(".tres").trim_suffix(".res")

func _is_outline_path(path: String) -> bool:
	if path.ends_with(".nroutline") or path.ends_with(".nrrail"):
		return true
	if path.ends_with("_outline.tres") or path.ends_with("_outline.res"):
		return true
	if ResourceLoader.exists(path):
		return _is_outline_resource(path)
	return false

func _selected_or_default_path() -> String:
	if story_option.selected >= 0:
		return String(story_option.get_item_metadata(story_option.selected))
	if not path_edit.text.strip_edges().is_empty():
		return path_edit.text.strip_edges()
	return DEFAULT_STORY_PATH

func _build_demo_story() -> Dictionary:
	return {
		"meta": {
			"schemaVersion": 1,
			"storyId": "demo_ui",
			"entryNodeId": "N_Start"
		},
		"variables": [],
		"nodes": [
			{
				"nodeId": "N_Start",
				"nodeType": "Dialogue",
				"dialogue": {"speakerId": "Hero", "textKey": "你好，今天一起去散步吗？"}
			},
			{
				"nodeId": "N_Choice",
				"nodeType": "Choice",
				"choices": [
					{"textKey": "好啊，一起去！", "targetNodeId": "N_Yes"},
					{"textKey": "今天先不了。", "targetNodeId": "N_No"}
				]
			},
			{
				"nodeId": "N_Yes",
				"nodeType": "Dialogue",
				"dialogue": {"speakerId": "Hero", "textKey": "太好了，那我们出发吧！"}
			},
			{
				"nodeId": "N_No",
				"nodeType": "Dialogue",
				"dialogue": {"speakerId": "Hero", "textKey": "没关系，下次再约。"}
			},
			{
				"nodeId": "N_End",
				"nodeType": "End"
			}
		],
		"edges": [
			{"sourceNodeId": "N_Start", "targetNodeId": "N_Choice", "priority": 0, "condition": {"logic": "All", "terms": []}},
			{"sourceNodeId": "N_Yes", "targetNodeId": "N_End", "priority": 0, "condition": {"logic": "All", "terms": []}},
			{"sourceNodeId": "N_No", "targetNodeId": "N_End", "priority": 0, "condition": {"logic": "All", "terms": []}}
		]
	}

func _on_line_changed(payload: Dictionary) -> void:
	var prefix := "Speaker"
	if payload.has("storyId"):
		prefix = "Story %s" % String(payload.get("storyId", ""))
	speaker_label.text = "%s: %s" % [prefix, String(payload.get("speakerId", ""))]
	text_label.text = String(payload.get("textKey", ""))
	_clear_choices()
	next_button.disabled = false

func _on_choices_changed(choices: Array) -> void:
	_clear_choices()
	next_button.disabled = true
	_ensure_choice_timer_label()
	if _session != null:
		var state: Dictionary = _session.get_state()
		_on_choice_timer_changed(state.get("choiceTimer", {}))
	for i in range(choices.size()):
		var c: Dictionary = choices[i]
		var btn := Button.new()
		btn.text = String(c.get("textKey", "Choice %d" % i))
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func() -> void:
			if _session != null:
				_session.choose(i)
		)
		choices_box.add_child(btn)

func _on_outline_node_entered(payload: Dictionary) -> void:
	var node_type := String(payload.get("nodeType", ""))
	var title := String(payload.get("title", ""))
	var node_id := String(payload.get("nodeId", ""))
	_push_status("Outline %s: %s" % [node_type, title if not title.is_empty() else node_id])

func _on_outline_branch_matched(payload: Dictionary) -> void:
	_push_status("Outline Branch: %s -> %s" % [
		String(payload.get("sourceHandle", "")),
		String(payload.get("targetNodeId", ""))
	])

func _on_choice_timer_changed(payload: Dictionary) -> void:
	if not bool(payload.get("enabled", false)):
		if _choice_timer_label != null and is_instance_valid(_choice_timer_label):
			_choice_timer_label.visible = false
		return

	_ensure_choice_timer_label()
	_choice_timer_label.visible = true
	_choice_timer_label.text = "Timeout: %.1fs" % float(payload.get("remainingSeconds", 0.0))

func _on_choice_timed_out(payload: Dictionary) -> void:
	_push_status("Timed out: %s" % String(payload.get("timeoutChoiceTextKey", "Timeout")))

func _on_ended() -> void:
	_clear_choices()
	next_button.disabled = true
	_push_status("Ended")

func _on_error(message: String) -> void:
	_push_status("Error: %s" % message)
	next_button.disabled = true

func _on_next_pressed() -> void:
	if _session != null:
		_session.next()

func _on_save_pressed() -> void:
	if _session == null:
		_push_status("No session to save")
		return
	if _current_mode != "story":
		_push_status("Save is only available for single story sessions in this demo UI")
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		_push_status("Save failed: %s" % error_string(FileAccess.get_open_error()))
		return

	var payload := {
		"storyPath": path_edit.text.strip_edges(),
		"snapshot": _session.create_save_snapshot()
	}
	file.store_string(JSON.stringify(payload, "\t"))
	_push_status("Saved: %s" % SAVE_PATH)

func _on_load_save_pressed() -> void:
	if _current_mode != "story":
		_push_status("Load Save is only available for single story sessions in this demo UI")
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		_push_status("Load save failed: %s" % error_string(FileAccess.get_open_error()))
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_push_status("Load save failed: invalid JSON")
		return

	var payload: Dictionary = parsed
	var save_path := String(payload.get("storyPath", DEFAULT_STORY_PATH))
	var snapshot = payload.get("snapshot", {})
	if typeof(snapshot) != TYPE_DICTIONARY:
		_push_status("Load save failed: missing snapshot")
		return

	_clear_story_view()
	path_edit.text = save_path
	_select_story_path_if_available(save_path)
	if not _create_session():
		return

	var story := _load_story_strict(save_path)
	if story.is_empty():
		return
	if _session.restore_save_snapshot(story, snapshot):
		_push_status("Loaded save: %s" % save_path)

func _on_load_pressed() -> void:
	_load_path(path_edit.text.strip_edges())

func _on_refresh_pressed() -> void:
	var current_path := path_edit.text.strip_edges()
	_refresh_story_list()
	if not current_path.is_empty():
		path_edit.text = current_path
	_load_path(path_edit.text.strip_edges())

func _on_story_selected(index: int) -> void:
	var path := String(story_option.get_item_metadata(index))
	path_edit.text = path
	_load_path(path)

func _select_story_path_if_available(path: String) -> void:
	for i in range(story_option.item_count):
		if String(story_option.get_item_metadata(i)) == path:
			story_option.select(i)
			return

func _clear_choices() -> void:
	for child in choices_box.get_children():
		child.queue_free()
	_choice_timer_label = null

func _ensure_choice_timer_label() -> void:
	if _choice_timer_label != null and is_instance_valid(_choice_timer_label):
		return
	_choice_timer_label = Label.new()
	_choice_timer_label.visible = false
	_choice_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_choice_timer_label.add_theme_font_size_override("font_size", 14)
	choices_box.add_child(_choice_timer_label)

func _clear_story_view() -> void:
	_clear_choices()
	speaker_label.text = "Speaker: "
	text_label.text = ""
	next_button.disabled = true

func _process(delta: float) -> void:
	if _session != null:
		_session.advance_time(delta)

func _build_story_library() -> Dictionary:
	var library: Dictionary = {}
	_collect_story_library_from_local_dir(library)
	_collect_story_library_from_synced_resources(SYNCED_STORY_ROOT, library)
	return library

func _collect_story_library_from_local_dir(library: Dictionary) -> void:
	var dir := DirAccess.open(STORY_DIR)
	if dir == null:
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.ends_with(".nrstory"):
			var path := "%s/%s" % [STORY_DIR, file_name]
			_add_story_to_library(path, library)
		file_name = dir.get_next()
	dir.list_dir_end()

func _collect_story_library_from_synced_resources(root: String, library: Dictionary) -> void:
	var dir := DirAccess.open(root)
	if dir == null:
		return

	dir.list_dir_begin()
	var name := dir.get_next()
	while not name.is_empty():
		var path := "%s/%s" % [root, name]
		if dir.current_is_dir():
			if not name.begins_with("."):
				_collect_story_library_from_synced_resources(path, library)
		elif (name.ends_with(".tres") or name.ends_with(".res")) and _is_story_resource(path):
			_add_story_to_library(path, library)
		name = dir.get_next()
	dir.list_dir_end()

func _add_story_to_library(path: String, library: Dictionary) -> void:
	var result := _load_story_result(path)
	if not result.get("ok", false):
		return
	var story: Dictionary = result.get("story", {})
	var story_id := String(story.get("meta", {}).get("storyId", ""))
	if story_id.is_empty():
		return
	library[story_id] = path

func _format_diagnostics(result: Dictionary) -> String:
	var diagnostics: Array = result.get("diagnostics", [])
	if diagnostics.is_empty():
		return String(result.get("error", "unknown"))

	var parts: Array[String] = []
	for d in diagnostics:
		var sev := String(d.get("severity", ""))
		var code := String(d.get("code", ""))
		var path := String(d.get("path", ""))
		var msg := String(d.get("message", ""))
		parts.append("[%s][%s] %s: %s" % [sev, code, path, msg])
	return " | ".join(parts)

func _push_status(text: String) -> void:
	status_label.text = text
