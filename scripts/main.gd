extends Node2D

const TANK_SCENE := preload("res://scenes/enemy/tank.tscn")
const MECHANICAL_DOG_SCENE := preload("res://scenes/enemy/mechanical_dog.tscn")
const BOSS_TANK_SCENE := preload("res://scenes/enemy/boss_tank.tscn")
const MAP_SCREEN_SCENE := preload("res://scenes/ui/map_screen.tscn")
const SHOP_SCREEN_SCENE := preload("res://scenes/map/shop_screen.tscn")
const TURRET_SCENE := preload("res://scenes/turret/turret.tscn")

enum FlowState { MAP, COMBAT, SHOP, TRANSITION }

var _flow_state: FlowState = FlowState.TRANSITION
var _map_screen_root: Control = null
var _map_screen: Control = null
var _shop_screen: Control = null

@onready var landship: Landship = $Landship
@onready var ui_layer: CanvasLayer = $UILayer
@onready var hud: Control = $UILayer/HUD
@onready var wave_ui: Control = $UILayer/WaveUI

func _ready() -> void:
	_setup_wave_manager()
	_setup_overlay_screens()
	_connect_signals()
	_ensure_starting_turrets()
	GameState.start_game()
	_show_map_screen()

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

func _connect_signals() -> void:
	MapManager.current_node_changed.connect(_on_current_node_changed)
	EventBus.wave_all_complete.connect(_on_wave_all_complete)
	EventBus.shop_entered.connect(_on_shop_entered)
	EventBus.game_started.connect(_on_game_started)
	EventBus.game_over.connect(_on_game_over)

func _on_game_started() -> void:
	_clear_runtime_enemies()
	_ensure_starting_turrets()
	_show_map_screen()

func _on_game_over(_won: bool) -> void:
	_flow_state = FlowState.TRANSITION
	_set_combat_visibility(true)
	if _map_screen_root:
		_map_screen_root.visible = false
	if _shop_screen:
		_shop_screen.visible = false

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

func _slot_has_turret(slot: Node2D) -> bool:
	for child in slot.get_children():
		if child is Turret:
			return true
	return false

func _show_map_screen() -> void:
	_flow_state = FlowState.MAP
	_set_combat_visibility(false)
	if _shop_screen:
		_shop_screen.visible = false
	if _map_screen_root:
		_map_screen_root.visible = true

func _start_combat_for_current_layer() -> void:
	_flow_state = FlowState.COMBAT
	if _map_screen_root:
		_map_screen_root.visible = false
	_set_combat_visibility(true)
	_clear_runtime_enemies()
	WaveManager.start_combat_session(MapManager.current_layer + 1)

func _set_combat_visibility(is_visible: bool) -> void:
	landship.visible = is_visible
	landship.process_mode = Node.PROCESS_MODE_INHERIT if is_visible else Node.PROCESS_MODE_DISABLED
	hud.visible = is_visible
	wave_ui.visible = is_visible

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
	_flow_state = FlowState.SHOP
	_set_combat_visibility(false)
	if _map_screen_root:
		_map_screen_root.visible = false
	if _shop_screen:
		_shop_screen.visible = true
		_shop_screen.call("_show_shop")

func _on_shop_closed() -> void:
	if GameState.get_state() == GameState.State.GAME_OVER:
		return
	_show_map_screen()

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
