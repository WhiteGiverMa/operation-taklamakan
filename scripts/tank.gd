class_name Tank
extends CharacterBody2D

## Tank enemy that moves toward the ship and deals damage on collision.

const FLOATING_BAR_SCENE := preload("res://scenes/ui/toughness_bar.tscn")

@export var speed: float = 100.0
@export var damage: float = 10.0
@export var currency_reward: int = 10
@export var collision_damage_cooldown: float = 0.5
@export var player_knockback_force: float = 420.0
@export var is_boss: bool = false

var _target: Node2D = null
var _health_component: HealthComponent
var _collision_damage_timer: float = 0.0
var _health_bar: ProgressBar
var _health_bar_hide_timer: float = 0.0
var _last_feedback_physics_frame: int = -1

const HEALTH_BAR_DISPLAY_DURATION: float = 1.5

@onready var visual: ColorRect = $Visual

func _ready() -> void:
	_health_component = $HealthComponent
	
	# Enemy: layer 3, mask 1 (ship), 2 (turret), 6 (player)
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(3, true)
	set_collision_mask_value(1, true)
	set_collision_mask_value(2, true)
	set_collision_mask_value(6, true)
	
	# Connect HealthComponent signals
	if _health_component:
		_health_component.health_changed.connect(_on_health_changed)
		_health_component.died.connect(_on_died)
	add_to_group("enemies")
	_spawn_health_bar()
	_update_health_bar()
	
	# Find the ship (Landship) in the scene
	_find_target()

func _find_target() -> void:
	# Try to find Landship in the scene
	var landship = get_tree().get_first_node_in_group("ship")
	if landship:
		_target = landship
	else:
		# Fallback: try to find by name
		landship = get_tree().root.find_child("Landship", true, false)
		if landship:
			_target = landship

func _physics_process(delta: float) -> void:
	# Update collision damage cooldown
	if _collision_damage_timer > 0:
		_collision_damage_timer -= delta
	
	# Update health bar hide timer
	if _health_bar_hide_timer > 0:
		_health_bar_hide_timer -= delta
		if _health_bar_hide_timer <= 0 and _health_bar:
			_health_bar.visible = false
	
	# Move toward target (ship)
	var target_pos := _get_target_position()
	var direction := (target_pos - global_position).normalized()
	velocity = direction * speed
	
	move_and_slide()
	
	# Check for collisions with ship or turrets and deal damage
	if _collision_damage_timer <= 0:
		for i in get_slide_collision_count():
			var collision := get_slide_collision(i)
			var collider := collision.get_collider()
			
			if collider != null and collider.has_method(&"receive_impact"):
				if _apply_player_impact(collider):
					_collision_damage_timer = collision_damage_cooldown
					break
			if collider != null and collider.has_method(&"take_damage"):
				var damage_data := DamageData.physical(damage, self)
				collider.take_damage(damage_data)
				_collision_damage_timer = collision_damage_cooldown
				break  # Only damage one target per cooldown

func _apply_player_impact(collider: Object) -> bool:
	var player := collider as Node2D
	if player == null:
		return false

	var push_direction := player.global_position - global_position
	if push_direction.length_squared() <= 0.001:
		push_direction = velocity
	if push_direction.length_squared() <= 0.001:
		push_direction = Vector2.RIGHT

	var impact_data := DamageData.new(0.0, self)
	impact_data.damage_type = "impact"
	impact_data.knockback = push_direction.normalized() * player_knockback_force
	return player.receive_impact(impact_data)

func _get_target_position() -> Vector2:
	if _target:
		return _target.global_position
	# Fallback: return center of screen
	return Vector2(960, 540)

func take_damage(data: DamageData) -> float:
	if _health_component == null:
		return 0.0
	var actual_damage := _health_component.take_damage(data)
	if actual_damage > 0.0:
		show_damage_feedback(actual_damage)
	return actual_damage

func show_damage_feedback(amount: float) -> void:
	if amount <= 0.0:
		return

	var physics_frame := Engine.get_physics_frames()
	if _last_feedback_physics_frame == physics_frame:
		return
	_last_feedback_physics_frame = physics_frame
	_on_damaged(amount, null)

func _on_health_changed(_old_health: float, _new_health: float) -> void:
	_update_health_bar()

func _on_damaged(amount: float, _source) -> void:
	if amount <= 0.0:
		return
	_show_health_bar()
	_show_damage_flash()
	_spawn_damage_number(amount)

func _spawn_health_bar() -> void:
	if FLOATING_BAR_SCENE == null or _health_bar != null:
		return

	_health_bar = FLOATING_BAR_SCENE.instantiate() as ProgressBar
	if _health_bar == null:
		return

	add_child(_health_bar)
	_health_bar.z_index = 10
	_health_bar.modulate = Color(1.0, 0.35, 0.35)
	_health_bar.visible = false  # 初始隐藏

func _show_health_bar() -> void:
	if _health_bar == null:
		return
	_health_bar.visible = true
	_health_bar_hide_timer = HEALTH_BAR_DISPLAY_DURATION

func _update_health_bar() -> void:
	if _health_bar == null or _health_component == null:
		return

	_health_bar.max_value = _health_component.max_health
	_health_bar.value = _health_component.current_health

func _show_damage_flash() -> void:
	visual.modulate = Color(1.0, 0.45, 0.45)
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color.WHITE, 0.18)

func _spawn_damage_number(amount: float) -> void:
	var popup := Label.new()
	popup.text = str(int(round(amount)))
	# 添加随机X偏移避免重叠
	var random_offset_x := randf_range(-20.0, 20.0)
	popup.position = global_position + Vector2(-40.0 + random_offset_x, -110.0)
	popup.size = Vector2(80.0, 36.0)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup.z_index = 20
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.modulate = Color(1.0, 0.92, 0.4, 1.0)
	popup.add_theme_font_size_override("font_size", 28)
	popup.add_theme_color_override("font_color", Color(1.0, 0.97, 0.7))
	popup.add_theme_color_override("font_outline_color", Color(0.08, 0.02, 0.02, 0.95))
	popup.add_theme_constant_override("outline_size", 6)

	var popup_parent := get_tree().root.get_node_or_null("Main/UILayer")
	if popup_parent != null:
		popup_parent.add_child(popup)
	else:
		add_child(popup)

	# 飘字动画：向上飘动 + 渐隐
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", popup.position.y - 40.0, 0.6)
	tween.tween_property(popup, "modulate:a", 0.0, 0.6)
	tween.finished.connect(popup.queue_free)

func _on_died() -> void:
	# Emit enemy_died signal for currency drop
	EventBus.enemy_died.emit(self, global_position, currency_reward)
	queue_free()
