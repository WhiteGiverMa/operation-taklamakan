class_name MapNodeUI
extends TextureButton

## UI representation of a single map node.
## Displays the node icon, handles selection, and visual states.

signal node_selected(node_ui: MapNodeUI)
signal node_confirmed(node_ui: MapNodeUI)

const MapNodeScript := preload("res://scripts/map_node.gd")

# Node type colors (placeholder circles)
const NODE_COLORS := {
	MapNodeScript.TYPE_START: Color.WHITE,
	MapNodeScript.TYPE_COMBAT: Color(0.9, 0.2, 0.2),      # Red
	MapNodeScript.TYPE_ELITE: Color(0.6, 0.2, 0.8),       # Purple
	MapNodeScript.TYPE_SHOP: Color(1.0, 0.8, 0.2),        # Gold
	MapNodeScript.TYPE_EVENT: Color(0.2, 0.5, 0.9),       # Blue
	MapNodeScript.TYPE_REST: Color(0.2, 0.8, 0.3),        # Green
	MapNodeScript.TYPE_END: Color(1.0, 0.5, 0.1),         # Orange
	MapNodeScript.TYPE_BOSS: Color(1.0, 0.3, 0.1),        # Orange-Red
}

const TYPE_KEYS := {
	MapNodeScript.TYPE_START: "map.node_type.start",
	MapNodeScript.TYPE_COMBAT: "map.node_type.combat",
	MapNodeScript.TYPE_ELITE: "map.node_type.elite",
	MapNodeScript.TYPE_SHOP: "map.node_type.shop",
	MapNodeScript.TYPE_EVENT: "map.node_type.event",
	MapNodeScript.TYPE_REST: "map.node_type.rest",
	MapNodeScript.TYPE_END: "map.node_type.end",
	MapNodeScript.TYPE_BOSS: "map.node_type.boss",
}

# Visual state colors
const COLOR_LOCKED := Color(0.3, 0.3, 0.3, 0.5)
const COLOR_VISITED := Color(0.5, 0.5, 0.5, 0.7)
const COLOR_REACHABLE := Color.WHITE
const COLOR_SELECTED := Color(1.0, 1.0, 0.5)  # Yellow highlight

@export var node_radius: float = 24.0

var node_id: String = ""
var node_type: int = MapNodeScript.TYPE_COMBAT
var node_position: Vector2 = Vector2.ZERO
var is_visited: bool = false
var is_reachable: bool = false
var is_selected: bool = false
var layer_index: int = 0

var _circle_texture: ImageTexture

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_PASS
	pressed.connect(_on_pressed)
	_create_circle_texture()
	_update_visuals()

func setup(node: Variant) -> void:
	if node == null:
		return
	
	node_id = node.id
	node_type = node.type
	node_position = node.position
	is_visited = node.visited
	layer_index = node.layer_index
	
	# Set position (will be adjusted by parent container)
	position = node_position - Vector2(node_radius, node_radius)
	
	# Set size for interaction
	size = Vector2(node_radius * 2, node_radius * 2)
	
	# Recreate texture with correct color
	_create_circle_texture()
	
	_update_visuals()

func set_reachable(reachable: bool) -> void:
	is_reachable = reachable
	_update_visuals()

func set_visited(visited: bool) -> void:
	is_visited = visited
	_update_visuals()

func set_selected(selected: bool) -> void:
	is_selected = selected
	_update_visuals()
	if is_selected:
		node_selected.emit(self)

func get_type_name() -> String:
	var type_key := str(TYPE_KEYS.get(node_type, "map.node_type.unknown"))
	return Localization.t(type_key)

func _create_circle_texture() -> void:
	var image := Image.create(int(node_radius * 2), int(node_radius * 2), false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	var center := Vector2(node_radius, node_radius)
	var color: Color = NODE_COLORS.get(node_type, Color.WHITE)
	
	# Draw filled circle
	for x in range(image.get_width()):
		for y in range(image.get_height()):
			var pixel_pos := Vector2(x, y)
			var dist := pixel_pos.distance_to(center)
			if dist <= node_radius - 2:
				image.set_pixel(x, y, color)
			elif dist <= node_radius:
				# Anti-aliased edge
				var alpha := 1.0 - (dist - (node_radius - 2)) / 2.0
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	
	# Add border for BOSS nodes
	if node_type == MapNodeScript.TYPE_BOSS:
		var border_radius := node_radius + 4
		for x in range(image.get_width()):
			for y in range(image.get_height()):
				var pixel_pos := Vector2(x, y)
				var dist := pixel_pos.distance_to(center)
				if dist <= border_radius and dist > node_radius:
					var border_color := Color(1.0, 0.8, 0.0)  # Gold border
					image.set_pixel(x, y, border_color)
	
	_circle_texture = ImageTexture.create_from_image(image)
	texture_normal = _circle_texture

func _update_visuals() -> void:
	if _circle_texture == null:
		return
	
	modulate = _get_display_color()

func _get_display_color() -> Color:
	if is_selected:
		return COLOR_SELECTED
	elif is_visited:
		return COLOR_VISITED
	elif not is_reachable:
		return COLOR_LOCKED
	else:
		return COLOR_REACHABLE

func _on_pressed() -> void:
	if _can_confirm():
		if is_selected:
			node_confirmed.emit(self)
		else:
			set_selected(true)
	elif is_reachable and is_visited:
		set_selected(true)

func _can_confirm() -> bool:
	if not is_reachable:
		return false
	if not is_visited:
		return true
	return node_type == MapNodeScript.TYPE_SHOP
