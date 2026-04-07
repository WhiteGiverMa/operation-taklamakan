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

var is_manual_mode: bool = false
var _can_fire: bool = true
var _fire_timer: float = 0.0
var _player_in_range: bool = false
var _repair_timer: float = 0.0
var _toughness_bar: ProgressBar

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
	EventBus.ship_damaged.connect(_on_ship_damaged)
	toughness_component.toughness_changed.connect(_on_toughness_changed)
	toughness_component.paralysis_started.connect(_on_paralysis_started)
	toughness_component.paralysis_ended.connect(_on_paralysis_ended)

	_spawn_toughness_bar()
	_update_toughness_bar()
	_update_visual_state()


func _physics_process(delta: float) -> void:
	_handle_repair(delta)
	_handle_fire_cooldown(delta)
	_handle_interact_input()

	if is_manual_mode:
		if toughness_component.is_paralyzed():
			return
		_rotate_barrel_toward_mouse()
		_handle_manual_fire_input()
	elif GameState.auto_fire_unlocked and not toughness_component.is_paralyzed():
		_handle_auto_fire()


func _rotate_barrel_toward_mouse() -> void:
	var mouse_pos := get_global_mouse_position()
	var angle := global_position.angle_to_point(mouse_pos)
	barrel.rotation = angle


func _handle_fire_cooldown(delta: float) -> void:
	if not _can_fire:
		_fire_timer -= delta
		if _fire_timer <= 0.0:
			_can_fire = true


func _handle_manual_fire_input() -> void:
	if InputManager.fire_action.is_triggered() and _can_fire and not toughness_component.is_paralyzed():
		_fire_at_position(get_global_mouse_position())

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

	_can_fire = false
	_fire_timer = fire_rate

	var direction := (target_position - barrel.global_position).normalized()

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
	InputManager.activate_turret_manual()
	_update_visual_state()


func exit_manual_mode() -> void:
	is_manual_mode = false
	InputManager.deactivate_turret_manual()
	_update_visual_state()


func take_damage(data: DamageData) -> float:
	return toughness_component.take_damage(data)


func _on_player_entered(body: Node2D) -> void:
	if _is_player(body):
		_player_in_range = true
		_update_visual_state()


func _on_player_exited(body: Node2D) -> void:
	if _is_player(body):
		_player_in_range = false
		_repair_timer = 0.0
		if is_manual_mode:
			exit_manual_mode()
		else:
			_update_visual_state()


func _is_player(body: Node2D) -> bool:
	return body.is_in_group("player") or body.has_method("is_player") or body.name == "Player" or body.name == "PlayerCharacter"


func _handle_interact_input() -> void:
	if not _player_in_range or is_manual_mode or toughness_component.is_paralyzed():
		return

	if InputManager.interact_action.is_triggered():
		enter_manual_mode()


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
