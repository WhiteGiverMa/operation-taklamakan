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

var _target: Node2D = null
var _health_component: HealthComponent
var _fire_timer: float = 0.0
var _can_fire: bool = true

func _ready() -> void:
	_health_component = $HealthComponent
	
	# Set collision layer to 3 (enemy) and mask to 1 (ship), 2 (turret)
	collision_layer = 4  # Layer 3 = bit 2 = value 4
	collision_mask = 3   # Layer 1 + 2 = bit 0 + bit 1 = value 1 + 2 = 3
	
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
