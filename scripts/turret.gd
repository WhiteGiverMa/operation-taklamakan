class_name Turret
extends Node2D

## Manual-fire turret. Player approaches → clicks → enters manual mode → mouse aim + click to fire.
## Supports multiple turret types via TurretDefinition resource.

signal turret_fired(target: Vector2)

# 使用 ProjectileSpawner 代替直接实例化
# const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const TOUGHNESS_BAR_SCENE := preload("res://scenes/ui/toughness_bar.tscn")
# Preload TurretDefinition to ensure type is available
const _TurretDefinitionScript := preload("res://scripts/resources/turret_definition.gd")

## 炮塔类型定义（设置后自动应用）
@export var definition: Resource:
	set(value):
		definition = value
		if value and is_inside_tree():
			_apply_definition()

## 运行时属性（由definition填充，或使用@export默认值）
var turret_id: StringName = &"standard"
var _base_damage: float = 15.0
var _base_fire_rate: float = 0.5
var _base_projectile_speed: float = 600.0
var _base_interaction_range: float = 150.0
var _base_auto_target_range: float = 1500.0
var _base_toughness_damage_radius: float = 180.0
var _base_repair_duration: float = 2.0
var _base_firing_arc_half_angle: float = 90.0

## 最终计算后的属性（受全局倍率和类型专精影响）
var projectile_damage: float = 15.0
var fire_rate: float = 0.5
var projectile_speed: float = 600.0
var interaction_range: float = 150.0
var auto_target_range: float = 1500.0
var toughness_damage_radius: float = 180.0
var repair_duration: float = 2.0
var firing_arc_half_angle_degrees: float = 90.0
var _visual_color: Color = Color.WHITE

# @export 保留用于编辑器调试，但运行时通过definition设置
@export var _debug_interaction_range: float = 150.0:
	set(value):
		_debug_interaction_range = value
		interaction_range = value
@export var _debug_auto_target_range: float = 1500.0:
	set(value):
		_debug_auto_target_range = value
		auto_target_range = value
@export var _debug_projectile_speed: float = 600.0:
	set(value):
		_debug_projectile_speed = value
		projectile_speed = value
@export var _debug_projectile_damage: float = 15.0:
	set(value):
		_debug_projectile_damage = value
		_base_damage = value
		projectile_damage = value
@export var _debug_fire_rate: float = 0.5:
	set(value):
		_debug_fire_rate = value
		fire_rate = value
@export var _debug_toughness_damage_radius: float = 180.0:
	set(value):
		_debug_toughness_damage_radius = value
		toughness_damage_radius = value
@export var _debug_repair_duration: float = 2.0:
	set(value):
		_debug_repair_duration = value
		repair_duration = value
@export_range(0.0, 180.0, 1.0) var _debug_firing_arc_half_angle_degrees: float = 90.0:
	set(value):
		_debug_firing_arc_half_angle_degrees = value
		firing_arc_half_angle_degrees = value

var is_manual_mode: bool = false
var _can_fire: bool = true
var _fire_timer: float = 0.0
var _player_in_range: bool = false
var _repair_timer: float = 0.0
var _toughness_bar: ProgressBar
var _player: Node2D
var _firing_arc_center_angle: float = 0.0
var _skip_manual_exit_once: bool = false

@onready var barrel: Node2D = $Barrel
@onready var muzzle: Marker2D = $Barrel/Muzzle
@onready var base: ColorRect = $Base
@onready var interaction_area: Area2D = $InteractionArea
@onready var toughness_component: ToughnessComponent = $ToughnessComponent

func _ready() -> void:
	# 如果有定义，先应用
	if definition:
		_apply_definition()
	
	interaction_area.collision_layer = 0
	interaction_area.collision_mask = 0
	interaction_area.set_collision_mask_value(6, true)
	interaction_area.input_pickable = false

	interaction_area.body_entered.connect(_on_player_entered)
	interaction_area.body_exited.connect(_on_player_exited)
	if not InputManager.fire_action.just_triggered.is_connected(_on_fire_action_just_triggered):
		InputManager.fire_action.just_triggered.connect(_on_fire_action_just_triggered)
	EventBus.ship_damaged.connect(_on_ship_damaged)
	EventBus.player_knockback_started.connect(_on_player_knockback_started)
	EventBus.turret_stats_refresh_requested.connect(_update_final_stats)
	toughness_component.toughness_changed.connect(_on_toughness_changed)
	toughness_component.paralysis_started.connect(_on_paralysis_started)
	toughness_component.paralysis_ended.connect(_on_paralysis_ended)
	_player = _resolve_player()
	_firing_arc_center_angle = _resolve_firing_arc_center_angle()

	_spawn_toughness_bar()
	_update_toughness_bar()
	_update_visual_state()


func _physics_process(delta: float) -> void:
	_update_player_in_range()
	_handle_repair(delta)
	_handle_fire_cooldown(delta)

	if is_manual_mode and SettingsManager.manual_fire_full_auto:
		_handle_manual_full_auto_fire()

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
	barrel.rotation = _resolve_fire_solution(mouse_pos).get("clamped_angle", barrel.rotation)


func _handle_fire_cooldown(delta: float) -> void:
	if not _can_fire:
		_fire_timer -= delta
		if _fire_timer <= 0.0:
			_can_fire = true


func _handle_manual_full_auto_fire() -> void:
	if not _can_fire or toughness_component.is_paralyzed():
		return
	# Use value_bool to check raw input state (held down), not is_triggered() which only fires once
	if not InputManager.fire_action.value_bool:
		return
	var mouse_position := get_global_mouse_position()
	_fire_at_position(mouse_position)


func _on_fire_action_just_triggered() -> void:
	if not is_manual_mode:
		return
	if SettingsManager.manual_fire_full_auto:
		return
	if not _can_fire or toughness_component.is_paralyzed():
		return

	var mouse_position := get_global_mouse_position()
	_fire_at_position(mouse_position)

func _handle_auto_fire() -> void:
	if not _can_fire:
		return

	var result := _find_auto_target()
	var target: Node2D = result.get("target")
	if target == null:
		return

	var lead_pos: Vector2 = result.get("lead_position")
	barrel.rotation = _resolve_fire_solution(lead_pos).get("clamped_angle", barrel.rotation)
	_fire_at_position(lead_pos, target)


## 计算预瞄提前量：根据敌人当前速度和投射物速度，求解拦截点
## 经典弹道拦截二次方程：|D + V*t|² = (s*t)²
## 展开为 (V·V - s²)t² + 2(D·V)t + D·D = 0
## D=敌我相对位置, V=敌速, s=弹速, t=飞行时间
## 当无有效解时（弹速不足或时间倒流），回退到敌人当前位置
func _calculate_lead_position(turret_pos: Vector2, enemy: Node2D, proj_speed: float) -> Vector2:
	# 读取敌人速度（CharacterBody2D.velocity，是 move_and_slide 后的近似值）
	var enemy_velocity := Vector2.ZERO
	if enemy is CharacterBody2D:
		enemy_velocity = enemy.velocity

	# 敌人静止 → 无需预瞄
	if enemy_velocity.length_squared() < 0.01:
		return enemy.global_position

	# 投射物速度为零或负值 → 安全回退
	if proj_speed <= 0.0:
		return enemy.global_position

	var relative_pos := enemy.global_position - turret_pos  # D
	var speed_sq := proj_speed * proj_speed                 # s²
	var vel_sq := enemy_velocity.length_squared()           # V·V

	# 二次方程 at² + bt + c = 0
	var a := vel_sq - speed_sq
	var b := 2.0 * relative_pos.dot(enemy_velocity)
	var c := relative_pos.length_squared()

	# 退化情况：敌速与弹速接近（a ≈ 0）→ 线性求解
	if is_equal_approx(vel_sq, speed_sq):
		if absf(b) < 0.001:
			return enemy.global_position
		var t_linear := -c / b
		if t_linear < 0.0:
			return enemy.global_position
		return enemy.global_position + enemy_velocity * t_linear

	var discriminant := b * b - 4.0 * a * c
	if discriminant < 0.0:
		# 无实数解 → 弹速不足以拦截，瞄当前位置
		return enemy.global_position

	var sqrt_disc: float = sqrt(discriminant)
	var two_a: float = 2.0 * a
	var t1: float = (-b - sqrt_disc) / two_a
	var t2: float = (-b + sqrt_disc) / two_a

	# 取最小的非负时间解（更快命中）
	var t: float = -1.0
	if t1 >= 0.0 and t2 >= 0.0:
		t = minf(t1, t2)
	elif t1 >= 0.0:
		t = t1
	elif t2 >= 0.0:
		t = t2

	if t < 0.0:
		# 两个解均为负 → 无法拦截
		return enemy.global_position

	return enemy.global_position + enemy_velocity * t


## 寻找最佳自动射击目标：基于预瞄提前量位置判断射界和距离
## 返回 { target: Node2D, lead_position: Vector2 } 或空字典（无目标）
func _find_auto_target() -> Dictionary:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var closest_distance := INF
	var closest_lead: Vector2 = Vector2.ZERO

	for candidate in enemies:
		if not (candidate is Node2D) or not is_instance_valid(candidate):
			continue
		var enemy := candidate as Node2D
		var distance := global_position.distance_to(enemy.global_position)
		# 只索敌射程内的敌人
		if distance > auto_target_range:
			continue
		# 用预瞄点判定射界，而非敌人当前位置
		# 避免选到"当前在射界但提前量不在射界"的目标
		var lead_pos := _calculate_lead_position(muzzle.global_position, enemy, projectile_speed)
		if not _resolve_fire_solution(lead_pos).get("within_arc", false):
			continue
		if distance < closest_distance:
			closest_distance = distance
			closest = enemy
			closest_lead = lead_pos

	if closest == null:
		return {}
	return { "target": closest, "lead_position": closest_lead }


func _fire_at_position(target_position: Vector2, target: Node2D = null) -> void:
	if toughness_component.is_paralyzed():
		return

	_can_fire = false
	_fire_timer = fire_rate

	var solution := _resolve_fire_solution(target_position)
	var firing_angle: float = solution.get("clamped_angle", global_position.angle_to_point(target_position))
	barrel.rotation = firing_angle
	var direction := Vector2.RIGHT.rotated(firing_angle)

	# 使用 ProjectileSpawner 生成投射物
	var spawner := get_tree().root.get_node_or_null("ProjectileSpawner")
	if spawner and spawner.has_method("spawn_projectile"):
		spawner.spawn_projectile(
			muzzle.global_position,
			direction,
			projectile_speed,
			projectile_damage,
			self
		)
	else:
		# 回退：直接实例化（兼容旧逻辑）
		push_warning("[Turret] ProjectileSpawner 不可用，使用回退逻辑")
		var projectile_scene := preload("res://scenes/projectile.tscn")
		var projectile := projectile_scene.instantiate() as Node2D
		projectile.global_position = muzzle.global_position
		projectile.setup(direction, projectile_speed, projectile_damage, self)
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


func _on_player_knockback_started(player: Node2D, _source: Node) -> void:
	if not _is_player(player):
		return

	_player = player
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
		base.modulate = _visual_color


## 从 TurretDefinition 应用属性
func _apply_definition() -> void:
	if definition == null:
		return
	
	# 使用动态属性访问（Resource 支持通过 .get() 访问导出属性）
	turret_id = definition.get("id")
	_base_damage = definition.get("base_damage")
	_base_fire_rate = definition.get("base_fire_rate")
	_base_projectile_speed = definition.get("projectile_speed")
	_base_interaction_range = definition.get("interaction_range")
	_base_auto_target_range = definition.get("auto_target_range")
	_base_toughness_damage_radius = definition.get("toughness_damage_radius")
	_base_repair_duration = definition.get("repair_duration")
	_base_firing_arc_half_angle = definition.get("firing_arc_half_angle")
	_visual_color = definition.get("visual_color")
	
	_update_final_stats()


## 更新最终属性（应用全局倍率和类型专精）
func _update_final_stats() -> void:
	var global_mult := GameState.get_global_turret_damage_multiplier()
	var type_mult := GameState.get_turret_type_multiplier(turret_id)
	
	# 伤害 = 基础 × 全局倍率 × 类型专精
	projectile_damage = _base_damage * global_mult * type_mult
	
	# 其他属性直接使用基础值
	fire_rate = _base_fire_rate * GameState.get_turret_fire_rate_multiplier()
	projectile_speed = _base_projectile_speed
	interaction_range = _base_interaction_range
	auto_target_range = _base_auto_target_range
	toughness_damage_radius = _base_toughness_damage_radius
	repair_duration = _base_repair_duration
	firing_arc_half_angle_degrees = _base_firing_arc_half_angle
	
	# 更新视觉状态以应用颜色
	_update_visual_state()


## 获取炮塔类型ID
func get_turret_id() -> StringName:
	return turret_id


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


func _resolve_firing_arc_center_angle() -> float:
	var ship := get_tree().get_first_node_in_group("ship") as Node2D
	if ship == null:
		return 0.0

	var outward := global_position - ship.global_position
	if outward.length_squared() <= 0.001:
		return 0.0

	return outward.angle()

func _resolve_fire_solution(target_position: Vector2) -> Dictionary:
	var raw_angle := global_position.angle_to_point(target_position)
	var relative_angle := wrapf(raw_angle - _firing_arc_center_angle, -PI, PI)
	var half_arc := deg_to_rad(firing_arc_half_angle_degrees)
	var clamped_relative_angle := clampf(relative_angle, -half_arc, half_arc)
	return {
		"raw_angle": raw_angle,
		"within_arc": absf(relative_angle) <= half_arc,
		"clamped_angle": _firing_arc_center_angle + clamped_relative_angle,
	}
