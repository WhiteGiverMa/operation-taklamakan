class_name MechanicalDog
extends CharacterBody2D

## MechanicalDog enemy that moves toward the ship and shoots projectiles.

# 使用 ProjectileSpawner 代替直接实例化
# const ENEMY_PROJECTILE_SCENE := preload("res://scenes/enemy/enemy_projectile.tscn")
const FLOATING_BAR_SCENE := preload("res://scenes/ui/toughness_bar.tscn")

@export var speed: float = 150.0
@export var projectile_damage: float = 8.0
@export var projectile_speed: float = 400.0
@export var fire_rate: float = 1.5
@export var attack_range: float = 350.0
@export var currency_reward: int = 8
@export var collision_impact_cooldown: float = 0.5
@export var player_knockback_force: float = 320.0

var _target: Node2D = null
var _health_component: HealthComponent
var _fire_timer: float = 0.0
var _can_fire: bool = true
var _collision_impact_timer: float = 0.0
var _health_bar: ProgressBar
var _health_bar_hide_timer: float = 0.0
var _last_feedback_physics_frame: int = -1

const HEALTH_BAR_DISPLAY_DURATION: float = 1.5

@onready var visual: ColorRect = $Visual

func _ready() -> void:
	_health_component = $HealthComponent
	
	# Enemy: layer 3, mask 1 (ship), 2 (turret), 6 (player)
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(3, true)
	set_collision_mask_value(1, true)
	set_collision_mask_value(2, true)
	set_collision_mask_value(6, true)
	
	# Connect HealthComponent signals
	if _health_component:
		_health_component.health_changed.connect(_on_health_changed)
		_health_component.died.connect(_on_died)
	add_to_group("enemies")
	_spawn_health_bar()
	_update_health_bar()
	
	# Find the ship (Landship) in the scene
	_find_target()

func _find_target() -> void:
	# Try to find Landship in the group first
	var landship = get_tree().get_first_node_in_group("ship")
	if landship:
		_target = landship
	else:
		# Fallback: try to find by name
		landship = get_tree().root.find_child("Landship", true, false)
		if landship:
			_target = landship

func _physics_process(delta: float) -> void:
	# Update fire cooldown
	if not _can_fire:
		_fire_timer -= delta
		if _fire_timer <= 0.0:
			_can_fire = true
	if _collision_impact_timer > 0.0:
		_collision_impact_timer = maxf(_collision_impact_timer - delta, 0.0)
	
	# Update health bar hide timer
	if _health_bar_hide_timer > 0:
		_health_bar_hide_timer -= delta
		if _health_bar_hide_timer <= 0 and _health_bar:
			_health_bar.visible = false
	
	var target_pos := _get_target_position()
	var distance_to_target := global_position.distance_to(target_pos)
	
	# Move toward target if outside attack range
	if distance_to_target > attack_range:
		var direction := (target_pos - global_position).normalized()
		velocity = direction * speed
	else:
		# Stop moving when in attack range
		velocity = Vector2.ZERO
		# Try to fire
		if _can_fire:
			_fire_at_target(target_pos)
	
	move_and_slide()
	_handle_player_collisions()

func _handle_player_collisions() -> void:
	if _collision_impact_timer > 0.0:
		return

	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider != null and collider.has_method(&"receive_impact"):
			if _apply_player_impact(collider):
				_collision_impact_timer = collision_impact_cooldown
				return

func _apply_player_impact(collider: Object) -> bool:
	var player := collider as Node2D
	if player == null:
		return false

	var push_direction := player.global_position - global_position
	if push_direction.length_squared() <= 0.001:
		push_direction = velocity
	if push_direction.length_squared() <= 0.001:
		push_direction = Vector2.RIGHT

	var impact_data := DamageData.new(0.0, self)
	impact_data.damage_type = "impact"
	impact_data.knockback = push_direction.normalized() * player_knockback_force
	return player.receive_impact(impact_data)

func _fire_at_target(target_pos: Vector2) -> void:
	_can_fire = false
	_fire_timer = fire_rate
	
	var direction := (target_pos - global_position).normalized()
	
	# 使用 ProjectileSpawner 生成敌方投射物
	var spawner := get_tree().root.get_node_or_null("ProjectileSpawner")
	if spawner and spawner.has_method("spawn_enemy_projectile"):
		spawner.spawn_enemy_projectile(
			global_position,
			direction,
			projectile_speed,
			projectile_damage,
			self
		)
	else:
		# 回退：直接实例化（兼容旧逻辑）
		push_warning("[MechanicalDog] ProjectileSpawner 不可用，使用回退逻辑")
		var projectile_scene := preload("res://scenes/enemy/enemy_projectile.tscn")
		var projectile := projectile_scene.instantiate() as Node2D
		projectile.global_position = global_position
		projectile.setup(direction, projectile_speed, projectile_damage, self)
		get_tree().root.add_child(projectile)

func _get_target_position() -> Vector2:
	if _target:
		return _target.global_position
	# Fallback: return center of screen
	return Vector2(960, 540)

func take_damage(data: DamageData) -> float:
	if _health_component == null:
		return 0.0
	var actual_damage := _health_component.take_damage(data)
	if actual_damage > 0.0:
		show_damage_feedback(actual_damage)
	return actual_damage

func show_damage_feedback(amount: float) -> void:
	if amount <= 0.0:
		return

	var physics_frame := Engine.get_physics_frames()
	if _last_feedback_physics_frame == physics_frame:
		return
	_last_feedback_physics_frame = physics_frame
	_on_damaged(amount, null)

func _on_health_changed(_old_health: float, _new_health: float) -> void:
	_update_health_bar()

func _on_damaged(amount: float, source) -> void:
	if amount <= 0.0:
		return
	_show_health_bar()
	_show_damage_flash()
	# Emit damage_dealt signal for DamagePopupManager to display
	var is_critical := false  # TODO: Get from DamageData when critical hit support is added
	EventBus.damage_dealt.emit(amount, global_position, source, is_critical)

func _spawn_health_bar() -> void:
	if FLOATING_BAR_SCENE == null or _health_bar != null:
		return

	_health_bar = FLOATING_BAR_SCENE.instantiate() as ProgressBar
	if _health_bar == null:
		return

	add_child(_health_bar)
	_health_bar.z_index = 10
	_health_bar.modulate = Color(1.0, 0.35, 0.35)
	_health_bar.visible = false  # 初始隐藏

func _show_health_bar() -> void:
	if _health_bar == null:
		return
	_health_bar.visible = true
	_health_bar_hide_timer = HEALTH_BAR_DISPLAY_DURATION

func _update_health_bar() -> void:
	if _health_bar == null or _health_component == null:
		return

	_health_bar.max_value = _health_component.max_health
	_health_bar.value = _health_component.current_health

func _show_damage_flash() -> void:
	visual.modulate = Color(1.0, 0.45, 0.45)
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color.WHITE, 0.18)

func _on_died() -> void:
	# Emit enemy_died signal for currency drop
	EventBus.enemy_died.emit(self, global_position, currency_reward)
	queue_free()
