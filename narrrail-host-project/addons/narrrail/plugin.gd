@tool
extends EditorPlugin

var _importer: EditorImportPlugin

func _enter_tree() -> void:
	var importer_script: Script = load("res://addons/narrrail/importer/nrstory_import_plugin.gd")
	if importer_script == null:
		push_error("[NarrRail] Failed to load import plugin script")
		return
	_importer = importer_script.new()
	add_import_plugin(_importer)
	print("[NarrRail] Plugin enabled")

func _exit_tree() -> void:
	if _importer != null:
		remove_import_plugin(_importer)
		_importer = null
	print("[NarrRail] Plugin disabled")
