extends Node

## Global damage popup manager for unified damage number display.
## Handles object pooling, styling, and positioning of damage popups.

# Configuration
@export_category("Pool Configuration")
@export var pool_size: int = 50
@export var preload_count: int = 20

@export_category("Animation")
@export var float_distance: float = 40.0
@export var animation_duration: float = 0.6

# Runtime State
var _popup_pool: Array[Label] = []
var _active_popups: Array[Label] = []
var _popup_parent: Node = null

# Style Configuration
var _normal_style: Dictionary = {
	"font_size": 28,
	"font_color": Color(1.0, 0.97, 0.7),
	"outline_color": Color(0.08, 0.02, 0.02, 0.95),
	"outline_size": 6,
	"modulate": Color(1.0, 0.92, 0.4, 1.0)
}

var _critical_style: Dictionary = {
	"font_size": 36,
	"font_color": Color(1.0, 0.2, 0.2),
	"outline_color": Color(0.5, 0.0, 0.0, 0.95),
	"outline_size": 8,
	"modulate": Color(1.0, 0.5, 0.3, 1.0)
}

func _ready() -> void:
	# Connect to EventBus signal
	EventBus.damage_dealt.connect(_on_damage_dealt)
	
	# Initialize popup parent (UILayer)
	_find_popup_parent()
	
	# Pre-populate pool
	_initialize_pool()

func _find_popup_parent() -> void:
	_popup_parent = get_tree().root.get_node_or_null("Main/UILayer")
	if _popup_parent == null:
		push_warning("DamagePopupManager: UILayer not found, popups may not render correctly")

func _initialize_pool() -> void:
	for i in range(preload_count):
		var popup := _create_popup_node()
		_popup_pool.append(popup)

func _create_popup_node() -> Label:
	var popup := Label.new()
	popup.size = Vector2(80.0, 36.0)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup.z_index = 20
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.visible = false  # Initially hidden
	return popup

func _on_damage_dealt(amount: float, position: Vector2, source: Node, is_critical: bool) -> void:
	if amount <= 0.0:
		return
	
	_spawn_popup(amount, position, is_critical)

func _spawn_popup(amount: float, world_position: Vector2, is_critical: bool) -> void:
	# Get popup from pool or create new one
	var popup := _get_popup_from_pool()
	if popup == null:
		popup = _create_popup_node()
	
	# Convert world position to screen position for Camera2D
	# Formula: screen_pos = (world_pos - camera_pos) * zoom + viewport_center
	var viewport := get_viewport()
	var camera := viewport.get_camera_2d()
	var screen_pos: Vector2
	if camera != null:
		var viewport_center := viewport.get_visible_rect().size * 0.5
		var camera_pos := camera.global_position
		var camera_zoom := camera.zoom
		screen_pos = (world_position - camera_pos) * camera_zoom + viewport_center
	else:
		screen_pos = world_position
	
	# Add random X offset to avoid overlapping
	var random_offset_x := randf_range(-20.0, 20.0)
	popup.position = screen_pos + Vector2(-40.0 + random_offset_x, -110.0)
	
	# Apply style based on critical hit
	var style := _critical_style if is_critical else _normal_style
	_apply_style(popup, style)
	
	# Set text
	popup.text = str(int(round(amount)))
	
	# Add to scene
	if _popup_parent != null:
		_popup_parent.add_child(popup)
	else:
		# Fallback: add to root
		get_tree().root.add_child(popup)
	
	popup.visible = true
	_active_popups.append(popup)
	
	# Animate and return to pool
	_animate_popup(popup)

func _get_popup_from_pool() -> Label:
	if _popup_pool.is_empty():
		return null
	return _popup_pool.pop_back()

func _apply_style(popup: Label, style: Dictionary) -> void:
	popup.add_theme_font_size_override("font_size", style.font_size)
	popup.add_theme_color_override("font_color", style.font_color)
	popup.add_theme_color_override("font_outline_color", style.outline_color)
	popup.add_theme_constant_override("outline_size", style.outline_size)
	popup.modulate = style.modulate

func _animate_popup(popup: Label) -> void:
	# Create tween for animation
	var tween := popup.create_tween()
	tween.set_parallel(true)
	
	# Float up
	tween.tween_property(popup, "position:y", popup.position.y - float_distance, animation_duration)
	
	# Fade out
	tween.tween_property(popup, "modulate:a", 0.0, animation_duration)
	
	# Return to pool when animation completes
	tween.finished.connect(func(): _return_popup_to_pool(popup))

func _return_popup_to_pool(popup: Label) -> void:
	# Remove from active list
	var index := _active_popups.find(popup)
	if index >= 0:
		_active_popups.remove_at(index)
	
	# Reset state
	popup.visible = false
	popup.modulate.a = 1.0
	
	# Remove from parent
	if popup.get_parent() != null:
		popup.get_parent().remove_child(popup)
	
	# Return to pool if under limit
	if _popup_pool.size() < pool_size:
		_popup_pool.append(popup)
	else:
		# Pool full, free the node
		popup.queue_free()

## Spawns a damage popup manually (for testing or custom triggers)
func spawn_damage_popup(amount: float, world_position: Vector2, is_critical: bool = false) -> void:
	_on_damage_dealt(amount, world_position, null, is_critical)
