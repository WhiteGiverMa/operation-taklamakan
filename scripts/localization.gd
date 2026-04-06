extends Node

signal language_changed(locale: String)

const DEFAULT_LANGUAGE := "zh"
const SUPPORTED_LANGUAGES := ["zh", "en"]
const TRANSLATION_FILES := {
	"zh": "res://localization/zh.json",
	"en": "res://localization/en.json",
}

var _language: String = DEFAULT_LANGUAGE
var _translations: Dictionary = {}
var _fallback_translations: Dictionary = {}

func _ready() -> void:
	_fallback_translations = _load_language(DEFAULT_LANGUAGE)
	_translations = _fallback_translations
	_language = DEFAULT_LANGUAGE

func set_language(locale: String) -> void:
	var normalized := locale.to_lower()
	if not SUPPORTED_LANGUAGES.has(normalized):
		normalized = DEFAULT_LANGUAGE

	_language = normalized
	_translations = _load_language(normalized)
	language_changed.emit(_language)

func get_language() -> String:
	return _language

func t(key: String, fallback: String = "", params: Dictionary = {}) -> String:
	var raw_value: Variant = _translations.get(key)
	if raw_value == null:
		raw_value = _fallback_translations.get(key)
	if raw_value == null:
		raw_value = fallback if not fallback.is_empty() else key

	var text := str(raw_value)
	for param_key in params:
		text = text.replace("{%s}" % str(param_key), str(params[param_key]))
	return text

func _load_language(locale: String) -> Dictionary:
	var path: String = TRANSLATION_FILES.get(locale, "")
	if path.is_empty():
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Localization: failed to open translation file %s" % path)
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed == null:
		push_error("Localization: failed to parse translation file %s" % path)
		return {}
	if parsed is Dictionary:
		return parsed

	push_error("Localization: translation file %s must contain a dictionary" % path)
	return {}
