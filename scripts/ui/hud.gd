extends Control

## Simple HUD showing ship HP bar at top-left.

@onready var hp_bar: ProgressBar = $HPBar

func _ready() -> void:
	EventBus.ship_health_changed.connect(_on_ship_health_changed)

func _on_ship_health_changed(current: float, maximum: float) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = current
