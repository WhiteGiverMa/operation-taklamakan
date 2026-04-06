class_name ShopItem
extends Resource

## Represents a purchasable item in the shop.

signal purchased

@export var id: StringName
@export var name: String
@export var description: String
@export var price: int
@export var icon: Texture2D

func _init(p_id: StringName = &"", p_name: String = "", p_desc: String = "", p_price: int = 0) -> void:
	id = p_id
	name = p_name
	description = p_desc
	price = p_price
