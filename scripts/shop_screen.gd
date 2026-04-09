extends Control

## Shop screen UI. Displays upgrades and random turret types for purchase.

signal shop_closed

@onready var currency_label: Label = $Panel/VBoxContainer/CurrencyLabel
@onready var item_list: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/ItemList
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton

## 固定升级商品
const UPGRADE_ITEMS: Array[Dictionary] = [
	{
		"type": "upgrade",
		"id": "turret_damage",
		"name_key": "shop.item.turret_damage.name",
		"description_key": "shop.item.turret_damage.desc",
		"price": 35
	},
	{
		"type": "upgrade",
		"id": "fire_control",
		"name_key": "shop.item.fire_control.name",
		"description_key": "shop.item.fire_control.desc",
		"price": 45
	},
	{
		"type": "service",
		"id": "hull_repair",
		"name_key": "shop.item.hull_repair.name",
		"description_key": "shop.item.hull_repair.desc",
		"price": 20
	}
]

## 每次商店显示的炮塔类型数量
const TURRET_OFFER_COUNT: int = 2

const TURRET_SCENE := preload("res://scenes/turret/turret.tscn")
const TURRET_PALETTE := preload("res://resources/turret/turret_palette.tres")

var _purchased_items: Array[String] = []
var _current_turret_offers: Array[Resource] = []
var _current_shop_items: Array[Dictionary] = []

func _ready() -> void:
	_close_requested()
	visible = false
	# 注意：不再直接监听 shop_entered，由 main.gd 统一管理商店显示
	EventBus.currency_changed.connect(_on_currency_changed)
	EventBus.game_started.connect(_on_game_started)
	close_button.pressed.connect(_on_close_pressed)
	_connect_localization()
	_apply_localization()

func _connect_localization() -> void:
	if not Localization.language_changed.is_connected(_on_language_changed):
		Localization.language_changed.connect(_on_language_changed)

func _on_language_changed(_locale: String) -> void:
	_apply_localization()

func _on_shop_entered() -> void:
	_show_shop()

func _on_currency_changed(_new_amount: int, _delta: int) -> void:
	_update_currency_display()

func _on_game_started() -> void:
	_purchased_items.clear()
	_current_turret_offers.clear()
	_current_shop_items.clear()
	_update_all_items()

func _on_close_pressed() -> void:
	_close_shop()

func _show_shop() -> void:
	_update_currency_display()
	_generate_shop_items()
	_build_item_list()
	visible = true
	get_tree().paused = true


func _generate_shop_items() -> void:
	_current_shop_items.clear()
	
	# 添加固定升级商品
	for item in UPGRADE_ITEMS:
		_current_shop_items.append(item.duplicate())
	
	# 从炮塔调色板随机选择炮塔类型
	if TURRET_PALETTE:
		var palette := TURRET_PALETTE as Resource
		if palette and palette.has_method("get_random"):
			_current_turret_offers = palette.call("get_random", TURRET_OFFER_COUNT)
			
			for turret_def in _current_turret_offers:
				_current_shop_items.append({
					"type": "turret",
					"id": "turret_" + String(turret_def.get("id")),
					"definition": turret_def,
					"name": turret_def.get("display_name"),
					"description": turret_def.get("description"),
					"price": turret_def.get("price")
				})

func _close_shop() -> void:
	visible = false
	get_tree().paused = false
	shop_closed.emit()

func _close_requested() -> void:
	visible = false

func _update_currency_display() -> void:
	currency_label.text = Localization.t("shop.currency", "", {"amount": GameState.currency})

func _build_item_list() -> void:
	# Clear existing items
	for child in item_list.get_children():
		child.queue_free()

	# Create item rows
	for item_data in _current_shop_items:
		var row := _create_item_row(item_data)
		item_list.add_child(row)

func _create_item_row(data: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 50

	# Name label
	var name_label := Label.new()
	if data.has("name_key"):
		name_label.text = Localization.t(data["name_key"])
	elif data.has("name"):
		name_label.text = data["name"]
	else:
		name_label.text = data.get("id", "Unknown")
	name_label.custom_minimum_size.x = 120
	row.add_child(name_label)

	# Description / Stats label
	var desc_label := Label.new()
	var desc_text := ""
	if data.has("description_key"):
		desc_text = Localization.t(data["description_key"])
	elif data.has("description"):
		desc_text = data["description"]
	
	# 对于炮塔类型，追加数值信息（应用全局和类型倍率）
	if data.get("type") == "turret" and data.has("definition"):
		var def: Resource = data["definition"]
		var base_dmg_val = def.get("base_damage")
		var rate_val = def.get("base_fire_rate")
		var range_val = def.get("interaction_range")
		var type_id_val = def.get("id")
		
		var base_dmg: float = base_dmg_val if base_dmg_val != null else 0.0
		var rate: float = rate_val if rate_val != null else 0.0
		var range_f: float = range_val if range_val != null else 0.0
		
		# 应用全局倍率和类型专精
		var effective_dmg: float = base_dmg * GameState.turret_damage_multiplier
		if type_id_val != null:
			effective_dmg *= GameState.get_turret_type_multiplier(type_id_val)
		
		var stats_text := " DMG:%.0f Rate:%.1fs Range:%.0f" % [effective_dmg, rate, range_f]
		if desc_text.length() > 0:
			desc_text += "\n" + stats_text
		else:
			desc_text = stats_text
	
	desc_label.text = desc_text
	desc_label.custom_minimum_size.x = 250
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(desc_label)

	# Price label
	var price_label := Label.new()
	price_label.text = "%d" % data["price"]
	price_label.custom_minimum_size.x = 60
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(price_label)

	# Buy button
	var buy_button := Button.new()
	buy_button.text = Localization.t("common.buy")
	buy_button.custom_minimum_size.x = 80
	buy_button.pressed.connect(_on_buy_pressed.bind(data))
	row.add_child(buy_button)

	_update_item_row(row, data, buy_button, price_label)

	return row

func _update_item_row(_row: HBoxContainer, data: Dictionary, buy_button: Button, price_label: Label) -> void:
	var item_id: String = data["id"]
	var item_type: String = data.get("type", "upgrade")
	
	# 只有固定升级类商品才跟踪一次性购买
	var is_purchased: bool = item_type == "upgrade" and item_id in _purchased_items
	var can_afford: bool = GameState.can_afford(data["price"])
	
	# 炮塔类商品需要检查是否有空槽位
	var has_empty_slot: bool = true
	if item_type == "turret":
		has_empty_slot = _has_empty_turret_slot()
	
	var can_buy: bool = not is_purchased and can_afford and has_empty_slot
	buy_button.disabled = not can_buy
	
	if is_purchased:
		buy_button.text = Localization.t("common.owned")
		price_label.add_theme_color_override("font_color", Color.GRAY)
	elif item_type == "turret" and not has_empty_slot:
		buy_button.text = Localization.t("shop.turret.full")
		price_label.add_theme_color_override("font_color", Color.GRAY)
	elif not can_afford:
		buy_button.text = Localization.t("common.buy")
		price_label.add_theme_color_override("font_color", Color.RED)
	else:
		buy_button.text = Localization.t("common.buy")
		price_label.remove_theme_color_override("font_color")

func _apply_localization() -> void:
	close_button.text = Localization.t("common.close")
	_update_currency_display()
	if item_list.get_child_count() > 0:
		_build_item_list()

func _update_all_items() -> void:
	for i in range(item_list.get_child_count()):
		var row := item_list.get_child(i) as HBoxContainer
		if row and i < _current_shop_items.size():
			var price_label := row.get_child(2) as Label
			var buy_button := row.get_child(3) as Button
			if buy_button and price_label:
				_update_item_row(row, _current_shop_items[i], buy_button, price_label)

func _on_buy_pressed(data: Dictionary) -> void:
	var item_id: String = data["id"]
	var item_type: String = data.get("type", "upgrade")
	var price: int = data["price"]

	# 只有固定升级类商品才检查一次性购买
	if item_type == "upgrade" and item_id in _purchased_items:
		return

	if not GameState.can_afford(price):
		return

	# 对于炮塔类商品，先尝试安装，成功后再扣款
	if item_type == "turret":
		var turret_def := _find_turret_definition_by_id(item_id.substr(7))
		if turret_def == null:
			return
		if not _install_new_turret(turret_def):
			return # 安装失败，不扣款
		# 安装成功，扣款并升级类型专精
		GameState.spend_currency(price)
		var type_id: StringName = turret_def.get("id")
		GameState.upgrade_turret_type(type_id)
		EventBus.upgrade_purchased.emit(item_id, price)
		# 重建商品列表以刷新数值显示
		_build_item_list()
		_update_currency_display()
		return

	# 非炮塔商品：扣款、记录、应用效果
	if not GameState.spend_currency(price):
		return

	if item_type == "upgrade":
		_purchased_items.append(item_id)
	_apply_effect(item_id)
	EventBus.upgrade_purchased.emit(item_id, price)
	# 如果是影响炮塔属性的升级，需要重建列表以刷新数值显示
	if item_id == "turret_damage":
		_build_item_list()
		_update_currency_display()
	else:
		_update_all_items()

func _apply_effect(item_id: String) -> void:
	match item_id:
		"turret_damage":
			GameState.turret_damage_multiplier += 0.1
			EventBus.turret_stats_refresh_requested.emit()
		"fire_control":
			GameState.auto_fire_unlocked = true
		"hull_repair":
			_apply_hull_repair()


func _find_turret_definition_by_id(id: String) -> Resource:
	for turret_def in _current_turret_offers:
		if turret_def:
			var def_id: StringName = turret_def.get("id")
			if String(def_id) == id:
				return turret_def
	return null

func _apply_hull_repair() -> void:
	var ship: Node = get_tree().get_first_node_in_group("ship")
	if ship and ship.get("health_component") != null:
		var health_comp: HealthComponent = ship.health_component
		if health_comp:
			var heal_amount: float = ship.max_health * 0.5
			health_comp.heal(heal_amount)

func _install_new_turret(turret_def: Resource = null) -> bool:
	var ship := get_tree().get_first_node_in_group("ship") as Node
	if not ship:
		return false

	var slots := ship.get_turret_slots() as Array[Node2D]
	for slot in slots:
		if not _slot_has_turret(slot):
			var turret := TURRET_SCENE.instantiate() as Turret
			if turret_def:
				turret.definition = turret_def
			slot.add_child(turret)
			EventBus.turret_placed.emit(turret, slots.find(slot))
			return true
	return false # 没有空槽位

func _slot_has_turret(slot: Node2D) -> bool:
	for child in slot.get_children():
		if child is Turret:
			return true
	return false

## 检查舰船上是否还有空炮位
func _has_empty_turret_slot() -> bool:
	var ship := get_tree().get_first_node_in_group("ship") as Node
	if not ship:
		return false
	
	var slots := ship.get_turret_slots() as Array[Node2D]
	for slot in slots:
		if not _slot_has_turret(slot):
			return true
	return false
