class_name ProjectileTrail
extends GPUParticles2D

## 无贴图资产的投射物拖尾。
## 当前目标是紧凑的彗尾效果；后续可在这里继续扩展为曳光弹、光晕等表现。

const TEXTURE_SIZE := 24

@export var reference_speed: float = 500.0
@export var base_amount: int = 18
@export var base_lifetime: float = 0.18
@export var base_scale_min: float = 0.16
@export var base_scale_max: float = 0.34
@export var velocity_spread_min: float = 4.0
@export var velocity_spread_max: float = 12.0

func _ready() -> void:
	local_coords = false
	one_shot = false
	emitting = false
	texture = _build_circle_texture()
	process_material = _build_process_material()
	amount = base_amount
	lifetime = base_lifetime
	explosiveness = 0.65
	randomness = 0.15


func configure_for_spawn(projectile_speed: float, trail_color: Color) -> void:
	var speed_ratio := clampf(projectile_speed / maxf(reference_speed, 1.0), 0.75, 1.6)
	amount = max(8, int(round(base_amount * speed_ratio)))
	lifetime = base_lifetime

	var particle_material := process_material as ParticleProcessMaterial
	if particle_material != null:
		particle_material.scale_min = base_scale_min * lerpf(0.95, 1.15, (speed_ratio - 0.75) / 0.85)
		particle_material.scale_max = base_scale_max * lerpf(0.95, 1.15, (speed_ratio - 0.75) / 0.85)
		particle_material.initial_velocity_min = velocity_spread_min * speed_ratio
		particle_material.initial_velocity_max = velocity_spread_max * speed_ratio
		particle_material.color_ramp = _build_color_ramp(trail_color)

	restart()
	emitting = true


func stop_for_pool() -> void:
	emitting = false


func _build_process_material() -> ParticleProcessMaterial:
	var particle_material := ParticleProcessMaterial.new()
	particle_material.gravity = Vector3.ZERO
	particle_material.direction = Vector3(0.0, 0.0, 0.0)
	particle_material.spread = 180.0
	particle_material.initial_velocity_min = velocity_spread_min
	particle_material.initial_velocity_max = velocity_spread_max
	particle_material.scale_min = base_scale_min
	particle_material.scale_max = base_scale_max
	particle_material.color_ramp = _build_color_ramp(Color.WHITE)
	return particle_material


func _build_circle_texture() -> ImageTexture:
	var image := Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)

	var center := Vector2(TEXTURE_SIZE * 0.5, TEXTURE_SIZE * 0.5)
	var radius := float(TEXTURE_SIZE) * 0.5 - 1.0

	for x in range(TEXTURE_SIZE):
		for y in range(TEXTURE_SIZE):
			var distance := Vector2(x, y).distance_to(center)
			if distance > radius:
				continue

			var alpha := 1.0 - smoothstep(radius * 0.2, radius, distance)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))

	return ImageTexture.create_from_image(image)


func _build_color_ramp(base_color: Color) -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.add_point(0.0, Color(base_color.r, base_color.g, base_color.b, 0.85))
	gradient.add_point(0.35, Color(base_color.r, base_color.g, base_color.b, 0.45))
	gradient.add_point(1.0, Color(base_color.r, base_color.g, base_color.b, 0.0))

	var ramp := GradientTexture1D.new()
	ramp.gradient = gradient
	return ramp
