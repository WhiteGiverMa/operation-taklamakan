extends Node

## ProjectileSpawner - 投射物生成器
## 统一管理游戏中所有投射物的创建、缓存和回收
## 使用对象池模式优化性能，避免频繁创建/销毁
## 参考 DreamerHeroines 的实现

# 投射物场景路径
const PROJECTILE_SCENE_PATH := "res://scenes/projectile.tscn"
const ENEMY_PROJECTILE_SCENE_PATH := "res://scenes/enemy/enemy_projectile.tscn"

# 对象池：按场景路径分类存储
var _projectile_pools: Dictionary = {}

# 缓存的场景资源
var _cached_projectile_scene: PackedScene = null
var _cached_enemy_projectile_scene: PackedScene = null

# 最大池大小（防止内存无限增长）
@export var max_pool_size: int = 100

# 预加载的投射物数量
@export var preload_count: int = 20


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_preload_scenes()
	_preload_pools()


## 预加载投射物场景
func _preload_scenes() -> void:
	if ResourceLoader.exists(PROJECTILE_SCENE_PATH):
		_cached_projectile_scene = load(PROJECTILE_SCENE_PATH)
	
	if ResourceLoader.exists(ENEMY_PROJECTILE_SCENE_PATH):
		_cached_enemy_projectile_scene = load(ENEMY_PROJECTILE_SCENE_PATH)


## 预填充对象池
func _preload_pools() -> void:
	# 预填充我方投射物
	if _cached_projectile_scene:
		var pool: Array = []
		for i in range(preload_count):
			var projectile = _cached_projectile_scene.instantiate()
			_deactivate_projectile(projectile)
			pool.append(projectile)
			add_child(projectile)
		_projectile_pools[PROJECTILE_SCENE_PATH] = pool
	
	# 预填充敌方投射物
	if _cached_enemy_projectile_scene:
		var pool: Array = []
		for i in range(preload_count):
			var projectile = _cached_enemy_projectile_scene.instantiate()
			_deactivate_projectile(projectile)
			pool.append(projectile)
			add_child(projectile)
		_projectile_pools[ENEMY_PROJECTILE_SCENE_PATH] = pool


## 停用投射物（准备放入池中）
func _deactivate_projectile(projectile: Node) -> void:
	if not is_instance_valid(projectile):
		return
	
	projectile.visible = false
	projectile.process_mode = Node.PROCESS_MODE_DISABLED
	
	if projectile is CollisionObject2D:
		projectile.set_deferred("monitoring", false)
		projectile.set_deferred("monitorable", false)
	
	# 移动到安全位置
	projectile.global_position = Vector2(-10000, -10000)


## 激活投射物（从池中取出使用）
func _activate_projectile(projectile: Node) -> void:
	if not is_instance_valid(projectile):
		return
	
	projectile.visible = true
	projectile.process_mode = Node.PROCESS_MODE_INHERIT
	
	if projectile is CollisionObject2D:
		projectile.set_deferred("monitoring", true)
		projectile.set_deferred("monitorable", true)


## 检查投射物是否可用于池复用
func _is_projectile_available(projectile: Node) -> bool:
	if not is_instance_valid(projectile):
		return false
	
	# 如果有对象池方法，使用它
	if projectile.has_method("is_available_for_pool"):
		return projectile.is_available_for_pool()
	
	# 默认：不可见即为可用
	return not projectile.visible


## 检查投射物是否处于激活状态
func _is_projectile_active(projectile: Node) -> bool:
	if not is_instance_valid(projectile):
		return false
	
	if projectile.has_method("is_pool_active"):
		return projectile.is_pool_active()
	
	return projectile.visible


## 从对象池获取投射物
func _get_from_pool(scene_path: String) -> Node:
	# 确保池存在
	if not scene_path in _projectile_pools:
		_projectile_pools[scene_path] = []
	
	var pool: Array = _projectile_pools[scene_path]
	
	# 查找可用的投射物
	for projectile in pool:
		if not is_instance_valid(projectile):
			continue
		
		if _is_projectile_available(projectile):
			_deactivate_projectile(projectile)
			return projectile
	
	# 池中没有可用投射物，创建新的
	var scene: PackedScene = null
	if scene_path == PROJECTILE_SCENE_PATH:
		scene = _cached_projectile_scene
	elif scene_path == ENEMY_PROJECTILE_SCENE_PATH:
		scene = _cached_enemy_projectile_scene
	
	if not scene:
		push_warning("[ProjectileSpawner] 无法加载场景: " + scene_path)
		return null
	
	var new_projectile = scene.instantiate()
	_deactivate_projectile(new_projectile)
	add_child(new_projectile)
	pool.append(new_projectile)
	
	# 限制池大小
	if pool.size() > max_pool_size:
		_prune_pool(pool)
	
	return new_projectile


## 清理池中的无效实例
func _prune_pool(pool: Array) -> void:
	var to_remove: Array = []
	
	for projectile in pool:
		if not is_instance_valid(projectile):
			to_remove.append(projectile)
			continue
		
		if not _is_projectile_active(projectile):
			to_remove.append(projectile)
			projectile.queue_free()
			break  # 只清理一个，避免一次性清理太多
	
	for projectile in to_remove:
		pool.erase(projectile)


## 回收投射物到对象池
func return_to_pool(projectile: Node, is_enemy: bool = false) -> void:
	if not projectile or not is_instance_valid(projectile):
		return
	
	var scene_path := ENEMY_PROJECTILE_SCENE_PATH if is_enemy else PROJECTILE_SCENE_PATH
	
	# 延迟调用，避免在物理回调中直接修改 CollisionObject 状态
	call_deferred("_deactivate_projectile", projectile)
	
	# 确保在池中
	if not scene_path in _projectile_pools:
		_projectile_pools[scene_path] = []
	
	var pool: Array = _projectile_pools[scene_path]
	if not projectile in pool:
		pool.append(projectile)


## 生成我方投射物
## @param position: 生成位置
## @param direction: 飞行方向（归一化向量）
## @param speed: 飞行速度
## @param damage: 伤害值
## @param source: 发射者节点（可选）
## @return: 生成的投射物实例
func spawn_projectile(
	position: Vector2,
	direction: Vector2,
	speed: float,
	damage: float,
	source: Node = null
) -> Node:
	var projectile = _get_from_pool(PROJECTILE_SCENE_PATH)
	
	if not projectile:
		push_warning("[ProjectileSpawner] 无法获取我方投射物实例")
		return null
	
	projectile.global_position = position
	
	# 调用 setup 方法初始化
	if projectile.has_method("setup"):
		projectile.setup(direction, speed, damage, source)
	
	_activate_projectile(projectile)
	
	return projectile


## 生成敌方投射物
## @param position: 生成位置
## @param direction: 飞行方向（归一化向量）
## @param speed: 飞行速度
## @param damage: 伤害值
## @param source: 发射者节点（可选）
## @return: 生成的投射物实例
func spawn_enemy_projectile(
	position: Vector2,
	direction: Vector2,
	speed: float,
	damage: float,
	source: Node = null
) -> Node:
	var projectile = _get_from_pool(ENEMY_PROJECTILE_SCENE_PATH)
	
	if not projectile:
		push_warning("[ProjectileSpawner] 无法获取敌方投射物实例")
		return null
	
	projectile.global_position = position
	
	# 调用 setup 方法初始化
	if projectile.has_method("setup"):
		projectile.setup(direction, speed, damage, source)
	
	_activate_projectile(projectile)
	
	return projectile


## 清理所有投射物（场景切换时调用）
func clear_all_projectiles() -> void:
	for pool_name in _projectile_pools:
		var pool: Array = _projectile_pools[pool_name]
		for projectile in pool:
			if is_instance_valid(projectile):
				projectile.queue_free()
		pool.clear()
	
	print("[ProjectileSpawner] 所有投射物已清理")


## 获取池信息（用于调试）
func get_pool_info() -> Dictionary:
	var info = {
		"cached_projectile_scene": _cached_projectile_scene != null,
		"cached_enemy_projectile_scene": _cached_enemy_projectile_scene != null,
		"pools": {}
	}
	
	for pool_name in _projectile_pools:
		var pool: Array = _projectile_pools[pool_name]
		var active_count := 0
		var invalid_count := 0
		
		for p in pool:
			if not is_instance_valid(p):
				invalid_count += 1
				continue
			if _is_projectile_active(p):
				active_count += 1
		
		info["pools"][pool_name] = {
			"total": pool.size(),
			"active": active_count,
			"inactive": pool.size() - active_count - invalid_count,
			"invalid": invalid_count
		}
	
	return info
