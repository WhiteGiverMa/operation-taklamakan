extends Control

## Wave intermission UI showing wave progress and intermission controls.
## Displays Continue, Repair, and Upgrade buttons between waves.

@onready var wave_label: Label = $Panel/VBoxContainer/WaveLabel
@onready var status_label: Label = $Panel/VBoxContainer/StatusLabel
@onready var timer_label: Label = $Panel/VBoxContainer/TimerLabel
@onready var enemy_info_label: Label = $Panel/VBoxContainer/EnemyInfoLabel
@onready var button_container: HBoxContainer = $Panel/VBoxContainer/ButtonContainer
@onready var continue_button: Button = $Panel/VBoxContainer/ButtonContainer/ContinueButton
@onready var repair_button: Button = $Panel/VBoxContainer/ButtonContainer/RepairButton
@onready var upgrade_button: Button = $Panel/VBoxContainer/ButtonContainer/UpgradeButton
@onready var wave_progress_bar: ProgressBar = $Panel/VBoxContainer/WaveProgressBar

var _wave_manager: Node = null
var _is_visible: bool = false

func _ready() -> void:
	_hide_ui()
	_find_wave_manager()
	_connect_signals()
	_connect_localization()
	_apply_localization()

func _process(_delta: float) -> void:
	if not _wave_manager:
		return
	
	_update_ui()

func _connect_signals() -> void:
	# Connect buttons
	continue_button.pressed.connect(_on_continue_pressed)
	repair_button.pressed.connect(_on_repair_pressed)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	
	# Connect to EventBus signals
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.wave_complete.connect(_on_wave_complete)
	EventBus.wave_all_complete.connect(_on_all_waves_complete)
	
	# Connect to WaveManager if available
	if _wave_manager:
		if not _wave_manager.intermission_started.is_connected(_on_intermission_started):
			_wave_manager.intermission_started.connect(_on_intermission_started)
		if not _wave_manager.intermission_ended.is_connected(_on_intermission_ended):
			_wave_manager.intermission_ended.connect(_on_intermission_ended)

func _connect_localization() -> void:
	if not Localization.language_changed.is_connected(_on_language_changed):
		Localization.language_changed.connect(_on_language_changed)

func _on_language_changed(_locale: String) -> void:
	_apply_localization()

func _find_wave_manager() -> void:
	_wave_manager = WaveManager

func _update_ui() -> void:
	if not _wave_manager:
		return
	
	var state = _wave_manager.get_state()
	
	match state:
		_wave_manager.State.BETWEEN_WAVES:
			if not _is_visible:
				_show_ui()
			_update_intermission_ui()
		_wave_manager.State.ACTIVE_WAVE:
			if _is_visible:
				_hide_ui()
		_wave_manager.State.COMPLETE:
			_show_completion_ui()

func _update_intermission_ui() -> void:
	var current_wave = _wave_manager.current_wave
	var total_waves = _wave_manager.total_waves
	
	wave_label.text = Localization.t("wave.ui.complete_title", "", {"wave": current_wave, "total": total_waves})
	status_label.text = Localization.t("wave.ui.intermission_status")
	
	var time_remaining = _wave_manager.get_intermission_time_remaining()
	timer_label.text = Localization.t("wave.ui.auto_continue", "", {"seconds": "%.1f" % time_remaining})
	
	# Get next wave info
	var next_wave_data = null
	if _wave_manager.wave_set and _wave_manager.wave_set.has_method("get_wave"):
		next_wave_data = _wave_manager.wave_set.get_wave(current_wave + 1)
	if next_wave_data and next_wave_data.has_method("get_enemy_counts"):
		var enemy_counts = next_wave_data.get_enemy_counts()
		enemy_info_label.text = Localization.t("wave.ui.next_wave_enemies", "", {
			"tanks": enemy_counts.get("tank", 0),
			"dogs": enemy_counts.get("mechanical_dog", 0),
			"bosses": enemy_counts.get("boss_tank", 0),
		})
	else:
		enemy_info_label.text = Localization.t("wave.ui.next_wave_unknown")
	
	# Update progress bar
	wave_progress_bar.value = float(current_wave) / float(total_waves) * 100.0

func _show_ui() -> void:
	visible = true
	_is_visible = true
	button_container.visible = true
	wave_progress_bar.visible = true
	
	# Enable all buttons
	continue_button.disabled = false
	repair_button.disabled = false
	upgrade_button.disabled = false

func _hide_ui() -> void:
	visible = false
	_is_visible = false

func _show_completion_ui() -> void:
	visible = true
	_is_visible = true
	button_container.visible = false
	wave_progress_bar.visible = false
	
	wave_label.text = Localization.t("wave.ui.all_complete")
	status_label.text = Localization.t("wave.ui.combat_finished")
	timer_label.text = ""
	enemy_info_label.text = Localization.t("wave.ui.victory")

func _apply_localization() -> void:
	continue_button.text = Localization.t("common.continue")
	repair_button.text = Localization.t("common.repair")
	upgrade_button.text = Localization.t("common.upgrade")
	if _wave_manager:
		_update_ui()

func _on_continue_pressed() -> void:
	if _wave_manager:
		_wave_manager.continue_to_next_wave()

func _on_repair_pressed() -> void:
	# Find the ship and heal it
	var ship = get_tree().get_first_node_in_group("ship")
	# health_component is a property, not a method - check if it exists
	if ship and "health_component" in ship and ship.health_component:
		var healed = ship.health_component.heal(100.0)  # Heal 100 HP
		if healed > 0:
			EventBus.ship_health_changed.emit(ship.health_component.current_health, ship.max_health)
	repair_button.disabled = true

func _on_upgrade_pressed() -> void:
	# Emit shop entered signal to show upgrade UI
	EventBus.shop_entered.emit()
	upgrade_button.disabled = true

func _on_wave_started(_wave_number: int) -> void:
	_hide_ui()

func _on_wave_complete(_wave_number: int) -> void:
	_show_ui()

func _on_all_waves_complete() -> void:
	_show_completion_ui()

func _on_intermission_started(_duration: float) -> void:
	_show_ui()

func _on_intermission_ended() -> void:
	_hide_ui()
