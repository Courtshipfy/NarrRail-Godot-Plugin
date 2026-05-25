extends Control

const SESSION_SCRIPT := "res://addons/narrrail/runtime/narrrail_session.gd"
const LOADER_SCRIPT := "res://addons/narrrail/importer/nrstory_loader.gd"
const STORY_PATH := "res://sample/stories/demo.nrstory"

@onready var speaker_label: Label = $Panel/Margin/VBox/SpeakerLabel
@onready var text_label: Label = $Panel/Margin/VBox/TextLabel
@onready var choices_box: VBoxContainer = $Panel/Margin/VBox/ChoicesBox
@onready var next_button: Button = $Panel/Margin/VBox/BottomBar/NextButton
@onready var status_label: Label = $Panel/Margin/VBox/BottomBar/StatusLabel

var _session: RefCounted

func _ready() -> void:
	next_button.pressed.connect(_on_next_pressed)
	_init_session()

func _init_session() -> void:
	var session_script: Script = load(SESSION_SCRIPT)
	if session_script == null:
		_push_status("Failed to load session script")
		return

	_session = session_script.new()
	_session.line_changed.connect(_on_line_changed)
	_session.choices_changed.connect(_on_choices_changed)
	_session.ended.connect(_on_ended)
	_session.error_raised.connect(_on_error)

	var story := _load_story_from_file_or_fallback()
	_session.start(story)
	_push_status("Running")

func _load_story_from_file_or_fallback() -> Dictionary:
	var loader_script: Script = load(LOADER_SCRIPT)
	if loader_script == null:
		_push_status("Loader missing, fallback to built-in story")
		return _build_demo_story()

	var result: Dictionary = loader_script.call("load_story", STORY_PATH)
	if not result.get("ok", false):
		_push_status("Load failed, fallback: %s" % String(result.get("error", "unknown")))
		return _build_demo_story()

	_push_status("Loaded from file: %s" % STORY_PATH)
	return result.get("story", {})

func _build_demo_story() -> Dictionary:
	return {
		"meta": {
			"schemaVersion": 1,
			"storyId": "demo_ui",
			"entryNodeId": "N_Start"
		},
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
	speaker_label.text = "Speaker: %s" % String(payload.get("speakerId", ""))
	text_label.text = String(payload.get("textKey", ""))
	_clear_choices()
	next_button.disabled = false

func _on_choices_changed(choices: Array) -> void:
	_clear_choices()
	next_button.disabled = true
	for i in range(choices.size()):
		var c: Dictionary = choices[i]
		var btn := Button.new()
		btn.text = String(c.get("textKey", "Choice %d" % i))
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func() -> void:
			_session.choose(i)
		)
		choices_box.add_child(btn)

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

func _clear_choices() -> void:
	for child in choices_box.get_children():
		child.queue_free()

func _push_status(text: String) -> void:
	status_label.text = text
