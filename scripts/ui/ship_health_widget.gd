class_name ShipHealthWidget
extends Control

const DEFAULT_MAX_HEALTH: float = 100.0

@export var auto_connect_ship_health_signal: bool = true

@onready var health_bar: ProgressBar = $Content/HealthBar
@onready var health_label: Label = $Content/HealthLabel

var _current_health: float = DEFAULT_MAX_HEALTH
var _max_health: float = DEFAULT_MAX_HEALTH

func _ready() -> void:
	if auto_connect_ship_health_signal and not EventBus.ship_health_changed.is_connected(_on_ship_health_changed):
		EventBus.ship_health_changed.connect(_on_ship_health_changed)
	sync_from_ship()
	_refresh_display()

func set_health(current: float, maximum: float) -> void:
	_max_health = maxf(maximum, 1.0)
	_current_health = clampf(current, 0.0, _max_health)
	_refresh_display()

func sync_from_ship(ship: Node = null) -> void:
	var target_ship := ship
	if target_ship == null:
		target_ship = get_tree().get_first_node_in_group("ship")

	if target_ship and "health_component" in target_ship and target_ship.health_component:
		set_health(target_ship.health_component.current_health, target_ship.health_component.max_health)
		return

	set_health(DEFAULT_MAX_HEALTH, DEFAULT_MAX_HEALTH)

func _on_ship_health_changed(current: float, maximum: float) -> void:
	set_health(current, maximum)

func _refresh_display() -> void:
	health_bar.max_value = _max_health
	health_bar.value = _current_health
	health_label.text = "%d/%d" % [int(round(_current_health)), int(round(_max_health))]
