extends Control

## 综合信息界面：整备 / 藏品 / 地图
## 波间期自动打开并允许操作整备；战斗进行中可手动打开查看，但整备功能只读。

const FloorGraphScript := preload("res://scripts/floor_graph.gd")

enum InfoTab {
	MAINTENANCE,
	RELICS,
	MAP,
}

const MapViewerScene := preload("res://scenes/ui/map_viewer.tscn")
const MaintenancePageControllerScript := preload("res://scripts/ui/maintenance_page_controller.gd")
const RelicsPageControllerScript := preload("res://scripts/ui/relics_page_controller.gd")

@onready var title_label: Label = $MainContainer/Sidebar/SidebarContent/Root/TopBar/TitleBlock/TitleLabel
@onready var state_label: Label = $MainContainer/Sidebar/SidebarContent/Root/TopBar/TitleBlock/StateLabel
@onready var maintenance_tab_button: Button = $MainContainer/Sidebar/SidebarContent/Root/TabBar/MaintenanceTabButton
@onready var relics_tab_button: Button = $MainContainer/Sidebar/SidebarContent/Root/TabBar/RelicsTabButton
@onready var map_tab_button: Button = $MainContainer/Sidebar/SidebarContent/Root/TabBar/MapTabButton
@onready var close_button: Button = $MainContainer/Sidebar/SidebarContent/Root/TopBar/CloseButton
@onready var maintenance_page: Control = $MainContainer/ContentArea/Panel/MarginContainer/PageContainer/MaintenancePage
@onready var relics_page: Control = $MainContainer/ContentArea/Panel/MarginContainer/PageContainer/RelicsPage
@onready var map_page: Control = $MainContainer/ContentArea/Panel/MarginContainer/PageContainer/MapPage

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
var _hud_presenter: Node = null
var _is_visible: bool = false
var _combat_visible: bool = false
var _current_tab: InfoTab = InfoTab.MAINTENANCE
var _panel_paused_tree: bool = false
var _embedded_map: Control = null

var maintenance_controller: Control
var relics_controller: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_find_wave_manager()
	_connect_signals()
	_connect_localization()
	_apply_localization()
	_setup_page_controllers()
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
		# Y 键继续下一波（仅在整备页且可操作时）
		if _current_tab == InfoTab.MAINTENANCE and _can_perform_maintenance():
			if InputManager.wave_continue_action.is_triggered():
				_on_continue_pressed()

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
	EventBus.game_started.connect(_on_game_started)

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
	if maintenance_controller and maintenance_controller.has_method("set_wave_manager"):
		maintenance_controller.call("set_wave_manager", _wave_manager)

func _setup_page_controllers() -> void:
	maintenance_controller = MaintenancePageControllerScript.new()
	maintenance_controller.name = "MaintenancePageController"
	var maintenance_content: Control = maintenance_page.get_node("Scroll/Margin/Content")
	maintenance_controller.wave_label = maintenance_content.get_node("WaveLabel")
	maintenance_controller.status_label = maintenance_content.get_node("StatusLabel")
	maintenance_controller.timer_label = maintenance_content.get_node("TimerLabel")
	maintenance_controller.enemy_info_label = maintenance_content.get_node("EnemyInfoLabel")
	maintenance_controller.ship_health_label = maintenance_content.get_node("ShipHealthLabel")
	maintenance_controller.ship_health_bar = maintenance_content.get_node("ShipHealthBar")
	maintenance_controller.upgrade_currency_label = maintenance_content.get_node("UpgradeCurrencyLabel")
	maintenance_controller.maintenance_hint_label = maintenance_content.get_node("MaintenanceHintLabel")
	maintenance_controller.button_container = maintenance_content.get_node("ButtonContainer")
	maintenance_controller.continue_button = continue_button
	maintenance_controller.repair_button = repair_button
	maintenance_controller.upgrade_button = upgrade_button
	maintenance_controller.upgrade_section = upgrade_section
	maintenance_controller.upgrade_title_label = upgrade_title_label
	maintenance_controller.upgrade_list = upgrade_list
	maintenance_controller.set_wave_manager(_wave_manager)
	maintenance_controller.set_hud_presenter(_hud_presenter)
	maintenance_controller.connect("content_update_requested", _on_maintenance_content_update_requested)
	add_child(maintenance_controller)

	relics_controller = RelicsPageControllerScript.new()
	relics_controller.name = "RelicsPageController"
	var relics_content: Control = relics_page.get_node("Scroll/Margin/Content")
	relics_controller.relic_summary_label = relic_summary_label
	relics_controller.relic_list = relic_list
	relics_controller.set_hud_presenter(_hud_presenter)
	add_child(relics_controller)

func set_hud_presenter(presenter: Node) -> void:
	var presenter_changed := Callable(self, "_on_presenter_state_changed")
	if _hud_presenter and _hud_presenter.has_signal("presentation_changed") and _hud_presenter.is_connected("presentation_changed", presenter_changed):
		_hud_presenter.disconnect("presentation_changed", presenter_changed)

	_hud_presenter = presenter
	if _hud_presenter and _hud_presenter.has_signal("presentation_changed") and not _hud_presenter.is_connected("presentation_changed", presenter_changed):
		_hud_presenter.connect("presentation_changed", presenter_changed)

	if maintenance_controller and maintenance_controller.has_method("set_hud_presenter"):
		maintenance_controller.call("set_hud_presenter", presenter)
	if relics_controller and relics_controller.has_method("set_hud_presenter"):
		relics_controller.call("set_hud_presenter", presenter)

	_update_all_content()

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
	if not _combat_visible:
		return false
	var game_state := GameState.get_state()
	if _hud_presenter and _hud_presenter.has_method("get_game_state"):
		game_state = _hud_presenter.call("get_game_state")
	if game_state != GameState.State.PLAYING:
		return false

	var wave_state := -1
	if _hud_presenter and _hud_presenter.has_method("get_wave_state"):
		wave_state = _hud_presenter.call("get_wave_state")
	elif _wave_manager:
		wave_state = _wave_manager.get_state()
	return wave_state == WaveManager.State.ACTIVE_WAVE or wave_state == WaveManager.State.BETWEEN_WAVES

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

	# 隐藏 ScrollContainer，为地图浏览腾出空间
	var scroll := map_page.get_node_or_null("Scroll")
	if scroll:
		scroll.visible = false

	# 实例化嵌入式地图浏览器（只读、无 UI 覆盖层）
	var map_viewer_instance := MapViewerScene.instantiate()

	# 设置全屏填充
	map_viewer_instance.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_viewer_instance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_viewer_instance.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# 添加到地图页容器
	map_page.add_child(map_viewer_instance)
	_embedded_map = map_viewer_instance

	# 延迟一帧后刷新并居中（确保容器尺寸有效）
	map_viewer_instance.refresh_view.call_deferred()
	map_viewer_instance.recenter_view.call_deferred()

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
	if maintenance_controller and maintenance_controller.has_method("update_page"):
		maintenance_controller.call("update_page", _get_wave_overview_state(), _get_ship_health_state())
	if relics_controller and relics_controller.has_method("update_page"):
		relics_controller.call("update_page", _get_relics_state())
	_update_map_page()
	call_deferred("_sync_dynamic_layouts")

func _update_header_state() -> void:
	state_label.text = Localization.t(_get_panel_state_key())

func _get_panel_state_key() -> String:
	var wave_state := -1
	if _hud_presenter and _hud_presenter.has_method("get_wave_state"):
		wave_state = _hud_presenter.call("get_wave_state")
	elif _wave_manager:
		wave_state = _wave_manager.get_state()

	match wave_state:
		WaveManager.State.ACTIVE_WAVE:
			return "info.state.read_only"
		WaveManager.State.BETWEEN_WAVES:
			return "info.state.editable"
		WaveManager.State.COMPLETE:
			return "info.state.complete"
		_:
			return "info.state.inactive"

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
	if maintenance_controller and maintenance_controller.has_method("update_page"):
		maintenance_controller.call("update_page", _get_wave_overview_state(), _get_ship_health_state())

func _on_upgrade_pressed() -> void:
	if not _is_visible:
		return
	if maintenance_controller and maintenance_controller.has_method("toggle_upgrade_section"):
		maintenance_controller.call("toggle_upgrade_section")
	if maintenance_controller and maintenance_controller.has_method("update_page"):
		maintenance_controller.call("update_page", _get_wave_overview_state(), _get_ship_health_state())
	call_deferred("_sync_dynamic_layouts")

func _on_maintenance_content_update_requested() -> void:
	_update_all_content()

func _on_wave_started(_wave_number: int) -> void:
	if maintenance_controller and maintenance_controller.has_method("set_upgrade_section_open"):
		maintenance_controller.call("set_upgrade_section_open", false)
	_close_panel()

func _on_wave_complete(_wave_number: int) -> void:
	_open_panel(true)

func _on_all_waves_complete() -> void:
	if maintenance_controller and maintenance_controller.has_method("set_upgrade_section_open"):
		maintenance_controller.call("set_upgrade_section_open", false)
	_update_all_content()

func _on_intermission_started(_duration: float) -> void:
	if maintenance_controller and maintenance_controller.has_method("set_upgrade_section_open"):
		maintenance_controller.call("set_upgrade_section_open", false)
	_open_panel(true)

func _on_intermission_ended() -> void:
	_update_all_content()

func _on_game_over(_won: bool) -> void:
	if maintenance_controller and maintenance_controller.has_method("set_upgrade_section_open"):
		maintenance_controller.call("set_upgrade_section_open", false)
	_close_panel()

func _on_game_started() -> void:
	if maintenance_controller and maintenance_controller.has_method("set_upgrade_section_open"):
		maintenance_controller.call("set_upgrade_section_open", false)
	_current_tab = InfoTab.MAINTENANCE
	_update_tab_visibility()
	_update_all_content()

func _on_runtime_state_changed(_value_a = null, _value_b = null) -> void:
	if _is_visible or _combat_visible:
		_update_all_content()

func _on_presenter_state_changed() -> void:
	_on_runtime_state_changed()

func _on_wave_progress_updated(_enemies_remaining: int, _total_enemies: int) -> void:
	_on_runtime_state_changed()

func _get_wave_overview_state() -> Dictionary:
	if _hud_presenter and _hud_presenter.has_method("get_wave_overview_state"):
		return _hud_presenter.call("get_wave_overview_state")
	return {}

func _get_ship_health_state() -> Dictionary:
	if _hud_presenter and _hud_presenter.has_method("get_ship_health_state"):
		return _hud_presenter.call("get_ship_health_state")
	return {
		"current": 0.0,
		"maximum": 100.0,
		"has_ship": false,
	}

func _get_relics_state() -> Dictionary:
	if _hud_presenter and _hud_presenter.has_method("get_relics_state"):
		return _hud_presenter.call("get_relics_state", RelicsPageControllerScript.RELIC_ITEMS.size())
	return {
		"owned": 0,
		"total": RelicsPageControllerScript.RELIC_ITEMS.size(),
	}

func _get_map_overview_state() -> Dictionary:
	if _hud_presenter and _hud_presenter.has_method("get_map_overview_state"):
		return _hud_presenter.call("get_map_overview_state")
	return {}

func _update_map_page() -> void:
	var map_state := _get_map_overview_state()
	var graph = map_state.get("graph")
	var visited_count := int(map_state.get("visited_count", 0))
	var current_chapter := int(map_state.get("current_chapter", 0))
	var reachable_count := int(map_state.get("reachable_count", 0))
	var current_node = map_state.get("current_node", null)
	map_overview_label.text = Localization.t("info.map.overview", "", {
		"chapter": current_chapter + 1,
		"visited": visited_count,
	})
	map_current_node_label.text = Localization.t("info.map.current_node", "", {
		"node": _get_current_node_text(current_node),
	})
	map_choices_label.text = Localization.t("info.map.reachable", "", {
		"count": reachable_count,
	})

	for child in map_list.get_children():
		child.queue_free()

	if graph == null:
		var empty_label := Label.new()
		empty_label.text = Localization.t("info.map.none")
		map_list.add_child(empty_label)
		return

	for chapter_index in range(FloorGraphScript.CHAPTER_COUNT):
		map_list.add_child(_create_map_chapter_row(chapter_index, graph.get_chapter_nodes(chapter_index), current_node))

func _create_map_chapter_row(chapter_index: int, chapter_nodes: Array, current_node = null) -> VBoxContainer:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var title := Label.new()
	title.text = Localization.t("info.map.chapter_title", "", {"chapter": chapter_index + 1})
	title.add_theme_font_size_override("font_size", 21)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(title)

	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.text = _build_chapter_summary_text(chapter_nodes, current_node)
	container.add_child(body)

	return container

func _build_chapter_summary_text(chapter_nodes: Array, current_node = null) -> String:
	if chapter_nodes.is_empty():
		return Localization.t("info.map.none")
	var parts: Array[String] = []
	for node in chapter_nodes:
		parts.append("%s · %s" % [_get_node_display_name(node), _get_node_state_text(node, current_node)])
	return "\n".join(parts)

func _get_current_node_text(current_node = null) -> String:
	if current_node == null:
		return Localization.t("map.node_type.unknown")
	return _get_node_display_name(current_node)

func _get_node_display_name(node) -> String:
	var type_key := "map.node_type.%s" % String(node.get_type_name())
	return Localization.t(type_key)

func _get_node_state_text(node, current_node = null) -> String:
	if current_node != null and node.id == current_node.id:
		return Localization.t("info.map.state.current")
	if node.visited:
		return Localization.t("info.map.state.visited")
	if current_node != null and current_node.connections.has(node.id):
		return Localization.t("info.map.state.reachable")
	return Localization.t("info.map.state.locked")
