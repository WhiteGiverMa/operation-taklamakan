class_name RunProgressWidget
extends Control

@onready var progress_label: Label = $ProgressLabel

var _chapter: int = 1
var _floor: int = 1
var _selected_floor: int = -1
var _current_wave: int = 0
var _total_waves: int = 0

func _ready() -> void:
	if not Localization.language_changed.is_connected(_on_language_changed):
		Localization.language_changed.connect(_on_language_changed)
	_refresh_display()

func set_progress_state(chapter: int, floor_number: int, selected_floor: int, current_wave: int, total_waves: int) -> void:
	_chapter = chapter
	_floor = floor_number
	_selected_floor = selected_floor
	_current_wave = current_wave
	_total_waves = total_waves
	_refresh_display()

func _on_language_changed(_locale: String) -> void:
	_refresh_display()

func _refresh_display() -> void:
	var parts: Array[String] = []
	parts.append(Localization.t("header.progress.chapter", "", {"chapter": _chapter}))

	var floor_to_show := _floor
	if _selected_floor > 0:
		floor_to_show = _selected_floor
		progress_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	else:
		progress_label.remove_theme_color_override("font_color")

	parts.append(Localization.t("header.progress.floor", "", {"floor": floor_to_show}))

	if _total_waves > 0:
		parts.append(Localization.t("header.progress.wave", "", {
			"current": _current_wave,
			"total": _total_waves,
		}))

	progress_label.text = " · ".join(parts)
