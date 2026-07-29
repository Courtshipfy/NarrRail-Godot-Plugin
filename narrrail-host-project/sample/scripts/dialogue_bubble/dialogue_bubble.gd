class_name DialogueBubble
extends Control

signal layout_changed

const TAIL_LEFT := preload("res://sample/assets/dialogue_bubble/bubble_tail_left.svg")
const TAIL_RIGHT := preload("res://sample/assets/dialogue_bubble/bubble_tail_right.svg")

@export var min_text_width := 112.0
@export var max_text_width := 430.0
@export var horizontal_padding := 62.0
@export var top_padding := 54.0
@export var bottom_padding := 30.0
@export var resize_duration := 0.42

@onready var shadow: NinePatchRect = $Shadow
@onready var tail: TextureRect = $Tail
@onready var body: NinePatchRect = $Body
@onready var speaker_label: Label = $SpeakerName
@onready var text_label: Label = $LineText

var _side: StringName = &"left"
var _tail_tip := Vector2.ZERO
var _appearance_tween: Tween
var _resize_tween: Tween
var _target_body_size := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2.ZERO
	visible = false

func present(speaker_name: String, content: String, side: StringName) -> void:
	_side = side
	speaker_label.text = speaker_name
	text_label.text = content

	var font := text_label.get_theme_font("font")
	var font_size := text_label.get_theme_font_size("font_size")
	var unwrapped := font.get_string_size(content, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var text_width := clampf(ceilf(unwrapped.x), min_text_width, max_text_width)
	var wrapped := font.get_multiline_string_size(
		content,
		HORIZONTAL_ALIGNMENT_LEFT,
		text_width,
		font_size
	)
	var font_height := float(font.get_height(font_size))
	var line_count := maxi(1, int(ceilf(wrapped.y / maxf(font_height, 1.0))))
	var line_spacing := text_label.get_theme_constant("line_spacing")
	var text_height := maxf(
		ceilf(wrapped.y) + float(maxi(0, line_count - 1) * line_spacing) + 4.0,
		font_height
	)
	var body_width := ceilf(text_width + horizontal_padding)
	var body_height := ceilf(maxf(104.0, text_height + top_padding + bottom_padding))
	_target_body_size = Vector2(body_width, body_height)

	speaker_label.position = Vector2(31.0, 18.0)
	text_label.position = Vector2(31.0, top_padding)
	text_label.size = Vector2(text_width, text_height)

	if not visible:
		_apply_body_size(_target_body_size)
		custom_minimum_size = size
		text_label.modulate.a = 1.0
		visible = true
		_play_appearance()
	else:
		_play_resize(_target_body_size)

func get_tail_tip_local_position() -> Vector2:
	return _tail_tip

func get_body_size() -> Vector2:
	return body.size

func get_target_body_size() -> Vector2:
	return _target_body_size

func _apply_body_size(next_body_size: Vector2) -> void:
	var body_width := next_body_size.x
	var body_height := next_body_size.y
	body.position = Vector2.ZERO
	body.size = next_body_size
	shadow.position = Vector2(6.0, 8.0)
	shadow.size = next_body_size
	speaker_label.size = Vector2(maxf(1.0, body_width - 62.0), 26.0)
	_layout_tail(body_width, body_height)
	size = Vector2(body_width, body_height + tail.size.y - 7.0)
	pivot_offset = Vector2(body_width * 0.5, body_height * 0.5)
	layout_changed.emit()

func _layout_tail(body_width: float, body_height: float) -> void:
	tail.size = Vector2(64.0, 52.0)
	tail.position.y = body_height - 8.0
	if _side == &"right":
		tail.texture = TAIL_RIGHT
		var desired_tip_x := body_width * 0.78
		tail.position.x = clampf(desired_tip_x - 54.0, 18.0, body_width - tail.size.x - 18.0)
		_tail_tip = tail.position + Vector2(54.0, 48.0)
	else:
		tail.texture = TAIL_LEFT
		var desired_tip_x := body_width * 0.22
		tail.position.x = clampf(desired_tip_x - 10.0, 18.0, body_width - tail.size.x - 18.0)
		_tail_tip = tail.position + Vector2(10.0, 48.0)

func _play_appearance() -> void:
	if _appearance_tween != null and _appearance_tween.is_valid():
		_appearance_tween.kill()
	scale = Vector2(0.94, 0.94)
	modulate.a = 0.0
	_appearance_tween = create_tween().set_parallel(true)
	_appearance_tween.tween_property(self, "scale", Vector2.ONE, 0.18)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_appearance_tween.tween_property(self, "modulate:a", 1.0, 0.11)

func _play_resize(target_body_size: Vector2) -> void:
	if _resize_tween != null and _resize_tween.is_valid():
		_resize_tween.kill()
	if _appearance_tween != null and _appearance_tween.is_valid():
		_appearance_tween.kill()
	scale = Vector2.ONE
	modulate.a = 1.0
	custom_minimum_size = Vector2.ZERO
	text_label.modulate.a = 0.0

	var start_body_size := body.size
	_resize_tween = create_tween().set_parallel(true)
	_resize_tween.tween_method(
		_apply_body_size,
		start_body_size,
		target_body_size,
		resize_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_resize_tween.tween_property(text_label, "modulate:a", 1.0, resize_duration * 0.38)\
		.set_delay(resize_duration * 0.55)
	_resize_tween.finished.connect(_finish_resize)

func _finish_resize() -> void:
	_apply_body_size(_target_body_size)
	custom_minimum_size = size
	text_label.modulate.a = 1.0
