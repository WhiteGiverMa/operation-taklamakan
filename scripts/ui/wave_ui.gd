extends Control

## Wave intermission UI showing wave progress and intermission controls.
## Displays Continue, Repair, and upgrade preparation options between waves.

@onready var wave_label: Label = $Panel/VBoxContainer/WaveLabel
@onready var status_label: Label = $Panel/VBoxContainer/StatusLabel
@onready var timer_label: Label = $Panel/VBoxContainer/TimerLabel
@onready var enemy_info_label: Label = $Panel/VBoxContainer/EnemyInfoLabel
@onready var button_container: HBoxContainer = $Panel/VBoxContainer/ButtonContainer
@onready var continue_button: Button = $Panel/VBoxContainer/ButtonContainer/ContinueButton
@onready var repair_button: Button = $Panel/VBoxContainer/ButtonContainer/RepairButton
@onready var upgrade_button: Button = $Panel/VBoxContainer/ButtonContainer/UpgradeButton
@onready var wave_progress_bar: ProgressBar = $Panel/VBoxContainer/WaveProgressBar
@onready var upgrade_section: VBoxContainer = $Panel/VBoxContainer/UpgradeSection
@onready var upgrade_title_label: Label = $Panel/VBoxContainer/UpgradeSection/UpgradeTitleLabel
@onready var upgrade_currency_label: Label = $Panel/VBoxContainer/UpgradeSection/UpgradeCurrencyLabel
@onready var upgrade_list: VBoxContainer = $Panel/VBoxContainer/UpgradeSection/UpgradeList

const INTERMISSION_UPGRADES: Array[Dictionary] = [
	{
		"id": "turret_damage",
		"name_key": "shop.item.turret_damage.name",
		"description_key": "shop.item.turret_damage.desc",
		"price": 35,
	},
	{
		"id": "fire_control",
		"name_key": "shop.item.fire_control.name",
		"description_key": "shop.item.fire_control.desc",
		"price": 45,
	}
]

var _wave_manager: Node = null
var _is_visible: bool = false
var _panel_open: bool = true
var _upgrade_section_open: bool = false

func _ready() -> void:
	_hide_ui()
	_find_wave_manager()
	_connect_signals()
	_connect_localization()
	_apply_localization()

func _process(_delta: float) -> void:
	if not _wave_manager:
		return

	if _wave_manager.get_state() == _wave_manager.State.BETWEEN_WAVES and InputManager.upgrade_toggle_action.is_triggered():
		_toggle_intermission_panel()
	
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
	EventBus.game_over.connect(_on_game_over)
	EventBus.currency_changed.connect(_on_currency_changed)
	EventBus.game_started.connect(_on_game_started)
	
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
			if _panel_open and not _is_visible:
				_show_ui()
			elif not _panel_open and _is_visible:
				_hide_ui()
			if _panel_open:
				_update_intermission_ui()
		_wave_manager.State.ACTIVE_WAVE:
			_panel_open = true
			_upgrade_section_open = false
			if _is_visible:
				_hide_ui()
		_wave_manager.State.COMPLETE:
			_panel_open = true
			_upgrade_section_open = false
			_show_completion_ui()

func _update_intermission_ui() -> void:
	var current_wave = _wave_manager.current_wave
	var total_waves = _wave_manager.total_waves

	if current_wave <= 0:
		wave_label.text = Localization.t("wave.ui.pre_battle_title")
		status_label.text = Localization.t("wave.ui.pre_battle_status")
	else:
		wave_label.text = Localization.t("wave.ui.complete_title", "", {"wave": current_wave, "total": total_waves})
		status_label.text = Localization.t("wave.ui.intermission_status")

	timer_label.text = Localization.t("wave.ui.waiting_for_continue")
	
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
	_panel_open = true
	button_container.visible = true
	wave_progress_bar.visible = true
	
	# Enable all buttons
	continue_button.disabled = false
	repair_button.disabled = false
	upgrade_button.disabled = false
	upgrade_section.visible = _upgrade_section_open
	_update_upgrade_ui()

func _hide_ui() -> void:
	visible = false
	_is_visible = false

func set_combat_visibility(should_show: bool) -> void:
	if not should_show:
		_panel_open = true
		_upgrade_section_open = false
		_hide_ui()
		return
	_update_ui()

func _toggle_intermission_panel() -> void:
	_panel_open = not _panel_open
	if _panel_open:
		_show_ui()
		_update_intermission_ui()
	else:
		_upgrade_section_open = false
		_hide_ui()

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
	upgrade_title_label.text = Localization.t("wave.ui.upgrade_title")
	if _wave_manager:
		_update_ui()
	_update_upgrade_ui()

func _on_continue_pressed() -> void:
	if _wave_manager:
		_wave_manager.continue_to_next_wave()

func _on_repair_pressed() -> void:
	# Find the ship and heal it
	var ship = get_tree().get_first_node_in_group("ship")
	# health_component is a property, not a method - check if it exists
	if ship and "health_component" in ship and ship.health_component:
		var healed = ship.health_component.heal(GameState.apply_repair_multiplier(100.0))
		if healed > 0:
			EventBus.ship_health_changed.emit(ship.health_component.current_health, ship.max_health)
	repair_button.disabled = true

func _on_upgrade_pressed() -> void:
	if not _is_visible:
		return
	_upgrade_section_open = not _upgrade_section_open
	upgrade_section.visible = _upgrade_section_open
	_update_upgrade_ui()

func _on_wave_started(_wave_number: int) -> void:
	_hide_ui()

func _on_wave_complete(_wave_number: int) -> void:
	_show_ui()

func _on_all_waves_complete() -> void:
	_show_completion_ui()

func _on_intermission_started(_duration: float) -> void:
	_panel_open = true
	_upgrade_section_open = false
	_show_ui()

func _on_intermission_ended() -> void:
	_update_ui()

func _on_game_over(_won: bool) -> void:
	_upgrade_section_open = false
	_hide_ui()

func _on_currency_changed(_new_amount: int, _delta: int) -> void:
	if _is_visible and _upgrade_section_open:
		_update_upgrade_ui()

func _on_game_started() -> void:
	_upgrade_section_open = false
	_update_upgrade_ui()

func _update_upgrade_ui() -> void:
	if not is_instance_valid(upgrade_section):
		return
	upgrade_section.visible = _upgrade_section_open and _is_visible
	upgrade_currency_label.text = Localization.t("shop.currency", "", {"amount": GameState.currency})

	for child in upgrade_list.get_children():
		child.queue_free()

	for item in INTERMISSION_UPGRADES:
		upgrade_list.add_child(_create_upgrade_row(item))

func _create_upgrade_row(data: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.add_theme_constant_override("separation", 12)

	var label := Label.new()
	label.text = "%s\n%s" % [Localization.t(data["name_key"]), Localization.t(data["description_key"])]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var price_label := Label.new()
	price_label.text = "%d" % int(data["price"])
	price_label.custom_minimum_size.x = 52
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(price_label)

	var buy_button := Button.new()
	buy_button.text = Localization.t("common.buy")
	buy_button.custom_minimum_size.x = 96
	buy_button.pressed.connect(_on_upgrade_purchase_pressed.bind(StringName(data["id"]), int(data["price"])))
	row.add_child(buy_button)

	_update_upgrade_row(StringName(data["id"]), int(data["price"]), buy_button, price_label)
	return row

func _update_upgrade_row(upgrade_id: StringName, price: int, buy_button: Button, price_label: Label) -> void:
	var is_owned := _is_upgrade_purchased(upgrade_id)
	var can_afford := GameState.can_afford(price)
	buy_button.disabled = is_owned or not can_afford

	if is_owned:
		buy_button.text = Localization.t("common.owned")
		price_label.add_theme_color_override("font_color", Color.GRAY)
	elif not can_afford:
		buy_button.text = Localization.t("common.buy")
		price_label.add_theme_color_override("font_color", Color.RED)
	else:
		buy_button.text = Localization.t("common.buy")
		price_label.remove_theme_color_override("font_color")

func _on_upgrade_purchase_pressed(upgrade_id: StringName, price: int) -> void:
	if _is_upgrade_purchased(upgrade_id):
		return
	if not GameState.spend_currency(price):
		return

	match upgrade_id:
		&"turret_damage":
			GameState.turret_damage_multiplier += 0.1
			EventBus.turret_stats_refresh_requested.emit()
		&"fire_control":
			GameState.auto_fire_unlocked = true
		_:
			GameState.add_currency(price)
			return

	EventBus.upgrade_purchased.emit(String(upgrade_id), price)
	_update_upgrade_ui()

func _is_upgrade_purchased(upgrade_id: StringName) -> bool:
	match upgrade_id:
		&"turret_damage":
			return GameState.turret_damage_multiplier > 1.0
		&"fire_control":
			return GameState.auto_fire_unlocked
		_:
			return false
