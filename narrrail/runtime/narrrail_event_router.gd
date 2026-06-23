class_name NarrRailEventRouter
extends RefCounted

signal event_handled(event_id: String, payload: Dictionary)
signal event_unhandled(event_id: String, payload: Dictionary)

var _handlers: Dictionary = {}

func register(event_id: String, handler: Callable) -> void:
	var normalized_id := event_id.strip_edges()
	if normalized_id.is_empty():
		push_error("[NarrRail] Cannot register an empty event id.")
		return
	if not handler.is_valid():
		push_error("[NarrRail] Cannot register invalid handler for event id: %s" % normalized_id)
		return
	_handlers[normalized_id] = handler

func unregister(event_id: String) -> void:
	_handlers.erase(event_id.strip_edges())

func clear() -> void:
	_handlers.clear()

func has_handler(event_id: String) -> bool:
	return _handlers.has(event_id.strip_edges())

func dispatch(payload: Dictionary) -> bool:
	var event_id := String(payload.get("eventId", "")).strip_edges()
	if event_id.is_empty() or not _handlers.has(event_id):
		event_unhandled.emit(event_id, payload)
		return false

	var handler: Callable = _handlers[event_id]
	if not handler.is_valid():
		event_unhandled.emit(event_id, payload)
		return false

	handler.call(payload)
	event_handled.emit(event_id, payload)
	return true
