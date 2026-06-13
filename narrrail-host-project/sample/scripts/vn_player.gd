extends Control

const SESSION_SCRIPT := "res://addons/narrrail/runtime/narrrail_session.gd"
const STORY_RESOURCE_LOADER_SCRIPT := "res://addons/narrrail/runtime/story_resource_loader.gd"
const SAVE_PATH := "user://narrrail_demo_save.json"

@export_file("*.nrstory") var story_path: String = "res://sample/stories/demo.nrstory"
@export var auto_start_on_ready: bool = true
@export var typewriter_chars_per_second: float = 30.0
@export var debug_overlay_visible: bool = false

@onready var speaker_label: Label = $RootMargin/VBox/Header/MarginContainer/SpeakerLabel
@onready var body_label: Label = $RootMargin/VBox/BodyPanel/BodyMargin/BodyText
@onready var choices_box: VBoxContainer = $RootMargin/VBox/ChoicesPanel/ChoicesMargin/ChoicesBox
@onready var status_label: Label = $RootMargin/VBox/Footer/StatusLabel
@onready var reload_button: Button = $RootMargin/VBox/Footer/ReloadButton
@onready var save_button: Button = $RootMargin/VBox/Footer/SaveButton
@onready var load_save_button: Button = $RootMargin/VBox/Footer/LoadSaveButton
@onready var debug_toggle: CheckButton = $RootMargin/VBox/Footer/DebugToggle
@onready var debug_panel: PanelContainer = $RootMargin/VBox/DebugPanel
@onready var debug_label: Label = $RootMargin/VBox/DebugPanel/DebugMargin/DebugLabel
@onready var click_catcher: Button = $RootMargin/VBox/BodyPanel/ClickCatcher

var _session: RefCounted
var _waiting_choice: bool = false
var _typing_active: bool = false
var _typing_full_text: String = ""
var _typing_visible_count: int = 0

func _ready() -> void:
	reload_button.pressed.connect(_on_reload_pressed)
	save_button.pressed.connect(_on_save_pressed)
	load_save_button.pressed.connect(_on_load_save_pressed)
	debug_toggle.toggled.connect(_on_debug_toggled)
	click_catcher.pressed.connect(_on_advance_pressed)
	debug_toggle.button_pressed = debug_overlay_visible
	debug_panel.visible = debug_overlay_visible
	set_process(true)
	if auto_start_on_ready:
		start_story()

func start_story() -> void:
	_clear_ui()
	if not _create_session():
		return

	var story := _load_story(story_path)
	if story.is_empty():
		_set_status("Load failed")
		return

	_session.start(story)
	_set_status("Running: %s" % story_path)

func _create_session() -> bool:
	var session_script: Script = load(SESSION_SCRIPT)
	if session_script == null:
		_set_status("Session script missing")
		return false

	_session = session_script.new()
	_session.line_changed.connect(_on_line_changed)
	_session.choices_changed.connect(_on_choices_changed)
	_session.ended.connect(_on_ended)
	_session.error_raised.connect(_on_error)
	_session.variable_changed.connect(func(_payload: Dictionary) -> void:
		_update_debug_overlay()
	)
	_session.event_emitted.connect(func(_payload: Dictionary) -> void:
		_update_debug_overlay()
	)
	return true

func _load_story(path: String) -> Dictionary:
	if path.strip_edges().is_empty():
		_set_status("story_path is empty")
		return {}

	var loader_script: Script = load(STORY_RESOURCE_LOADER_SCRIPT)
	if loader_script == null:
		_set_status("Story resource loader missing")
		return {}

	var result: Dictionary = loader_script.call("load_story", path)
	if not result.get("ok", false):
		_set_status("Load failed: %s" % _format_diagnostics(result))
		return {}

	var diagnostics: Array = result.get("diagnostics", [])
	if diagnostics.is_empty():
		_set_status("Loaded: %s" % path)
	else:
		_set_status("Loaded with diagnostics")
	return result.get("story", {})

func _on_line_changed(payload: Dictionary) -> void:
	_waiting_choice = false
	_clear_choices()
	speaker_label.text = String(payload.get("speakerId", ""))
	if speaker_label.text.is_empty():
		speaker_label.text = "Narrator"
	_start_typewriter(String(payload.get("textKey", "")))
	click_catcher.disabled = false
	_update_debug_overlay()

func _on_choices_changed(choices: Array) -> void:
	_waiting_choice = true
	_clear_choices()
	click_catcher.disabled = true

	for i in range(choices.size()):
		var c: Dictionary = choices[i]
		var btn := Button.new()
		btn.text = String(c.get("textKey", "Choice %d" % i))
		btn.custom_minimum_size = Vector2(0, 40)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func() -> void:
			if _session != null:
				_session.choose(i)
		)
		choices_box.add_child(btn)
	_update_debug_overlay()

func _on_advance_pressed() -> void:
	if _session == null:
		return
	if _waiting_choice:
		return
	if _typing_active:
		_finish_typewriter_now()
		return
	_session.next()

func _on_ended() -> void:
	_waiting_choice = false
	click_catcher.disabled = true
	_set_status("Ended")
	_update_debug_overlay()

func _on_error(message: String) -> void:
	_waiting_choice = false
	click_catcher.disabled = true
	_set_status("Error: %s" % message)
	_update_debug_overlay()

func _on_reload_pressed() -> void:
	start_story()

func _on_save_pressed() -> void:
	if _session == null:
		_set_status("No session to save")
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		_set_status("Save failed: %s" % error_string(FileAccess.get_open_error()))
		return

	var payload := {
		"storyPath": story_path,
		"snapshot": _session.create_save_snapshot()
	}
	file.store_string(JSON.stringify(payload, "\t"))
	_set_status("Saved: %s" % SAVE_PATH)

func _on_load_save_pressed() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		_set_status("Load save failed: %s" % error_string(FileAccess.get_open_error()))
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_set_status("Load save failed: invalid JSON")
		return

	var payload: Dictionary = parsed
	var loaded_story_path := String(payload.get("storyPath", story_path))
	var snapshot = payload.get("snapshot", {})
	if typeof(snapshot) != TYPE_DICTIONARY:
		_set_status("Load save failed: missing snapshot")
		return

	_clear_ui()
	story_path = loaded_story_path
	if not _create_session():
		return

	var story := _load_story(story_path)
	if story.is_empty():
		_set_status("Load save failed: story load failed")
		return

	if _session.restore_save_snapshot(story, snapshot):
		_set_status("Loaded save: %s" % story_path)
		_update_debug_overlay()

func _on_debug_toggled(enabled: bool) -> void:
	debug_overlay_visible = enabled
	debug_panel.visible = enabled
	_update_debug_overlay()

func _clear_ui() -> void:
	speaker_label.text = "Speaker"
	body_label.text = "Click to start / continue"
	_clear_choices()
	_waiting_choice = false
	_typing_active = false
	_typing_full_text = ""
	_typing_visible_count = 0
	click_catcher.disabled = false
	_update_debug_overlay()

func _clear_choices() -> void:
	for child in choices_box.get_children():
		child.queue_free()

func _set_status(text: String) -> void:
	status_label.text = text

func _update_debug_overlay() -> void:
	if debug_panel == null or debug_label == null:
		return
	if not debug_panel.visible:
		return
	if _session == null:
		debug_label.text = "state: no session"
		return

	var state: Dictionary = _session.get_state()
	debug_label.text = "state: %s\nnode: %s\nline: %d\nchoices: %d\nvariables: %s\nevents: %d" % [
		String(state.get("state", "")),
		String(state.get("currentNodeId", "")),
		int(state.get("currentLineIndex", -1)),
		(state.get("choices", []) as Array).size(),
		str(state.get("variables", {})),
		(state.get("events", []) as Array).size()
	]

func _process(delta: float) -> void:
	if not _typing_active:
		return
	if typewriter_chars_per_second <= 0.0:
		_finish_typewriter_now()
		return

	var add_count := int(ceil(typewriter_chars_per_second * delta))
	if add_count < 1:
		add_count = 1
	_typing_visible_count = min(_typing_visible_count + add_count, _typing_full_text.length())
	body_label.text = _typing_full_text.substr(0, _typing_visible_count)
	if _typing_visible_count >= _typing_full_text.length():
		_typing_active = false

func _start_typewriter(text: String) -> void:
	_typing_full_text = text
	_typing_visible_count = 0
	_typing_active = not text.is_empty()
	if _typing_active:
		body_label.text = ""
	else:
		body_label.text = text

func _finish_typewriter_now() -> void:
	_typing_active = false
	_typing_visible_count = _typing_full_text.length()
	body_label.text = _typing_full_text

func _format_diagnostics(result: Dictionary) -> String:
	var diagnostics: Array = result.get("diagnostics", [])
	if diagnostics.is_empty():
		return String(result.get("error", "unknown"))

	var parts: Array[String] = []
	for d in diagnostics:
		var code := String((d as Dictionary).get("code", ""))
		var path := String((d as Dictionary).get("path", ""))
		var msg := String((d as Dictionary).get("message", ""))
		parts.append("[%s] %s: %s" % [code, path, msg])
	return " | ".join(parts)
