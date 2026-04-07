class_name Landship
extends StaticBody2D

## Central base ship. Fixed during combat. Has 8 turret slots around perimeter.

@export var max_health: float = 100.0

# Repair settings
const REPAIR_RANGE: float = 80.0
const REPAIR_TIME: float = 2.0
const REPAIR_AMOUNT: float = 100.0

@onready var health_component: HealthComponent = $HealthComponent
@onready var damage_indicator: ColorRect = $DamageIndicator

var _repair_progress: float = 0.0
var _is_repairing: bool = false

func _ready() -> void:
	add_to_group("ship")
	
	# Configure health
	health_component.max_health = max_health
	health_component.current_health = max_health
	
	# Connect signals
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_ship_destroyed)
	health_component.damaged.connect(_on_ship_damaged)
	
	# Collision: layer 1 (ship hull)
	collision_layer = 0
	set_collision_layer_value(1, true)
	# Mask: layer 3 (enemies), layer 5 (enemy projectiles)
	collision_mask = 0
	set_collision_mask_value(3, true)
	set_collision_mask_value(5, true)
	
	# Hide damage indicator initially
	damage_indicator.modulate.a = 0.0
	
	# Emit initial health to HUD
	EventBus.ship_health_changed.emit(max_health, max_health)

func _physics_process(delta: float) -> void:
	_check_repair_input(delta)

func get_turret_slots() -> Array[Node2D]:
	var slots: Array[Node2D] = []
	for i in range(1, 9):
		var slot := get_node_or_null("TurretSlot%d" % i) as Node2D
		if slot:
			slots.append(slot)
	return slots

func _check_repair_input(delta: float) -> void:
	var player := get_node_or_null("PlayerCharacter") as Node2D
	if not player:
		return
	
	# Check if player is near ship hull (center area)
	var player_pos := player.global_position
	var ship_pos := global_position
	var distance := player_pos.distance_to(ship_pos)
	
	if distance > REPAIR_RANGE:
		_repair_progress = 0.0
		_is_repairing = false
		return
	
	# Player is nearby - check for repair input
	if InputManager.repair_action.is_triggered():
		_is_repairing = true
		_repair_progress += delta
		
		if _repair_progress >= REPAIR_TIME:
			_repair_ship()
			_repair_progress = 0.0
			_is_repairing = false
	else:
		_repair_progress = 0.0
		_is_repairing = false

func _repair_ship() -> void:
	if health_component.is_dead():
		return
	
	var healed := health_component.heal(REPAIR_AMOUNT)
	if healed > 0.0:
		EventBus.ship_health_changed.emit(health_component.current_health, max_health)

func take_damage(data: DamageData) -> void:
	health_component.take_damage(data)

func _on_health_changed(_old_health: float, new_health: float) -> void:
	EventBus.ship_health_changed.emit(new_health, max_health)

func _on_ship_damaged(amount: float, source: Node) -> void:
	EventBus.ship_damaged.emit(amount, source)
	_show_damage_indicator()

func _show_damage_indicator() -> void:
	# Flash red on hull for 0.2 seconds
	damage_indicator.modulate.a = 0.5
	var tween := create_tween()
	tween.tween_property(damage_indicator, "modulate:a", 0.0, 0.2)

func _on_ship_destroyed() -> void:
	EventBus.ship_destroyed.emit()
	GameState.end_game(false)
