class_name Projectile
extends Area2D

## Player projectile. Moves in a straight line and damages enemies on contact.

var velocity: Vector2 = Vector2.ZERO
var speed: float = 600.0
var damage: float = 15.0
var _source: Node = null

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: ColorRect = $Visual

func _ready() -> void:
	# Projectile: layer 4
	set_collision_layer_value(4, true)
	# Collide with: layer 3 (enemies)
	set_collision_mask_value(3, true)
	
	body_entered.connect(_on_body_entered)

func setup(dir: Vector2, spd: float, dmg: float, source: Node = null) -> void:
	velocity = dir.normalized() * spd
	speed = spd
	damage = dmg
	_source = source
	
	# Rotate visual to face direction of travel
	rotation = dir.angle()

func _physics_process(delta: float) -> void:
	position += velocity * delta
	
	# Queue free if too far from any relevant point (cleanup)
	# For now, just use lifetime timer
	pass

func _on_body_entered(body: Node2D) -> void:
	# Apply damage to enemy
	if body.has_method("take_damage"):
		var dmg_data := DamageData.new(damage, _source)
		body.take_damage(dmg_data)
		EventBus.projectile_hit.emit(self, body)
	
	# Destroy projectile on any hit
	queue_free()
