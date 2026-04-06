class_name DamageData
extends RefCounted

## Lightweight damage data container passed between hitboxes and hurtboxes.
## Extends RefCounted for automatic cleanup when no references remain.

signal amount_changed(new_amount: float)

var amount: float = 0.0:
	set(value):
		amount = value
		amount_changed.emit(amount)

var source: Node = null
var damage_type: String = "physical"
var knockback: Vector2 = Vector2.ZERO
var is_critical: bool = false

func _init(dmg: float = 0.0, src: Node = null) -> void:
	amount = dmg
	source = src

func _to_string() -> String:
	return "DamageData(%.1f, %s, critical=%s)" % [amount, damage_type, is_critical]

static func physical(dmg: float, src: Node = null) -> DamageData:
	var data := DamageData.new(dmg, src)
	data.damage_type = "physical"
	return data

static func explosive(dmg: float, src: Node = null) -> DamageData:
	var data := DamageData.new(dmg, src)
	data.damage_type = "explosive"
	return data

static func piercing(dmg: float, src: Node = null) -> DamageData:
	var data := DamageData.new(dmg, src)
	data.damage_type = "piercing"
	return data
