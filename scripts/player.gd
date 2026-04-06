extends CharacterBody2D

## Player character movement script
## Moves with WASD in local coordinates relative to parent ship
## Constrained to ship bounds

@export var speed: float = 250.0

# Ship bounds (half-extents)
const SHIP_BOUNDS_X: float = 380.0
const SHIP_BOUNDS_Y: float = 180.0

func _physics_process(delta: float) -> void:
	# Get input direction in local coordinates
	var input_direction := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	
	# Apply movement in local space (relative to parent ship)
	velocity = input_direction * speed
	
	# Move using move_and_slide() - handles physics automatically
	move_and_slide()
	
	# Constrain to ship bounds after movement
	_constrain_to_bounds()

func _constrain_to_bounds() -> void:
	# Clamp position to ship bounds
	position.x = clamp(position.x, -SHIP_BOUNDS_X, SHIP_BOUNDS_X)
	position.y = clamp(position.y, -SHIP_BOUNDS_Y, SHIP_BOUNDS_Y)
