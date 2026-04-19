class_name LeadCalculator
extends RefCounted

## 通用预瞄计算器：根据目标速度与弹速，返回拦截点。

static func calculate_intercept_point(origin: Vector2, target: Node2D, projectile_speed: float) -> Vector2:
	if target == null or not is_instance_valid(target):
		return origin

	var target_velocity := Vector2.ZERO
	if target is CharacterBody2D:
		target_velocity = target.velocity

	if target_velocity.length_squared() < 0.01 or projectile_speed <= 0.0:
		return target.global_position

	var relative_pos := target.global_position - origin
	var speed_sq := projectile_speed * projectile_speed
	var vel_sq := target_velocity.length_squared()
	var a := vel_sq - speed_sq
	var b := 2.0 * relative_pos.dot(target_velocity)
	var c := relative_pos.length_squared()

	if is_equal_approx(vel_sq, speed_sq):
		if absf(b) < 0.001:
			return target.global_position
		var t_linear := -c / b
		if t_linear < 0.0:
			return target.global_position
		return target.global_position + target_velocity * t_linear

	var discriminant := b * b - 4.0 * a * c
	if discriminant < 0.0:
		return target.global_position

	var sqrt_disc := sqrt(discriminant)
	var two_a := 2.0 * a
	var t1 := (-b - sqrt_disc) / two_a
	var t2 := (-b + sqrt_disc) / two_a
	var intercept_time := -1.0
	if t1 >= 0.0 and t2 >= 0.0:
		intercept_time = minf(t1, t2)
	elif t1 >= 0.0:
		intercept_time = t1
	elif t2 >= 0.0:
		intercept_time = t2

	if intercept_time < 0.0:
		return target.global_position
	return target.global_position + target_velocity * intercept_time
