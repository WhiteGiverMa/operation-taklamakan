class_name TurretTargetingHelper
extends RefCounted

const LEAD_CALCULATOR := preload("res://scripts/lead_calculator.gd")

## 炮塔自动火控辅助：封装射界求解与自动目标筛选。

static func resolve_fire_solution(
		origin: Vector2,
		target_position: Vector2,
		firing_arc_center_angle: float,
		firing_arc_half_angle_degrees: float
	) -> Dictionary:
	var raw_angle := origin.angle_to_point(target_position)
	var relative_angle := wrapf(raw_angle - firing_arc_center_angle, -PI, PI)
	var half_arc := deg_to_rad(firing_arc_half_angle_degrees)
	var clamped_relative_angle := clampf(relative_angle, -half_arc, half_arc)
	return {
		"raw_angle": raw_angle,
		"within_arc": absf(relative_angle) <= half_arc,
		"clamped_angle": firing_arc_center_angle + clamped_relative_angle,
	}


static func find_auto_target(
		tree: SceneTree,
		origin: Vector2,
		muzzle_position: Vector2,
		auto_target_range: float,
		projectile_speed: float,
		firing_arc_center_angle: float,
		firing_arc_half_angle_degrees: float
	) -> Dictionary:
	if tree == null:
		return {}

	var enemies: Array = tree.get_nodes_in_group("enemies")
	var closest: Node2D = null
	var closest_distance := INF
	var closest_lead: Vector2 = Vector2.ZERO

	for candidate in enemies:
		if not (candidate is Node2D) or not is_instance_valid(candidate):
			continue
		var enemy := candidate as Node2D
		var distance := origin.distance_to(enemy.global_position)
		if distance > auto_target_range:
			continue

		var lead_pos := LEAD_CALCULATOR.calculate_intercept_point(muzzle_position, enemy, projectile_speed)
		if not resolve_fire_solution(origin, lead_pos, firing_arc_center_angle, firing_arc_half_angle_degrees).get("within_arc", false):
			continue

		if distance < closest_distance:
			closest_distance = distance
			closest = enemy
			closest_lead = lead_pos

	if closest == null:
		return {}
	return {"target": closest, "lead_position": closest_lead}
