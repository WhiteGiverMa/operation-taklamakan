class_name BattleMaid
extends CharacterBody2D

## 舰上 AI 队友：优先维修瘫痪炮塔；空闲时自动索敌射击。

const WEAPON_DEF := preload("res://scripts/resources/weapon_definition.gd")

signal repair_started(turret: Turret)
signal repair_completed(turret: Turret)

@export var speed: float = 210.0
@export var knockback_decay: float = 1400.0
@export var max_knockback_speed: float = 520.0
@export var impact_cooldown: float = 0.18
@export var repair_stop_distance: float = 44.0
@export var idle_anchor: Vector2 = Vector2(0.0, 90.0)
@export var idle_reposition_tolerance: float = 12.0
@export var weapon_definition: Resource
@export var repair_scan_interval: float = 0.2

const SHIP_BOUNDS_X: float = 380.0
const SHIP_BOUNDS_Y: float = 180.0


enum MaidState {
	IDLE,
	MOVING_TO_REPAIR,
	REPAIRING,
	COMBAT,
}

var _state: MaidState = MaidState.IDLE
var _weapon_damage: float = 6.0
var _weapon_fire_rate: float = 0.45
var _weapon_projectile_speed: float = 600.0
var _attack_range: float = 900.0
var _knockback_velocity: Vector2 = Vector2.ZERO
var _impact_cooldown_timer: float = 0.0
var _can_fire: bool = true
var _fire_timer: float = 0.0
var _repair_timer: float = 0.0
var _repair_scan_timer: float = 0.0
var _repair_state_announced: bool = false
var _repair_target: Turret
var _combat_target: Node2D
var _tracked_turrets: Array[Turret] = []

@onready var visual: ColorRect = $Visual
@onready var barrel: Node2D = $Barrel
@onready var muzzle: Marker2D = $Barrel/Muzzle
@onready var repair_indicator: ColorRect = $RepairIndicator


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(6, true)
	set_collision_mask_value(3, true)
	set_collision_mask_value(5, true)
	_apply_weapon_definition()
	_register_existing_turrets()
	if not EventBus.turret_placed.is_connected(_on_turret_placed):
		EventBus.turret_placed.connect(_on_turret_placed, CONNECT_REFERENCE_COUNTED)
	_update_visual_state()


func _physics_process(delta: float) -> void:
	_update_impact_cooldown(delta)
	_update_fire_cooldown(delta)
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
	_update_repair_scan(delta)
	_refresh_combat_target()
	_update_state()
	_process_state(delta)
	move_and_slide()
	_constrain_to_bounds()
	_handle_attack()
	_update_visual_state()


func receive_impact(data: DamageData) -> bool:
	if data == null or data.knockback.length_squared() <= 0.001:
		return false
	if _impact_cooldown_timer > 0.0:
		return false

	_impact_cooldown_timer = impact_cooldown
	_knockback_velocity += _global_vector_to_local(data.knockback)
	if _knockback_velocity.length() > max_knockback_speed:
		_knockback_velocity = _knockback_velocity.normalized() * max_knockback_speed
	_repair_timer = 0.0
	_repair_state_announced = false
	return true


func _apply_weapon_definition() -> void:
	if weapon_definition == null:
		return
	if not (weapon_definition is WEAPON_DEF):
		push_warning("[BattleMaid] weapon_definition 不是 WeaponDefinition，继续使用默认武器参数")
		return
	_weapon_damage = weapon_definition.damage
	_weapon_fire_rate = weapon_definition.fire_rate
	_weapon_projectile_speed = weapon_definition.projectile_speed
	_attack_range = weapon_definition.attack_range


func _register_existing_turrets() -> void:
	var ship := get_parent() as Landship
	if ship == null:
		return
	for slot in ship.get_turret_slots():
		for child in slot.get_children():
			if child is Turret:
				_track_turret(child as Turret)
	_refresh_repair_target()


func _track_turret(turret: Turret) -> void:
	if turret == null or not is_instance_valid(turret):
		return
	if _tracked_turrets.has(turret):
		return
	_tracked_turrets.append(turret)
	if turret.toughness_component != null:
		if not turret.toughness_component.paralysis_started.is_connected(_on_turret_paralysis_started):
			turret.toughness_component.paralysis_started.connect(_on_turret_paralysis_started.bind(turret), CONNECT_REFERENCE_COUNTED)
		if not turret.toughness_component.paralysis_ended.is_connected(_on_turret_paralysis_ended):
			turret.toughness_component.paralysis_ended.connect(_on_turret_paralysis_ended.bind(turret), CONNECT_REFERENCE_COUNTED)


func _on_turret_placed(turret: Node2D, _slot_index: int) -> void:
	if turret is Turret:
		_track_turret(turret as Turret)
		_refresh_repair_target()


func _on_turret_paralysis_started(turret: Turret) -> void:
	_track_turret(turret)
	_refresh_repair_target()


func _on_turret_paralysis_ended(turret: Turret) -> void:
	if turret == _repair_target and turret.toughness_component != null and not turret.toughness_component.is_paralyzed():
		_repair_target = null
		_repair_timer = 0.0
		_repair_state_announced = false
	_refresh_repair_target()


func _update_repair_scan(delta: float) -> void:
	_repair_scan_timer -= delta
	if _repair_scan_timer > 0.0:
		return
	_repair_scan_timer = repair_scan_interval
	_refresh_repair_target()


func _update_impact_cooldown(delta: float) -> void:
	if _impact_cooldown_timer > 0.0:
		_impact_cooldown_timer = maxf(_impact_cooldown_timer - delta, 0.0)


func _update_fire_cooldown(delta: float) -> void:
	if not _can_fire:
		_fire_timer -= delta
		if _fire_timer <= 0.0:
			_can_fire = true


func _refresh_repair_target() -> void:
	var closest: Turret = null
	var closest_distance := INF
	for turret in _tracked_turrets:
		if turret == null or not is_instance_valid(turret):
			continue
		if turret.toughness_component == null or not turret.toughness_component.is_paralyzed():
			continue
		var distance := global_position.distance_to(turret.global_position)
		if distance < closest_distance:
			closest = turret
			closest_distance = distance

	_repair_target = closest
	if _repair_target == null:
		_repair_timer = 0.0
		_repair_state_announced = false


func _refresh_combat_target() -> void:
	if _state == MaidState.MOVING_TO_REPAIR or _state == MaidState.REPAIRING or _repair_target != null:
		_combat_target = null
		return

	var closest: Node2D = null
	var closest_distance := INF
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not (candidate is Node2D) or not is_instance_valid(candidate):
			continue
		var enemy := candidate as Node2D
		var distance := global_position.distance_to(enemy.global_position)
		if distance > _attack_range:
			continue
		if distance < closest_distance:
			closest = enemy
			closest_distance = distance

	_combat_target = closest


func _update_state() -> void:
	if _repair_target != null:
		if global_position.distance_to(_repair_target.global_position) <= repair_stop_distance:
			_set_state(MaidState.REPAIRING)
		else:
			_set_state(MaidState.MOVING_TO_REPAIR)
		return

	if _combat_target != null:
		_set_state(MaidState.COMBAT)
		return

	_set_state(MaidState.IDLE)


func _set_state(next_state: MaidState) -> void:
	if _state == next_state:
		return
	if next_state != MaidState.REPAIRING:
		_repair_timer = 0.0
		_repair_state_announced = false
	_state = next_state


func _process_state(delta: float) -> void:
	match _state:
		MaidState.MOVING_TO_REPAIR:
			if _repair_target == null or not is_instance_valid(_repair_target):
				velocity = _knockback_velocity
				return
			_move_toward_global(_repair_target.global_position)
			_aim_at(_repair_target.global_position)
		MaidState.REPAIRING:
			velocity = _knockback_velocity
			if _repair_target == null or not is_instance_valid(_repair_target):
				_repair_timer = 0.0
				_repair_state_announced = false
				return
			_aim_at(_repair_target.global_position)
			if not _repair_state_announced:
				repair_started.emit(_repair_target)
				_repair_state_announced = true
			_repair_timer += delta
			if _repair_timer >= _repair_target.repair_duration:
				var repaired := _repair_target.toughness_component.repair_full()
				if repaired > 0.0:
					repair_completed.emit(_repair_target)
				_repair_timer = 0.0
				_repair_state_announced = false
				_repair_target = null
		MaidState.COMBAT:
			_move_toward_local(idle_anchor)
		MaidState.IDLE:
			_move_toward_local(idle_anchor)


func _move_toward_global(target_global: Vector2) -> void:
	var direction := _global_vector_to_local(target_global - global_position)
	if direction.length_squared() > 0.001:
		direction = direction.normalized()
	velocity = direction * speed + _knockback_velocity


func _move_toward_local(target_local: Vector2) -> void:
	var direction := target_local - position
	if direction.length_squared() <= idle_reposition_tolerance * idle_reposition_tolerance:
		velocity = _knockback_velocity
		return
	velocity = direction.normalized() * speed + _knockback_velocity


func _handle_attack() -> void:
	if _state == MaidState.MOVING_TO_REPAIR or _state == MaidState.REPAIRING:
		return
	if not _can_fire:
		return
	if _combat_target == null or not is_instance_valid(_combat_target):
		return

	var lead_position := _calculate_lead_position(muzzle.global_position, _combat_target, _weapon_projectile_speed)
	_aim_at(lead_position)
	_fire_at_position(lead_position)


func _calculate_lead_position(origin: Vector2, enemy: Node2D, projectile_speed: float) -> Vector2:
	var enemy_velocity := Vector2.ZERO
	if enemy is CharacterBody2D:
		enemy_velocity = enemy.velocity

	if enemy_velocity.length_squared() < 0.01 or projectile_speed <= 0.0:
		return enemy.global_position

	var relative_pos := enemy.global_position - origin
	var speed_sq := projectile_speed * projectile_speed
	var vel_sq := enemy_velocity.length_squared()
	var a := vel_sq - speed_sq
	var b := 2.0 * relative_pos.dot(enemy_velocity)
	var c := relative_pos.length_squared()

	if is_equal_approx(vel_sq, speed_sq):
		if absf(b) < 0.001:
			return enemy.global_position
		var t_linear := -c / b
		if t_linear < 0.0:
			return enemy.global_position
		return enemy.global_position + enemy_velocity * t_linear

	var discriminant := b * b - 4.0 * a * c
	if discriminant < 0.0:
		return enemy.global_position

	var sqrt_disc := sqrt(discriminant)
	var two_a := 2.0 * a
	var t1 := (-b - sqrt_disc) / two_a
	var t2 := (-b + sqrt_disc) / two_a
	var intercept_time := -1.0
	if t1 >= 0.0 and t2 >= 0.0:
		intercept_time = minf(t1, t2)
	elif t1 >= 0.0:
		intercept_time = t1
	elif t2 >= 0.0:
		intercept_time = t2

	if intercept_time < 0.0:
		return enemy.global_position
	return enemy.global_position + enemy_velocity * intercept_time


func _fire_at_position(target_position: Vector2) -> void:
	_can_fire = false
	_fire_timer = _weapon_fire_rate

	var direction := target_position - muzzle.global_position
	if direction.length_squared() <= 0.001:
		return
	var normalized_direction := direction.normalized()
	var spawner := get_tree().root.get_node_or_null("ProjectileSpawner")
	if spawner != null and spawner.has_method("spawn_projectile"):
		spawner.spawn_projectile(muzzle.global_position, normalized_direction, _weapon_projectile_speed, _weapon_damage, self)
	else:
		push_warning("[BattleMaid] ProjectileSpawner 不可用，使用回退逻辑")
		var projectile_scene := preload("res://scenes/projectile.tscn")
		var projectile := projectile_scene.instantiate() as Node2D
		projectile.global_position = muzzle.global_position
		projectile.setup(normalized_direction, _weapon_projectile_speed, _weapon_damage, self)
		get_tree().root.add_child(projectile)


func _aim_at(target_position: Vector2) -> void:
	var direction := target_position - barrel.global_position
	if direction.length_squared() <= 0.001:
		return
	barrel.rotation = direction.angle()


func _constrain_to_bounds() -> void:
	var previous_position := position
	position.x = clamp(position.x, -SHIP_BOUNDS_X, SHIP_BOUNDS_X)
	position.y = clamp(position.y, -SHIP_BOUNDS_Y, SHIP_BOUNDS_Y)

	if not is_equal_approx(position.x, previous_position.x):
		_knockback_velocity.x = 0.0
	if not is_equal_approx(position.y, previous_position.y):
		_knockback_velocity.y = 0.0


func _global_vector_to_local(global_vector: Vector2) -> Vector2:
	var parent_2d := get_parent() as Node2D
	if parent_2d == null:
		return global_vector

	var local_from := parent_2d.to_local(global_position)
	var local_to := parent_2d.to_local(global_position + global_vector)
	return local_to - local_from


func _update_visual_state() -> void:
	match _state:
		MaidState.MOVING_TO_REPAIR:
			visual.color = Color(0.95, 0.85, 0.35, 1.0)
		MaidState.REPAIRING:
			visual.color = Color(0.95, 0.55, 0.35, 1.0)
		MaidState.COMBAT:
			visual.color = Color(0.85, 0.45, 0.8, 1.0)
		_:
			visual.color = Color(0.9, 0.65, 0.85, 1.0)

	repair_indicator.visible = _state == MaidState.REPAIRING
	if repair_indicator.visible:
		var progress_ratio := 0.0
		if _repair_target != null and is_instance_valid(_repair_target) and _repair_target.repair_duration > 0.0:
			progress_ratio = clampf(_repair_timer / _repair_target.repair_duration, 0.0, 1.0)
		repair_indicator.modulate.a = 0.35 + progress_ratio * 0.65
	else:
		repair_indicator.modulate.a = 0.0
