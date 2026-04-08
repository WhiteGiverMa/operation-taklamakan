extends Node2D

const TANK_SCENE := preload("res://scenes/enemy/tank.tscn")
const MECHANICAL_DOG_SCENE := preload("res://scenes/enemy/mechanical_dog.tscn")
const BOSS_TANK_SCENE := preload("res://scenes/enemy/boss_tank.tscn")
const MAP_SCREEN_SCENE := preload("res://scenes/ui/map_screen.tscn")
const SHOP_SCREEN_SCENE := preload("res://scenes/map/shop_screen.tscn")
const TURRET_SCENE := preload("res://scenes/turret/turret.tscn")
const MAIN_MENU_SCENE := preload("res://scenes/ui/main_menu.tscn")
const SETTINGS_MENU_SCENE := preload("res://scenes/ui/settings_menu.tscn")
const PAUSE_MENU_SCENE := preload("res://scenes/ui/pause_menu.tscn")

enum FlowState { MAP, COMBAT, SHOP, TRANSITION }
enum SettingsReturnTarget { MAIN_MENU, PAUSE_MENU }

var _flow_state: FlowState = FlowState.TRANSITION
var _shop_return_flow_state: FlowState = FlowState.MAP
var _map_screen_root: Control = null
var _map_screen: Control = null
var _shop_screen: Control = null
var _main_menu: Control = null
var _settings_menu: Control = null
var _pause_menu: Control = null
var _settings_return_target: SettingsReturnTarget = SettingsReturnTarget.MAIN_MENU

@onready var landship: Landship = $Landship
@onready var ui_layer: CanvasLayer = $UILayer
@onready var hud: Control = $UILayer/HUD
@onready var wave_ui: Control = $UILayer/WaveUI

func _ready() -> void:
	_setup_wave_manager()
	_setup_overlay_screens()
	_connect_signals()
	_ensure_starting_turrets()
	_show_main_menu(false)

func _setup_wave_manager() -> void:
	# Assign enemy scenes to WaveManager
	WaveManager.tank_scene = TANK_SCENE
	WaveManager.mechanical_dog_scene = MECHANICAL_DOG_SCENE
	WaveManager.boss_tank_scene = BOSS_TANK_SCENE

func _setup_overlay_screens() -> void:
	_map_screen_root = MAP_SCREEN_SCENE.instantiate() as Control
	ui_layer.add_child(_map_screen_root)
	_map_screen_root.visible = false
	_map_screen = _map_screen_root.get_node_or_null("MapScreen")

	_shop_screen = SHOP_SCREEN_SCENE.instantiate() as Control
	ui_layer.add_child(_shop_screen)
	_shop_screen.visible = false
	if _shop_screen.has_signal("shop_closed"):
		_shop_screen.shop_closed.connect(_on_shop_closed)

	_main_menu = MAIN_MENU_SCENE.instantiate() as Control
	ui_layer.add_child(_main_menu)
	_main_menu.visible = false
	_main_menu.continue_requested.connect(_on_main_menu_continue_requested)
	_main_menu.new_game_requested.connect(_on_main_menu_new_game_requested)
	_main_menu.settings_requested.connect(_on_main_menu_settings_requested)

	_pause_menu = PAUSE_MENU_SCENE.instantiate() as Control
	ui_layer.add_child(_pause_menu)
	_pause_menu.visible = false
	_pause_menu.resume_requested.connect(_on_pause_resume_requested)
	_pause_menu.settings_requested.connect(_on_pause_settings_requested)
	_pause_menu.main_menu_requested.connect(_on_pause_main_menu_requested)

	_settings_menu = SETTINGS_MENU_SCENE.instantiate() as Control
	ui_layer.add_child(_settings_menu)
	_settings_menu.visible = false
	_settings_menu.back_requested.connect(_on_settings_back_requested)

func _connect_signals() -> void:
	MapManager.current_node_changed.connect(_on_current_node_changed)
	EventBus.wave_all_complete.connect(_on_wave_all_complete)
	EventBus.shop_entered.connect(_on_shop_entered)
	EventBus.game_started.connect(_on_game_started)
	EventBus.game_over.connect(_on_game_over)
	GameState.game_state_changed.connect(_on_game_state_changed)

func _on_game_started() -> void:
	_shop_return_flow_state = FlowState.MAP
	_hide_menu_overlays()
	_reset_turrets_to_starting_loadout()
	_clear_runtime_enemies()
	_show_map_screen()

func _on_game_over(_won: bool) -> void:
	_flow_state = FlowState.TRANSITION
	_shop_return_flow_state = FlowState.MAP
	InputManager.activate_menu()
	_hide_menu_overlays()
	_set_combat_visibility(false)
	if _map_screen_root:
		_map_screen_root.visible = false
	if _shop_screen:
		_shop_screen.visible = false

func _on_game_state_changed(state: int) -> void:
	match state:
		GameState.State.PAUSED:
			if GameState.has_active_run and not _settings_menu.visible and not _main_menu.visible:
				InputManager.activate_pause()
				_pause_menu.visible = true
		GameState.State.PLAYING:
			if _pause_menu:
				_pause_menu.visible = false
		_:
			pass

func _ensure_starting_turrets() -> void:
	var slots := landship.get_turret_slots()
	if slots.is_empty():
		return

	var target_indices := [1, 4]
	for index in target_indices:
		if index >= slots.size():
			continue
		var slot := slots[index]
		if _slot_has_turret(slot):
			continue
		var turret := TURRET_SCENE.instantiate() as Node2D
		slot.add_child(turret)
		EventBus.turret_placed.emit(turret, index)

func _reset_turrets_to_starting_loadout() -> void:
	for slot in landship.get_turret_slots():
		for child in slot.get_children():
			if child is Turret:
				slot.remove_child(child)
				child.queue_free()
	_ensure_starting_turrets()

func _slot_has_turret(slot: Node2D) -> bool:
	for child in slot.get_children():
		if child is Turret:
			return true
	return false

func _show_map_screen() -> void:
	_apply_flow_state(FlowState.MAP)

func _start_combat_for_current_layer() -> void:
	_apply_flow_state(FlowState.COMBAT)
	_clear_runtime_enemies()
	WaveManager.start_combat_session(MapManager.current_layer + 1)

func _set_combat_visibility(should_show: bool) -> void:
	landship.visible = should_show
	landship.process_mode = Node.PROCESS_MODE_INHERIT if should_show else Node.PROCESS_MODE_DISABLED
	hud.visible = should_show
	hud.call("set_input_hints_enabled", should_show)
	if wave_ui and wave_ui.has_method("set_combat_visibility"):
		wave_ui.call("set_combat_visibility", should_show)
	elif wave_ui:
		wave_ui.visible = should_show

func _on_current_node_changed(node) -> void:
	if node == null:
		return

	match node.type:
		MapNode.TYPE_COMBAT, MapNode.TYPE_ELITE, MapNode.TYPE_BOSS, MapNode.TYPE_END:
			_start_combat_for_current_layer()
		MapNode.TYPE_SHOP:
			_on_shop_entered()
		MapNode.TYPE_REST:
			_apply_rest_heal()
			_show_map_screen()
		_:
			_show_map_screen()

func _on_shop_entered() -> void:
	if _flow_state == FlowState.SHOP:
		return
	_shop_return_flow_state = _flow_state
	_flow_state = FlowState.SHOP
	InputManager.activate_shop()
	_hide_menu_overlays()
	_set_combat_visibility(false)
	if _map_screen_root:
		_map_screen_root.visible = false
	if _shop_screen:
		_shop_screen.visible = true
		_shop_screen.call("_show_shop")

func _on_shop_closed() -> void:
	if GameState.get_state() == GameState.State.GAME_OVER:
		return
	_apply_flow_state(_shop_return_flow_state)

func _apply_rest_heal() -> void:
	if landship and landship.health_component:
		landship.health_component.heal(landship.max_health * 0.3)

func _on_wave_all_complete() -> void:
	WaveManager.end_combat_session()
	_clear_runtime_enemies()

	MapManager.go_to_layer_start(MapManager.current_layer + 1)
	GameState.advance_layer()
	_show_map_screen()

func _clear_runtime_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			enemy.queue_free()

func _show_main_menu(preserve_run: bool) -> void:
	if _main_menu == null:
		return
	InputManager.activate_menu()
	_hide_gameplay_flow()
	_hide_menu_overlays()
	if preserve_run and GameState.has_active_run:
		GameState.return_to_menu(true)
	else:
		GameState.return_to_menu(false)
	_main_menu.visible = true
	_main_menu.refresh_state()

func _hide_gameplay_flow() -> void:
	_set_combat_visibility(false)
	if _map_screen_root:
		_map_screen_root.visible = false
	if _shop_screen:
		_shop_screen.visible = false

func _hide_menu_overlays() -> void:
	if _main_menu:
		_main_menu.visible = false
	if _settings_menu:
		_settings_menu.visible = false
	if _pause_menu:
		_pause_menu.visible = false

func _apply_flow_state(next_flow_state: FlowState) -> void:
	_flow_state = next_flow_state
	_hide_menu_overlays()
	match next_flow_state:
		FlowState.COMBAT:
			InputManager.activate_combat()
			_set_combat_visibility(true)
			if _map_screen_root:
				_map_screen_root.visible = false
			if _shop_screen:
				_shop_screen.visible = false
		FlowState.SHOP:
			InputManager.activate_shop()
			_set_combat_visibility(false)
			if _map_screen_root:
				_map_screen_root.visible = false
			if _shop_screen:
				_shop_screen.visible = true
		FlowState.MAP:
			InputManager.activate_map()
			_set_combat_visibility(false)
			if _shop_screen:
				_shop_screen.visible = false
			if _map_screen_root:
				_map_screen_root.visible = true
		_:
			InputManager.restore_flow_context()
			_set_combat_visibility(false)
			if _shop_screen:
				_shop_screen.visible = false
			if _map_screen_root:
				_map_screen_root.visible = false

func _restore_current_flow() -> void:
	_apply_flow_state(_flow_state)

func _on_main_menu_continue_requested() -> void:
	if not GameState.has_active_run:
		return
	_hide_menu_overlays()
	GameState.resume_game()
	_restore_current_flow()

func _on_main_menu_new_game_requested() -> void:
	GameState.start_game()

func _on_main_menu_settings_requested() -> void:
	_settings_return_target = SettingsReturnTarget.MAIN_MENU
	InputManager.activate_settings()
	if _main_menu:
		_main_menu.visible = false
	if _settings_menu:
		_settings_menu.visible = true

func _on_pause_resume_requested() -> void:
	_hide_menu_overlays()
	GameState.resume_game()
	InputManager.restore_flow_context()
	_restore_current_flow()

func _on_pause_settings_requested() -> void:
	_settings_return_target = SettingsReturnTarget.PAUSE_MENU
	InputManager.activate_settings()
	if _pause_menu:
		_pause_menu.visible = false
	if _settings_menu:
		_settings_menu.visible = true

func _on_pause_main_menu_requested() -> void:
	_show_main_menu(true)

func _on_settings_back_requested() -> void:
	if _settings_menu:
		_settings_menu.visible = false
	match _settings_return_target:
		SettingsReturnTarget.PAUSE_MENU:
			InputManager.activate_pause()
			if _pause_menu:
				_pause_menu.visible = true
		_:
			InputManager.activate_menu()
			if _main_menu:
				_main_menu.visible = true
				_main_menu.refresh_state()
