class_name Projectile
extends Area2D

## Player projectile. Moves in a straight line and damages enemies on contact.
## 支持对象池模式，通过 ProjectileSpawner 管理生命周期

var velocity: Vector2 = Vector2.ZERO
var speed: float = 600.0
var damage: float = 15.0
var _source: Node = null
var _has_hit: bool = false
var _is_pool_active: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: ColorRect = $Visual
@onready var trail: GPUParticles2D = $Trail

func _ready() -> void:
	# 投射物由 ProjectileSpawner（Autoload 根节点）管理，
	# 场景树绘制顺序在陆行舰之前，需要显式提高 z_index
	# 以确保投射物可见于舰体之上
	z_index = 10

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
	_has_hit = false
	_is_pool_active = true
	
	# Rotate visual to face direction of travel
	rotation = dir.angle()
	if trail != null and trail.has_method("configure_for_spawn"):
		trail.configure_for_spawn(spd, visual.color)

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
	_is_pool_active = false

	var dmg_data := DamageData.new(damage, _source)
	var actual_damage = body.take_damage(dmg_data)
	var emitted_damage := damage
	if actual_damage is float:
		emitted_damage = actual_damage
	EventBus.projectile_hit.emit(self, body, emitted_damage)
	_recycle_to_pool()


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
	if is_instance_valid(_source) and _source is CollisionObject2D:
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

func _is_enemy_target(body: Node2D) -> bool:
	return body.is_in_group("enemies") and body.has_method("take_damage")


## 对象池支持：检查是否可用于池复用
func is_available_for_pool() -> bool:
	return not _is_pool_active and not _has_hit


## 对象池支持：检查是否处于激活状态
func is_pool_active() -> bool:
	return _is_pool_active


## 回收到对象池
func _recycle_to_pool() -> void:
	_is_pool_active = false
	if trail != null and trail.has_method("stop_for_pool"):
		trail.stop_for_pool()
	
	# 尝试通过 ProjectileSpawner 回收
	if is_inside_tree():
		var spawner := get_tree().root.get_node_or_null("ProjectileSpawner")
		if spawner and spawner.has_method("return_to_pool"):
			spawner.return_to_pool(self, false)
			return
	
	# 回退：直接销毁
	queue_free()
