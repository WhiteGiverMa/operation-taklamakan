class_name EnemySpawnQueueBuilder
extends RefCounted

## 根据当前波次配置构造敌人生成队列，避免 WaveManager 持续膨胀。

static func build_queue(config: Dictionary, scenes: Dictionary, spawn_point_count: int) -> Array[Dictionary]:
	var queue: Array[Dictionary] = []
	_append_entries(queue, "tank", scenes.get("tank"), config.get("tank_count", 0), spawn_point_count)
	_append_entries(queue, "mechanical_dog", scenes.get("mechanical_dog"), config.get("dog_count", 0), spawn_point_count)
	_append_entries(queue, "boss_tank", scenes.get("boss_tank"), config.get("boss_tank_count", 0), spawn_point_count)
	queue.shuffle()
	return queue


static func _append_entries(queue: Array[Dictionary], enemy_type: String, scene: PackedScene, count: int, spawn_point_count: int) -> void:
	for i in range(count):
		queue.append({
			"type": enemy_type,
			"scene": scene,
			"spawn_point": _pick_spawn_point(spawn_point_count),
		})


static func _pick_spawn_point(spawn_point_count: int) -> int:
	if spawn_point_count <= 0:
		return 0
	return randi() % spawn_point_count
