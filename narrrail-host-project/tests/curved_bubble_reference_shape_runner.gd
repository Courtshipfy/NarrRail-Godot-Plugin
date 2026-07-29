extends SceneTree

const CURVED_BUBBLE_SCENE := preload("res://sample/scenes/dialogue_bubble/curved_dialogue_bubble.tscn")

var _failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var bubble: CurvedDialogueBubble = CURVED_BUBBLE_SCENE.instantiate()
	root.add_child(bubble)
	await process_frame
	bubble.present("托马斯", "我看见那只狐狸了。", &"right")
	await create_timer(0.25).timeout

	_expect_true("reference plaque has no speech-pointer tail", not bubble.has_node("Tail"))
	_expect_true("short plaque keeps a page-like minimum height", bubble.get_body_size().y >= 190.0)
	_expect_true(
		"short plaque aspect ratio stays page-like",
		bubble.get_body_size().x / bubble.get_body_size().y <= 1.55
	)

	var spine: TextureRect = bubble.get_node("Spine")
	var curves: Dictionary = bubble.call("_build_curves", bubble.get_body_size())
	var top: PackedVector2Array = curves.top
	var bottom: PackedVector2Array = curves.bottom
	_expect_true("spine overlaps the page top", spine.position.y <= top[0].y + 2.0)
	_expect_true("spine overlaps the page bottom", spine.position.y + spine.size.y >= bottom[0].y - 2.0)

	if _failures == 0:
		print("CURVED_REFERENCE_SHAPE_PASS")
		quit(0)
	else:
		push_error("CURVED_REFERENCE_SHAPE_FAIL failures=%d" % _failures)
		quit(1)

func _expect_true(label: String, condition: bool) -> void:
	if not condition:
		_failures += 1
		push_error(label)
