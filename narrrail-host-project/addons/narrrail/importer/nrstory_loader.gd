class_name NarrRailStoryLoader
extends RefCounted

# Loader strategy:
# 1) Try YAML-like parser (for .nrstory spec)
# 2) Fallback to JSON parser (for backward compatibility in early MVP files)
#
# Return shape:
# { ok: bool, story: Dictionary, error: String }

class _YamlParser:
	var _lines: Array = []
	var _index: int = 0

	func parse(text: String) -> Dictionary:
		_lines = _preprocess(text)
		_index = 0
		if _lines.is_empty():
			return {}
		var root = _parse_block(0)
		if typeof(root) != TYPE_DICTIONARY:
			return {}
		return root

	func _preprocess(text: String) -> Array:
		var out: Array = []
		for raw in text.split("\n"):
			var line := String(raw).replace("\r", "")
			var trimmed := line.strip_edges()
			if trimmed.is_empty():
				continue
			if trimmed.begins_with("#"):
				continue
			out.append(line)
		return out

	func _indent_of(line: String) -> int:
		var n := 0
		while n < line.length() and line[n] == " ":
			n += 1
		return n

	func _trim_comment(s: String) -> String:
		var p := s.find(" #")
		if p >= 0:
			return s.substr(0, p)
		return s

	func _parse_block(indent: int):
		if _index >= _lines.size():
			return {}
		var line: String = _lines[_index]
		if _indent_of(line) < indent:
			return {}
		var content := line.substr(indent).strip_edges()
		if content.begins_with("- "):
			return _parse_array(indent)
		return _parse_map(indent)

	func _parse_map(indent: int) -> Dictionary:
		var obj: Dictionary = {}
		while _index < _lines.size():
			var line: String = _lines[_index]
			var line_indent := _indent_of(line)
			if line_indent < indent:
				break
			if line_indent > indent:
				# malformed indentation for map key line, stop this block
				break

			var content := _trim_comment(line.substr(indent).strip_edges())
			if content.begins_with("- "):
				break

			var sep := content.find(":")
			if sep < 0:
				_index += 1
				continue

			var key := content.substr(0, sep).strip_edges()
			var rest := content.substr(sep + 1).strip_edges()
			_index += 1

			if rest.is_empty():
				if _index < _lines.size() and _indent_of(_lines[_index]) > indent:
					obj[key] = _parse_block(indent + 2)
				else:
					obj[key] = {}
			else:
				obj[key] = _parse_scalar(rest)
		return obj

	func _parse_array(indent: int) -> Array:
		var arr: Array = []
		while _index < _lines.size():
			var line: String = _lines[_index]
			var line_indent := _indent_of(line)
			if line_indent < indent:
				break
			if line_indent != indent:
				# part of previous item's nested block or malformed; leave to caller
				break

			var content := _trim_comment(line.substr(indent).strip_edges())
			if not content.begins_with("- "):
				break

			var item_head := content.substr(2).strip_edges()
			_index += 1

			# Case A: "-" followed by nested block
			if item_head.is_empty():
				if _index < _lines.size() and _indent_of(_lines[_index]) > indent:
					arr.append(_parse_block(indent + 2))
				else:
					arr.append(null)
				continue

			# Case B: inline map head: "- key: value"
			var sep := item_head.find(":")
			if sep >= 0:
				var key := item_head.substr(0, sep).strip_edges()
				var rest := item_head.substr(sep + 1).strip_edges()
				var item_obj: Dictionary = {}
				if rest.is_empty():
					if _index < _lines.size() and _indent_of(_lines[_index]) > indent:
						item_obj[key] = _parse_block(indent + 4)
					else:
						item_obj[key] = {}
				else:
					item_obj[key] = _parse_scalar(rest)

				# Parse additional same-level fields for this item (indent + 2)
				while _index < _lines.size():
					var nline: String = _lines[_index]
					var nindent := _indent_of(nline)
					if nindent <= indent:
						break
					if nindent != indent + 2:
						break
					var ncontent := _trim_comment(nline.substr(nindent).strip_edges())
					if ncontent.begins_with("- "):
						break
					var nsep := ncontent.find(":")
					if nsep < 0:
						_index += 1
						continue
					var nkey := ncontent.substr(0, nsep).strip_edges()
					var nrest := ncontent.substr(nsep + 1).strip_edges()
					_index += 1
					if nrest.is_empty():
						if _index < _lines.size() and _indent_of(_lines[_index]) > nindent:
							item_obj[nkey] = _parse_block(nindent + 2)
						else:
							item_obj[nkey] = {}
					else:
						item_obj[nkey] = _parse_scalar(nrest)
				arr.append(item_obj)
				continue

			# Case C: scalar item
			arr.append(_parse_scalar(item_head))
		return arr

	func _parse_scalar(raw: String):
		var s := raw.strip_edges()
		if s == "[]":
			return []
		if s == "{}":
			return {}
		if s == "null" or s == "~":
			return null
		if s == "true":
			return true
		if s == "false":
			return false

		# quoted string
		if s.length() >= 2:
			if (s.begins_with("\"") and s.ends_with("\"")) or (s.begins_with("'") and s.ends_with("'")):
				return s.substr(1, s.length() - 2)

		# number
		if s.is_valid_int():
			return int(s)
		if s.is_valid_float():
			return float(s)

		return s

static func load_story(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {
			"ok": false,
			"story": {},
			"error": "Story file not found: %s" % path
		}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {
			"ok": false,
			"story": {},
			"error": "Failed to open story file: %s" % path
		}

	var content := file.get_as_text()
	file.close()

	# Try YAML-like parser first
	var yaml_parser := _YamlParser.new()
	var yaml_data = yaml_parser.parse(content)
	if typeof(yaml_data) == TYPE_DICTIONARY and not yaml_data.is_empty():
		return {
			"ok": true,
			"story": yaml_data,
			"error": ""
		}

	# Fallback to JSON
	var json := JSON.new()
	var parse_err := json.parse(content)
	if parse_err != OK:
		return {
			"ok": false,
			"story": {},
			"error": "Failed to parse .nrstory as YAML/JSON. json_line=%d json_message=%s" % [json.get_error_line(), json.get_error_message()]
		}

	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		return {
			"ok": false,
			"story": {},
			"error": "Parsed story root is not an object/dictionary"
		}

	return {
		"ok": true,
		"story": data,
		"error": ""
	}
