extends Control

signal continue_requested
signal new_game_requested
signal settings_requested

@onready var title_label: Label = $Backdrop/ContentPanel/MarginContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $Backdrop/ContentPanel/MarginContainer/VBoxContainer/SubtitleLabel
@onready var continue_button: Button = $Backdrop/ContentPanel/MarginContainer/VBoxContainer/ButtonContainer/ContinueButton
@onready var new_game_button: Button = $Backdrop/ContentPanel/MarginContainer/VBoxContainer/ButtonContainer/NewGameButton
@onready var settings_button: Button = $Backdrop/ContentPanel/MarginContainer/VBoxContainer/ButtonContainer/SettingsButton
@onready var quit_button: Button = $Backdrop/ContentPanel/MarginContainer/VBoxContainer/ButtonContainer/QuitButton
@onready var status_label: Label = $Backdrop/ContentPanel/MarginContainer/VBoxContainer/StatusLabel
@onready var new_game_dialog: ConfirmationDialog = $NewGameDialog

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	continue_button.pressed.connect(_on_continue_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	settings_button.pressed.connect(func() -> void: settings_requested.emit())
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	new_game_dialog.confirmed.connect(func() -> void: new_game_requested.emit())
	if not Localization.language_changed.is_connected(_on_language_changed):
		Localization.language_changed.connect(_on_language_changed)
	_apply_localization()
	refresh_state()

func refresh_state() -> void:
	var has_run := GameState.has_active_run
	continue_button.disabled = not has_run
	status_label.visible = not has_run
	status_label.text = Localization.t("menu.no_active_run")
	subtitle_label.text = Localization.t("menu.subtitle.active") if has_run else Localization.t("menu.subtitle.idle")

func _on_continue_pressed() -> void:
	if GameState.has_active_run:
		continue_requested.emit()

func _on_new_game_pressed() -> void:
	if GameState.has_active_run:
		new_game_dialog.title = Localization.t("menu.confirm_new_game.title")
		new_game_dialog.dialog_text = Localization.t("menu.confirm_new_game.body")
		new_game_dialog.get_ok_button().text = Localization.t("common.confirm")
		new_game_dialog.get_cancel_button().text = Localization.t("common.cancel")
		new_game_dialog.popup_centered()
		return
	new_game_requested.emit()

func _on_language_changed(_locale: String) -> void:
	_apply_localization()
	refresh_state()

func _apply_localization() -> void:
	title_label.text = Localization.t("menu.title")
	continue_button.text = Localization.t("menu.continue_game")
	new_game_button.text = Localization.t("menu.new_game")
	settings_button.text = Localization.t("common.settings")
	quit_button.text = Localization.t("common.quit")
