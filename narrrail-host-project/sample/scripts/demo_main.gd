extends Node

const SESSION_SCRIPT := "res://addons/narrrail/runtime/narrrail_session.gd"

var _session: RefCounted

func _ready() -> void:
	var session_script: Script = load(SESSION_SCRIPT)
	if session_script == null:
		push_error("Failed to load NarrRailSession script at: %s" % SESSION_SCRIPT)
		return

	_session = session_script.new()
	_session.line_changed.connect(_on_line_changed)
	_session.choices_changed.connect(_on_choices_changed)
	_session.ended.connect(_on_ended)
	_session.error_raised.connect(_on_error)

	var story := {
		"meta": {
			"schemaVersion": 1,
			"storyId": "demo",
			"entryNodeId": "N_Start"
		},
		"nodes": [
			{
				"nodeId": "N_Start",
				"nodeType": "Dialogue",
				"dialogue": {"speakerId": "Hero", "textKey": "line_start"}
			},
			{
				"nodeId": "N_Choice",
				"nodeType": "Choice",
				"choices": [
					{"textKey": "option_yes", "targetNodeId": "N_Yes"},
					{"textKey": "option_no", "targetNodeId": "N_No"}
				]
			},
			{
				"nodeId": "N_Yes",
				"nodeType": "Dialogue",
				"dialogue": {"speakerId": "Hero", "textKey": "line_yes"}
			},
			{
				"nodeId": "N_No",
				"nodeType": "Dialogue",
				"dialogue": {"speakerId": "Hero", "textKey": "line_no"}
			},
			{
				"nodeId": "N_End",
				"nodeType": "End"
			}
		],
		"edges": [
			{"sourceNodeId": "N_Start", "targetNodeId": "N_Choice", "priority": 0, "condition": {"logic": "All", "terms": []}},
			{"sourceNodeId": "N_Yes", "targetNodeId": "N_End", "priority": 0, "condition": {"logic": "All", "terms": []}},
			{"sourceNodeId": "N_No", "targetNodeId": "N_End", "priority": 0, "condition": {"logic": "All", "terms": []}}
		]
	}

	print("[Demo] start")
	_session.start(story)
	print("[Demo] next -> Choice")
	_session.next()
	print("[Demo] choose(0) -> Yes")
	_session.choose(0)
	print("[Demo] next -> End")
	_session.next()

func _on_line_changed(payload: Dictionary) -> void:
	print("[Demo] line_changed: ", payload)

func _on_choices_changed(choices: Array) -> void:
	print("[Demo] choices_changed: ", choices)

func _on_ended() -> void:
	print("[Demo] ended")

func _on_error(message: String) -> void:
	push_error("[Demo] error: %s" % message)
