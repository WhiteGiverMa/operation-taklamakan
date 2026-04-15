class_name MaintenancePageController
extends Control

## 维修页控制器 - 负责波间期整备页面的内容渲染与交互

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

signal content_update_requested

var _wave_manager: Node = null
var _hud_presenter: Node = null
var _upgrade_section_open: bool = false

# 页面节点引用（由主容器注入）
var wave_label: Label
var status_label: Label
var timer_label: Label
var enemy_info_label: Label
var ship_health_label: Label
var ship_health_bar: ProgressBar
var upgrade_currency_label: Label
var maintenance_hint_label: Label
var button_container: HBoxContainer
var continue_button: Button
var repair_button: Button
var upgrade_button: Button
var upgrade_section: VBoxContainer
var upgrade_title_label: Label
var upgrade_list: VBoxContainer

func set_wave_manager(wm: Node) -> void:
	_wave_manager = wm

func set_hud_presenter(presenter: Node) -> void:
	_hud_presenter = presenter

func set_upgrade_section_open(open: bool) -> void:
	_upgrade_section_open = open

func is_upgrade_section_open() -> bool:
	return _upgrade_section_open

func toggle_upgrade_section() -> void:
	_upgrade_section_open = not _upgrade_section_open

func update_page(overview: Dictionary, ship_health: Dictionary) -> void:
	if not _wave_manager:
		return

	var current_wave: int = int(overview.get("current_wave", 0))
	var total_waves: int = int(overview.get("total_waves", 0))
	var wave_state: int = int(overview.get("wave_state", -1))

	match wave_state:
		_wave_manager.State.ACTIVE_WAVE:
			wave_label.text = Localization.t("info.maintenance.wave_active", "", {"wave": current_wave, "total": total_waves})
			status_label.text = Localization.t("info.maintenance.active_wave")
			timer_label.text = Localization.t("info.maintenance.actions_locked")
		_wave_manager.State.BETWEEN_WAVES:
			if current_wave <= 0:
				wave_label.text = Localization.t("wave.ui.pre_battle_title")
				status_label.text = Localization.t("wave.ui.pre_battle_status")
			else:
				wave_label.text = Localization.t("wave.ui.complete_title", "", {"wave": current_wave, "total": total_waves})
				status_label.text = Localization.t("wave.ui.intermission_status")
			timer_label.text = Localization.t("wave.ui.waiting_for_continue")
		_wave_manager.State.COMPLETE:
			wave_label.text = Localization.t("wave.ui.all_complete")
			status_label.text = Localization.t("wave.ui.combat_finished")
			timer_label.text = Localization.t("wave.ui.victory")
		_:
			wave_label.text = Localization.t("info.maintenance.wave_idle")
			status_label.text = Localization.t("info.state.inactive")
			timer_label.text = ""

	enemy_info_label.text = _get_next_wave_info_text(overview.get("next_wave_enemy_counts", {}))
	_update_ship_health_display(ship_health)
	upgrade_currency_label.text = Localization.t("shop.currency", "", {"amount": int(overview.get("currency", GameState.currency))})
	maintenance_hint_label.text = Localization.t("info.maintenance.actions_locked") if bool(overview.get("read_only", _is_maintenance_read_only())) else Localization.t("info.maintenance.actions_available")

	var maintenance_enabled := bool(overview.get("maintenance_enabled", _can_perform_maintenance()))
	continue_button.disabled = not maintenance_enabled
	repair_button.disabled = not maintenance_enabled
	upgrade_button.disabled = false
	button_container.modulate = Color(1, 1, 1, 1) if maintenance_enabled else Color(0.72, 0.72, 0.72, 1)
	upgrade_section.visible = _upgrade_section_open
	_update_upgrade_ui()

func _get_next_wave_info_text(enemy_counts: Dictionary = {}) -> String:
	if enemy_counts.is_empty() and _hud_presenter and _hud_presenter.has_method("get_wave_overview_state"):
		enemy_counts = _hud_presenter.call("get_wave_overview_state").get("next_wave_enemy_counts", {})

	if not enemy_counts.is_empty():
		return Localization.t("wave.ui.next_wave_enemies", "", {
			"tanks": enemy_counts.get("tank", 0),
			"dogs": enemy_counts.get("mechanical_dog", 0),
			"bosses": enemy_counts.get("boss_tank", 0),
		})
	return Localization.t("wave.ui.next_wave_unknown")

func _update_ship_health_display(ship_health: Dictionary) -> void:
	if bool(ship_health.get("has_ship", false)):
		var current_health: float = float(ship_health.get("current", 0.0))
		var max_health: float = float(ship_health.get("maximum", 100.0))
		ship_health_bar.max_value = max_health
		ship_health_bar.value = current_health
		ship_health_label.text = Localization.t("info.maintenance.ship_health", "", {
			"current": int(round(current_health)),
			"maximum": int(round(max_health)),
		})
		return
	ship_health_bar.max_value = 100.0
	ship_health_bar.value = 0.0
	ship_health_label.text = Localization.t("info.maintenance.ship_health", "", {"current": 0, "maximum": 0})

func _update_upgrade_ui() -> void:
	if not is_instance_valid(upgrade_section):
		return
	upgrade_section.visible = _upgrade_section_open
	for child in upgrade_list.get_children():
		child.queue_free()
	for item in INTERMISSION_UPGRADES:
		upgrade_list.add_child(_create_upgrade_row(item))

func _create_upgrade_row(data: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	buy_button.focus_mode = Control.FOCUS_NONE
	buy_button.clip_text = true
	buy_button.pressed.connect(_on_upgrade_purchase_pressed.bind(StringName(data["id"]), int(data["price"])))
	row.add_child(buy_button)

	_update_upgrade_row(StringName(data["id"]), int(data["price"]), buy_button, price_label)
	return row

func _update_upgrade_row(upgrade_id: StringName, price: int, buy_button: Button, price_label: Label) -> void:
	var is_owned := _is_upgrade_purchased(upgrade_id)
	var can_afford := GameState.can_afford(price)
	var read_only := _is_maintenance_read_only()
	buy_button.disabled = is_owned or not can_afford or read_only

	if is_owned:
		buy_button.text = Localization.t("common.owned")
		price_label.add_theme_color_override("font_color", Color.GRAY)
	elif read_only:
		buy_button.text = Localization.t("info.maintenance.locked_button")
		price_label.add_theme_color_override("font_color", Color.DIM_GRAY)
	elif not can_afford:
		buy_button.text = Localization.t("common.buy")
		price_label.add_theme_color_override("font_color", Color.RED)
	else:
		buy_button.text = Localization.t("common.buy")
		price_label.remove_theme_color_override("font_color")

func _is_maintenance_read_only() -> bool:
	if _hud_presenter and _hud_presenter.has_method("is_maintenance_read_only"):
		return _hud_presenter.call("is_maintenance_read_only")
	if not _wave_manager:
		return true
	return _wave_manager.get_state() == _wave_manager.State.ACTIVE_WAVE

func _can_perform_maintenance() -> bool:
	if _hud_presenter and _hud_presenter.has_method("can_perform_maintenance"):
		return _hud_presenter.call("can_perform_maintenance")
	if not _wave_manager:
		return false
	return _wave_manager.get_state() == _wave_manager.State.BETWEEN_WAVES

func _is_upgrade_purchased(upgrade_id: StringName) -> bool:
	match upgrade_id:
		&"turret_damage":
			return GameState.turret_damage_multiplier > 1.0
		&"fire_control":
			return GameState.auto_fire_unlocked
		_:
			return false

func _on_upgrade_purchase_pressed(upgrade_id: StringName, price: int) -> void:
	if _is_maintenance_read_only():
		return
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
	content_update_requested.emit()
