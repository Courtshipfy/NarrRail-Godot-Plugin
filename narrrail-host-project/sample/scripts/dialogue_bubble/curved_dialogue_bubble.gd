class_name CurvedDialogueBubble
extends Control

signal layout_changed

@export var min_text_width := 190.0
@export var max_text_width := 360.0
@export var resize_duration := 0.48
@export var top_padding := 82.0
@export var bottom_padding := 58.0

@onready var paper_grain: TextureRect = $PaperGrain
@onready var spine: TextureRect = $Spine
@onready var top_ribbon: TextureRect = $TopRibbon
@onready var bottom_ribbon: TextureRect = $BottomRibbon
@onready var speaker_label: Label = $SpeakerName
@onready var text_label: Label = $LineText

var _body_size := Vector2.ZERO
var _target_body_size := Vector2.ZERO
var _speaker_anchor := Vector2.ZERO
var _appearance_tween: Tween
var _resize_tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2.ZERO
	visible = false

func present(speaker_name: String, content: String, _side: StringName) -> void:
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
	var body_width := ceilf(text_width + 112.0)
	var content_height := text_height + top_padding + bottom_padding
	var body_height := ceilf(maxf(maxf(200.0, content_height), body_width / 1.48))
	_target_body_size = Vector2(body_width, body_height)

	text_label.position = Vector2(76.0, top_padding)
	text_label.size = Vector2(text_width, text_height)
	speaker_label.position = Vector2(74.0, 49.0)

	if not visible:
		_apply_body_size(_target_body_size)
		custom_minimum_size = size
		text_label.modulate.a = 1.0
		visible = true
		_play_appearance()
	else:
		_play_resize(_target_body_size)

func get_tail_tip_local_position() -> Vector2:
	return _speaker_anchor

func get_body_size() -> Vector2:
	return _body_size

func get_target_body_size() -> Vector2:
	return _target_body_size

func _draw() -> void:
	if _body_size.x <= 0.0 or _body_size.y <= 0.0:
		return

	var curves := _build_curves(_body_size)
	var top: PackedVector2Array = curves.top
	var bottom: PackedVector2Array = curves.bottom
	var polygon := _build_polygon(top, bottom)
	var shadow_polygon := PackedVector2Array()
	for point in polygon:
		shadow_polygon.append(point + Vector2(5.0, 6.0))

	draw_colored_polygon(shadow_polygon, Color(0.10, 0.075, 0.085, 0.18))
	draw_colored_polygon(polygon, Color("#eee5cf"))
	draw_polyline(top, Color("#30283b"), 4.5, true)
	draw_polyline(bottom, Color("#30283b"), 4.5, true)
	draw_line(top[0], bottom[0], Color("#30283b"), 4.5, true)
	draw_line(top[-1], bottom[-1], Color("#30283b"), 4.5, true)

	var inner_top := PackedVector2Array()
	var inner_bottom := PackedVector2Array()
	for point in top:
		inner_top.append(point + Vector2(0.0, 5.0))
	for point in bottom:
		inner_bottom.append(point - Vector2(0.0, 5.0))
	draw_polyline(inner_top, Color(0.53, 0.46, 0.65, 0.55), 2.0, true)
	draw_polyline(inner_bottom, Color(0.53, 0.46, 0.65, 0.55), 2.0, true)
	_draw_page_folds(top[0].y, bottom[0].y)

func _build_curves(next_body_size: Vector2) -> Dictionary:
	var top := PackedVector2Array()
	var bottom := PackedVector2Array()
	var start_x := 42.0
	var end_x := next_body_size.x - 8.0
	var curve_width := maxf(1.0, end_x - start_x)
	var steps := maxi(28, int(curve_width / 11.0))
	for i in range(steps + 1):
		var ratio := float(i) / float(steps)
		var x := lerpf(start_x, end_x, ratio)
		var top_y := _top_curve_y_at_ratio(next_body_size, ratio)
		var bottom_y := _bottom_curve_y_at_ratio(next_body_size, ratio)
		top.append(Vector2(x, top_y))
		bottom.append(Vector2(x, bottom_y))
	return {"top": top, "bottom": bottom}

func _build_polygon(top: PackedVector2Array, bottom: PackedVector2Array) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	polygon.append_array(top)
	for i in range(bottom.size() - 1, -1, -1):
		polygon.append(bottom[i])
	return polygon

func _draw_page_folds(top_y: float, bottom_y: float) -> void:
	for fold_index in range(4):
		var fold := PackedVector2Array()
		var base_x := 49.0 + float(fold_index) * 5.5
		for i in range(17):
			var ratio := float(i) / 16.0
			var y := lerpf(top_y + 5.0, bottom_y - 5.0, ratio)
			var x := base_x + sin(ratio * PI) * (2.5 + float(fold_index) * 0.35)
			fold.append(Vector2(x, y))
		draw_polyline(fold, Color(0.55, 0.47, 0.35, 0.18), 1.2, true)

func _apply_body_size(next_body_size: Vector2) -> void:
	_body_size = next_body_size
	size = Vector2(next_body_size.x, next_body_size.y + 34.0)
	pivot_offset = Vector2(next_body_size.x * 0.5, next_body_size.y * 0.5)
	speaker_label.size = Vector2(maxf(1.0, next_body_size.x - 112.0), 25.0)
	_layout_art(next_body_size)
	queue_redraw()
	layout_changed.emit()

func _layout_art(next_body_size: Vector2) -> void:
	var curves := _build_curves(next_body_size)
	var top: PackedVector2Array = curves.top
	var bottom: PackedVector2Array = curves.bottom
	spine.position = Vector2(7.0, top[0].y - 6.0)
	spine.size = Vector2(52.0, bottom[0].y - top[0].y + 12.0)

	var top_ribbon_x := maxf(76.0, next_body_size.x - 126.0)
	var top_connection_y := _top_curve_y_at_x(next_body_size, top_ribbon_x + 54.0)
	top_ribbon.position = Vector2(top_ribbon_x, top_connection_y - 36.0)
	top_ribbon.size = Vector2(126.0, 54.0)

	var bottom_ribbon_x := 12.0
	var bottom_connection_y := _bottom_curve_y_at_x(next_body_size, bottom_ribbon_x + 58.0)
	bottom_ribbon.position = Vector2(bottom_ribbon_x, bottom_connection_y - 14.0)
	bottom_ribbon.size = Vector2(126.0, 58.0)

	paper_grain.position = Vector2(68.0, 65.0)
	paper_grain.size = Vector2(
		maxf(1.0, next_body_size.x - 96.0),
		maxf(1.0, next_body_size.y - 124.0)
	)

	_speaker_anchor = Vector2(next_body_size.x * 0.78, next_body_size.y + 28.0)

func _top_curve_y_at_x(next_body_size: Vector2, x: float) -> float:
	var start_x := 42.0
	var end_x := next_body_size.x - 8.0
	var ratio := clampf((x - start_x) / maxf(1.0, end_x - start_x), 0.0, 1.0)
	return _top_curve_y_at_ratio(next_body_size, ratio)

func _bottom_curve_y_at_x(next_body_size: Vector2, x: float) -> float:
	var start_x := 42.0
	var end_x := next_body_size.x - 8.0
	var ratio := clampf((x - start_x) / maxf(1.0, end_x - start_x), 0.0, 1.0)
	return _bottom_curve_y_at_ratio(next_body_size, ratio)

func _top_curve_y_at_ratio(next_body_size: Vector2, ratio: float) -> float:
	var amplitude := clampf(next_body_size.y * 0.105, 20.0, 30.0)
	return 25.0 + sin(ratio * PI) * amplitude + sin(ratio * TAU + 0.35) * 2.2

func _bottom_curve_y_at_ratio(next_body_size: Vector2, ratio: float) -> float:
	var amplitude := clampf(next_body_size.y * 0.09, 17.0, 27.0)
	return next_body_size.y - 34.0 + sin(ratio * PI + 0.12) * amplitude

func _play_appearance() -> void:
	if _appearance_tween != null and _appearance_tween.is_valid():
		_appearance_tween.kill()
	scale = Vector2(0.95, 0.93)
	modulate.a = 0.0
	_appearance_tween = create_tween().set_parallel(true)
	_appearance_tween.tween_property(self, "scale", Vector2.ONE, 0.2)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_appearance_tween.tween_property(self, "modulate:a", 1.0, 0.12)

func _play_resize(target_body_size: Vector2) -> void:
	if _resize_tween != null and _resize_tween.is_valid():
		_resize_tween.kill()
	if _appearance_tween != null and _appearance_tween.is_valid():
		_appearance_tween.kill()
	scale = Vector2.ONE
	modulate.a = 1.0
	custom_minimum_size = Vector2.ZERO
	text_label.modulate.a = 0.0

	var start_body_size := _body_size
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
