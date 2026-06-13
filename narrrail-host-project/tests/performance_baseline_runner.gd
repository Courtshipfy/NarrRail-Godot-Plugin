extends SceneTree

const LOADER_SCRIPT := "res://addons/narrrail/runtime/story_resource_loader.gd"
const SESSION_SCRIPT := "res://addons/narrrail/runtime/narrrail_session.gd"
const CASES := [
	{
		"name": "small_fixture",
		"path": "res://tests/conformance/condition_type_matrix.nrstory",
		"steps": 4
	},
	{
		"name": "choice_fixture",
		"path": "res://tests/conformance/choice_exhaustive.nrstory",
		"steps": 4
	},
	{
		"name": "synced_story",
		"path": "res://narrrail_stories/NarrRailEditor-TestRepo/Stories/伤物语.tres",
		"steps": 8,
		"optional": true
	}
]

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for test_case in CASES:
		_run_case(test_case)

	if _failures.is_empty():
		print("[NarrRail][PerformanceBaseline] PASS")
		quit(0)
	else:
		for failure in _failures:
			push_error("[NarrRail][PerformanceBaseline] %s" % failure)
		quit(1)

func _run_case(test_case: Dictionary) -> void:
	var path := String(test_case.get("path", ""))
	if bool(test_case.get("optional", false)) and not ResourceLoader.exists(path):
		print("[NarrRail][PerformanceBaseline] SKIP %s path=%s" % [String(test_case.get("name", "")), path])
		return

	var loader_script: Script = load(LOADER_SCRIPT)
	var session_script: Script = load(SESSION_SCRIPT)
	if loader_script == null or session_script == null:
		_failures.append("Required scripts missing")
		return

	var load_start := Time.get_ticks_usec()
	var result: Dictionary = loader_script.call("load_story", path)
	var load_usec := Time.get_ticks_usec() - load_start
	if not result.get("ok", false):
		_failures.append("Load failed for %s: %s" % [path, String(result.get("error", "unknown"))])
		return

	var trace: Array = []
	var errors: Array = []
	var session: RefCounted = session_script.new()
	session.error_raised.connect(func(message: String) -> void:
		errors.append(message)
	)
	session.choices_changed.connect(func(_choices: Array) -> void:
		trace.append("choice")
	)
	session.line_changed.connect(func(_payload: Dictionary) -> void:
		trace.append("line")
	)
	session.ended.connect(func() -> void:
		trace.append("end")
	)

	var start_usec := _measure_usec(func() -> void:
		session.start(result.get("story", {}))
	)
	var transition_start := Time.get_ticks_usec()
	var max_steps := int(test_case.get("steps", 0))
	for _i in range(max_steps):
		var state := String(session.get_state().get("state", ""))
		if state == "running":
			session.next()
		elif state == "waiting_choice":
			session.choose(0)
		else:
			break
	var transition_usec := Time.get_ticks_usec() - transition_start

	if not errors.is_empty():
		_failures.append("Runtime errors for %s: %s" % [path, str(errors)])
		return

	print("[NarrRail][PerformanceBaseline] case=%s load_usec=%d start_usec=%d transition_usec=%d events=%d" % [
		String(test_case.get("name", "")),
		load_usec,
		start_usec,
		transition_usec,
		trace.size()
	])

func _measure_usec(callable: Callable) -> int:
	var start := Time.get_ticks_usec()
	callable.call()
	return Time.get_ticks_usec() - start

