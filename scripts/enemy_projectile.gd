class_name EnemyProjectile
extends Area2D

## Enemy projectile that damages the ship on contact.
## 支持对象池模式，通过 ProjectileSpawner 管理生命周期

var velocity: Vector2 = Vector2.ZERO
var speed: float = 400.0
var damage: float = 15.0
@export var player_knockback_force: float = 360.0
var _source: Node = null
var _is_pool_active: bool = false
var _lifetime_timer: SceneTreeTimer = null

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: ColorRect = $Visual
@onready var trail: GPUParticles2D = $Trail

func _ready() -> void:
	# 敌方投射物同样由 ProjectileSpawner 管理，需要提高 z_index
	# 以确保可见于舰体和炮塔之上
	z_index = 10
	process_mode = Node.PROCESS_MODE_PAUSABLE

	# Enemy projectile: layer 5 (enemy_projectile)
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(5, true)
	# Collide with: layer 1 (ship), layer 2 (turret), layer 6 (player)
	set_collision_mask_value(1, true)
	set_collision_mask_value(2, true)
	set_collision_mask_value(6, true)
	
	body_entered.connect(_on_body_entered)

func setup(dir: Vector2, spd: float, dmg: float, source: Node = null) -> void:
	velocity = dir.normalized() * spd
	speed = spd
	damage = dmg
	_source = source
	_is_pool_active = true
	
	# Rotate visual to face direction of travel
	rotation = dir.angle()
	if trail != null and trail.has_method("configure_for_spawn"):
		trail.configure_for_spawn(spd, visual.color)
	
	# Auto-recycle after 5 seconds to prevent memory leaks
	# 取消之前的定时器（如果存在）
	if _lifetime_timer and _lifetime_timer.timeout.is_connected(_on_lifetime_timeout):
		_lifetime_timer.timeout.disconnect(_on_lifetime_timeout)
	_lifetime_timer = get_tree().create_timer(5.0)
	_lifetime_timer.timeout.connect(_on_lifetime_timeout)

func _physics_process(delta: float) -> void:
	position += velocity * delta

func _on_body_entered(body: Node2D) -> void:
	# 检查 source 是否仍然有效，避免传入已释放的对象
	var valid_source: Node = null
	if is_instance_valid(_source):
		valid_source = _source
	
	if body.has_method(&"receive_impact"):
		var impact_data := DamageData.new(0.0, valid_source)
		impact_data.damage_type = "impact"
		impact_data.knockback = velocity.normalized() * player_knockback_force
		body.receive_impact(impact_data)
		call_deferred(&"_recycle_to_pool")
		return

	# Apply damage to ship or turret
	if body.has_method("take_damage"):
		var dmg_data := DamageData.new(damage, valid_source)
		body.take_damage(dmg_data)
	
	# Destroy projectile on any hit - 使用 call_deferred 避免在物理回调中禁用碰撞体
	call_deferred(&"_recycle_to_pool")


## 生命周期超时回调
func _on_lifetime_timeout() -> void:
	_recycle_to_pool()


## 对象池支持：检查是否可用于池复用
func is_available_for_pool() -> bool:
	return not _is_pool_active


## 对象池支持：检查是否处于激活状态
func is_pool_active() -> bool:
	return _is_pool_active


## 回收到对象池
func _recycle_to_pool() -> void:
	_is_pool_active = false
	if trail != null and trail.has_method("stop_for_pool"):
		trail.stop_for_pool()
	
	# 取消生命周期定时器
	if _lifetime_timer and _lifetime_timer.timeout.is_connected(_on_lifetime_timeout):
		_lifetime_timer.timeout.disconnect(_on_lifetime_timeout)
	_lifetime_timer = null
	
	# 尝试通过 ProjectileSpawner 回收
	if is_inside_tree():
		var spawner := get_tree().root.get_node_or_null("ProjectileSpawner")
		if spawner and spawner.has_method("return_to_pool"):
			spawner.return_to_pool(self, true)
			return
	
	# 回退：直接销毁
	queue_free()
