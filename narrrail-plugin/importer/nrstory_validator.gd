class_name NarrRailStoryValidator
extends RefCounted

# Diagnostic shape:
# {
#   severity: "error" | "warning",
#   code: String,
#   path: String,
#   message: String
# }

static func validate_story(story: Dictionary) -> Array:
	var diagnostics: Array = []

	var nodes: Array = story.get("nodes", [])
	var edges: Array = story.get("edges", [])
	var meta: Dictionary = story.get("meta", {})

	# Collect node ids
	var node_ids: Dictionary = {}
	for i in range(nodes.size()):
		var node: Dictionary = nodes[i]
		var node_id := String(node.get("nodeId", ""))
		if node_id.is_empty():
			diagnostics.append(_diag("error", "NODE_ID_EMPTY", "nodes[%d].nodeId" % i, "nodeId must not be empty"))
			continue
		if node_ids.has(node_id):
			diagnostics.append(_diag("error", "NODE_ID_DUPLICATE", "nodes[%d].nodeId" % i, "Duplicate nodeId: %s" % node_id))
		else:
			node_ids[node_id] = true

	# entryNodeId existence
	var entry_id := String(meta.get("entryNodeId", ""))
	if not entry_id.is_empty() and not node_ids.has(entry_id):
		diagnostics.append(_diag("error", "ENTRY_NOT_FOUND", "meta.entryNodeId", "entryNodeId not found in nodes: %s" % entry_id))

	# Edge refs
	for i in range(edges.size()):
		var edge: Dictionary = edges[i]
		var s := String(edge.get("sourceNodeId", ""))
		var t := String(edge.get("targetNodeId", ""))
		if s.is_empty():
			diagnostics.append(_diag("error", "EDGE_SOURCE_EMPTY", "edges[%d].sourceNodeId" % i, "sourceNodeId must not be empty"))
		elif not node_ids.has(s):
			diagnostics.append(_diag("error", "EDGE_SOURCE_NOT_FOUND", "edges[%d].sourceNodeId" % i, "sourceNodeId not found: %s" % s))
		if t.is_empty():
			diagnostics.append(_diag("error", "EDGE_TARGET_EMPTY", "edges[%d].targetNodeId" % i, "targetNodeId must not be empty"))
		elif not node_ids.has(t):
			diagnostics.append(_diag("error", "EDGE_TARGET_NOT_FOUND", "edges[%d].targetNodeId" % i, "targetNodeId not found: %s" % t))

	# Choice target refs
	for i in range(nodes.size()):
		var node: Dictionary = nodes[i]
		if String(node.get("nodeType", "")) != "Choice":
			continue
		var choices: Array = node.get("choices", [])
		for j in range(choices.size()):
			var choice: Dictionary = choices[j]
			var target := String(choice.get("targetNodeId", ""))
			if target.is_empty():
				diagnostics.append(_diag("error", "CHOICE_TARGET_EMPTY", "nodes[%d].choices[%d].targetNodeId" % [i, j], "Choice targetNodeId must not be empty"))
			elif not node_ids.has(target):
				diagnostics.append(_diag("error", "CHOICE_TARGET_NOT_FOUND", "nodes[%d].choices[%d].targetNodeId" % [i, j], "Choice target not found: %s" % target))

	# Orphan node warning (exclude entry)
	var incoming: Dictionary = {}
	for edge in edges:
		var t := String((edge as Dictionary).get("targetNodeId", ""))
		if not t.is_empty():
			incoming[t] = true

	for i in range(nodes.size()):
		var node: Dictionary = nodes[i]
		var node_id := String(node.get("nodeId", ""))
		if node_id.is_empty() or node_id == entry_id:
			continue
		if not incoming.has(node_id):
			diagnostics.append(_diag("warning", "NODE_ORPHAN", "nodes[%d].nodeId" % i, "Orphan node (no incoming edge): %s" % node_id))

	return diagnostics

static func _diag(severity: String, code: String, path: String, message: String) -> Dictionary:
	return {
		"severity": severity,
		"code": code,
		"path": path,
		"message": message
	}

static func has_errors(diagnostics: Array) -> bool:
	for d in diagnostics:
		if String((d as Dictionary).get("severity", "")) == "error":
			return true
	return false
