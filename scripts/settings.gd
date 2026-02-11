class_name TetrixSettings
extends RefCounted

const CONFIG_PATH := "user://tetrix.json"
const OBFUSCATION_CONSTANT: int = 0x9E3779B9

static func load_settings() -> Dictionary:
	var settings := {
		"high_score": 0,
		"music_enabled": true,
		"is_fullscreen": false,
	}
	if not FileAccess.file_exists(CONFIG_PATH):
		return settings

	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return settings

	var content := file.get_as_text()
	var parsed: Variant = JSON.parse_string(content)
	if typeof(parsed) != TYPE_DICTIONARY:
		return settings

	var data: Dictionary = parsed
	if data.has("highScore"):
		var value: Variant = data["highScore"]
		if typeof(value) == TYPE_STRING:
			settings["high_score"] = _deobfuscate_high_score(value)
		elif typeof(value) == TYPE_INT:
			settings["high_score"] = value
	if data.has("musicEnabled") and typeof(data["musicEnabled"]) == TYPE_BOOL:
		settings["music_enabled"] = data["musicEnabled"]
	if data.has("isFullscreen") and typeof(data["isFullscreen"]) == TYPE_BOOL:
		settings["is_fullscreen"] = data["isFullscreen"]
	return settings

static func save_settings(high_score: int, music_enabled: bool, is_fullscreen: bool) -> void:
	var payload := {
		"highScore": _obfuscate_high_score(high_score),
		"musicEnabled": music_enabled,
		"isFullscreen": is_fullscreen,
	}
	var file := FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(payload))

static func _obfuscate_high_score(score: int) -> String:
	var obfuscated := (score + OBFUSCATION_CONSTANT) & 0xFFFFFFFF
	return "HS%d" % obfuscated

static func _deobfuscate_high_score(encoded: String) -> int:
	if encoded.begins_with("HS"):
		var value := encoded.substr(2).to_int()
		return int((value - OBFUSCATION_CONSTANT) & 0xFFFFFFFF)
	return encoded.to_int()
