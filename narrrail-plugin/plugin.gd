@tool
extends EditorPlugin

func _enter_tree() -> void:
	print("[NarrRail] Plugin enabled")

func _exit_tree() -> void:
	print("[NarrRail] Plugin disabled")
