class_name BaseEnemy
extends CharacterBody2D

## 敌人基础类：封装目标查找、受伤反馈、血条与死亡事件。

const FLOATING_BAR_SCENE := preload("res://scenes/ui/toughness_bar.tscn")
const HEALTH_BAR_DISPLAY_DURATION: float = 1.5

@export var currency_reward: int = 0
@export var player_knockback_force: float = 320.0

var _target: Node2D = null
var _health_bar: ProgressBar
var _health_bar_hide_timer: float = 0.0
var _last_feedback_physics_frame: int = -1

@onready var _health_component: HealthComponent = $HealthComponent
@onready var visual: ColorRect = $Visual


func _base_enemy_ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(3, true)
	set_collision_mask_value(1, true)
	set_collision_mask_value(2, true)
	set_collision_mask_value(6, true)

	if _health_component:
		_health_component.health_changed.connect(_on_health_changed)
		_health_component.died.connect(_on_died)
	add_to_group("enemies")
	_spawn_health_bar()
	_update_health_bar()
	_find_target()


func _update_enemy_feedback(delta: float) -> void:
	if _health_bar_hide_timer > 0.0:
		_health_bar_hide_timer -= delta
		if _health_bar_hide_timer <= 0.0 and _health_bar != null:
			_health_bar.visible = false


func _find_target() -> void:
	var landship := get_tree().get_first_node_in_group("ship") as Node2D
	if landship != null:
		_target = landship
		return

	landship = get_tree().root.find_child("Landship", true, false) as Node2D
	_target = landship


func _get_target_position() -> Vector2:
	if _target != null and is_instance_valid(_target):
		return _target.global_position
	return get_viewport().get_visible_rect().size * 0.5


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


func _on_damaged(amount: float, source) -> void:
	if amount <= 0.0:
		return
	_show_health_bar()
	_show_damage_flash()
	var is_critical := false
	EventBus.damage_dealt.emit(amount, global_position, source, is_critical)


func _spawn_health_bar() -> void:
	if FLOATING_BAR_SCENE == null or _health_bar != null:
		return

	_health_bar = FLOATING_BAR_SCENE.instantiate() as ProgressBar
	if _health_bar == null:
		return

	add_child(_health_bar)
	_health_bar.z_index = 10
	_health_bar.modulate = Color(1.0, 0.35, 0.35)
	_health_bar.visible = false


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
	if visual == null:
		return
	visual.modulate = Color(1.0, 0.45, 0.45)
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color.WHITE, 0.18)


func _on_died() -> void:
	EventBus.enemy_died.emit(self, global_position, currency_reward)
	queue_free()
