class_name NarrRailSession
extends RefCounted

signal line_changed(payload: Dictionary)
signal choices_changed(choices: Array)
signal ended()
signal error_raised(message: String)
signal variable_changed(payload: Dictionary)
signal event_emitted(payload: Dictionary)

const STATE_IDLE := "idle"
const STATE_RUNNING := "running"
const STATE_WAITING_CHOICE := "waiting_choice"
const STATE_ENDED := "ended"

var _story: Dictionary = {}
var _node_by_id: Dictionary = {}
var _out_edges: Dictionary = {}
var _variable_defs: Dictionary = {}
var _variables: Dictionary = {}
var _emitted_events: Array = []
var _exhausted_choice_targets: Dictionary = {}
var _exhaustive_choice_stack: Array[String] = []
var _state: String = STATE_IDLE
var _current_node_id: String = ""
var _current_choices: Array = []
var _current_line_index: int = -1

func start(story_data: Dictionary) -> void:
	var check := NarrRailStoryModel.validate_minimal(story_data)
	if not check.get("ok", false):
		_emit_error("Story validation failed: %s" % "; ".join(check.get("errors", [])))
		return

	_story = story_data
	_build_indexes()
	_emitted_events.clear()
	_exhausted_choice_targets.clear()
	_exhaustive_choice_stack.clear()
	var variables_check := _initialize_variables()
	if not variables_check.get("ok", false):
		_emit_error("Variable initialization failed: %s" % String(variables_check.get("error", "unknown")))
		return

	_state = STATE_RUNNING
	_current_choices.clear()
	_current_line_index = -1

	var entry_id := String(_story.get("meta", {}).get("entryNodeId", ""))
	_enter_node(entry_id)

func next() -> void:
	if _state == STATE_ENDED:
		return
	if _state == STATE_WAITING_CHOICE:
		_emit_error("Cannot next(): waiting for choose(index)")
		return
	if _state != STATE_RUNNING:
		_emit_error("Cannot next() in state: %s" % _state)
		return

	var node: Dictionary = _node_by_id.get(_current_node_id, {})
	var node_type := String(node.get("nodeType", ""))

	match node_type:
		"Dialogue":
			var leave_check := _execute_exit_actions(_current_node_id)
			if not leave_check.get("ok", false):
				_emit_error(String(leave_check.get("error", "Unknown exit action error")))
				return
			_move_to_next_by_edges(_current_node_id)
		"MultiDialogue":
			_advance_multi_dialogue(node)
		"End":
			_finish()
		_:
			_emit_error("next() not supported for nodeType: %s" % node_type)

func choose(index: int) -> void:
	if _state != STATE_WAITING_CHOICE:
		_emit_error("Cannot choose(): not in waiting_choice state")
		return

	if index < 0 or index >= _current_choices.size():
		_emit_error("Choice index out of range: %d" % index)
		return

	var chosen: Dictionary = _current_choices[index]
	var target := String(chosen.get("targetNodeId", ""))
	if target.is_empty():
		_emit_error("Chosen option has empty targetNodeId")
		return
	var source_node_id := _current_node_id

	var leave_check := _execute_exit_actions(_current_node_id)
	if not leave_check.get("ok", false):
		_emit_error(String(leave_check.get("error", "Unknown exit action error")))
		return

	_mark_exhaustive_choice_selected(source_node_id, target)
	_push_exhaustive_choice_frame(source_node_id)
	_current_choices.clear()
	_state = STATE_RUNNING
	_enter_node(target)

func get_state() -> Dictionary:
	return {
		"state": _state,
		"currentNodeId": _current_node_id,
		"currentLineIndex": _current_line_index,
		"choices": _current_choices.duplicate(true),
		"variables": _variables.duplicate(true),
		"events": _emitted_events.duplicate(true),
		"exhaustedChoiceTargets": _exhausted_choice_targets.duplicate(true),
		"exhaustiveChoiceStack": _exhaustive_choice_stack.duplicate(true)
	}

func _build_indexes() -> void:
	_node_by_id.clear()
	_out_edges.clear()

	for n in _story.get("nodes", []):
		var id := String(n.get("nodeId", ""))
		_node_by_id[id] = n

	for e in _story.get("edges", []):
		var s := String(e.get("sourceNodeId", ""))
		if not _out_edges.has(s):
			_out_edges[s] = []
		_out_edges[s].append(e)

func _enter_node(node_id: String) -> void:
	if not _node_by_id.has(node_id):
		_emit_error("Node not found: %s" % node_id)
		return

	_current_node_id = node_id
	_current_line_index = -1
	var node: Dictionary = _node_by_id[node_id]
	var node_type := String(node.get("nodeType", ""))
	var enter_check := _execute_actions(node.get("enterActions", []), "enter", node_id)
	if not enter_check.get("ok", false):
		_emit_error(String(enter_check.get("error", "Unknown enter action error")))
		return

	match node_type:
		"Dialogue":
			var dialogue: Dictionary = node.get("dialogue", {})
			line_changed.emit({
				"nodeId": node_id,
				"lineIndex": 0,
				"speakerId": String(dialogue.get("speakerId", "")),
				"textKey": String(dialogue.get("textKey", ""))
			})
		"MultiDialogue":
			_current_line_index = 0
			var emit_check := _emit_multi_dialogue_line(node)
			if not emit_check.get("ok", false):
				_emit_error(String(emit_check.get("error", "Unknown MultiDialogue error")))
				return
		"Choice":
			var available_check := _get_available_choices(node)
			if not available_check.get("ok", false):
				_emit_error(String(available_check.get("error", "Unknown choice availability error")))
				return
			var choices: Array = available_check.get("choices", [])
			if choices.is_empty() and _choice_mode(node) == "ExhaustiveUntilComplete":
				var completion_target := String(node.get("choiceCompletionTargetNodeId", ""))
				if completion_target.is_empty():
					_emit_error("Exhaustive choice has empty choiceCompletionTargetNodeId: %s" % node_id)
					return
				var leave_check := _execute_exit_actions(node_id)
				if not leave_check.get("ok", false):
					_emit_error(String(leave_check.get("error", "Unknown exhaustive choice exit action error")))
					return
				_pop_exhaustive_choice_frame(node_id)
				_enter_node(completion_target)
				return
			_current_choices = choices.duplicate(true)
			_state = STATE_WAITING_CHOICE
			choices_changed.emit(_current_choices.duplicate(true))
		"Jump":
			var target := String(node.get("jumpTargetNodeId", ""))
			if target.is_empty():
				_emit_error("Jump node has empty jumpTargetNodeId: %s" % node_id)
				return
			var leave_check := _execute_exit_actions(node_id)
			if not leave_check.get("ok", false):
				_emit_error(String(leave_check.get("error", "Unknown jump exit action error")))
				return
			_enter_node(target)
		"End":
			_finish()
		_:
			_emit_error("Unsupported nodeType in MVP: %s" % node_type)

func _move_to_next_by_edges(source_node_id: String) -> void:
	var edges: Array = _out_edges.get(source_node_id, [])
	if edges.is_empty():
		_finish()
		return

	var filtered: Array = []
	for e in edges:
		var condition_check := _condition_true(e.get("condition", {}))
		if not condition_check.get("ok", false):
			_emit_error("Edge condition failed from %s to %s: %s" % [
				source_node_id,
				String(e.get("targetNodeId", "")),
				String(condition_check.get("error", "unknown"))
			])
			return
		if bool(condition_check.get("value", false)):
			filtered.append(e)

	if filtered.is_empty():
		_finish()
		return

	filtered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("priority", 0)) < int(b.get("priority", 0))
	)

	var target := String(filtered[0].get("targetNodeId", ""))
	if target.is_empty():
		_emit_error("Resolved edge has empty targetNodeId")
		return

	_enter_node(target)

func _advance_multi_dialogue(node: Dictionary) -> void:
	var lines: Array = node.get("multiDialogue", {}).get("lines", [])
	if lines.is_empty():
		_emit_error("MultiDialogue node has no lines: %s" % _current_node_id)
		return

	if _current_line_index < lines.size() - 1:
		_current_line_index += 1
		var emit_check := _emit_multi_dialogue_line(node)
		if not emit_check.get("ok", false):
			_emit_error(String(emit_check.get("error", "Unknown MultiDialogue error")))
		return

	var leave_check := _execute_exit_actions(_current_node_id)
	if not leave_check.get("ok", false):
		_emit_error(String(leave_check.get("error", "Unknown exit action error")))
		return
	_move_to_next_by_edges(_current_node_id)

func _emit_multi_dialogue_line(node: Dictionary) -> Dictionary:
	var node_id := String(node.get("nodeId", ""))
	var multi_dialogue: Dictionary = node.get("multiDialogue", {})
	var lines: Array = multi_dialogue.get("lines", [])
	if lines.is_empty():
		return {"ok": false, "error": "MultiDialogue node has no lines: %s" % node_id}
	if _current_line_index < 0 or _current_line_index >= lines.size():
		return {"ok": false, "error": "MultiDialogue line index out of range on node %s: %d" % [node_id, _current_line_index]}

	var line: Dictionary = lines[_current_line_index]
	line_changed.emit({
		"nodeId": node_id,
		"lineIndex": _current_line_index,
		"speakerId": String(multi_dialogue.get("speakerId", "")),
		"textKey": String(line.get("textKey", ""))
	})
	return {"ok": true, "error": ""}

func _initialize_variables() -> Dictionary:
	_variable_defs.clear()
	_variables.clear()

	for v in _story.get("variables", []):
		var variable: Dictionary = v
		var name := String(variable.get("name", ""))
		var type_name := _normalize_variable_type(String(variable.get("type", "")))
		if type_name.is_empty():
			return {"ok": false, "error": "Unsupported variable type for %s: %s" % [name, String(variable.get("type", ""))]}

		var parsed := _parse_value_for_type(variable.get("defaultValue", null), type_name)
		if not parsed.get("ok", false):
			return {"ok": false, "error": "Invalid defaultValue for %s: %s" % [name, String(parsed.get("error", "unknown"))]}

		_variable_defs[name] = {
			"name": name,
			"type": type_name,
			"scope": String(variable.get("scope", "Session"))
		}
		_variables[name] = parsed.get("value")

	return {"ok": true, "error": ""}

func _get_available_choices(node: Dictionary) -> Dictionary:
	var out: Array = []
	var node_id := String(node.get("nodeId", ""))
	var exhausted_targets: Dictionary = _exhausted_choice_targets.get(node_id, {})
	var is_exhaustive := _choice_mode(node) == "ExhaustiveUntilComplete"

	for raw_choice in node.get("choices", []):
		var choice: Dictionary = raw_choice
		var target := String(choice.get("targetNodeId", ""))
		if is_exhaustive and exhausted_targets.has(target):
			continue
		var availability: Dictionary = choice.get("availability", {})
		var check := _condition_true(availability)
		if not check.get("ok", false):
			return {
				"ok": false,
				"choices": [],
				"error": "Choice availability failed on node %s: %s" % [node_id, String(check.get("error", "unknown"))]
			}
		if bool(check.get("value", false)):
			out.append(choice)

	return {"ok": true, "choices": out, "error": ""}

func _choice_mode(node: Dictionary) -> String:
	return String(node.get("choiceMode", "SinglePass"))

func _mark_exhaustive_choice_selected(source_node_id: String, target_node_id: String) -> void:
	if not _node_by_id.has(source_node_id):
		return
	var node: Dictionary = _node_by_id[source_node_id]
	if String(node.get("nodeType", "")) != "Choice":
		return
	if _choice_mode(node) != "ExhaustiveUntilComplete":
		return
	if not _exhausted_choice_targets.has(source_node_id):
		_exhausted_choice_targets[source_node_id] = {}
	var exhausted_targets: Dictionary = _exhausted_choice_targets[source_node_id]
	exhausted_targets[target_node_id] = true

func _push_exhaustive_choice_frame(source_node_id: String) -> void:
	if not _node_by_id.has(source_node_id):
		return
	var node: Dictionary = _node_by_id[source_node_id]
	if String(node.get("nodeType", "")) != "Choice":
		return
	if _choice_mode(node) != "ExhaustiveUntilComplete":
		return
	if not _exhaustive_choice_stack.is_empty() and _exhaustive_choice_stack.back() == source_node_id:
		return
	_exhaustive_choice_stack.append(source_node_id)

func _pop_exhaustive_choice_frame(choice_node_id: String) -> void:
	for i in range(_exhaustive_choice_stack.size() - 1, -1, -1):
		if _exhaustive_choice_stack[i] == choice_node_id:
			_exhaustive_choice_stack.remove_at(i)
			return

func _return_to_exhaustive_choice_if_needed() -> bool:
	if _exhaustive_choice_stack.is_empty():
		return false
	var choice_node_id := String(_exhaustive_choice_stack.back())
	if not _node_by_id.has(choice_node_id):
		_exhaustive_choice_stack.pop_back()
		return false
	_state = STATE_RUNNING
	_current_choices.clear()
	_enter_node(choice_node_id)
	return true

func _condition_true(condition: Dictionary) -> Dictionary:
	if condition.is_empty():
		return {"ok": true, "value": true, "error": ""}

	var logic := String(condition.get("logic", "All"))
	if logic != "All":
		return {"ok": false, "value": false, "error": "Unsupported condition logic: %s" % logic}

	var terms: Array = condition.get("terms", [])
	if terms.is_empty():
		return {"ok": true, "value": true, "error": ""}

	for raw_term in terms:
		var term: Dictionary = raw_term
		var term_check := _condition_term_true(term)
		if not term_check.get("ok", false):
			return term_check
		if not bool(term_check.get("value", false)):
			return {"ok": true, "value": false, "error": ""}

	return {"ok": true, "value": true, "error": ""}

func _condition_term_true(term: Dictionary) -> Dictionary:
	var variable_ref: Dictionary = term.get("variable", {})
	var name := String(variable_ref.get("name", ""))
	if name.is_empty():
		return {"ok": false, "value": false, "error": "Condition term has empty variable name"}
	if not _variable_defs.has(name):
		return {"ok": false, "value": false, "error": "Condition variable not defined: %s" % name}

	var def: Dictionary = _variable_defs[name]
	var type_name := String(def.get("type", ""))
	var ref_type := _normalize_variable_type(String(variable_ref.get("type", type_name)))
	if ref_type != type_name:
		return {
			"ok": false,
			"value": false,
			"error": "Condition variable type mismatch for %s: expected %s got %s" % [name, type_name, ref_type]
		}

	var right := _parse_value_for_type(term.get("compareValue", null), type_name)
	if not right.get("ok", false):
		return {"ok": false, "value": false, "error": "Invalid compareValue for %s: %s" % [name, String(right.get("error", "unknown"))]}

	var op := String(term.get("operator", ""))
	var left_value = _variables.get(name)
	var right_value = right.get("value")
	var compare := _compare_values(left_value, right_value, type_name, op)
	if not compare.get("ok", false):
		return compare

	return {"ok": true, "value": compare.get("value", false), "error": ""}

func _normalize_variable_type(type_name: String) -> String:
	match type_name:
		"Bool", "Int", "Float", "String":
			return type_name
		_:
			return ""

func _parse_value_for_type(raw_value, type_name: String) -> Dictionary:
	if raw_value == null:
		match type_name:
			"Bool":
				return {"ok": true, "value": false, "error": ""}
			"Int":
				return {"ok": true, "value": 0, "error": ""}
			"Float":
				return {"ok": true, "value": 0.0, "error": ""}
			"String":
				return {"ok": true, "value": "", "error": ""}

	match type_name:
		"Bool":
			if typeof(raw_value) == TYPE_BOOL:
				return {"ok": true, "value": raw_value, "error": ""}
			var bool_text := String(raw_value).to_lower()
			if bool_text == "true":
				return {"ok": true, "value": true, "error": ""}
			if bool_text == "false":
				return {"ok": true, "value": false, "error": ""}
			return {"ok": false, "value": false, "error": "Expected Bool but got %s" % String(raw_value)}
		"Int":
			if typeof(raw_value) == TYPE_INT:
				return {"ok": true, "value": raw_value, "error": ""}
			var int_text := String(raw_value)
			if int_text.is_valid_int():
				return {"ok": true, "value": int(int_text), "error": ""}
			return {"ok": false, "value": 0, "error": "Expected Int but got %s" % String(raw_value)}
		"Float":
			if typeof(raw_value) == TYPE_FLOAT or typeof(raw_value) == TYPE_INT:
				return {"ok": true, "value": float(raw_value), "error": ""}
			var float_text := String(raw_value)
			if float_text.is_valid_float():
				return {"ok": true, "value": float(float_text), "error": ""}
			return {"ok": false, "value": 0.0, "error": "Expected Float but got %s" % String(raw_value)}
		"String":
			return {"ok": true, "value": String(raw_value), "error": ""}

	return {"ok": false, "value": null, "error": "Unsupported variable type: %s" % type_name}

func _compare_values(left_value, right_value, type_name: String, op: String) -> Dictionary:
	match type_name:
		"Bool":
			return _compare_ordered(int(bool(left_value)), int(bool(right_value)), op)
		"Int":
			return _compare_ordered(int(left_value), int(right_value), op)
		"Float":
			return _compare_ordered(float(left_value), float(right_value), op)
		"String":
			var string_order := String(left_value).casecmp_to(String(right_value))
			return _compare_ordered(string_order, 0, op)

	return {
		"ok": false,
		"value": false,
		"error": "Unsupported operator for %s: %s" % [type_name, op]
	}

func _compare_ordered(left_value, right_value, op: String) -> Dictionary:
	match op:
		"==":
			return {"ok": true, "value": left_value == right_value, "error": ""}
		"!=":
			return {"ok": true, "value": left_value != right_value, "error": ""}
		">":
			return {"ok": true, "value": left_value > right_value, "error": ""}
		">=":
			return {"ok": true, "value": left_value >= right_value, "error": ""}
		"<":
			return {"ok": true, "value": left_value < right_value, "error": ""}
		"<=":
			return {"ok": true, "value": left_value <= right_value, "error": ""}
		_:
			return {"ok": false, "value": false, "error": "Unsupported operator: %s" % op}

func _execute_exit_actions(node_id: String) -> Dictionary:
	if not _node_by_id.has(node_id):
		return {"ok": false, "error": "Cannot execute exit actions for missing node: %s" % node_id}
	var node: Dictionary = _node_by_id[node_id]
	return _execute_actions(node.get("exitActions", []), "exit", node_id)

func _execute_actions(actions: Array, phase: String, node_id: String) -> Dictionary:
	for raw_action in actions:
		var action: Dictionary = raw_action
		var result := _execute_action(action, phase, node_id)
		if not result.get("ok", false):
			return result
	return {"ok": true, "error": ""}

func _execute_action(action: Dictionary, phase: String, node_id: String) -> Dictionary:
	var action_type := String(action.get("actionType", ""))
	match action_type:
		"Set":
			return _execute_variable_action(action, phase, node_id, action_type)
		"Add":
			return _execute_variable_action(action, phase, node_id, action_type)
		"Subtract":
			return _execute_variable_action(action, phase, node_id, action_type)
		"EmitEvent":
			return _execute_emit_event_action(action, phase, node_id)
		_:
			return {
				"ok": false,
				"error": "Unsupported actionType on node %s: %s" % [node_id, action_type]
			}

func _execute_variable_action(action: Dictionary, phase: String, node_id: String, action_type: String) -> Dictionary:
	var variable_ref: Dictionary = action.get("variable", {})
	var name := String(variable_ref.get("name", ""))
	if name.is_empty():
		return {"ok": false, "error": "%s action has empty variable name on node %s" % [action_type, node_id]}
	if not _variable_defs.has(name):
		return {"ok": false, "error": "%s action references undefined variable on node %s: %s" % [action_type, node_id, name]}

	var def: Dictionary = _variable_defs[name]
	var type_name := String(def.get("type", ""))
	var ref_type := _normalize_variable_type(String(variable_ref.get("type", type_name)))
	if ref_type != type_name:
		return {
			"ok": false,
			"error": "%s action variable type mismatch for %s on node %s: expected %s got %s" % [
				action_type,
				name,
				node_id,
				type_name,
				ref_type
			]
		}

	var parsed := _parse_value_for_type(action.get("value", null), type_name)
	if not parsed.get("ok", false):
		return {
			"ok": false,
			"error": "Invalid %s action value for %s on node %s: %s" % [
				action_type,
				name,
				node_id,
				String(parsed.get("error", "unknown"))
			]
		}

	var old_value = _variables.get(name)
	var operand = parsed.get("value")
	var new_value = old_value
	match action_type:
		"Set":
			new_value = operand
		"Add":
			if type_name != "Int" and type_name != "Float":
				return {"ok": false, "error": "Add action only supports Int/Float variables: %s" % name}
			new_value = old_value + operand
		"Subtract":
			if type_name != "Int" and type_name != "Float":
				return {"ok": false, "error": "Subtract action only supports Int/Float variables: %s" % name}
			new_value = old_value - operand

	_variables[name] = new_value
	var payload := {
		"nodeId": node_id,
		"phase": phase,
		"actionType": action_type,
		"name": name,
		"type": type_name,
		"oldValue": old_value,
		"newValue": new_value
	}
	variable_changed.emit(payload)
	return {"ok": true, "error": ""}

func _execute_emit_event_action(action: Dictionary, phase: String, node_id: String) -> Dictionary:
	var event_id := String(action.get("eventId", ""))
	if event_id.is_empty():
		return {"ok": false, "error": "EmitEvent action has empty eventId on node %s" % node_id}

	var payload := {
		"nodeId": node_id,
		"phase": phase,
		"eventId": event_id
	}
	_emitted_events.append(payload)
	event_emitted.emit(payload)
	return {"ok": true, "error": ""}

func _finish() -> void:
	if _return_to_exhaustive_choice_if_needed():
		return
	_state = STATE_ENDED
	_current_choices.clear()
	ended.emit()

func _emit_error(message: String) -> void:
	_state = STATE_ENDED
	error_raised.emit(message)
