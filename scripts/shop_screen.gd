extends Control

## Shop screen UI. Displays 4 fixed items for purchase.

signal shop_closed

@onready var currency_label: Label = $Panel/VBoxContainer/CurrencyLabel
@onready var item_list: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/ItemList
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton

const SHOP_ITEMS: Array[Dictionary] = [
	{
		"id": "turret_damage",
		"name": "Turret Damage +10%",
		"description": "Increases all turret damage.",
		"price": 35
	},
	{
		"id": "fire_control",
		"name": "Fire Control System",
		"description": "Unlocks auto-fire for all turrets.",
		"price": 45
	},
	{
		"id": "hull_repair",
		"name": "Hull Repair Kit",
		"description": "Restores 50% of ship HP.",
		"price": 20
	},
	{
		"id": "new_turret",
		"name": "New Turret",
		"description": "Installs turret on empty slot.",
		"price": 40
	}
]

const TURRET_SCENE := preload("res://scenes/turret/turret.tscn")

var _purchased_items: Array[String] = []

func _ready() -> void:
	_close_requested()
	visible = false
	EventBus.shop_entered.connect(_on_shop_entered)
	EventBus.currency_changed.connect(_on_currency_changed)
	EventBus.game_started.connect(_on_game_started)
	close_button.pressed.connect(_on_close_pressed)

func _on_shop_entered() -> void:
	_show_shop()

func _on_currency_changed(_new_amount: int, _delta: int) -> void:
	_update_currency_display()

func _on_game_started() -> void:
	_purchased_items.clear()
	_update_all_items()

func _on_close_pressed() -> void:
	_close_shop()

func _show_shop() -> void:
	_update_currency_display()
	_build_item_list()
	visible = true
	get_tree().paused = true

func _close_shop() -> void:
	visible = false
	get_tree().paused = false
	shop_closed.emit()

func _close_requested() -> void:
	visible = false

func _update_currency_display() -> void:
	currency_label.text = "Currency: %d" % GameState.currency

func _build_item_list() -> void:
	# Clear existing items
	for child in item_list.get_children():
		child.queue_free()

	# Create item rows
	for item_data in SHOP_ITEMS:
		var row := _create_item_row(item_data)
		item_list.add_child(row)

func _create_item_row(data: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 50

	# Name label
	var name_label := Label.new()
	name_label.text = data["name"]
	name_label.custom_minimum_size.x = 180
	row.add_child(name_label)

	# Description label
	var desc_label := Label.new()
	desc_label.text = data["description"]
	desc_label.custom_minimum_size.x = 200
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
	buy_button.text = "Buy"
	buy_button.custom_minimum_size.x = 80
	buy_button.pressed.connect(_on_buy_pressed.bind(data))
	row.add_child(buy_button)

	_update_item_row(row, data, buy_button, price_label)

	return row

func _update_item_row(_row: HBoxContainer, data: Dictionary, buy_button: Button, price_label: Label) -> void:
	var item_id: String = data["id"]
	var is_purchased: bool = item_id in _purchased_items
	var can_afford: bool = GameState.can_afford(data["price"])

	buy_button.disabled = is_purchased or not can_afford
	if is_purchased:
		buy_button.text = "Owned"
		price_label.add_theme_color_override("font_color", Color.GRAY)
	elif not can_afford:
		price_label.add_theme_color_override("font_color", Color.RED)
	else:
		price_label.remove_theme_color_override("font_color")

func _update_all_items() -> void:
	for i in range(item_list.get_child_count()):
		var row := item_list.get_child(i) as HBoxContainer
		if row and i < SHOP_ITEMS.size():
			var price_label := row.get_child(2) as Label
			var buy_button := row.get_child(3) as Button
			if buy_button and price_label:
				_update_item_row(row, SHOP_ITEMS[i], buy_button, price_label)

func _on_buy_pressed(data: Dictionary) -> void:
	var item_id: String = data["id"]
	var price: int = data["price"]

	if item_id in _purchased_items:
		return

	if not GameState.spend_currency(price):
		return

	_purchased_items.append(item_id)
	_apply_effect(item_id)
	EventBus.upgrade_purchased.emit(item_id, price)
	_update_all_items()

func _apply_effect(item_id: String) -> void:
	match item_id:
		"turret_damage":
			GameState.turret_damage_multiplier += 0.1
		"fire_control":
			GameState.auto_fire_unlocked = true
		"hull_repair":
			_apply_hull_repair()
		"new_turret":
			_install_new_turret()

func _apply_hull_repair() -> void:
	var ship: Node = get_tree().get_first_node_in_group("ship")
	if ship and ship.get("health_component") != null:
		var health_comp: HealthComponent = ship.health_component
		if health_comp:
			var heal_amount: float = ship.max_health * 0.5
			health_comp.heal(heal_amount)

func _install_new_turret() -> void:
	var ship := get_tree().get_first_node_in_group("ship") as Node
	if not ship:
		return

	var slots := ship.get_turret_slots() as Array[Node2D]
	for slot in slots:
		if not _slot_has_turret(slot):
			var turret := TURRET_SCENE.instantiate() as Node2D
			slot.add_child(turret)
			EventBus.turret_placed.emit(turret, slots.find(slot))
			break

func _slot_has_turret(slot: Node2D) -> bool:
	for child in slot.get_children():
		if child is Turret:
			return true
	return false
