class_name MechanicalDog
extends "res://scripts/base_enemy.gd"

## MechanicalDog enemy that moves toward the ship and shoots projectiles.

# 使用 ProjectileSpawner 代替直接实例化
# const ENEMY_PROJECTILE_SCENE := preload("res://scenes/enemy/enemy_projectile.tscn")
@export var speed: float = 150.0
@export var projectile_damage: float = 8.0
@export var projectile_speed: float = 400.0
@export var fire_rate: float = 1.5
@export var attack_range: float = 350.0
@export var collision_impact_cooldown: float = 0.5

var _fire_timer: float = 0.0
var _can_fire: bool = true
var _collision_impact_timer: float = 0.0

func _ready() -> void:
	_base_enemy_ready()

func _physics_process(delta: float) -> void:
	# Update fire cooldown
	if not _can_fire:
		_fire_timer -= delta
		if _fire_timer <= 0.0:
			_can_fire = true
	if _collision_impact_timer > 0.0:
		_collision_impact_timer = maxf(_collision_impact_timer - delta, 0.0)
	_update_enemy_feedback(delta)
	
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

func _fire_at_target(target_pos: Vector2) -> void:
	_can_fire = false
	_fire_timer = fire_rate
	
	var direction := (target_pos - global_position).normalized()
	ProjectileSpawner.spawn_enemy_projectile(global_position, direction, projectile_speed, projectile_damage, self)
