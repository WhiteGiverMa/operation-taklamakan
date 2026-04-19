class_name TargetLocator
extends RefCounted

## 通用目标定位工具，避免各 AI 单位重复手写节点组扫描。

static func find_primary_ship(tree: SceneTree) -> Node2D:
	if tree == null:
		return null

	var ship := tree.get_first_node_in_group("ship") as Node2D
	if ship != null:
		return ship

	return tree.root.find_child("Landship", true, false) as Node2D


static func fallback_viewport_center(viewport: Viewport) -> Vector2:
	if viewport == null:
		return Vector2.ZERO
	return viewport.get_visible_rect().size * 0.5


static func resolve_position(target: Node2D, viewport: Viewport) -> Vector2:
	if target != null and is_instance_valid(target):
		return target.global_position
	return fallback_viewport_center(viewport)


static func find_closest_node_in_group(
		tree: SceneTree,
		origin: Vector2,
		group_name: StringName,
		max_distance: float = INF,
		exclude: Node = null
	) -> Node2D:
	if tree == null:
		return null

	var closest: Node2D = null
	var closest_distance := max_distance

	for candidate in tree.get_nodes_in_group(group_name):
		if candidate == exclude or not (candidate is Node2D) or not is_instance_valid(candidate):
			continue

		var node := candidate as Node2D
		var distance := origin.distance_to(node.global_position)
		if distance > max_distance:
			continue
		if distance < closest_distance:
			closest_distance = distance
			closest = node

	return closest
