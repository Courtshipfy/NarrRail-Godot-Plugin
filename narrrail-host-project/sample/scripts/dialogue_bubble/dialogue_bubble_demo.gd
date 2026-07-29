extends Control

const SESSION_SCRIPT := "res://addons/narrrail/runtime/narrrail_session.gd"
const STORY_LOADER_SCRIPT := "res://addons/narrrail/runtime/story_resource_loader.gd"
const STORY_PATH := "res://sample/stories/dialogue_bubble_demo.nrstory"

const SPEAKER_NAMES := {
	"Elin": "艾琳",
	"Tomas": "托马斯"
}

@onready var bubble_layer: Control = $BubbleLayer
@onready var bubble: DialogueBubble = $BubbleLayer/DialogueBubble
@onready var left_anchor: Control = $BubbleLayer/LeftSpeechAnchor
@onready var right_anchor: Control = $BubbleLayer/RightSpeechAnchor
@onready var left_portrait: TextureRect = $Characters/Elin
@onready var right_portrait: TextureRect = $Characters/Tomas
@onready var next_button: Button = $Chrome/NextButton
@onready var status_label: Label = $Chrome/StatusLabel
@onready var metrics_label: Label = $Chrome/MetricsLabel

var _session: RefCounted
var _current_side: StringName = &"left"
var _ended := false
var _portrait_tween: Tween

func _ready() -> void:
	next_button.pressed.connect(_on_next_pressed)
	resized.connect(_on_resized)
	bubble.layout_changed.connect(_on_bubble_layout_changed)
	_start_story()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_on_next_pressed()

func _start_story() -> void:
	_ended = false
	next_button.text = "下一句   Space"
	status_label.text = "NarrRail 对话气泡演示"

	var session_script: Script = load(SESSION_SCRIPT)
	var loader_script: Script = load(STORY_LOADER_SCRIPT)
	if session_script == null or loader_script == null:
		_show_error("NarrRail runtime 或 story loader 缺失")
		return

	var result: Dictionary = loader_script.call("load_story", STORY_PATH)
	if not result.get("ok", false):
		_show_error("故事加载失败：%s" % String(result.get("error", "unknown")))
		return

	_session = session_script.new()
	_session.line_changed.connect(_on_line_changed)
	_session.choices_changed.connect(_on_choices_changed)
	_session.ended.connect(_on_ended)
	_session.error_raised.connect(_show_error)
	_session.start(result.get("story", {}))

func _on_line_changed(payload: Dictionary) -> void:
	var speaker_id := String(payload.get("speakerId", ""))
	_current_side = &"right" if speaker_id == "Tomas" else &"left"
	var speaker_name := String(SPEAKER_NAMES.get(speaker_id, speaker_id))
	bubble.present(speaker_name, String(payload.get("textKey", "")), _current_side)
	_set_active_speaker(_current_side)
	next_button.disabled = false
	status_label.text = "%s 正在说话" % speaker_name

func _on_choices_changed(_choices: Array) -> void:
	next_button.disabled = true
	status_label.text = "这个演示故事没有选择分支"

func _on_ended() -> void:
	_ended = true
	next_button.disabled = false
	next_button.text = "重新播放"
	status_label.text = "演示结束"
	metrics_label.text = "按 Enter / Space 或点击按钮重新播放"

func _on_next_pressed() -> void:
	if _ended:
		_start_story()
	elif _session != null:
		_session.next()

func _position_bubble() -> void:
	var anchor := right_anchor.position if _current_side == &"right" else left_anchor.position
	var target := anchor - bubble.get_tail_tip_local_position()
	var margin := 24.0
	target.x = clampf(target.x, margin, maxf(margin, bubble_layer.size.x - bubble.size.x - margin))
	target.y = clampf(target.y, 64.0, maxf(64.0, bubble_layer.size.y - bubble.size.y - 92.0))
	bubble.position = target

func _set_active_speaker(side: StringName) -> void:
	if _portrait_tween != null and _portrait_tween.is_valid():
		_portrait_tween.kill()
	var left_target := Color.WHITE if side == &"left" else Color(0.5, 0.5, 0.5, 0.82)
	var right_target := Color.WHITE if side == &"right" else Color(0.5, 0.5, 0.5, 0.82)
	_portrait_tween = create_tween().set_parallel(true)
	_portrait_tween.tween_property(left_portrait, "modulate", left_target, 0.16)
	_portrait_tween.tween_property(right_portrait, "modulate", right_target, 0.16)

func _on_resized() -> void:
	if bubble.visible:
		call_deferred("_position_bubble")

func _on_bubble_layout_changed() -> void:
	_position_bubble()
	var body_size := bubble.get_body_size()
	var target_size := bubble.get_target_body_size()
	metrics_label.text = "气泡主体  %d × %d px  →  %d × %d px\n宽高正在随文本平滑过渡" % [
		int(body_size.x),
		int(body_size.y),
		int(target_size.x),
		int(target_size.y)
	]

func _show_error(message: String) -> void:
	status_label.text = message
	metrics_label.text = "请检查 Output 中的导入或解析错误"
	next_button.disabled = true
	push_error(message)
