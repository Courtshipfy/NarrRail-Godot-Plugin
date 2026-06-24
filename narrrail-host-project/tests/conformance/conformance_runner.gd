extends SceneTree

const LOADER_SCRIPT := "res://addons/narrrail/importer/nrstory_loader.gd"
const OUTLINE_LOADER_SCRIPT := "res://addons/narrrail/importer/nroutline_loader.gd"
const STORY_MODEL_SCRIPT := "res://addons/narrrail/runtime/story_model.gd"
const SESSION_SCRIPT := "res://addons/narrrail/runtime/narrrail_session.gd"
const OUTLINE_RUNNER_SCRIPT := "res://addons/narrrail/runtime/narrrail_outline_runner.gd"
const EVENT_ROUTER_SCRIPT := "res://addons/narrrail/runtime/narrrail_event_router.gd"

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_run_condition_int_branch()
	_run_condition_type_matrix()
	_run_choice_availability_bool()
	_run_invalid_condition_variable()
	_run_action_chain()
	_run_jump_actions()
	_run_emit_event_node()
	_run_emit_event_structured()
	_run_event_router()
	_run_trace_logging()
	_run_invalid_action_variable()
	_run_invalid_emit_event_node()
	_run_invalid_emit_event_action()
	_run_invalid_emit_event_params()
	_run_minimal_emit_event_validation()
	_run_multi_dialogue()
	_run_invalid_multi_dialogue_empty()
	_run_choice_exhaustive()
	_run_choice_exhaustive_terminal_return()
	_run_invalid_choice_exhaustive_completion()
	_run_choice_timer_timeout()
	_run_choice_timer_manual_priority()
	_run_choice_timer_save_restore()
	_run_set_variable_condition_node()
	_run_save_restore_waiting_choice()
	_run_save_restore_multi_dialogue()
	_run_save_restore_after_other_story()
	_run_outline_branch_route_a()
	_run_outline_branch_fallback()
	_run_invalid_parser_missing_fields()
	_run_invalid_validator_refs()
	_run_invalid_choice_timer()

	if _failures.is_empty():
		print("[NarrRail][Conformance] PASS")
		quit(0)
	else:
		for failure in _failures:
			push_error("[NarrRail][Conformance] %s" % failure)
		quit(1)

func _load_story(path: String) -> Dictionary:
	var result := _load_story_result(path)
	if not result.get("ok", false):
		_failures.append("Failed to load %s: %s" % [path, String(result.get("error", "unknown"))])
		return {}
	return result.get("story", {})

func _load_story_result(path: String) -> Dictionary:
	var loader_script: Script = load(LOADER_SCRIPT)
	if loader_script == null:
		_failures.append("Failed to load story loader script")
		return {"ok": false, "error": "loader script missing", "diagnostics": []}
	var result: Dictionary = loader_script.call("load_story", path)
	return result

func _new_session(trace: Array, errors: Array) -> RefCounted:
	var session_script: Script = load(SESSION_SCRIPT)
	if session_script == null:
		_failures.append("Failed to load session script")
		return null
	var session: RefCounted = session_script.new()
	session.line_changed.connect(func(payload: Dictionary) -> void:
		trace.append("LINE:%s:%d:%s" % [
			String(payload.get("nodeId", "")),
			int(payload.get("lineIndex", 0)),
			String(payload.get("textKey", ""))
		])
	)
	session.choices_changed.connect(func(choices: Array) -> void:
		trace.append("CHOICE:%s:%d" % [String(session.get_state().get("currentNodeId", "")), choices.size()])
	)
	session.ended.connect(func() -> void:
		trace.append("END")
	)
	session.error_raised.connect(func(message: String) -> void:
		errors.append(message)
	)
	session.variable_changed.connect(func(payload: Dictionary) -> void:
		trace.append("VAR:%s:%s:%s" % [
			String(payload.get("nodeId", "")),
			String(payload.get("name", "")),
			str(payload.get("newValue"))
		])
	)
	session.event_emitted.connect(func(payload: Dictionary) -> void:
		trace.append("EVENT:%s:%s:%s" % [
			String(payload.get("nodeId", "")),
			String(payload.get("phase", "")),
			String(payload.get("eventId", ""))
		])
	)
	session.choice_timed_out.connect(func(payload: Dictionary) -> void:
		trace.append("TIMEOUT:%s:%s" % [
			String(payload.get("nodeId", "")),
			String(payload.get("targetNodeId", ""))
		])
	)
	return session

func _run_condition_int_branch() -> void:
	var trace: Array = []
	var errors: Array = []
	var story := _load_story("res://tests/conformance/condition_int_branch.nrstory")
	var session := _new_session(trace, errors)
	if session == null:
		return

	session.start(story)
	session.next()
	session.next()

	_expect_equal("condition_int_branch trace", trace, ["LINE:N_Start:0:start", "LINE:N_High:0:high", "END"])
	_expect_equal("condition_int_branch errors", errors, [])
	_expect_equal("condition_int_branch variables", session.get_state().get("variables", {}), {"Affinity": 10})

func _run_condition_type_matrix() -> void:
	var trace: Array = []
	var errors: Array = []
	var story := _load_story("res://tests/conformance/condition_type_matrix.nrstory")
	var session := _new_session(trace, errors)
	if session == null:
		return

	session.start(story)
	session.next()
	session.next()
	session.next()
	session.next()

	_expect_equal("condition_type_matrix trace", trace, [
		"LINE:N_Start:0:start",
		"LINE:N_Bool:0:bool",
		"LINE:N_Float:0:float",
		"LINE:N_String:0:string",
		"END"
	])
	_expect_equal("condition_type_matrix errors", errors, [])
	_expect_equal("condition_type_matrix variables", session.get_state().get("variables", {}), {
		"Flag": true,
		"Ratio": 0.75,
		"Route": "beta"
	})

func _run_choice_availability_bool() -> void:
	var trace: Array = []
	var errors: Array = []
	var story := _load_story("res://tests/conformance/choice_availability_bool.nrstory")
	var session := _new_session(trace, errors)
	if session == null:
		return

	session.start(story)
	session.next()
	var state: Dictionary = session.get_state()
	var choices: Array = state.get("choices", [])
	_expect_equal("choice_availability_bool trace before choose", trace, ["LINE:N_Start:0:start", "CHOICE:N_Choice:1"])
	_expect_equal("choice_availability_bool choice count", choices.size(), 1)
	if choices.size() == 1:
		_expect_equal("choice_availability_bool choice text", String(choices[0].get("textKey", "")), "open")

	session.choose(0)
	session.next()

	_expect_equal("choice_availability_bool trace after choose", trace, [
		"LINE:N_Start:0:start",
		"CHOICE:N_Choice:1",
		"LINE:N_Open:0:open_path",
		"END"
	])
	_expect_equal("choice_availability_bool errors", errors, [])

func _run_invalid_condition_variable() -> void:
	var trace: Array = []
	var errors: Array = []
	var story := _load_story("res://tests/conformance/invalid_condition_variable.nrstory")
	var session := _new_session(trace, errors)
	if session == null:
		return

	session.start(story)
	session.next()

	_expect_equal("invalid_condition_variable trace", trace, ["LINE:N_Start:0:start"])
	if errors.size() != 1 or not String(errors[0]).contains("Condition variable not defined: Missing"):
		_failures.append("invalid_condition_variable expected missing-variable error, got %s" % str(errors))

func _run_action_chain() -> void:
	var trace: Array = []
	var errors: Array = []
	var story := _load_story("res://tests/conformance/action_chain.nrstory")
	var session := _new_session(trace, errors)
	if session == null:
		return

	session.start(story)
	session.next()
	session.next()

	_expect_equal("action_chain trace", trace, [
		"VAR:N_Start:Score:1",
		"VAR:N_Start:Score:10",
		"EVENT:N_Start:enter:score_ready",
		"LINE:N_Start:0:start",
		"VAR:N_Start:Score:6",
		"EVENT:N_Start:exit:left_start",
		"VAR:N_Bonus:Score:10",
		"EVENT:N_Bonus:enter:bonus_enter",
		"LINE:N_Bonus:0:bonus",
		"EVENT:N_End:enter:end_enter",
		"END"
	])
	_expect_equal("action_chain errors", errors, [])
	_expect_equal("action_chain variables", session.get_state().get("variables", {}), {"Score": 10})
	_expect_equal("action_chain events", _event_ids(session.get_state().get("events", [])), [
		"score_ready",
		"left_start",
		"bonus_enter",
		"end_enter"
	])

func _run_jump_actions() -> void:
	var trace: Array = []
	var errors: Array = []
	var story := _load_story("res://tests/conformance/jump_actions.nrstory")
	var session := _new_session(trace, errors)
	if session == null:
		return

	session.start(story)
	session.next()

	_expect_equal("jump_actions trace", trace, [
		"LINE:N_Start:0:start",
		"VAR:N_Jump:Flag:true",
		"EVENT:N_Jump:enter:jump_enter",
		"EVENT:N_Jump:exit:jump_exit",
		"EVENT:N_End:enter:jump_end",
		"END"
	])
	_expect_equal("jump_actions errors", errors, [])
	_expect_equal("jump_actions variables", session.get_state().get("variables", {}), {"Flag": true})
	_expect_equal("jump_actions events", _event_ids(session.get_state().get("events", [])), [
		"jump_enter",
		"jump_exit",
		"jump_end"
	])

func _run_emit_event_node() -> void:
	var trace: Array = []
	var errors: Array = []
	var story := _load_story("res://tests/conformance/emit_event_node.nrstory")
	var session := _new_session(trace, errors)
	if session == null:
		return

	session.start(story)
	session.next()
	session.next()

	_expect_equal("emit_event_node trace", trace, [
		"LINE:N_Start:0:start",
		"EVENT:N_Event:node:door_open",
		"LINE:N_EndLine:0:after_event",
		"END"
	])
	_expect_equal("emit_event_node errors", errors, [])
	_expect_equal("emit_event_node events", _event_ids(session.get_state().get("events", [])), ["door_open"])

func _run_emit_event_structured() -> void:
	var trace: Array = []
	var errors: Array = []
	var story := _load_story("res://tests/conformance/emit_event_structured.nrstory")
	var session := _new_session(trace, errors)
	if session == null:
		return

	session.start(story)
	session.next()

	_expect_equal("emit_event_structured trace", trace, [
		"EVENT:N_Start:enter:",
		"LINE:N_Start:0:start",
		"EVENT:N_Start:exit:legacy_and_type",
		"EVENT:N_TypeNode:node:",
		"EVENT:N_DefaultParams:node:",
		"END"
	])
	_expect_equal("emit_event_structured errors", errors, [])

	var events: Array = session.get_state().get("events", [])
	_expect_equal("emit_event_structured event count", events.size(), 4)
	if events.size() != 4:
		return
	_expect_equal("emit_event_structured action type", String((events[0] as Dictionary).get("eventType", "")), "inventory.add_item")
	_expect_equal("emit_event_structured action params", (events[0] as Dictionary).get("params", {}), {"itemId": "key", "count": 1})
	_expect_equal("emit_event_structured combined id", String((events[1] as Dictionary).get("eventId", "")), "legacy_and_type")
	_expect_equal("emit_event_structured combined type", String((events[1] as Dictionary).get("eventType", "")), "ui.flash")
	_expect_equal("emit_event_structured node type", String((events[2] as Dictionary).get("eventType", "")), "audio.play")
	_expect_equal("emit_event_structured node params", (events[2] as Dictionary).get("params", {}), {"cue": "door"})
	_expect_equal("emit_event_structured default params", (events[3] as Dictionary).get("params", {}), {})

func _run_event_router() -> void:
	var router_script: Script = load(EVENT_ROUTER_SCRIPT)
	if router_script == null:
		_failures.append("Failed to load event router script")
		return

	var router: RefCounted = router_script.new()
	var handled: Array = []
	var unhandled: Array = []
	var type_handled: Array = []
	router.event_handled.connect(func(event_id: String, _payload: Dictionary) -> void:
		handled.append(event_id)
	)
	router.event_unhandled.connect(func(event_id: String, _payload: Dictionary) -> void:
		unhandled.append(event_id)
	)
	router.event_type_handled.connect(func(event_type: String, _payload: Dictionary) -> void:
		type_handled.append(event_type)
	)
	router.register("123", func(payload: Dictionary) -> void:
		handled.append("call:%s:%s" % [
			String(payload.get("eventId", "")),
			String(payload.get("nodeId", ""))
		])
	)
	router.register_type("inventory.add_item", func(payload: Dictionary) -> void:
		type_handled.append("call:%s:%s" % [
			String(payload.get("eventType", "")),
			String(payload.get("nodeId", ""))
		])
	)

	_expect_equal("event_router handles registered event", router.dispatch({"eventId": "123", "nodeId": "N_Event"}), true)
	_expect_equal("event_router handles registered type", router.dispatch({"eventType": "inventory.add_item", "nodeId": "N_Type"}), true)
	_expect_equal("event_router id wins over type", router.dispatch({"eventId": "123", "eventType": "inventory.add_item", "nodeId": "N_Both"}), true)
	_expect_equal("event_router ignores unregistered event", router.dispatch({"eventId": "missing", "eventType": "missing.type", "nodeId": "N_Event"}), false)
	_expect_equal("event_router has type handler", router.has_type_handler("inventory.add_item"), true)
	_expect_equal("event_router handled trace", handled, ["call:123:N_Event", "123", "call:123:N_Both", "123"])
	_expect_equal("event_router type handled trace", type_handled, ["call:inventory.add_item:N_Type", "inventory.add_item"])
	_expect_equal("event_router unhandled trace", unhandled, ["missing"])
	router.unregister_type("inventory.add_item")
	_expect_equal("event_router unregisters type handler", router.has_type_handler("inventory.add_item"), false)

func _run_trace_logging() -> void:
	var trace: Array = []
	var errors: Array = []
	var runtime_trace: Array = []
	var story := _load_story("res://tests/conformance/emit_event_node.nrstory")
	var session := _new_session(trace, errors)
	if session == null:
		return

	session.set_trace_enabled(true)
	session.trace_logged.connect(func(payload: Dictionary) -> void:
		runtime_trace.append(String(payload.get("eventType", "")))
	)
	session.start(story)
	session.next()
	session.next()

	_expect_equal("trace_logging errors", errors, [])
	for expected in ["session_start", "node_enter", "line", "transition", "event", "ended"]:
		if not runtime_trace.has(expected):
			_failures.append("trace_logging missing eventType=%s actual=%s" % [expected, str(runtime_trace)])
	var records: Array = session.get_trace_records()
	if records.is_empty():
		_failures.append("trace_logging expected trace records")
	else:
		var first: Dictionary = records[0]
		if not first.has("storyId") or not first.has("eventType") or not first.has("nodeId") or not first.has("state"):
			_failures.append("trace_logging missing context fields in %s" % str(first))

func _run_invalid_action_variable() -> void:
	var trace: Array = []
	var errors: Array = []
	var story := _load_story("res://tests/conformance/invalid_action_variable.nrstory")
	var session := _new_session(trace, errors)
	if session == null:
		return

	session.start(story)

	_expect_equal("invalid_action_variable trace", trace, [])
	if errors.size() != 1 or not String(errors[0]).contains("Add action variable not found on node N_Start: Missing"):
		_failures.append("invalid_action_variable expected action-variable error, got %s" % str(errors))

func _run_invalid_emit_event_node() -> void:
	var result := _load_story_result("res://tests/conformance/invalid_emit_event_node.nrstory")
	_expect_equal("invalid_emit_event_node ok", result.get("ok", true), false)
	_expect_diag_codes("invalid_emit_event_node diagnostics", result.get("diagnostics", []), [
		"EMIT_EVENT_ID_OR_TYPE_EMPTY"
	])
	_expect_diag_suggestions("invalid_emit_event_node suggestions", result.get("diagnostics", []), [
		"EMIT_EVENT_ID_OR_TYPE_EMPTY"
	])

func _run_invalid_emit_event_action() -> void:
	var result := _load_story_result("res://tests/conformance/invalid_emit_event_action.nrstory")
	_expect_equal("invalid_emit_event_action ok", result.get("ok", true), false)
	_expect_diag_codes("invalid_emit_event_action diagnostics", result.get("diagnostics", []), [
		"ACTION_EVENT_ID_OR_TYPE_EMPTY"
	])
	_expect_diag_suggestions("invalid_emit_event_action suggestions", result.get("diagnostics", []), [
		"ACTION_EVENT_ID_OR_TYPE_EMPTY"
	])

func _run_invalid_emit_event_params() -> void:
	var node_result := _load_story_result("res://tests/conformance/invalid_emit_event_params_node.nrstory")
	_expect_equal("invalid_emit_event_params_node ok", node_result.get("ok", true), false)
	_expect_diag_codes("invalid_emit_event_params_node diagnostics", node_result.get("diagnostics", []), [
		"EMIT_EVENT_PARAMS_TYPE_INVALID"
	])

	var action_result := _load_story_result("res://tests/conformance/invalid_emit_event_params_action.nrstory")
	_expect_equal("invalid_emit_event_params_action ok", action_result.get("ok", true), false)
	_expect_diag_codes("invalid_emit_event_params_action diagnostics", action_result.get("diagnostics", []), [
		"ACTION_EVENT_PARAMS_TYPE_INVALID"
	])

func _run_minimal_emit_event_validation() -> void:
	var model_script: Script = load(STORY_MODEL_SCRIPT)
	if model_script == null:
		_failures.append("Failed to load story model script")
		return

	var valid_type_only := _minimal_story([{
		"nodeId": "N_Event",
		"nodeType": "EmitEvent",
		"eventType": "inventory.add_item",
		"params": {"itemId": "key"}
	}])
	_expect_equal("minimal_emit_event type-only ok", model_script.call("validate_minimal", valid_type_only).get("ok", false), true)

	var invalid_empty := _minimal_story([{
		"nodeId": "N_Event",
		"nodeType": "EmitEvent",
		"eventId": "",
		"eventType": ""
	}])
	var invalid_empty_check: Dictionary = model_script.call("validate_minimal", invalid_empty)
	_expect_equal("minimal_emit_event empty ok", invalid_empty_check.get("ok", true), false)
	_expect_error_contains("minimal_emit_event empty error", invalid_empty_check.get("errors", []), "missing eventId or eventType")

	var invalid_node_params := _minimal_story([{
		"nodeId": "N_Event",
		"nodeType": "EmitEvent",
		"eventType": "inventory.add_item",
		"params": "invalid"
	}])
	var invalid_node_params_check: Dictionary = model_script.call("validate_minimal", invalid_node_params)
	_expect_equal("minimal_emit_event bad node params ok", invalid_node_params_check.get("ok", true), false)
	_expect_error_contains("minimal_emit_event bad node params error", invalid_node_params_check.get("errors", []), "params must be an object")

	var invalid_action_params := _minimal_story([{
		"nodeId": "N_Start",
		"nodeType": "Dialogue",
		"dialogue": {"speakerId": "Hero", "textKey": "start"},
		"enterActions": [{
			"actionType": "EmitEvent",
			"eventType": "inventory.add_item",
			"params": "invalid"
		}]
	}])
	var invalid_action_params_check: Dictionary = model_script.call("validate_minimal", invalid_action_params)
	_expect_equal("minimal_emit_event bad action params ok", invalid_action_params_check.get("ok", true), false)
	_expect_error_contains("minimal_emit_event bad action params error", invalid_action_params_check.get("errors", []), "params must be an object")

func _run_multi_dialogue() -> void:
	var trace: Array = []
	var errors: Array = []
	var story := _load_story("res://tests/conformance/multi_dialogue.nrstory")
	var session := _new_session(trace, errors)
	if session == null:
		return

	session.start(story)
	_expect_equal("multi_dialogue state after start", session.get_state().get("currentLineIndex", -1), 0)
	session.next()
	_expect_equal("multi_dialogue state after line 2", session.get_state().get("currentLineIndex", -1), 1)
	session.next()
	_expect_equal("multi_dialogue state after line 3", session.get_state().get("currentLineIndex", -1), 2)
	session.next()

	_expect_equal("multi_dialogue trace", trace, [
		"EVENT:N_Start:enter:multi_enter",
		"LINE:N_Start:0:line_1",
		"LINE:N_Start:1:line_2",
		"LINE:N_Start:2:line_3",
		"EVENT:N_Start:exit:multi_exit",
		"EVENT:N_End:enter:multi_end",
		"END"
	])
	_expect_equal("multi_dialogue errors", errors, [])
	_expect_equal("multi_dialogue events", _event_ids(session.get_state().get("events", [])), [
		"multi_enter",
		"multi_exit",
		"multi_end"
	])

func _run_invalid_multi_dialogue_empty() -> void:
	var trace: Array = []
	var errors: Array = []
	var story := _load_story("res://tests/conformance/invalid_multi_dialogue_empty.nrstory")
	var session := _new_session(trace, errors)
	if session == null:
		return

	session.start(story)

	_expect_equal("invalid_multi_dialogue_empty trace", trace, [])
	if errors.size() != 1 or not String(errors[0]).contains("MultiDialogue node has no lines: N_Start"):
		_failures.append("invalid_multi_dialogue_empty expected no-lines error, got %s" % str(errors))

func _run_choice_exhaustive() -> void:
	var trace: Array = []
	var errors: Array = []
	var story := _load_story("res://tests/conformance/choice_exhaustive.nrstory")
	var session := _new_session(trace, errors)
	if session == null:
		return

	session.start(story)
	_expect_equal("choice_exhaustive initial choice count", session.get_state().get("choices", []).size(), 2)
	session.choose(0)
	session.next()
	_expect_equal("choice_exhaustive second choice count", session.get_state().get("choices", []).size(), 1)
	if session.get_state().get("choices", []).size() == 1:
		_expect_equal("choice_exhaustive remaining choice", String(session.get_state().get("choices", [])[0].get("textKey", "")), "B")
	session.choose(0)
	session.next()
	session.next()

	_expect_equal("choice_exhaustive trace", trace, [
		"CHOICE:N_Choice:2",
		"EVENT:N_Choice:exit:choice_exit",
		"LINE:N_A:0:branch_a",
		"CHOICE:N_Choice:1",
		"EVENT:N_Choice:exit:choice_exit",
		"LINE:N_B:0:branch_b",
		"EVENT:N_Choice:exit:choice_exit",
		"LINE:N_Complete:0:complete",
		"END"
	])
	_expect_equal("choice_exhaustive errors", errors, [])
	_expect_equal("choice_exhaustive exhausted targets", session.get_state().get("exhaustedChoiceTargets", {}), {
		"N_Choice": {
			"N_A": true,
			"N_B": true
		}
	})

func _run_choice_exhaustive_terminal_return() -> void:
	var trace: Array = []
	var errors: Array = []
	var story := _load_story("res://tests/conformance/choice_exhaustive_terminal_return.nrstory")
	var session := _new_session(trace, errors)
	if session == null:
		return

	session.start(story)
	_expect_equal("choice_exhaustive_terminal_return initial choice count", session.get_state().get("choices", []).size(), 2)
	session.choose(0)
	session.next()
	_expect_equal("choice_exhaustive_terminal_return second choice count", session.get_state().get("choices", []).size(), 1)
	session.choose(0)
	session.next()
	session.next()

	_expect_equal("choice_exhaustive_terminal_return trace", trace, [
		"CHOICE:N_Choice:2",
		"LINE:N_A:0:branch_a",
		"CHOICE:N_Choice:1",
		"LINE:N_B:0:branch_b",
		"LINE:N_Complete:0:complete",
		"END"
	])
	_expect_equal("choice_exhaustive_terminal_return errors", errors, [])
	_expect_equal("choice_exhaustive_terminal_return stack", session.get_state().get("exhaustiveChoiceStack", []), [])

func _run_invalid_choice_exhaustive_completion() -> void:
	var trace: Array = []
	var errors: Array = []
	var story := _load_story("res://tests/conformance/invalid_choice_exhaustive_completion.nrstory")
	var session := _new_session(trace, errors)
	if session == null:
		return

	session.start(story)

	_expect_equal("invalid_choice_exhaustive_completion trace", trace, [])
	if errors.size() != 1 or not String(errors[0]).contains("Exhaustive choice missing choiceCompletionTargetNodeId on node: N_Choice"):
		_failures.append("invalid_choice_exhaustive_completion expected completion-target error, got %s" % str(errors))

func _run_choice_timer_timeout() -> void:
	var trace: Array = []
	var errors: Array = []
	var timer_ticks: Array = []
	var story := _load_story("res://tests/conformance/choice_timer.nrstory")
	var session := _new_session(trace, errors)
	if session == null:
		return
	session.choice_timer_changed.connect(func(payload: Dictionary) -> void:
		timer_ticks.append(float(payload.get("remainingSeconds", 0.0)))
	)

	session.start(story)
	_expect_equal("choice_timer_timeout initial remaining", float(session.get_state().get("choiceTimer", {}).get("remainingSeconds", 0.0)), 2.0)
	session.advance_time(1.0)
	_expect_equal("choice_timer_timeout remaining after 1s", float(session.get_state().get("choiceTimer", {}).get("remainingSeconds", 0.0)), 1.0)
	session.advance_time(1.1)
	session.next()

	_expect_equal("choice_timer_timeout trace", trace, [
		"CHOICE:N_Choice:1",
		"TIMEOUT:N_Choice:N_Timeout",
		"EVENT:N_Choice:exit:choice_exit",
		"LINE:N_Timeout:0:timeout_path",
		"END"
	])
	_expect_equal("choice_timer_timeout errors", errors, [])
	if timer_ticks.size() < 3:
		_failures.append("choice_timer_timeout expected timer ticks, got %s" % str(timer_ticks))

func _run_choice_timer_manual_priority() -> void:
	var trace: Array = []
	var errors: Array = []
	var story := _load_story("res://tests/conformance/choice_timer.nrstory")
	var session := _new_session(trace, errors)
	if session == null:
		return

	session.start(story)
	session.advance_time(1.0)
	session.choose(0)
	session.advance_time(10.0)
	session.next()

	_expect_equal("choice_timer_manual_priority trace", trace, [
		"CHOICE:N_Choice:1",
		"EVENT:N_Choice:exit:choice_exit",
		"LINE:N_Manual:0:manual_path",
		"END"
	])
	_expect_equal("choice_timer_manual_priority errors", errors, [])

func _run_choice_timer_save_restore() -> void:
	var before_trace: Array = []
	var before_errors: Array = []
	var story := _load_story("res://tests/conformance/choice_timer.nrstory")
	var before_session := _new_session(before_trace, before_errors)
	if before_session == null:
		return

	before_session.start(story)
	before_session.advance_time(0.75)
	var snapshot: Dictionary = before_session.create_save_snapshot()

	var trace: Array = []
	var errors: Array = []
	var session := _new_session(trace, errors)
	if session == null:
		return
	var restored: bool = session.restore_save_snapshot(story, snapshot)
	_expect_equal("choice_timer_save_restore restored", restored, true)
	_expect_equal("choice_timer_save_restore remaining", float(session.get_state().get("choiceTimer", {}).get("remainingSeconds", 0.0)), 1.25)
	session.advance_time(1.3)
	session.next()

	_expect_equal("choice_timer_save_restore trace", trace, [
		"CHOICE:N_Choice:1",
		"TIMEOUT:N_Choice:N_Timeout",
		"EVENT:N_Choice:exit:choice_exit",
		"LINE:N_Timeout:0:timeout_path",
		"END"
	])
	_expect_equal("choice_timer_save_restore errors", errors, [])

func _run_set_variable_condition_node() -> void:
	var story := _load_story("res://tests/conformance/set_variable_condition_node.nrstory")
	_run_set_variable_condition_path(story, 0, [
		"CHOICE:N_Choice:2",
		"VAR:N_Set:Trust:1",
		"LINE:N_High:0:high",
		"END"
	], {"Trust": 1})
	_run_set_variable_condition_path(story, 1, [
		"CHOICE:N_Choice:2",
		"LINE:N_Low:0:low",
		"END"
	], {"Trust": 0})

func _run_set_variable_condition_path(story: Dictionary, choice_index: int, expected_trace: Array, expected_variables: Dictionary) -> void:
	var trace: Array = []
	var errors: Array = []
	var session := _new_session(trace, errors)
	if session == null:
		return

	session.start(story)
	session.choose(choice_index)
	session.next()

	_expect_equal("set_variable_condition_node trace choice %d" % choice_index, trace, expected_trace)
	_expect_equal("set_variable_condition_node errors choice %d" % choice_index, errors, [])
	_expect_equal("set_variable_condition_node variables choice %d" % choice_index, session.get_state().get("variables", {}), expected_variables)

func _run_save_restore_waiting_choice() -> void:
	var before_trace: Array = []
	var before_errors: Array = []
	var story := _load_story("res://tests/conformance/choice_exhaustive.nrstory")
	var before_session := _new_session(before_trace, before_errors)
	if before_session == null:
		return

	before_session.start(story)
	before_session.choose(0)
	before_session.next()
	var snapshot: Dictionary = before_session.create_save_snapshot()

	var trace: Array = []
	var errors: Array = []
	var session := _new_session(trace, errors)
	if session == null:
		return

	var restored: bool = session.restore_save_snapshot(story, snapshot)
	_expect_equal("save_restore_waiting_choice restored", restored, true)
	session.choose(0)
	session.next()
	session.next()

	_expect_equal("save_restore_waiting_choice trace", trace, [
		"CHOICE:N_Choice:1",
		"EVENT:N_Choice:exit:choice_exit",
		"LINE:N_B:0:branch_b",
		"EVENT:N_Choice:exit:choice_exit",
		"LINE:N_Complete:0:complete",
		"END"
	])
	_expect_equal("save_restore_waiting_choice errors", errors, [])
	_expect_equal("save_restore_waiting_choice exhausted targets", session.get_state().get("exhaustedChoiceTargets", {}), {
		"N_Choice": {
			"N_A": true,
			"N_B": true
		}
	})

func _run_save_restore_multi_dialogue() -> void:
	var before_trace: Array = []
	var before_errors: Array = []
	var story := _load_story("res://tests/conformance/multi_dialogue.nrstory")
	var before_session := _new_session(before_trace, before_errors)
	if before_session == null:
		return

	before_session.start(story)
	before_session.next()
	var snapshot: Dictionary = before_session.create_save_snapshot()

	var trace: Array = []
	var errors: Array = []
	var session := _new_session(trace, errors)
	if session == null:
		return

	var restored: bool = session.restore_save_snapshot(story, snapshot)
	_expect_equal("save_restore_multi_dialogue restored", restored, true)
	_expect_equal("save_restore_multi_dialogue line index", session.get_state().get("currentLineIndex", -1), 1)
	session.next()
	session.next()

	_expect_equal("save_restore_multi_dialogue trace", trace, [
		"LINE:N_Start:1:line_2",
		"LINE:N_Start:2:line_3",
		"EVENT:N_Start:exit:multi_exit",
		"EVENT:N_End:enter:multi_end",
		"END"
	])
	_expect_equal("save_restore_multi_dialogue errors", errors, [])

func _run_save_restore_after_other_story() -> void:
	var trace: Array = []
	var errors: Array = []
	var story_a := _load_story("res://tests/conformance/choice_availability_bool.nrstory")
	var story_b := _load_story("res://tests/conformance/condition_int_branch.nrstory")
	var session := _new_session(trace, errors)
	if session == null:
		return

	session.start(story_a)
	session.next()
	var snapshot: Dictionary = session.create_save_snapshot()

	session.start(story_b)
	session.next()

	var restored: bool = session.restore_save_snapshot(story_a, snapshot)
	_expect_equal("save_restore_after_other_story restored", restored, true)
	session.choose(0)
	session.next()

	_expect_equal("save_restore_after_other_story trace", trace, [
		"LINE:N_Start:0:start",
		"CHOICE:N_Choice:1",
		"LINE:N_Start:0:start",
		"LINE:N_High:0:high",
		"CHOICE:N_Choice:1",
		"LINE:N_Open:0:open_path",
		"END"
	])
	_expect_equal("save_restore_after_other_story errors", errors, [])

func _run_outline_branch_route_a() -> void:
	var trace: Array = []
	var errors: Array = []
	var runner := _new_outline_runner(trace, errors)
	if runner == null:
		return

	var outline := _load_outline("res://tests/conformance/outline_main.nroutline")
	var library := _outline_story_library()
	runner.start(outline, library)
	runner.choose(0)
	runner.next()

	_expect_equal("outline_branch_route_a trace", trace, [
		"OUTLINE:rail_start:Note",
		"OUTLINE:chapter:Story",
		"CHOICE:chapter:2",
		"VAR:chapter:Route:A",
		"OUTLINE:route_check:Branch",
		"BRANCH:route_check:branch-0:route_a",
		"OUTLINE:route_a:Story",
		"LINE:route_a:outline_route_a:N_Start:route_a_line",
		"OUTLINE:rail_end:End",
		"OUTLINE_END"
	])
	_expect_equal("outline_branch_route_a errors", errors, [])
	_expect_equal("outline_branch_route_a variables", runner.get_state().get("variables", {}), {"Route": "A"})

func _run_outline_branch_fallback() -> void:
	var trace: Array = []
	var errors: Array = []
	var runner := _new_outline_runner(trace, errors)
	if runner == null:
		return

	var outline := _load_outline("res://tests/conformance/outline_main.nroutline")
	var library := _outline_story_library()
	runner.start(outline, library)
	runner.choose(1)
	runner.next()

	_expect_equal("outline_branch_fallback trace", trace, [
		"OUTLINE:rail_start:Note",
		"OUTLINE:chapter:Story",
		"CHOICE:chapter:2",
		"VAR:chapter:Route:B",
		"OUTLINE:route_check:Branch",
		"BRANCH:route_check:branch-fallback:route_b",
		"OUTLINE:route_b:Story",
		"LINE:route_b:outline_route_b:N_Start:route_b_line",
		"OUTLINE:rail_end:End",
		"OUTLINE_END"
	])
	_expect_equal("outline_branch_fallback errors", errors, [])
	_expect_equal("outline_branch_fallback variables", runner.get_state().get("variables", {}), {"Route": "B"})

func _new_outline_runner(trace: Array, errors: Array) -> RefCounted:
	var runner_script: Script = load(OUTLINE_RUNNER_SCRIPT)
	if runner_script == null:
		_failures.append("Failed to load outline runner script")
		return null
	var runner: RefCounted = runner_script.new()
	runner.outline_node_entered.connect(func(payload: Dictionary) -> void:
		trace.append("OUTLINE:%s:%s" % [
			String(payload.get("nodeId", "")),
			String(payload.get("nodeType", ""))
		])
	)
	runner.outline_branch_matched.connect(func(payload: Dictionary) -> void:
		trace.append("BRANCH:%s:%s:%s" % [
			String(payload.get("nodeId", "")),
			String(payload.get("sourceHandle", "")),
			String(payload.get("targetNodeId", ""))
		])
	)
	runner.line_changed.connect(func(payload: Dictionary) -> void:
		trace.append("LINE:%s:%s:%s:%s" % [
			String(payload.get("outlineNodeId", "")),
			String(payload.get("storyId", "")),
			String(payload.get("nodeId", "")),
			String(payload.get("textKey", ""))
		])
	)
	runner.choices_changed.connect(func(choices: Array) -> void:
		trace.append("CHOICE:%s:%d" % [
			String(runner.get_state().get("currentOutlineNodeId", "")),
			choices.size()
		])
	)
	runner.variable_changed.connect(func(payload: Dictionary) -> void:
		trace.append("VAR:%s:%s:%s" % [
			String(payload.get("outlineNodeId", "")),
			String(payload.get("name", "")),
			str(payload.get("newValue"))
		])
	)
	runner.ended.connect(func() -> void:
		trace.append("OUTLINE_END")
	)
	runner.error_raised.connect(func(message: String) -> void:
		errors.append(message)
	)
	return runner

func _load_outline(path: String) -> Dictionary:
	var loader_script: Script = load(OUTLINE_LOADER_SCRIPT)
	if loader_script == null:
		_failures.append("Failed to load outline loader script")
		return {}
	var result: Dictionary = loader_script.call("load_outline", path, ["outline_chapter", "outline_route_a", "outline_route_b"])
	if not result.get("ok", false):
		_failures.append("Failed to load outline %s: %s" % [path, String(result.get("error", "unknown"))])
		return {}
	return result.get("outline", {})

func _outline_story_library() -> Dictionary:
	return {
		"outline_chapter": _load_story("res://tests/conformance/outline_chapter.nrstory"),
		"outline_route_a": _load_story("res://tests/conformance/outline_route_a.nrstory"),
		"outline_route_b": _load_story("res://tests/conformance/outline_route_b.nrstory")
	}

func _run_invalid_parser_missing_fields() -> void:
	var result := _load_story_result("res://tests/conformance/invalid_parser_missing_fields.nrstory")
	_expect_equal("invalid_parser_missing_fields ok", result.get("ok", true), false)
	_expect_diag_codes("invalid_parser_missing_fields diagnostics", result.get("diagnostics", []), [
		"MISSING_FIELD"
	])

func _run_invalid_validator_refs() -> void:
	var result := _load_story_result("res://tests/conformance/invalid_validator_refs.nrstory")
	_expect_equal("invalid_validator_refs ok", result.get("ok", true), false)
	_expect_diag_codes("invalid_validator_refs diagnostics", result.get("diagnostics", []), [
		"NODE_ID_DUPLICATE",
		"EDGE_TARGET_NOT_FOUND",
		"CHOICE_TARGET_NOT_FOUND"
	])
	_expect_diag_suggestions("invalid_validator_refs suggestions", result.get("diagnostics", []), [
		"NODE_ID_DUPLICATE",
		"EDGE_TARGET_NOT_FOUND",
		"CHOICE_TARGET_NOT_FOUND"
	])

func _run_invalid_choice_timer() -> void:
	var result := _load_story_result("res://tests/conformance/invalid_choice_timer.nrstory")
	_expect_equal("invalid_choice_timer ok", result.get("ok", true), false)
	_expect_diag_codes("invalid_choice_timer diagnostics", result.get("diagnostics", []), [
		"CHOICE_TIMER_DURATION_INVALID",
		"CHOICE_TIMER_TEXT_EMPTY",
		"CHOICE_TIMER_EDGE_MISSING"
	])

func _event_ids(events: Array) -> Array:
	var out: Array = []
	for event in events:
		out.append(String(event.get("eventId", "")))
	return out

func _minimal_story(nodes: Array) -> Dictionary:
	return {
		"meta": {
			"schemaVersion": 1,
			"storyId": "minimal_emit_event_validation",
			"entryNodeId": "N_Event" if String((nodes[0] as Dictionary).get("nodeId", "")) == "N_Event" else "N_Start"
		},
		"variables": [],
		"nodes": nodes,
		"edges": []
	}

func _expect_error_contains(label: String, errors: Array, needle: String) -> void:
	for error in errors:
		if String(error).contains(needle):
			return
	_failures.append("%s missing '%s' actual=%s" % [label, needle, str(errors)])

func _expect_diag_codes(label: String, diagnostics: Array, expected_codes: Array) -> void:
	var actual_codes: Dictionary = {}
	for d in diagnostics:
		var code := String((d as Dictionary).get("code", ""))
		if not code.is_empty():
			actual_codes[code] = true

	for expected_code in expected_codes:
		if not actual_codes.has(String(expected_code)):
			_failures.append("%s missing code=%s actual=%s" % [label, String(expected_code), str(actual_codes.keys())])

func _expect_diag_suggestions(label: String, diagnostics: Array, expected_codes: Array) -> void:
	var by_code: Dictionary = {}
	for d in diagnostics:
		var diag: Dictionary = d
		var code := String(diag.get("code", ""))
		if not code.is_empty():
			by_code[code] = diag

	for expected_code in expected_codes:
		var code := String(expected_code)
		if not by_code.has(code):
			_failures.append("%s missing code=%s" % [label, code])
			continue
		var suggestion := String((by_code[code] as Dictionary).get("suggestion", ""))
		if suggestion.is_empty():
			_failures.append("%s missing suggestion for code=%s" % [label, code])

func _expect_equal(label: String, actual, expected) -> void:
	if actual != expected:
		_failures.append("%s expected=%s actual=%s" % [label, str(expected), str(actual)])
