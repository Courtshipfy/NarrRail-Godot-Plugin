extends SceneTree

const SYNC_SCRIPT := "res://addons/narrrail/editor/story_repository_sync.gd"
const STORY_RESOURCE_LOADER_SCRIPT := "res://addons/narrrail/runtime/story_resource_loader.gd"
const SESSION_SCRIPT := "res://addons/narrrail/runtime/narrrail_session.gd"
const TARGET_ROOT := "res://tests/generated_sync"
const REPO_NAME := "story_repo_sync_fixture"

var _failures: Array[String] = []
var _repo_abs := ""

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_repo_abs = "%s/%s" % [OS.get_user_data_dir().replace("\\", "/"), REPO_NAME]
	_remove_tree_abs(_repo_abs)
	_remove_tree_abs(ProjectSettings.globalize_path(TARGET_ROOT))
	_create_fixture_repo()
	_create_stale_resource()

	var sync_script: Script = load(SYNC_SCRIPT)
	if sync_script == null:
		_failures.append("Failed to load sync script")
		_finish()
		return

	var report: Dictionary = sync_script.call("sync_repository", _repo_abs, TARGET_ROOT, {
		"pull_git": false,
		"delete_stale": true
	})
	_expect_equal("report failed", report.get("failed", -1), 0)
	_expect_equal("report created", report.get("created", -1), 4)
	_expect_equal("report deleted", report.get("deleted", -1), 1)

	var generated_root := "%s/%s" % [TARGET_ROOT, REPO_NAME]
	_expect_story("%s/main.tres" % generated_root, "sync_main", "%s/main.nrstory" % _repo_abs)
	_expect_story("%s/nested/branch.tres" % generated_root, "sync_branch", "%s/nested/branch.nrstory" % _repo_abs)
	_expect_story("%s/nested/global_ref.tres" % generated_root, "sync_global_ref", "%s/nested/global_ref.nrstory" % _repo_abs)
	_expect_global_config("%s/global_config.tres" % generated_root, "%s/global_config.nrstory" % _repo_abs)
	_expect_global_config_runtime("%s/nested/global_ref.tres" % generated_root)
	if ResourceLoader.exists("%s/deleted.tres" % generated_root):
		_failures.append("stale generated resource was not deleted")

	_remove_tree_abs(_repo_abs)
	_remove_tree_abs(ProjectSettings.globalize_path(TARGET_ROOT))
	_finish()

func _create_fixture_repo() -> void:
	DirAccess.make_dir_recursive_absolute("%s/nested" % _repo_abs)
	_write_file("%s/main.nrstory" % _repo_abs, _story_text("sync_main", "N_Start", "main_line"))
	_write_file("%s/nested/branch.nrstory" % _repo_abs, _story_text("sync_branch", "N_Branch", "branch_line"))
	_write_file("%s/nested/global_ref.nrstory" % _repo_abs, _global_ref_story_text())
	_write_file("%s/global_config.nrstory" % _repo_abs, """meta:
  schemaVersion: 1
  configType: GlobalConfig

variables:
  - name: Affinity
    type: Int
    scope: Session
    defaultValue: "0"

presetSpeakers:
  - speakerId: Hero
    displayName: Hero
""")

func _create_stale_resource() -> void:
	var global_config_script: Script = load("res://addons/narrrail/narrrail_global_config_resource.gd")
	if global_config_script == null:
		_failures.append("Failed to load global config resource script")
		return

	var stale_path := "%s/%s/deleted.tres" % [TARGET_ROOT, REPO_NAME]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(stale_path.get_base_dir()))
	var resource: Resource = global_config_script.new()
	resource.set("source_path", "%s/deleted.nrstory" % _repo_abs)
	var err := ResourceSaver.save(resource, stale_path)
	if err != OK:
		_failures.append("Failed to create stale resource: %s" % stale_path)

func _story_text(story_id: String, start_id: String, text_key: String) -> String:
	return """meta:
  schemaVersion: 1
  storyId: %s
  entryNodeId: %s

variables: []

nodes:
  - nodeId: %s
    nodeType: Dialogue
    dialogue:
      speakerId: Hero
      textKey: %s

  - nodeId: N_End
    nodeType: End

edges:
  - sourceNodeId: %s
    targetNodeId: N_End
    priority: 0
    condition:
      logic: All
      terms: []
""" % [story_id, start_id, start_id, text_key, start_id]

func _global_ref_story_text() -> String:
	return """meta:
  schemaVersion: 1
  storyId: sync_global_ref
  entryNodeId: N_Set

variables: []

nodes:
  - nodeId: N_Set
    nodeType: SetVariable
    actions:
      - actionType: Add
        variable:
          variableName: Affinity
          variableType: Int
        value: "1"

  - nodeId: N_Line
    nodeType: Dialogue
    dialogue:
      speakerId: Hero
      textKey: global_ref_line

  - nodeId: N_End
    nodeType: End

edges:
  - sourceNodeId: N_Set
    targetNodeId: N_Line
    priority: 0
    sourceHandle: ""

  - sourceNodeId: N_Line
    targetNodeId: N_End
    priority: 0
    sourceHandle: ""
"""

func _expect_story(path: String, story_id: String, source_path: String) -> void:
	var resource := ResourceLoader.load(path)
	if resource == null:
		_failures.append("Missing generated story resource: %s" % path)
		return
	_expect_equal("%s source_path" % path, String(resource.get("source_path")), source_path)
	var story: Dictionary = resource.get("story_data")
	_expect_equal("%s storyId" % path, String(story.get("meta", {}).get("storyId", "")), story_id)

func _expect_global_config(path: String, source_path: String) -> void:
	var resource := ResourceLoader.load(path)
	if resource == null:
		_failures.append("Missing generated global config resource: %s" % path)
		return
	_expect_equal("%s source_path" % path, String(resource.get("source_path")), source_path)
	_expect_equal("%s schema_version" % path, int(resource.get("schema_version")), 1)
	_expect_equal("%s variables" % path, resource.get("variables").size(), 1)
	_expect_equal("%s preset_speakers" % path, resource.get("preset_speakers").size(), 1)

func _expect_global_config_runtime(path: String) -> void:
	var loader_script: Script = load(STORY_RESOURCE_LOADER_SCRIPT)
	var session_script: Script = load(SESSION_SCRIPT)
	if loader_script == null or session_script == null:
		_failures.append("Failed to load runtime scripts for global config runtime check")
		return

	var result: Dictionary = loader_script.call("load_story", path)
	if not result.get("ok", false):
		_failures.append("Failed to load merged story resource: %s" % String(result.get("error", "unknown")))
		return
	var story: Dictionary = result.get("story", {})
	_expect_equal("merged global variables", story.get("variables", []).size(), 1)

	var session: RefCounted = session_script.new()
	var errors: Array = []
	session.error_raised.connect(func(message: String) -> void:
		errors.append(message)
	)
	session.start(story)
	session.next()
	_expect_equal("global config runtime errors", errors, [])
	_expect_equal("global config runtime variables", session.get_state().get("variables", {}), {"Affinity": 1})

func _write_file(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_failures.append("Failed to write fixture file: %s" % path)
		return
	file.store_string(content)
	file.close()

func _remove_tree_abs(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while not name.is_empty():
		var child := "%s/%s" % [path, name]
		if dir.current_is_dir():
			_remove_tree_abs(child)
		else:
			DirAccess.remove_absolute(child)
		name = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(path)

func _expect_equal(label: String, actual, expected) -> void:
	if actual != expected:
		_failures.append("%s expected=%s actual=%s" % [label, str(expected), str(actual)])

func _finish() -> void:
	if _failures.is_empty():
		print("[NarrRail][SyncRepository] PASS")
		quit(0)
	else:
		for failure in _failures:
			push_error("[NarrRail][SyncRepository] %s" % failure)
		quit(1)
