class_name MechanicalDog
extends CharacterBody2D

## MechanicalDog enemy that moves toward the ship and shoots projectiles.

const ENEMY_PROJECTILE_SCENE := preload("res://scenes/enemy/enemy_projectile.tscn")

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
		_health_component.died.connect(_on_died)
	add_to_group("enemies")
	
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
	
	# Spawn enemy projectile
	if ENEMY_PROJECTILE_SCENE:
		var projectile := ENEMY_PROJECTILE_SCENE.instantiate() as Node2D
		projectile.global_position = global_position
		projectile.setup(direction, projectile_speed, projectile_damage, self)
		get_tree().root.add_child(projectile)

func _get_target_position() -> Vector2:
	if _target:
		return _target.global_position
	# Fallback: return center of screen
	return Vector2(960, 540)

func _on_died() -> void:
	# Emit enemy_died signal for currency drop
	EventBus.enemy_died.emit(self, global_position, currency_reward)
	queue_free()
