class_name WeaponDefinition
extends Resource

## 通用武器定义资源，供玩家与战斗女仆共用。

@export var id: StringName = &"default"
@export var display_name: String = "Default Weapon"
@export var description: String = ""
@export var damage: float = 8.0
@export var fire_rate: float = 0.2
@export var projectile_speed: float = 600.0
@export var attack_range: float = 900.0
@export var muzzle_flash_color: Color = Color.WHITE


func _to_string() -> String:
	return "WeaponDefinition(%s: dmg=%.1f, rate=%.2f, speed=%.1f)" % [id, damage, fire_rate, projectile_speed]
