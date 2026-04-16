extends CharacterBody2D

## Player character movement script
## Moves with WASD in local coordinates relative to parent ship
## Constrained to ship bounds

const WEAPON_DEF := preload("res://scripts/resources/weapon_definition.gd")

@export var speed: float = 250.0
@export var knockback_decay: float = 1400.0
@export var max_knockback_speed: float = 520.0
@export var impact_cooldown: float = 0.18
@export var weapon_definition: Resource

# Ship bounds (half-extents)
const SHIP_BOUNDS_X: float = 380.0
const SHIP_BOUNDS_Y: float = 180.0
const FIRE_INPUT_BUFFER := 0.12

var _weapon_damage: float = 8.0
var _weapon_fire_rate: float = 0.2
var _weapon_projectile_speed: float = 600.0
var _knockback_velocity: Vector2 = Vector2.ZERO
var _impact_cooldown_timer: float = 0.0

# 武器冷却
var _can_fire: bool = true
var _fire_timer: float = 0.0
var _fire_buffer_timer: float = 0.0

func _ready() -> void:
	# 玩家站在舰体内部移动，不应与舰体 hull 自身发生物理碰撞，
	# 否则 CharacterBody2D 会被父节点 StaticBody2D 的碰撞解算限制移动。
	add_to_group("player")
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(6, true)
	set_collision_mask_value(3, true)
	set_collision_mask_value(5, true)
	_apply_weapon_definition()
	if not InputManager.fire_action.just_triggered.is_connected(_on_fire_action_just_triggered):
		InputManager.fire_action.just_triggered.connect(_on_fire_action_just_triggered)

func _physics_process(delta: float) -> void:
	if _impact_cooldown_timer > 0.0:
		_impact_cooldown_timer = maxf(_impact_cooldown_timer - delta, 0.0)
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)

	# Get input direction in local coordinates
	var input_direction := InputManager.move_action.value_axis_2d.normalized()
	
	# Apply movement in local space (relative to parent ship).
	# Normalize to keep diagonal movement speed consistent across contexts and future input devices.
	velocity = input_direction * speed + _knockback_velocity
	
	# Move using move_and_slide() - handles physics automatically
	move_and_slide()
	
	# 武器系统
	_handle_weapon_cooldown(delta)
	_handle_fire_buffer(delta)
	_handle_player_shooting()
	
	# Constrain to ship bounds after movement
	_constrain_to_bounds()

func receive_impact(data: DamageData) -> bool:
	if data == null or data.knockback.length_squared() <= 0.001:
		return false
	if _impact_cooldown_timer > 0.0:
		return false

	EventBus.player_knockback_started.emit(self, data.source)
	_impact_cooldown_timer = impact_cooldown
	_knockback_velocity += _global_vector_to_local(data.knockback)
	if _knockback_velocity.length() > max_knockback_speed:
		_knockback_velocity = _knockback_velocity.normalized() * max_knockback_speed
	return true

func is_player() -> bool:
	return true

func _apply_weapon_definition() -> void:
	if weapon_definition == null:
		return
	if not (weapon_definition is WEAPON_DEF):
		push_warning("[Player] weapon_definition 不是 WeaponDefinition，继续使用默认武器参数")
		return
	_weapon_damage = weapon_definition.damage
	_weapon_fire_rate = weapon_definition.fire_rate
	_weapon_projectile_speed = weapon_definition.projectile_speed

func _global_vector_to_local(global_vector: Vector2) -> Vector2:
	var parent_2d := get_parent() as Node2D
	if parent_2d == null:
		return global_vector

	var local_from := parent_2d.to_local(global_position)
	var local_to := parent_2d.to_local(global_position + global_vector)
	return local_to - local_from

func _constrain_to_bounds() -> void:
	var previous_position := position
	# Clamp position to ship bounds
	position.x = clamp(position.x, -SHIP_BOUNDS_X, SHIP_BOUNDS_X)
	position.y = clamp(position.y, -SHIP_BOUNDS_Y, SHIP_BOUNDS_Y)

	if not is_equal_approx(position.x, previous_position.x):
		_knockback_velocity.x = 0.0
	if not is_equal_approx(position.y, previous_position.y):
		_knockback_velocity.y = 0.0

func _handle_weapon_cooldown(delta: float) -> void:
	if not _can_fire:
		_fire_timer -= delta
		if _fire_timer <= 0.0:
			_can_fire = true

func _handle_fire_buffer(delta: float) -> void:
	if _fire_buffer_timer <= 0.0:
		return
	_fire_buffer_timer = maxf(_fire_buffer_timer - delta, 0.0)

func _on_fire_action_just_triggered() -> void:
	_fire_buffer_timer = FIRE_INPUT_BUFFER

func _is_any_turret_in_manual_mode() -> bool:
	# 使用类名发现所有炮塔
	var turrets: Array[Node] = get_tree().get_nodes_in_group("turrets")
	if turrets.is_empty():
		# 备用方案：遍历场景树查找 Turret 类节点
		turrets = _find_all_turrets()
	for turret in turrets:
		if turret is Turret and turret.is_manual_mode:
			return true
	return false

func _find_all_turrets() -> Array[Node]:
	# 递归查找所有 Turret 节点
	var result: Array[Node] = []
	_find_turrets_recursive(get_tree().root, result)
	return result

func _find_turrets_recursive(node: Node, result: Array[Node]) -> void:
	if node is Turret:
		result.append(node)
	for child in node.get_children():
		_find_turrets_recursive(child, result)

func _handle_player_shooting() -> void:
	# 检查炮塔手动模式优先级
	if _is_any_turret_in_manual_mode():
		return

	var wants_to_fire := false
	if SettingsManager.manual_fire_full_auto:
		wants_to_fire = InputManager.fire_action.value_bool
	else:
		wants_to_fire = _fire_buffer_timer > 0.0

	if not wants_to_fire:
		return
	if not _can_fire:
		return
	
	var mouse_pos := get_global_mouse_position()
	var direction := (mouse_pos - global_position).normalized()
	
	# 边界情况：鼠标在玩家位置时，忽略射击
	if direction.length_squared() < 0.001:
		return
	
	_fire_projectile(direction)
	_fire_buffer_timer = 0.0
	_can_fire = false
	_fire_timer = _weapon_fire_rate

func _fire_projectile(direction: Vector2) -> void:
	# 使用 ProjectileSpawner 生成投射物
	var spawner := get_tree().root.get_node_or_null("ProjectileSpawner")
	if spawner and spawner.has_method("spawn_projectile"):
		spawner.spawn_projectile(
			global_position,
			direction,
			_weapon_projectile_speed,
			_weapon_damage,
			self
		)
	else:
		# 回退：直接实例化（兼容旧逻辑）
		push_warning("[Player] ProjectileSpawner 不可用，使用回退逻辑")
		var projectile_scene := preload("res://scenes/projectile.tscn")
		var projectile := projectile_scene.instantiate() as Node2D
		projectile.global_position = global_position
		projectile.setup(direction, _weapon_projectile_speed, _weapon_damage, self)
		get_tree().root.add_child(projectile)
