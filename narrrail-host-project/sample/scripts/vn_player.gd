extends Control

const SESSION_SCRIPT := "res://addons/narrrail/runtime/narrrail_session.gd"
const LOADER_SCRIPT := "res://addons/narrrail/importer/nrstory_loader.gd"

@export_file("*.nrstory") var story_path: String = "res://sample/stories/demo.nrstory"
@export var auto_start_on_ready: bool = true
@export var typewriter_chars_per_second: float = 30.0

@onready var speaker_label: Label = $RootMargin/VBox/Header/MarginContainer/SpeakerLabel
@onready var body_label: Label = $RootMargin/VBox/BodyPanel/BodyMargin/BodyText
@onready var choices_box: VBoxContainer = $RootMargin/VBox/ChoicesPanel/ChoicesMargin/ChoicesBox
@onready var status_label: Label = $RootMargin/VBox/Footer/StatusLabel
@onready var reload_button: Button = $RootMargin/VBox/Footer/ReloadButton
@onready var click_catcher: Button = $RootMargin/VBox/BodyPanel/ClickCatcher

var _session: RefCounted
var _waiting_choice: bool = false
var _typing_active: bool = false
var _typing_full_text: String = ""
var _typing_visible_count: int = 0

func _ready() -> void:
	reload_button.pressed.connect(_on_reload_pressed)
	click_catcher.pressed.connect(_on_advance_pressed)
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
	return true

func _load_story(path: String) -> Dictionary:
	if path.strip_edges().is_empty():
		_set_status("story_path is empty")
		return {}

	# Prefer imported resource pipeline
	var imported := load(path)
	if imported != null:
		var data = imported.get("story_data")
		if typeof(data) == TYPE_DICTIONARY and not (data as Dictionary).is_empty():
			_set_status("Loaded imported: %s" % path)
			return data

	# Fallback direct loader parse
	var loader_script: Script = load(LOADER_SCRIPT)
	if loader_script == null:
		_set_status("Loader script missing")
		return {}

	var result: Dictionary = loader_script.call("load_story", path)
	if not result.get("ok", false):
		_set_status("Load failed: %s" % _format_diagnostics(result))
		return {}

	var diagnostics: Array = result.get("diagnostics", [])
	if diagnostics.is_empty():
		_set_status("Loaded parsed: %s" % path)
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

func _on_error(message: String) -> void:
	_waiting_choice = false
	click_catcher.disabled = true
	_set_status("Error: %s" % message)

func _on_reload_pressed() -> void:
	start_story()

func _clear_ui() -> void:
	speaker_label.text = "Speaker"
	body_label.text = "Click to start / continue"
	_clear_choices()
	_waiting_choice = false
	_typing_active = false
	_typing_full_text = ""
	_typing_visible_count = 0
	click_catcher.disabled = false

func _clear_choices() -> void:
	for child in choices_box.get_children():
		child.queue_free()

func _set_status(text: String) -> void:
	status_label.text = text

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
