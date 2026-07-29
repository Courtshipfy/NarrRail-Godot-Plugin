extends SceneTree

const BUBBLE_SCENE := preload("res://sample/scenes/dialogue_bubble/dialogue_bubble.tscn")
const LONG_LINE := "昨夜送来的旧册页上还有许多手印，有些来自抄写员，有些来自读者；那些没有留下姓名的人，仍通过这些细小痕迹活在书页之间。"

var _failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var bubble: DialogueBubble = BUBBLE_SCENE.instantiate()
	root.add_child(bubble)
	await process_frame

	bubble.present("艾琳", "早。", &"left")
	await create_timer(0.3).timeout
	var short_size := bubble.size

	bubble.present("艾琳", LONG_LINE, &"left")
	_expect_close("grow transition starts from previous size", bubble.size, short_size)
	await create_timer(0.55).timeout
	var long_size := bubble.size
	_expect_true("long line grows wider", long_size.x > short_size.x + 100.0)
	_expect_true("long line grows taller", long_size.y > short_size.y + 20.0)

	bubble.present("艾琳", "好。", &"left")
	_expect_close("shrink transition starts from previous size", bubble.size, long_size)
	await create_timer(0.55).timeout
	var final_short_size := bubble.size
	_expect_true("short line shrinks narrower", final_short_size.x < long_size.x - 100.0)
	_expect_true("short line shrinks shorter", final_short_size.y < long_size.y - 20.0)

	if _failures == 0:
		print("DIALOGUE_BUBBLE_TRANSITION_PASS")
		quit(0)
	else:
		push_error("DIALOGUE_BUBBLE_TRANSITION_FAIL failures=%d" % _failures)
		quit(1)

func _expect_close(label: String, actual: Vector2, expected: Vector2) -> void:
	if actual.distance_to(expected) > 1.0:
		_failures += 1
		push_error("%s expected=%s actual=%s" % [label, expected, actual])

func _expect_true(label: String, condition: bool) -> void:
	if not condition:
		_failures += 1
		push_error(label)
