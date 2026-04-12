extends Control

## 综合信息界面：整备 / 藏品 / 地图
## 波间期自动打开并允许操作整备；战斗进行中可手动打开查看，但整备功能只读。

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

const RELIC_ITEMS: Array[Dictionary] = [
	{
		"id": "gyro_sight",
		"name_key": "shop.relic.gyro_sight.name",
		"description_key": "shop.relic.gyro_sight.desc",
	},
	{
		"id": "salvage_contract",
		"name_key": "shop.relic.salvage_contract.name",
		"description_key": "shop.relic.salvage_contract.desc",
	},
	{
		"id": "field_toolkit",
		"name_key": "shop.relic.field_toolkit.name",
		"description_key": "shop.relic.field_toolkit.desc",
	},
	{
		"id": "overclock_core",
		"name_key": "shop.relic.overclock_core.name",
		"description_key": "shop.relic.overclock_core.desc",
	}
]

enum InfoTab {
	MAINTENANCE,
	RELICS,
	MAP,
}

const MapScreenScene := preload("res://scenes/ui/map_screen.tscn")

@onready var title_label: Label = $MainContainer/Sidebar/SidebarContent/Root/TopBar/TitleBlock/TitleLabel
@onready var state_label: Label = $MainContainer/Sidebar/SidebarContent/Root/TopBar/TitleBlock/StateLabel
@onready var maintenance_tab_button: Button = $MainContainer/Sidebar/SidebarContent/Root/TabBar/MaintenanceTabButton
@onready var relics_tab_button: Button = $MainContainer/Sidebar/SidebarContent/Root/TabBar/RelicsTabButton
@onready var map_tab_button: Button = $MainContainer/Sidebar/SidebarContent/Root/TabBar/MapTabButton
@onready var close_button: Button = $MainContainer/Sidebar/SidebarContent/Root/TopBar/CloseButton
@onready var maintenance_page: Control = $MainContainer/ContentArea/Panel/MarginContainer/PageContainer/MaintenancePage
@onready var relics_page: Control = $MainContainer/ContentArea/Panel/MarginContainer/PageContainer/RelicsPage
@onready var map_page: Control = $MainContainer/ContentArea/Panel/MarginContainer/PageContainer/MapPage

@onready var wave_label: Label = $MainContainer/ContentArea/Panel/MarginContainer/PageContainer/MaintenancePage/Scroll/Margin/Content/WaveLabel
@onready var status_label: Label = $MainContainer/ContentArea/Panel/MarginContainer/PageContainer/MaintenancePage/Scroll/Margin/Content/StatusLabel
@onready var timer_label: Label = $MainContainer/ContentArea/Panel/MarginContainer/PageContainer/MaintenancePage/Scroll/Margin/Content/TimerLabel
@onready var enemy_info_label: Label = $MainContainer/ContentArea/Panel/MarginContainer/PageContainer/MaintenancePage/Scroll/Margin/Content/EnemyInfoLabel
@onready var ship_health_label: Label = $MainContainer/ContentArea/Panel/MarginContainer/PageContainer/MaintenancePage/Scroll/Margin/Content/ShipHealthLabel
@onready var ship_health_bar: ProgressBar = $MainContainer/ContentArea/Panel/MarginContainer/PageContainer/MaintenancePage/Scroll/Margin/Content/ShipHealthBar
@onready var upgrade_currency_label: Label = $MainContainer/ContentArea/Panel/MarginContainer/PageContainer/MaintenancePage/Scroll/Margin/Content/UpgradeCurrencyLabel
@onready var maintenance_hint_label: Label = $MainContainer/ContentArea/Panel/MarginContainer/PageContainer/MaintenancePage/Scroll/Margin/Content/MaintenanceHintLabel
@onready var button_container: HBoxContainer = $MainContainer/ContentArea/Panel/MarginContainer/PageContainer/MaintenancePage/Scroll/Margin/Content/ButtonContainer
@onready var continue_button: Button = $MainContainer/ContentArea/Panel/MarginContainer/PageContainer/MaintenancePage/Scroll/Margin/Content/ButtonContainer/ContinueButton
@onready var repair_button: Button = $MainContainer/ContentArea/Panel/MarginContainer/PageContainer/MaintenancePage/Scroll/Margin/Content/ButtonContainer/RepairButton
@onready var upgrade_button: Button = $MainContainer/ContentArea/Panel/MarginContainer/PageContainer/MaintenancePage/Scroll/Margin/Content/ButtonContainer/UpgradeButton
@onready var upgrade_section: VBoxContainer = $MainContainer/ContentArea/Panel/MarginContainer/PageContainer/MaintenancePage/Scroll/Margin/Content/UpgradeSection
@onready var upgrade_title_label: Label = $MainContainer/ContentArea/Panel/MarginContainer/PageContainer/MaintenancePage/Scroll/Margin/Content/UpgradeSection/UpgradeTitleLabel
@onready var upgrade_list: VBoxContainer = $MainContainer/ContentArea/Panel/MarginContainer/PageContainer/MaintenancePage/Scroll/Margin/Content/UpgradeSection/UpgradeList

@onready var relic_summary_label: Label = $MainContainer/ContentArea/Panel/MarginContainer/PageContainer/RelicsPage/Scroll/Margin/Content/RelicSummaryLabel
@onready var relic_list: VBoxContainer = $MainContainer/ContentArea/Panel/MarginContainer/PageContainer/RelicsPage/Scroll/Margin/Content/RelicList

@onready var map_overview_label: Label = $MainContainer/ContentArea/Panel/MarginContainer/PageContainer/MapPage/Scroll/Margin/Content/MapOverviewLabel
@onready var map_current_node_label: Label = $MainContainer/ContentArea/Panel/MarginContainer/PageContainer/MapPage/Scroll/Margin/Content/MapCurrentNodeLabel
@onready var map_choices_label: Label = $MainContainer/ContentArea/Panel/MarginContainer/PageContainer/MapPage/Scroll/Margin/Content/MapChoicesLabel
@onready var map_list: VBoxContainer = $MainContainer/ContentArea/Panel/MarginContainer/PageContainer/MapPage/Scroll/Margin/Content/MapList

var _wave_manager: Node = null
var _is_visible: bool = false
var _combat_visible: bool = false
var _upgrade_section_open: bool = false
var _current_tab: InfoTab = InfoTab.MAINTENANCE
var _panel_paused_tree: bool = false
var _embedded_map: Control = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_find_wave_manager()
	_connect_signals()
	_connect_localization()
	_apply_localization()
	_update_tab_visibility()
	_update_all_content()

func _process(_delta: float) -> void:
	if not _combat_visible:
		return
	if InputManager.upgrade_toggle_action.is_triggered():
		_toggle_panel()
		return
	if _is_visible and InputManager.ui_back_action.is_triggered():
		_close_panel()
		return
	# Q/E 标签切换（仅在面板可见时）
	if _is_visible:
		if InputManager.info_tab_prev_action.is_triggered():
			_cycle_tab(-1)
		if InputManager.info_tab_next_action.is_triggered():
			_cycle_tab(+1)

func _connect_signals() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	repair_button.pressed.connect(_on_repair_pressed)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	close_button.pressed.connect(_close_panel)
	maintenance_tab_button.pressed.connect(_on_tab_pressed.bind(InfoTab.MAINTENANCE))
	relics_tab_button.pressed.connect(_on_tab_pressed.bind(InfoTab.RELICS))
	map_tab_button.pressed.connect(_on_tab_pressed.bind(InfoTab.MAP))

	EventBus.wave_started.connect(_on_wave_started)
	EventBus.wave_complete.connect(_on_wave_complete)
	EventBus.wave_all_complete.connect(_on_all_waves_complete)
	EventBus.game_over.connect(_on_game_over)
	EventBus.currency_changed.connect(_on_runtime_state_changed)
	EventBus.game_started.connect(_on_game_started)
	EventBus.relic_purchased.connect(_on_relic_purchased)
	EventBus.ship_health_changed.connect(_on_ship_health_changed)
	MapManager.current_node_changed.connect(_on_map_changed)
	MapManager.layer_changed.connect(_on_map_layer_changed)
	MapManager.map_generated.connect(_on_map_generated)

	if _wave_manager:
		if not _wave_manager.intermission_started.is_connected(_on_intermission_started):
			_wave_manager.intermission_started.connect(_on_intermission_started)
		if not _wave_manager.intermission_ended.is_connected(_on_intermission_ended):
			_wave_manager.intermission_ended.connect(_on_intermission_ended)
		if not _wave_manager.wave_progress_updated.is_connected(_on_wave_progress_updated):
			_wave_manager.wave_progress_updated.connect(_on_wave_progress_updated)

func _connect_localization() -> void:
	if not Localization.language_changed.is_connected(_on_language_changed):
		Localization.language_changed.connect(_on_language_changed)

func _on_language_changed(_locale: String) -> void:
	_apply_localization()

func _find_wave_manager() -> void:
	_wave_manager = WaveManager

func set_combat_visibility(should_show: bool) -> void:
	_combat_visible = should_show
	if not should_show:
		_close_panel()
		return
	_update_all_content()

func _toggle_panel() -> void:
	if not _can_toggle_panel():
		return
	if _is_visible:
		_close_panel()
	else:
		_open_panel(false)

func _can_toggle_panel() -> bool:
	if not _combat_visible or not _wave_manager:
		return false
	if GameState.get_state() != GameState.State.PLAYING:
		return false
	var wave_state: int = _wave_manager.get_state()
	return wave_state == _wave_manager.State.ACTIVE_WAVE or wave_state == _wave_manager.State.BETWEEN_WAVES

func _open_panel(force_maintenance_tab: bool) -> void:
	if force_maintenance_tab:
		_current_tab = InfoTab.MAINTENANCE
	_update_tab_visibility()
	_update_all_content()
	visible = true
	_is_visible = true
	InputManager.activate_info_overlay()
	if not get_tree().paused:
		get_tree().paused = true
		_panel_paused_tree = true

func _close_panel(restore_input: bool = true) -> void:
	if _panel_paused_tree:
		get_tree().paused = false
		_panel_paused_tree = false
	visible = false
	_is_visible = false
	if restore_input:
		InputManager.restore_flow_context()

func _on_tab_pressed(tab: InfoTab) -> void:
	if tab == _current_tab and _is_visible:
		_close_panel()
		return
	_current_tab = tab
	_update_tab_visibility()
	_update_all_content()

func _cycle_tab(direction: int) -> void:
	var tabs := [InfoTab.MAINTENANCE, InfoTab.RELICS, InfoTab.MAP]
	var current_index := tabs.find(_current_tab)
	var new_index := wrapi(current_index + direction, 0, tabs.size())
	_current_tab = tabs[new_index]
	_update_tab_visibility()
	_update_tab_buttons()

	# 切换到地图页时确保嵌入地图存在并刷新
	if _current_tab == InfoTab.MAP:
		_ensure_embedded_map()
		if _embedded_map:
			_embedded_map.recenter_view.call_deferred()

func _ensure_embedded_map() -> void:
	# 如果已存在，直接显示
	if _embedded_map != null:
		_embedded_map.visible = true
		return

	# 实例化地图场景
	var map_instance := MapScreenScene.instantiate()

	# 配置只读模式
	var map_screen: Control = map_instance.get_node("MapScreen") if map_instance.has_node("MapScreen") else map_instance
	
	# 先设置只读模式，再添加到场景树，避免实例化瞬间 UILayer 抢焦点
	map_screen.set_read_only_mode(true)
	map_screen.set_show_overlay_ui(false)
	map_screen.allow_pan_in_read_only = true  # 允许只读模式平移

	# 设置全屏填充
	map_instance.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_instance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_instance.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# 添加到地图页容器
	map_page.add_child(map_instance)
	_embedded_map = map_screen

	# 延迟一帧后居中（确保容器尺寸有效）
	map_screen.recenter_view.call_deferred()

func _update_tab_visibility() -> void:
	maintenance_page.visible = _current_tab == InfoTab.MAINTENANCE
	relics_page.visible = _current_tab == InfoTab.RELICS
	map_page.visible = _current_tab == InfoTab.MAP
	_update_tab_buttons()

	# 切换到地图页时确保嵌入地图存在
	if _current_tab == InfoTab.MAP:
		_ensure_embedded_map()

	# 隐藏嵌入地图当不在地图页时
	if _embedded_map != null and _current_tab != InfoTab.MAP:
		_embedded_map.visible = false
	call_deferred("_sync_dynamic_layouts")

func _update_tab_buttons() -> void:
	_update_tab_button_state(maintenance_tab_button, _current_tab == InfoTab.MAINTENANCE)
	_update_tab_button_state(relics_tab_button, _current_tab == InfoTab.RELICS)
	_update_tab_button_state(map_tab_button, _current_tab == InfoTab.MAP)

func _update_tab_button_state(button: Button, is_active: bool) -> void:
	button.disabled = false
	button.modulate = Color(1.0, 1.0, 1.0, 1.0) if is_active else Color(0.82, 0.84, 0.9, 1.0)

func _update_all_content() -> void:
	_update_header_state()
	_update_maintenance_page()
	_update_relics_page()
	_update_map_page()
	call_deferred("_sync_dynamic_layouts")

func _update_header_state() -> void:
	state_label.text = Localization.t(_get_panel_state_key())

func _get_panel_state_key() -> String:
	if not _wave_manager:
		return "info.state.inactive"
	match _wave_manager.get_state():
		_wave_manager.State.ACTIVE_WAVE:
			return "info.state.read_only"
		_wave_manager.State.BETWEEN_WAVES:
			return "info.state.editable"
		_wave_manager.State.COMPLETE:
			return "info.state.complete"
		_:
			return "info.state.inactive"

func _update_maintenance_page() -> void:
	if not _wave_manager:
		return

	var current_wave: int = _wave_manager.current_wave
	var total_waves: int = _wave_manager.total_waves
	var wave_state: int = _wave_manager.get_state()

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

	enemy_info_label.text = _get_next_wave_info_text()
	_update_ship_health_display()
	upgrade_currency_label.text = Localization.t("shop.currency", "", {"amount": GameState.currency})
	maintenance_hint_label.text = Localization.t("info.maintenance.actions_locked") if _is_maintenance_read_only() else Localization.t("info.maintenance.actions_available")

	var maintenance_enabled := _can_perform_maintenance()
	continue_button.disabled = not maintenance_enabled
	repair_button.disabled = not maintenance_enabled
	upgrade_button.disabled = false
	button_container.modulate = Color(1, 1, 1, 1) if maintenance_enabled else Color(0.72, 0.72, 0.72, 1)
	upgrade_section.visible = _upgrade_section_open
	_update_upgrade_ui()

func _get_next_wave_info_text() -> String:
	if not _wave_manager or not _wave_manager.wave_set or not _wave_manager.wave_set.has_method("get_wave"):
		return Localization.t("wave.ui.next_wave_unknown")
	var next_wave_data = _wave_manager.wave_set.get_wave(_wave_manager.current_wave + 1)
	if next_wave_data and next_wave_data.has_method("get_enemy_counts"):
		var enemy_counts = next_wave_data.get_enemy_counts()
		return Localization.t("wave.ui.next_wave_enemies", "", {
			"tanks": enemy_counts.get("tank", 0),
			"dogs": enemy_counts.get("mechanical_dog", 0),
			"bosses": enemy_counts.get("boss_tank", 0),
		})
	return Localization.t("wave.ui.next_wave_unknown")

func _update_ship_health_display() -> void:
	var ship = get_tree().get_first_node_in_group("ship")
	if ship and "health_component" in ship and ship.health_component:
		var current_health: float = ship.health_component.current_health
		var max_health: float = ship.health_component.max_health
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
	call_deferred("_sync_dynamic_layouts")

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

func _sync_dynamic_layouts() -> void:
	_sync_container_width(upgrade_section, upgrade_list)
	_sync_container_width(relics_page.get_node("Scroll/Margin/Content"), relic_list)
	_sync_container_width(map_page.get_node("Scroll/Margin/Content"), map_list)

	for row in upgrade_list.get_children():
		_sync_box_row_width(row, upgrade_list.size.x)
	for row in relic_list.get_children():
		_sync_label_stack_width(row, relic_list.size.x)
	for row in map_list.get_children():
		_sync_label_stack_width(row, map_list.size.x)

	for label in [map_overview_label, map_current_node_label, map_choices_label, relic_summary_label]:
		if is_instance_valid(label):
			label.custom_minimum_size.x = maxf(label.get_parent().size.x, 0.0)

func _sync_container_width(reference: Control, target: Control) -> void:
	if not is_instance_valid(reference) or not is_instance_valid(target):
		return
	var width := reference.size.x
	if width <= 0.0:
		return
	target.custom_minimum_size.x = width
	target.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target.reset_size()
	var parent := target.get_parent()
	if parent is Container:
		parent.queue_sort()

func _sync_box_row_width(row: Node, width: float) -> void:
	if not (row is Control) or width <= 0.0:
		return
	var control := row as Control
	control.custom_minimum_size.x = width
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for child in control.get_children():
		if child is Label:
			var label := child as Label
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			label.custom_minimum_size.x = 0.0

func _sync_label_stack_width(row: Node, width: float) -> void:
	if not (row is Control) or width <= 0.0:
		return
	var control := row as Control
	control.custom_minimum_size.x = width
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for child in control.get_children():
		if child is Label:
			var label := child as Label
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			label.custom_minimum_size.x = width

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

func _update_relics_page() -> void:
	relic_summary_label.text = Localization.t("info.relics.summary", "", {
		"owned": GameState.owned_relic_ids.size(),
		"total": RELIC_ITEMS.size(),
	})
	for child in relic_list.get_children():
		child.queue_free()
	for relic_data in RELIC_ITEMS:
		relic_list.add_child(_create_relic_row(relic_data))

func _create_relic_row(data: Dictionary) -> VBoxContainer:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	container.custom_minimum_size.y = 78
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var relic_id := StringName(data["id"])
	var owned := GameState.has_relic(relic_id)
	var title := Label.new()
	title.text = "%s  [%s]" % [
		Localization.t(data["name_key"]),
		Localization.t("info.relics.owned_tag") if owned else Localization.t("info.relics.unowned_tag")
	]
	title.add_theme_font_size_override("font_size", 22)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(title)

	var desc := Label.new()
	desc.text = Localization.t(data["description_key"])
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc.modulate = Color(1, 1, 1, 1) if owned else Color(0.62, 0.62, 0.62, 1)
	container.add_child(desc)

	return container

func _update_map_page() -> void:
	var graph = MapManager.get_graph()
	var visited_count := MapManager.visited_nodes.size()
	map_overview_label.text = Localization.t("info.map.overview", "", {
		"layer": MapManager.current_layer + 1,
		"visited": visited_count,
	})
	map_current_node_label.text = Localization.t("info.map.current_node", "", {
		"node": _get_current_node_text(),
	})
	map_choices_label.text = Localization.t("info.map.reachable", "", {
		"count": MapManager.get_current_choices().size(),
	})

	for child in map_list.get_children():
		child.queue_free()

	if graph == null:
		var empty_label := Label.new()
		empty_label.text = Localization.t("info.map.none")
		map_list.add_child(empty_label)
		return

	for layer_index in range(3):
		map_list.add_child(_create_map_layer_row(layer_index, graph.get_layer_nodes(layer_index)))

func _create_map_layer_row(layer_index: int, layer_nodes: Array) -> VBoxContainer:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var title := Label.new()
	title.text = Localization.t("info.map.layer_title", "", {"layer": layer_index + 1})
	title.add_theme_font_size_override("font_size", 21)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(title)

	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.text = _build_layer_summary_text(layer_nodes)
	container.add_child(body)

	return container

func _build_layer_summary_text(layer_nodes: Array) -> String:
	if layer_nodes.is_empty():
		return Localization.t("info.map.none")
	var parts: Array[String] = []
	for node in layer_nodes:
		parts.append("%s · %s" % [_get_node_display_name(node), _get_node_state_text(node)])
	return "\n".join(parts)

func _get_current_node_text() -> String:
	if MapManager.current_node == null:
		return Localization.t("map.node_type.unknown")
	return _get_node_display_name(MapManager.current_node)

func _get_node_display_name(node) -> String:
	var type_key := "map.node_type.%s" % String(node.get_type_name())
	return Localization.t(type_key)

func _get_node_state_text(node) -> String:
	if MapManager.current_node != null and node.id == MapManager.current_node.id:
		return Localization.t("info.map.state.current")
	if node.visited:
		return Localization.t("info.map.state.visited")
	if MapManager.current_node != null and MapManager.current_node.connections.has(node.id):
		return Localization.t("info.map.state.reachable")
	return Localization.t("info.map.state.locked")

func _is_maintenance_read_only() -> bool:
	if not _wave_manager:
		return true
	return _wave_manager.get_state() == _wave_manager.State.ACTIVE_WAVE

func _can_perform_maintenance() -> bool:
	if not _wave_manager:
		return false
	return _wave_manager.get_state() == _wave_manager.State.BETWEEN_WAVES

func _apply_localization() -> void:
	title_label.text = Localization.t("info.title")
	maintenance_tab_button.text = Localization.t("info.tab.maintenance")
	relics_tab_button.text = Localization.t("info.tab.relics")
	map_tab_button.text = Localization.t("info.tab.map")
	close_button.text = "×"
	close_button.tooltip_text = Localization.t("common.close")
	continue_button.text = Localization.t("common.continue")
	repair_button.text = Localization.t("common.repair")
	upgrade_button.text = Localization.t("common.upgrade")
	upgrade_title_label.text = Localization.t("wave.ui.upgrade_title")
	_update_all_content()

func _on_continue_pressed() -> void:
	if not _can_perform_maintenance():
		return
	_close_panel()
	if _wave_manager:
		_wave_manager.continue_to_next_wave()

func _on_repair_pressed() -> void:
	if not _can_perform_maintenance():
		return
	var ship = get_tree().get_first_node_in_group("ship")
	if ship and "health_component" in ship and ship.health_component:
		var healed = ship.health_component.heal(GameState.apply_repair_multiplier(100.0))
		if healed > 0:
			EventBus.ship_health_changed.emit(ship.health_component.current_health, ship.max_health)
	repair_button.disabled = true
	_update_maintenance_page()

func _on_upgrade_pressed() -> void:
	if not _is_visible:
		return
	_upgrade_section_open = not _upgrade_section_open
	_update_maintenance_page()

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
	_update_all_content()

func _is_upgrade_purchased(upgrade_id: StringName) -> bool:
	match upgrade_id:
		&"turret_damage":
			return GameState.turret_damage_multiplier > 1.0
		&"fire_control":
			return GameState.auto_fire_unlocked
		_:
			return false

func _on_wave_started(_wave_number: int) -> void:
	_upgrade_section_open = false
	_close_panel()

func _on_wave_complete(_wave_number: int) -> void:
	_open_panel(true)

func _on_all_waves_complete() -> void:
	_upgrade_section_open = false
	_update_all_content()

func _on_intermission_started(_duration: float) -> void:
	_upgrade_section_open = false
	_open_panel(true)

func _on_intermission_ended() -> void:
	_update_all_content()

func _on_game_over(_won: bool) -> void:
	_upgrade_section_open = false
	_close_panel()

func _on_game_started() -> void:
	_upgrade_section_open = false
	_current_tab = InfoTab.MAINTENANCE
	_update_tab_visibility()
	_update_all_content()

func _on_runtime_state_changed(_value_a = null, _value_b = null) -> void:
	if _is_visible:
		_update_all_content()

func _on_relic_purchased(_relic_id: String, _cost: int) -> void:
	_on_runtime_state_changed()

func _on_ship_health_changed(_current: float, _maximum: float) -> void:
	_on_runtime_state_changed()

func _on_map_changed(_node) -> void:
	_on_runtime_state_changed()

func _on_map_layer_changed(_new_layer: int) -> void:
	_on_runtime_state_changed()

func _on_map_generated(_seed: int, _graph) -> void:
	_on_runtime_state_changed()

func _on_wave_progress_updated(_enemies_remaining: int, _total_enemies: int) -> void:
	_on_runtime_state_changed()
