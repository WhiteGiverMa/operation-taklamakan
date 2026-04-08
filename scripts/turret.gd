class_name Turret
extends Node2D

## Manual-fire turret. Player approaches → clicks → enters manual mode → mouse aim + click to fire.

signal turret_fired(target: Vector2)

const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const TOUGHNESS_BAR_SCENE := preload("res://scenes/ui/toughness_bar.tscn")

@export var interaction_range: float = 150.0
@export var projectile_speed: float = 600.0
@export var projectile_damage: float = 15.0
@export var fire_rate: float = 0.5
@export var toughness_damage_radius: float = 180.0
@export var repair_duration: float = 2.0
@export_range(0.0, 180.0, 1.0) var manual_fire_arc_half_angle_degrees: float = 90.0

var is_manual_mode: bool = false
var _can_fire: bool = true
var _fire_timer: float = 0.0
var _player_in_range: bool = false
var _repair_timer: float = 0.0
var _toughness_bar: ProgressBar
var _player: Node2D
var _manual_arc_center_angle: float = 0.0
var _skip_manual_exit_once: bool = false

@onready var barrel: Node2D = $Barrel
@onready var base: ColorRect = $Base
@onready var interaction_area: Area2D = $InteractionArea
@onready var toughness_component: ToughnessComponent = $ToughnessComponent

func _ready() -> void:
	interaction_area.collision_layer = 0
	interaction_area.set_collision_mask_value(1, true)
	interaction_area.input_pickable = true

	interaction_area.body_entered.connect(_on_player_entered)
	interaction_area.body_exited.connect(_on_player_exited)
	if not InputManager.fire_action.just_triggered.is_connected(_on_fire_action_just_triggered):
		InputManager.fire_action.just_triggered.connect(_on_fire_action_just_triggered)
	EventBus.ship_damaged.connect(_on_ship_damaged)
	toughness_component.toughness_changed.connect(_on_toughness_changed)
	toughness_component.paralysis_started.connect(_on_paralysis_started)
	toughness_component.paralysis_ended.connect(_on_paralysis_ended)
	_player = _resolve_player()
	_manual_arc_center_angle = _resolve_manual_arc_center_angle()

	_spawn_toughness_bar()
	_update_toughness_bar()
	_update_visual_state()


func _physics_process(delta: float) -> void:
	_update_player_in_range()
	_handle_repair(delta)
	_handle_fire_cooldown(delta)

	if not is_manual_mode and GameState.auto_fire_unlocked and not toughness_component.is_paralyzed():
		_handle_auto_fire()


func _process(_delta: float) -> void:
	_handle_interact_input()

	if is_manual_mode:
		if toughness_component.is_paralyzed():
			return
		if _handle_manual_exit_input():
			return
		_rotate_barrel_toward_mouse()


func _rotate_barrel_toward_mouse() -> void:
	var mouse_pos := get_global_mouse_position()
	var angle := global_position.angle_to_point(mouse_pos)
	barrel.rotation = _clamp_angle_to_manual_arc(angle)


func _handle_fire_cooldown(delta: float) -> void:
	if not _can_fire:
		_fire_timer -= delta
		if _fire_timer <= 0.0:
			_can_fire = true


func _handle_manual_fire_input() -> void:
	if InputManager.fire_action.is_triggered() and _can_fire and not toughness_component.is_paralyzed() and _is_position_within_manual_arc(get_global_mouse_position()):
		_fire_at_position(get_global_mouse_position())


func _on_fire_action_just_triggered() -> void:
	if not is_manual_mode:
		return
	if not _can_fire or toughness_component.is_paralyzed():
		return

	var mouse_position := get_global_mouse_position()
	if not _is_position_within_manual_arc(mouse_position):
		return

	_fire_at_position(mouse_position)

func _handle_auto_fire() -> void:
	if not _can_fire:
		return

	var target := _find_auto_target()
	if target == null:
		return

	barrel.rotation = barrel.global_position.angle_to_point(target.global_position)
	_fire_at_position(target.global_position, target)


func _find_auto_target() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var closest_distance := INF

	for candidate in enemies:
		if not (candidate is Node2D) or not is_instance_valid(candidate):
			continue
		var enemy := candidate as Node2D
		var distance := global_position.distance_to(enemy.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest = enemy

	return closest


func _fire_at_position(target_position: Vector2, target: Node2D = null) -> void:
	if toughness_component.is_paralyzed():
		return
	if is_manual_mode and not _is_position_within_manual_arc(target_position):
		return

	_can_fire = false
	_fire_timer = fire_rate

	var firing_angle := barrel.global_position.angle_to_point(target_position)
	if is_manual_mode:
		firing_angle = _clamp_angle_to_manual_arc(firing_angle)
	barrel.rotation = firing_angle
	var direction := Vector2.RIGHT.rotated(firing_angle)

	var projectile := PROJECTILE_SCENE.instantiate() as Node2D
	projectile.global_position = barrel.global_position
	projectile.setup(direction, projectile_speed, projectile_damage * GameState.turret_damage_multiplier, self)
	get_tree().root.add_child(projectile)

	turret_fired.emit(target_position)
	EventBus.turret_fired.emit(self, target)


func enter_manual_mode() -> void:
	if toughness_component.is_paralyzed():
		return
	is_manual_mode = true
	_skip_manual_exit_once = true
	InputManager.activate_turret_manual()
	_update_visual_state()


func exit_manual_mode() -> void:
	if not is_manual_mode:
		return
	is_manual_mode = false
	_skip_manual_exit_once = false
	InputManager.deactivate_turret_manual()
	_update_visual_state()


func take_damage(data: DamageData) -> float:
	return toughness_component.take_damage(data)


func _on_player_entered(body: Node2D) -> void:
	if _is_player(body):
		_player = body
		_set_player_in_range(true)


func _on_player_exited(body: Node2D) -> void:
	if _is_player(body):
		_set_player_in_range(false)
		_repair_timer = 0.0
		if is_manual_mode:
			exit_manual_mode()


func _is_player(body: Node2D) -> bool:
	return body.is_in_group("player") or body.has_method("is_player") or body.name == "Player" or body.name == "PlayerCharacter"


func _handle_interact_input() -> void:
	if not _player_in_range or is_manual_mode or toughness_component.is_paralyzed():
		return

	if InputManager.interact_action.is_triggered():
		enter_manual_mode()


func _handle_manual_exit_input() -> bool:
	if _skip_manual_exit_once:
		_skip_manual_exit_once = false
		return false

	if InputManager.interact_action.is_triggered() or InputManager.move_action.value_axis_2d.length_squared() > 0.0:
		exit_manual_mode()
		return true
	return false


func _handle_repair(delta: float) -> void:
	if not _player_in_range or not toughness_component.is_paralyzed():
		_repair_timer = 0.0
		return

	if InputManager.repair_action.is_triggered():
		_repair_timer += delta
		if _repair_timer >= repair_duration:
			toughness_component.repair_full()
			_repair_timer = 0.0
	else:
		_repair_timer = 0.0


func _on_ship_damaged(amount: float, source: Node) -> void:
	if amount <= 0.0 or source == null or not (source is Node2D):
		return

	var source_2d := source as Node2D
	if source_2d.global_position.distance_to(global_position) <= toughness_damage_radius:
		toughness_component.apply_damage(amount)


func _on_toughness_changed(_old_value: float, _new_value: float) -> void:
	_update_toughness_bar()
	_update_visual_state()


func _on_paralysis_started() -> void:
	if is_manual_mode:
		exit_manual_mode()
	_update_visual_state()


func _on_paralysis_ended() -> void:
	_update_visual_state()


func _spawn_toughness_bar() -> void:
	_toughness_bar = TOUGHNESS_BAR_SCENE.instantiate() as ProgressBar
	if _toughness_bar == null:
		return
	add_child(_toughness_bar)


func _update_toughness_bar() -> void:
	if _toughness_bar == null:
		return

	_toughness_bar.max_value = toughness_component.max_toughness
	_toughness_bar.value = toughness_component.current_toughness
	_toughness_bar.modulate = Color(1.0, 0.4, 0.4) if toughness_component.is_paralyzed() else Color.WHITE


func _update_visual_state() -> void:
	if toughness_component != null and toughness_component.is_paralyzed():
		base.modulate = Color(1.0, 0.25, 0.25)
	elif is_manual_mode:
		base.modulate = Color.GREEN
	elif _player_in_range:
		base.modulate = Color.YELLOW
	else:
		base.modulate = Color.WHITE


func _update_player_in_range() -> void:
	if not is_instance_valid(_player):
		_player = _resolve_player()
	if not is_instance_valid(_player):
		_set_player_in_range(false)
		return

	_set_player_in_range(global_position.distance_to(_player.global_position) <= interaction_range)


func _set_player_in_range(in_range: bool) -> void:
	if _player_in_range == in_range:
		return

	_player_in_range = in_range
	if not _player_in_range:
		_repair_timer = 0.0
		if is_manual_mode:
			exit_manual_mode()
			return

	_update_visual_state()


func _resolve_player() -> Node2D:
	var ship := get_tree().get_first_node_in_group("ship")
	if ship != null:
		var player_on_ship := ship.get_node_or_null("PlayerCharacter") as Node2D
		if player_on_ship != null:
			return player_on_ship

	return get_tree().get_first_node_in_group("player") as Node2D


func _resolve_manual_arc_center_angle() -> float:
	var ship := get_tree().get_first_node_in_group("ship") as Node2D
	if ship == null:
		return 0.0

	var outward := global_position - ship.global_position
	if outward.length_squared() <= 0.001:
		return 0.0

	return outward.angle()


func _is_position_within_manual_arc(target_position: Vector2) -> bool:
	return _is_angle_within_manual_arc(barrel.global_position.angle_to_point(target_position))


func _is_angle_within_manual_arc(angle: float) -> bool:
	var relative_angle := wrapf(angle - _manual_arc_center_angle, -PI, PI)
	var half_arc := deg_to_rad(manual_fire_arc_half_angle_degrees)
	return absf(relative_angle) <= half_arc


func _clamp_angle_to_manual_arc(angle: float) -> float:
	var relative_angle := wrapf(angle - _manual_arc_center_angle, -PI, PI)
	var half_arc := deg_to_rad(manual_fire_arc_half_angle_degrees)
	return _manual_arc_center_angle + clampf(relative_angle, -half_arc, half_arc)
