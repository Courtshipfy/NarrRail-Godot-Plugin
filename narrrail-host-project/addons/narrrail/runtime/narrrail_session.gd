class_name NarrRailSession
extends RefCounted

signal line_changed(payload: Dictionary)
signal choices_changed(choices: Array)
signal ended()
signal error_raised(message: String)

const STATE_IDLE := "idle"
const STATE_RUNNING := "running"
const STATE_WAITING_CHOICE := "waiting_choice"
const STATE_ENDED := "ended"

var _story: Dictionary = {}
var _node_by_id: Dictionary = {}
var _out_edges: Dictionary = {}
var _state: String = STATE_IDLE
var _current_node_id: String = ""
var _current_choices: Array = []

func start(story_data: Dictionary) -> void:
	var check := NarrRailStoryModel.validate_minimal(story_data)
	if not check.get("ok", false):
		_emit_error("Story validation failed: %s" % "; ".join(check.get("errors", [])))
		return

	_story = story_data
	_build_indexes()
	_state = STATE_RUNNING
	_current_choices.clear()

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
			_move_to_next_by_edges(_current_node_id)
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

	_current_choices.clear()
	_state = STATE_RUNNING
	_enter_node(target)

func get_state() -> Dictionary:
	return {
		"state": _state,
		"currentNodeId": _current_node_id,
		"choices": _current_choices.duplicate(true)
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
	var node: Dictionary = _node_by_id[node_id]
	var node_type := String(node.get("nodeType", ""))

	match node_type:
		"Dialogue":
			var dialogue: Dictionary = node.get("dialogue", {})
			line_changed.emit({
				"nodeId": node_id,
				"speakerId": String(dialogue.get("speakerId", "")),
				"textKey": String(dialogue.get("textKey", ""))
			})
		"Choice":
			var choices: Array = node.get("choices", [])
			_current_choices = choices.duplicate(true)
			_state = STATE_WAITING_CHOICE
			choices_changed.emit(_current_choices.duplicate(true))
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
		if _edge_condition_true(e):
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

func _edge_condition_true(edge: Dictionary) -> bool:
	var condition: Dictionary = edge.get("condition", {})
	var terms: Array = condition.get("terms", [])
	return terms.is_empty()

func _finish() -> void:
	_state = STATE_ENDED
	_current_choices.clear()
	ended.emit()

func _emit_error(message: String) -> void:
	_state = STATE_ENDED
	error_raised.emit(message)
