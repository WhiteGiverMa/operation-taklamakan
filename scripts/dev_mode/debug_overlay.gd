extends Node2D

## Debug overlay for rendering collision boxes, enemy paths, and attack ranges.

var show_collision_boxes: bool = false
var show_paths: bool = false
var show_attack_ranges: bool = false


func _ready() -> void:
	top_level = true
	z_index = 1000
	z_as_relative = false
	if get_parent() == null:
		get_tree().root.add_child.call_deferred(self)
	EventBus.dev_event.connect(_on_dev_event)


func _on_dev_event(event_type: String, data: Dictionary) -> void:
	match event_type:
		"toggle_collision":
			show_collision_boxes = data.get("enabled", false)
		"toggle_paths":
			show_paths = data.get("enabled", false)
		"toggle_ranges":
			show_attack_ranges = data.get("enabled", false)
	queue_redraw()


func _draw() -> void:
	_draw_collision_shapes()
	_draw_paths()
	_draw_attack_ranges()


func _draw_collision_shapes() -> void:
	if not show_collision_boxes:
		return

	var targets: Array[Node2D] = []

	for node in get_tree().get_nodes_in_group("ship"):
		if node is Node2D:
			targets.append(node)

	for node in get_tree().get_nodes_in_group("enemies"):
		if node is Node2D:
			targets.append(node)

	_find_nodes_of_class(get_tree().root, Turret, targets)

	for target in targets:
		if not is_instance_valid(target):
			continue
		var shapes := _find_collision_shape_2d_children(target)
		for shape_node in shapes:
			if not is_instance_valid(shape_node) or shape_node.shape == null:
				continue
			_draw_shape(shape_node)

	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_shape(shape_node: CollisionShape2D) -> void:
	draw_set_transform_matrix(shape_node.get_global_transform())
	var shape := shape_node.shape

	if shape is CircleShape2D:
		var radius := (shape as CircleShape2D).radius
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color.RED, 2.0, true)
	elif shape is RectangleShape2D:
		var size := (shape as RectangleShape2D).size
		draw_rect(Rect2(-size * 0.5, size), Color.RED, false, 2.0)
	elif shape is CapsuleShape2D:
		var caps := shape as CapsuleShape2D
		var size := Vector2(caps.radius * 2.0, caps.height)
		draw_rect(Rect2(-size * 0.5, size), Color.RED, false, 2.0)
	else:
		# Fallback: bounding rect if available, else 20x20
		var rect: Rect2
		if shape.has_method("get_rect"):
			rect = shape.get_rect()
		else:
			rect = Rect2(-Vector2(10, 10), Vector2(20, 20))
		draw_rect(rect, Color.RED, false, 2.0)

	draw_set_transform_matrix(Transform2D.IDENTITY)


func _find_collision_shape_2d_children(root: Node) -> Array[CollisionShape2D]:
	var result: Array[CollisionShape2D] = []
	for child in root.get_children():
		if child is CollisionShape2D:
			result.append(child)
		result.append_array(_find_collision_shape_2d_children(child))
	return result


func _find_nodes_of_class(root: Node, p_class, out: Array[Node2D]) -> void:
	for child in root.get_children():
		if child is Node2D and is_instance_of(child, p_class):
			out.append(child as Node2D)
		_find_nodes_of_class(child, p_class, out)


func _draw_paths() -> void:
	if not show_paths:
		return

	var ship := get_tree().get_first_node_in_group("ship") as Node2D
	var target_pos := Vector2.ZERO
	if ship != null:
		target_pos = ship.global_position
	else:
		target_pos = get_viewport_rect().size * 0.5

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not (enemy is Node2D) or not is_instance_valid(enemy):
			continue
		var enemy_2d := enemy as Node2D
		draw_line(enemy_2d.global_position, target_pos, Color.GREEN, 2.0)


func _draw_attack_ranges() -> void:
	if not show_attack_ranges:
		return

	var turrets: Array[Node2D] = []
	_find_nodes_of_class(get_tree().root, Turret, turrets)

	for turret_node in turrets:
		if not is_instance_valid(turret_node):
			continue
		var turret := turret_node as Turret
		var range_val: float = turret.auto_target_range
		draw_arc(turret.global_position, range_val, 0.0, TAU, 64, Color.CYAN, 2.0, true)
