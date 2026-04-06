class_name Tank
extends CharacterBody2D

## Tank enemy that moves toward the ship and deals damage on collision.

@export var speed: float = 100.0
@export var damage: float = 10.0
@export var currency_reward: int = 10
@export var collision_damage_cooldown: float = 0.5
@export var is_boss: bool = false

var _target: Node2D = null
var _health_component: HealthComponent
var _collision_damage_timer: float = 0.0

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
	# Try to find Landship in the scene
	var landship = get_tree().get_first_node_in_group("ship")
	if landship:
		_target = landship
	else:
		# Fallback: try to find by name
		landship = get_tree().root.find_child("Landship", true, false)
		if landship:
			_target = landship

func _physics_process(delta: float) -> void:
	# Update collision damage cooldown
	if _collision_damage_timer > 0:
		_collision_damage_timer -= delta
	
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
			
			if collider.has_method(&"take_damage"):
				var damage_data := DamageData.physical(damage, self)
				collider.take_damage(damage_data)
				_collision_damage_timer = collision_damage_cooldown
				break  # Only damage one target per cooldown

func _get_target_position() -> Vector2:
	if _target:
		return _target.global_position
	# Fallback: return center of screen
	return Vector2(960, 540)

func _on_died() -> void:
	# Emit enemy_died signal for currency drop
	EventBus.enemy_died.emit(self, global_position, currency_reward)
	queue_free()
