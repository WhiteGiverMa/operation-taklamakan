class_name EnemyProjectile
extends Area2D

## Enemy projectile that damages the ship on contact.

var velocity: Vector2 = Vector2.ZERO
var speed: float = 400.0
var damage: float = 15.0
@export var player_knockback_force: float = 360.0
var _source: Node = null

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: ColorRect = $Visual

func _ready() -> void:
	# Enemy projectile: layer 5 (enemy_projectile)
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(5, true)
	# Collide with: layer 1 (ship), layer 2 (turret), layer 6 (player)
	set_collision_mask_value(1, true)
	set_collision_mask_value(2, true)
	set_collision_mask_value(6, true)
	
	body_entered.connect(_on_body_entered)
	
	# Auto-destroy after 5 seconds to prevent memory leaks
	var timer := get_tree().create_timer(5.0)
	timer.timeout.connect(queue_free)

func setup(dir: Vector2, spd: float, dmg: float, source: Node = null) -> void:
	velocity = dir.normalized() * spd
	speed = spd
	damage = dmg
	_source = source
	
	# Rotate visual to face direction of travel
	rotation = dir.angle()

func _physics_process(delta: float) -> void:
	position += velocity * delta

func _on_body_entered(body: Node2D) -> void:
	if body.has_method(&"receive_impact"):
		var impact_data := DamageData.new(0.0, _source)
		impact_data.damage_type = "impact"
		impact_data.knockback = velocity.normalized() * player_knockback_force
		body.receive_impact(impact_data)
		queue_free()
		return

	# Apply damage to ship or turret
	if body.has_method("take_damage"):
		var dmg_data := DamageData.new(damage, _source)
		body.take_damage(dmg_data)
	
	# Destroy projectile on any hit
	queue_free()
