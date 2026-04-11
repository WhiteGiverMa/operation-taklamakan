extends Control

signal back_requested

const LANGUAGE_OPTIONS := ["zh", "en"]

var _updating_ui := false

@onready var title_label: Label = $Backdrop/Panel/MarginContainer/VBoxContainer/Header/TitleLabel
@onready var language_label: Label = $Backdrop/Panel/MarginContainer/VBoxContainer/Content/LanguageRow/LanguageLabel
@onready var language_option: OptionButton = $Backdrop/Panel/MarginContainer/VBoxContainer/Content/LanguageRow/LanguageOption
@onready var display_section_label: Label = $Backdrop/Panel/MarginContainer/VBoxContainer/Content/DisplaySectionLabel
@onready var window_mode_label: Label = $Backdrop/Panel/MarginContainer/VBoxContainer/Content/WindowModeRow/WindowModeLabel
@onready var window_mode_option: OptionButton = $Backdrop/Panel/MarginContainer/VBoxContainer/Content/WindowModeRow/WindowModeOption
@onready var vsync_toggle: CheckButton = $Backdrop/Panel/MarginContainer/VBoxContainer/Content/VSyncRow/VSyncToggle
@onready var gameplay_section_label: Label = $Backdrop/Panel/MarginContainer/VBoxContainer/Content/GameplaySectionLabel
@onready var dev_mode_label: Label = $Backdrop/Panel/MarginContainer/VBoxContainer/Content/DevModeRow/DevModeLabel
@onready var dev_mode_toggle: CheckButton = $Backdrop/Panel/MarginContainer/VBoxContainer/Content/DevModeRow/DevModeToggle
@onready var manual_fire_mode_toggle: CheckButton = $Backdrop/Panel/MarginContainer/VBoxContainer/Content/ManualFireModeRow/ManualFireModeToggle
@onready var audio_section_label: Label = $Backdrop/Panel/MarginContainer/VBoxContainer/Content/AudioSectionLabel
@onready var master_volume_label: Label = $Backdrop/Panel/MarginContainer/VBoxContainer/Content/MasterVolumeRow/MasterVolumeLabel
@onready var master_volume_slider: HSlider = $Backdrop/Panel/MarginContainer/VBoxContainer/Content/MasterVolumeRow/MasterVolumeSlider
@onready var master_volume_value: Label = $Backdrop/Panel/MarginContainer/VBoxContainer/Content/MasterVolumeRow/MasterVolumeValue
@onready var back_button: Button = $Backdrop/Panel/MarginContainer/VBoxContainer/Footer/BackButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	master_volume_slider.min_value = 0.0
	master_volume_slider.max_value = 100.0
	master_volume_slider.step = 1.0
	language_option.item_selected.connect(_on_language_selected)
	window_mode_option.item_selected.connect(_on_window_mode_selected)
	vsync_toggle.toggled.connect(_on_vsync_toggled)
	dev_mode_toggle.toggled.connect(_on_dev_mode_toggled)
	manual_fire_mode_toggle.toggled.connect(_on_manual_fire_mode_toggled)
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	back_button.pressed.connect(func() -> void: back_requested.emit())
	if not Localization.language_changed.is_connected(_on_language_changed):
		Localization.language_changed.connect(_on_language_changed)
	if not SettingsManager.settings_changed.is_connected(_on_settings_changed):
		SettingsManager.settings_changed.connect(_on_settings_changed)
	_refresh_from_settings()
	_apply_localization()

func _process(_delta: float) -> void:
	if visible and InputManager.ui_back_action.is_triggered():
		back_requested.emit()

func _on_language_selected(index: int) -> void:
	if _updating_ui:
		return
	SettingsManager.set_language_setting(LANGUAGE_OPTIONS[index])

func _on_window_mode_selected(index: int) -> void:
	if _updating_ui:
		return
	SettingsManager.set_window_mode_setting(index)

func _on_vsync_toggled(toggled_on: bool) -> void:
	if _updating_ui:
		return
	SettingsManager.set_vsync_enabled_setting(toggled_on)

func _on_dev_mode_toggled(toggled_on: bool) -> void:
	if _updating_ui:
		return
	SettingsManager.set_dev_mode_enabled(toggled_on)

func _on_manual_fire_mode_toggled(toggled_on: bool) -> void:
	if _updating_ui:
		return
	SettingsManager.set_manual_fire_full_auto(toggled_on)

func _on_master_volume_changed(value: float) -> void:
	if _updating_ui:
		return
	SettingsManager.set_master_volume(value / 100.0)
	_update_volume_label()

func _on_language_changed(_locale: String) -> void:
	_refresh_from_settings()
	_apply_localization()

func _on_settings_changed() -> void:
	_refresh_from_settings()

func _refresh_from_settings() -> void:
	_updating_ui = true
	var language_index := LANGUAGE_OPTIONS.find(SettingsManager.language)
	language_option.selected = max(language_index, 0)
	window_mode_option.selected = int(SettingsManager.window_mode)
	vsync_toggle.button_pressed = SettingsManager.vsync_enabled
	dev_mode_toggle.button_pressed = SettingsManager.dev_mode_enabled
	manual_fire_mode_toggle.button_pressed = SettingsManager.manual_fire_full_auto
	master_volume_slider.value = round(SettingsManager.master_volume * 100.0)
	_update_volume_label()
	_updating_ui = false

func _apply_localization() -> void:
	title_label.text = Localization.t("settings.title")
	language_label.text = Localization.t("settings.language")
	display_section_label.text = Localization.t("settings.display_section")
	window_mode_label.text = Localization.t("settings.window_mode")
	vsync_toggle.text = Localization.t("settings.vsync")
	gameplay_section_label.text = Localization.t("settings.gameplay_section")
	dev_mode_label.text = "DevMode"
	dev_mode_toggle.text = ""
	manual_fire_mode_toggle.text = Localization.t("settings.manual_fire_full_auto")
	audio_section_label.text = Localization.t("settings.audio_section")
	back_button.text = Localization.t("common.back")
	_language_items()
	_window_mode_items()
	_refresh_from_settings()

func _language_items() -> void:
	language_option.clear()
	language_option.add_item(Localization.t("settings.language.zh"))
	language_option.add_item(Localization.t("settings.language.en"))

func _window_mode_items() -> void:
	window_mode_option.clear()
	window_mode_option.add_item(Localization.t("common.windowed"))
	window_mode_option.add_item(Localization.t("common.fullscreen"))

func _update_volume_label() -> void:
	var percent := int(round(master_volume_slider.value))
	master_volume_label.text = Localization.t("settings.master_volume")
	master_volume_value.text = "%d%%" % percent
