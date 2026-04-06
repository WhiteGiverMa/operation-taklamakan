extends Control

## Turret UI for mode display and fire control upgrade
## Note: This UI is a placeholder - turret mode/fire control not yet implemented

@export var turret: Turret = null

@onready var mode_label: Label = $VBoxContainer/ModeLabel
@onready var mode_button: Button = $VBoxContainer/ModeButton
@onready var upgrade_button: Button = $VBoxContainer/UpgradeButton

func _ready() -> void:
	_connect_localization()
	_update_ui()
	mode_button.pressed.connect(_on_mode_button_pressed)
	upgrade_button.pressed.connect(_on_upgrade_button_pressed)

func _connect_localization() -> void:
	if not Localization.language_changed.is_connected(_on_language_changed):
		Localization.language_changed.connect(_on_language_changed)

func _on_language_changed(_locale: String) -> void:
	_update_ui()

func _update_ui() -> void:
	if not turret:
		mode_label.text = Localization.t("turret_ui.mode.manual")
		mode_button.text = Localization.t("turret_ui.switch_to_auto")
		upgrade_button.text = Localization.t("turret_ui.fire_control_locked")
		upgrade_button.disabled = true
		return
	
	# Show manual/auto mode based on actual turret state
	if turret.is_manual_mode:
		mode_label.text = Localization.t("turret_ui.mode.manual")
		mode_button.text = Localization.t("turret_ui.switch_to_auto")
	else:
		mode_label.text = Localization.t("turret_ui.mode.auto")
		mode_button.text = Localization.t("turret_ui.switch_to_manual")
	
	upgrade_button.text = Localization.t("turret_ui.fire_control_locked")
	upgrade_button.disabled = true

func _on_mode_button_pressed() -> void:
	if turret:
		if turret.is_manual_mode:
			turret.exit_manual_mode()
		else:
			turret.enter_manual_mode()
	_update_ui()

func _on_upgrade_button_pressed() -> void:
	# Fire control upgrade not yet implemented
	pass

func set_turret(new_turret: Turret) -> void:
	turret = new_turret
	_update_ui()
