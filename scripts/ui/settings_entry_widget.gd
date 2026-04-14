class_name SettingsEntryWidget
extends Control

signal pressed

@onready var settings_button: Button = $SettingsButton

func _ready() -> void:
	settings_button.pressed.connect(_on_button_pressed)
	if not Localization.language_changed.is_connected(_on_language_changed):
		Localization.language_changed.connect(_on_language_changed)
	_apply_localization()

func _on_button_pressed() -> void:
	pressed.emit()

func _on_language_changed(_locale: String) -> void:
	_apply_localization()

func _apply_localization() -> void:
	settings_button.tooltip_text = Localization.t("header.settings.tooltip")
