class_name Projectile
extends Area2D

## Player projectile. Moves in a straight line and damages enemies on contact.

var velocity: Vector2 = Vector2.ZERO
var speed: float = 600.0
var damage: float = 15.0
var _source: Node = null
var _has_hit: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: ColorRect = $Visual

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	# Projectile: layer 4
	set_collision_layer_value(4, true)
	# Collide with: layer 3 (enemies)
	set_collision_mask_value(3, true)
	
	body_entered.connect(_on_body_entered)

func setup(dir: Vector2, spd: float, dmg: float, source: Node = null) -> void:
	velocity = dir.normalized() * spd
	speed = spd
	damage = dmg
	_source = source
	
	# Rotate visual to face direction of travel
	rotation = dir.angle()

func _physics_process(delta: float) -> void:
	if _has_hit:
		return

	var current_position := global_position
	var next_position := current_position + velocity * delta

	var hit_target := _find_overlap_target(current_position)
	if hit_target == null:
		hit_target = _find_swept_target(current_position, next_position)
	if hit_target == null:
		hit_target = _find_overlap_target(next_position)

	if hit_target != null:
		_apply_hit(hit_target)
		return

	global_position = next_position
	
	# Queue free if too far from any relevant point (cleanup)
	# For now, just use lifetime timer
	pass

func _on_body_entered(body: Node2D) -> void:
	if _has_hit or not _is_enemy_target(body):
		return
	_apply_hit(body)


func _apply_hit(body: Node2D) -> void:
	if _has_hit:
		return
	_has_hit = true

	var dmg_data := DamageData.new(damage, _source)
	var actual_damage = body.take_damage(dmg_data)
	if actual_damage is float and actual_damage > 0.0 and body.has_method("show_damage_feedback"):
		body.show_damage_feedback(actual_damage)
	var emitted_damage := damage
	if actual_damage is float:
		emitted_damage = actual_damage
	if emitted_damage > 0.0:
		_spawn_damage_number(body.global_position, emitted_damage)
	EventBus.projectile_hit.emit(self, body, emitted_damage)
	queue_free()


func _find_overlap_target(check_position: Vector2) -> Node2D:
	if collision_shape == null or collision_shape.shape == null:
		return null

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = collision_shape.shape
	query.transform = Transform2D(rotation, check_position)
	query.collision_mask = collision_mask
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.exclude = _build_query_excludes()

	var results := get_world_2d().direct_space_state.intersect_shape(query, 8)
	return _pick_closest_target(results, check_position)


func _find_swept_target(from_position: Vector2, to_position: Vector2) -> Node2D:
	var query := PhysicsRayQueryParameters2D.create(from_position, to_position, collision_mask)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.exclude = _build_query_excludes()

	var result := get_world_2d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return null

	var collider := result.get("collider") as Node2D
	if collider == null or not _is_enemy_target(collider):
		return null
	return collider


func _build_query_excludes() -> Array[RID]:
	var excludes: Array[RID] = [get_rid()]
	if _source is CollisionObject2D:
		excludes.append((_source as CollisionObject2D).get_rid())
	return excludes


func _pick_closest_target(results: Array[Dictionary], origin: Vector2) -> Node2D:
	var closest_target: Node2D = null
	var closest_distance_sq := INF

	for result in results:
		var collider := result.get("collider") as Node2D
		if collider == null or not _is_enemy_target(collider):
			continue

		var distance_sq := origin.distance_squared_to(collider.global_position)
		if distance_sq < closest_distance_sq:
			closest_distance_sq = distance_sq
			closest_target = collider

	return closest_target


func _spawn_damage_number(target_position: Vector2, amount: float) -> void:
	var popup := Label.new()
	popup.text = str(int(round(amount)))
	popup.position = target_position + Vector2(-40.0, -110.0)
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

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", popup.position.y - 28.0, 0.45)
	tween.tween_property(popup, "modulate:a", 0.0, 0.45)
	tween.finished.connect(popup.queue_free)


func _is_enemy_target(body: Node2D) -> bool:
	return body.is_in_group("enemies") and body.has_method("take_damage")
