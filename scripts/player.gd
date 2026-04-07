extends CharacterBody2D

## Player character movement script
## Moves with WASD in local coordinates relative to parent ship
## Constrained to ship bounds

@export var speed: float = 250.0

# Ship bounds (half-extents)
const SHIP_BOUNDS_X: float = 380.0
const SHIP_BOUNDS_Y: float = 180.0

func _ready() -> void:
	# 玩家站在舰体内部移动，不应与舰体 hull 自身发生物理碰撞，
	# 否则 CharacterBody2D 会被父节点 StaticBody2D 的碰撞解算限制移动。
	collision_layer = 0
	collision_mask = 0

func _physics_process(_delta: float) -> void:
	# Get input direction in local coordinates
	var input_direction := InputManager.move_action.value_axis_2d
	
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
