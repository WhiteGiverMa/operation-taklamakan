extends Control

signal resume_requested
signal settings_requested
signal main_menu_requested

@onready var title_label: Label = $Backdrop/Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var resume_button: Button = $Backdrop/Panel/MarginContainer/VBoxContainer/ResumeButton
@onready var settings_button: Button = $Backdrop/Panel/MarginContainer/VBoxContainer/SettingsButton
@onready var main_menu_button: Button = $Backdrop/Panel/MarginContainer/VBoxContainer/MainMenuButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	resume_button.pressed.connect(func() -> void: resume_requested.emit())
	settings_button.pressed.connect(func() -> void: settings_requested.emit())
	main_menu_button.pressed.connect(func() -> void: main_menu_requested.emit())
	if not Localization.language_changed.is_connected(_on_language_changed):
		Localization.language_changed.connect(_on_language_changed)
	_apply_localization()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		resume_requested.emit()
		get_viewport().set_input_as_handled()

func _on_language_changed(_locale: String) -> void:
	_apply_localization()

func _apply_localization() -> void:
	title_label.text = Localization.t("pause.title")
	resume_button.text = Localization.t("common.resume")
	settings_button.text = Localization.t("common.settings")
	main_menu_button.text = Localization.t("common.main_menu")
