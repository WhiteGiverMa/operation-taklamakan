class_name HealthComponent
extends Node

## Component that manages entity health with damage/heal support.
## Emits signals for health changes, healing, and death.

signal health_changed(old_health: float, new_health: float)
signal died()
signal healed(amount: float)
signal damaged(amount: float, source: Node)

@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var invincibility_time: float = 0.0

var _invincible: bool = false
var _invincibility_timer: float = 0.0

func _physics_process(delta: float) -> void:
	if _invincible and invincibility_time > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false

func take_damage(data: DamageData) -> float:
	## Apply damage. Returns actual damage dealt (may be less than requested).
	if _invincible or current_health <= 0.0:
		return 0.0
	
	var old_health := current_health
	var actual_damage := minf(data.amount, current_health)
	current_health = maxf(current_health - actual_damage, 0.0)
	
	damaged.emit(actual_damage, data.source)
	health_changed.emit(old_health, current_health)
	
	if current_health <= 0.0:
		died.emit()
	elif invincibility_time > 0.0:
		_start_invincibility()
	
	return actual_damage

func heal(amount: float) -> float:
	## Heal by amount. Returns actual amount healed.
	if current_health <= 0.0:
		return 0.0
	
	var actual := minf(amount, max_health - current_health)
	if actual > 0.0:
		var old_health := current_health
		current_health += actual
		healed.emit(actual)
		health_changed.emit(old_health, current_health)
	return actual

func _start_invincibility() -> void:
	_invincible = true
	_invincibility_timer = invincibility_time

func is_dead() -> bool:
	return current_health <= 0.0

func is_invincible() -> bool:
	return _invincible

func get_health_ratio() -> float:
	if max_health <= 0.0:
		return 0.0
	return current_health / max_health
