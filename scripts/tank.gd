class_name Tank
extends "res://scripts/base_enemy.gd"

## Tank enemy that moves toward the ship and deals damage on collision.

@export var speed: float = 100.0
@export var damage: float = 10.0
@export var collision_damage_cooldown: float = 0.5
@export var is_boss: bool = false

var _collision_damage_timer: float = 0.0
func _ready() -> void:
	_base_enemy_ready()

func _physics_process(delta: float) -> void:
	# Update collision damage cooldown
	if _collision_damage_timer > 0:
		_collision_damage_timer -= delta
	_update_enemy_feedback(delta)
	
	# Move toward target (ship)
	var target_pos := _get_target_position()
	var direction := (target_pos - global_position).normalized()
	velocity = direction * speed
	
	move_and_slide()
	
	# Check for collisions with ship or turrets and deal damage
	if _collision_damage_timer <= 0:
		for i in get_slide_collision_count():
			var collision := get_slide_collision(i)
			var collider := collision.get_collider()
			
			if collider != null and collider.has_method(&"receive_impact"):
				if _apply_player_impact(collider):
					_collision_damage_timer = collision_damage_cooldown
					break
			if collider != null and collider.has_method(&"take_damage"):
				var damage_data := DamageData.physical(damage, self)
				collider.take_damage(damage_data)
				_collision_damage_timer = collision_damage_cooldown
				break  # Only damage one target per cooldown
