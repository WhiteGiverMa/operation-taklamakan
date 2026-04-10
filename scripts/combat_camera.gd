extends Camera2D

const DEFAULT_ZOOM_LEVEL := 1.0
const MIN_ZOOM_LEVEL := 0.6
const MAX_ZOOM_LEVEL := 1.4
const ZOOM_STEP := 0.1

func _ready() -> void:
	enabled = true
	zoom = Vector2.ONE * DEFAULT_ZOOM_LEVEL
	_connect_actions()

func _connect_actions() -> void:
	if not InputManager.camera_zoom_in_action.just_triggered.is_connected(_on_zoom_in_triggered):
		InputManager.camera_zoom_in_action.just_triggered.connect(_on_zoom_in_triggered)
	if not InputManager.camera_zoom_out_action.just_triggered.is_connected(_on_zoom_out_triggered):
		InputManager.camera_zoom_out_action.just_triggered.connect(_on_zoom_out_triggered)
	if not InputManager.camera_zoom_reset_action.just_triggered.is_connected(_on_zoom_reset_triggered):
		InputManager.camera_zoom_reset_action.just_triggered.connect(_on_zoom_reset_triggered)

func _on_zoom_in_triggered() -> void:
	_set_zoom_level(zoom.x + ZOOM_STEP)

func _on_zoom_out_triggered() -> void:
	_set_zoom_level(zoom.x - ZOOM_STEP)

func _on_zoom_reset_triggered() -> void:
	_set_zoom_level(DEFAULT_ZOOM_LEVEL)

func get_world_half_extents() -> Vector2:
	var viewport_size := get_viewport_rect().size
	if viewport_size == Vector2.ZERO:
		return Vector2.ZERO
	return (viewport_size * 0.5) / zoom

func _set_zoom_level(next_zoom_level: float) -> void:
	var clamped_zoom := clampf(next_zoom_level, MIN_ZOOM_LEVEL, MAX_ZOOM_LEVEL)
	zoom = Vector2.ONE * clamped_zoom
