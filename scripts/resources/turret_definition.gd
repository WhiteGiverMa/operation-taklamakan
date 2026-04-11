class_name TurretDefinition
extends Resource

## 炮塔类型定义资源。
## 定义炮塔的基础属性、特性和价格。

## 类型标识符（用于专精倍率查找）
@export var id: StringName = &"standard"

## 显示名称（本地化key或直接文本）
@export var display_name: String = "Standard Turret"

## 描述（本地化key或直接文本）
@export var description: String = "Balanced turret with average damage and fire rate."

## 商店图标（可选）
@export var icon: Texture2D

## === 基础战斗属性 ===

## 基础伤害（会被全局倍率和类型专精放大）
@export var base_damage: float = 15.0

## 射击间隔（秒，越小越快）
@export var base_fire_rate: float = 0.5

## 投射物飞行速度
@export var projectile_speed: float = 600.0

## 玩家交互范围（靠近炮塔可进入手动模式）
@export var interaction_range: float = 150.0

## 自动索敌射程（自动火控发现目标的距离）
@export var auto_target_range: float = 1500.0

## === 韧性参数 ===

## 舰船受伤时波及炮塔的范围
@export var toughness_damage_radius: float = 180.0

## 玩家维修瘫痪炮塔所需时间
@export var repair_duration: float = 2.0

## === 射界参数 ===

## 炮塔射界半弧角度（手动瞄准与自动火控共用）
@export_range(0.0, 180.0, 1.0) var firing_arc_half_angle: float = 120.0

## === 经济参数 ===

## 商店基础价格
@export var price: int = 40

## === 可选特性 ===

## 穿透（投射物可穿透敌人，预留扩展）
@export var can_pierce: bool = false

## 颜色标识（用于视觉区分）
@export var visual_color: Color = Color.WHITE


func get_id_string() -> String:
	return String(id)


func _to_string() -> String:
	return "TurretDefinition(%s: dmg=%.1f, rate=%.2f, price=%d)" % [id, base_damage, base_fire_rate, price]
