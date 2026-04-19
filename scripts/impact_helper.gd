class_name ImpactHelper
extends RefCounted

## 通用冲击辅助：统一击退方向与 receive_impact 数据构造。

static func build_knockback_damage(
		source: Node,
		source_position: Vector2,
		target: Node2D,
		fallback_velocity: Vector2,
		force: float
	) -> DamageData:
	var push_direction := target.global_position - source_position
	if push_direction.length_squared() <= 0.001:
		push_direction = fallback_velocity
	if push_direction.length_squared() <= 0.001:
		push_direction = Vector2.RIGHT

	var impact_data := DamageData.new(0.0, source)
	impact_data.damage_type = "impact"
	impact_data.knockback = push_direction.normalized() * force
	return impact_data


static func apply_receive_impact(
		collider: Object,
		source: Node,
		source_position: Vector2,
		fallback_velocity: Vector2,
		force: float
	) -> bool:
	var target := collider as Node2D
	if target == null or not collider.has_method(&"receive_impact"):
		return false

	var impact_data := build_knockback_damage(source, source_position, target, fallback_velocity, force)
	return target.receive_impact(impact_data)
