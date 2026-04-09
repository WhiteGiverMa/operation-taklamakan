class_name TurretPalette
extends Resource

## 可用炮塔类型集合。
## 商店从中随机选择炮塔类型出售。

## 所有可用的炮塔定义
@export var turrets: Array[Resource] = []


func get_all() -> Array[Resource]:
	return turrets


func get_by_id(id: StringName) -> Resource:
	for def in turrets:
		if def and def.get("id") == id:
			return def
	return null


func get_random(count: int = 1, exclude: Array[StringName] = []) -> Array[Resource]:
	var available: Array[Resource] = []
	for def in turrets:
		if def:
			var def_id: StringName = def.get("id")
			if def_id not in exclude:
				available.append(def)
	
	available.shuffle()
	var result: Array[Resource] = []
	for i in range(mini(count, available.size())):
		result.append(available[i])
	return result


func get_count() -> int:
	return turrets.size()
