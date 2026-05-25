class_name NarrRailStoryModel
extends RefCounted

static func validate_minimal(story: Dictionary) -> Dictionary:
	var errors: Array[String] = []

	for key in ["meta", "nodes", "edges"]:
		if not story.has(key):
			errors.append("Missing required root field: %s" % key)

	if errors.size() > 0:
		return {"ok": false, "errors": errors}

	var meta: Dictionary = story.get("meta", {})
	if not meta.has("entryNodeId"):
		errors.append("Missing meta.entryNodeId")

	var node_ids: Dictionary = {}
	for n in story.get("nodes", []):
		var node_id := String(n.get("nodeId", ""))
		if node_id.is_empty():
			errors.append("Node with empty nodeId")
			continue
		if node_ids.has(node_id):
			errors.append("Duplicate nodeId: %s" % node_id)
		else:
			node_ids[node_id] = true

	var entry_id := String(meta.get("entryNodeId", ""))
	if not entry_id.is_empty() and not node_ids.has(entry_id):
		errors.append("entryNodeId not found in nodes: %s" % entry_id)

	for e in story.get("edges", []):
		var s := String(e.get("sourceNodeId", ""))
		var t := String(e.get("targetNodeId", ""))
		if s.is_empty() or t.is_empty():
			errors.append("Edge has empty source/target")
			continue
		if not node_ids.has(s):
			errors.append("Edge source not found: %s" % s)
		if not node_ids.has(t):
			errors.append("Edge target not found: %s" % t)

	return {"ok": errors.is_empty(), "errors": errors}
