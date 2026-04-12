extends Control

## Shop screen UI. Displays relics available for purchase.

signal shop_closed

@onready var currency_label: Label = $Panel/VBoxContainer/CurrencyLabel
@onready var item_list: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/ItemList
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton

## 藏品商品池（单局唯一）
const RELIC_ITEMS: Array[Dictionary] = [
	{
		"type": "relic",
		"id": "gyro_sight",
		"name_key": "shop.relic.gyro_sight.name",
		"description_key": "shop.relic.gyro_sight.desc",
		"price": 55
	},
	{
		"type": "relic",
		"id": "salvage_contract",
		"name_key": "shop.relic.salvage_contract.name",
		"description_key": "shop.relic.salvage_contract.desc",
		"price": 45
	},
	{
		"type": "relic",
		"id": "field_toolkit",
		"name_key": "shop.relic.field_toolkit.name",
		"description_key": "shop.relic.field_toolkit.desc",
		"price": 40
	},
	{
		"type": "relic",
		"id": "overclock_core",
		"name_key": "shop.relic.overclock_core.name",
		"description_key": "shop.relic.overclock_core.desc",
		"price": 60
	}
]

## 每次商店显示的藏品数量
const RELIC_OFFER_COUNT: int = 3

var _current_shop_items: Array[Dictionary] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_close_requested()
	visible = false
	# 注意：不再直接监听 shop_entered，由 main.gd 统一管理商店显示
	EventBus.currency_changed.connect(_on_currency_changed)
	EventBus.game_started.connect(_on_game_started)
	close_button.pressed.connect(_on_close_pressed)
	_connect_localization()
	_apply_localization()

func _process(_delta: float) -> void:
	if not visible:
		return

	if InputManager.upgrade_toggle_action.is_triggered() or InputManager.ui_back_action.is_triggered():
		_close_shop()

func _connect_localization() -> void:
	if not Localization.language_changed.is_connected(_on_language_changed):
		Localization.language_changed.connect(_on_language_changed)

func _on_language_changed(_locale: String) -> void:
	_apply_localization()

func _on_shop_entered() -> void:
	_show_shop()

func _on_currency_changed(_new_amount: int, _delta: int) -> void:
	_update_currency_display()
	if visible:
		_update_all_items()

func _on_game_started() -> void:
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
	var available_items: Array[Dictionary] = []
	for item in RELIC_ITEMS:
		var relic_id := StringName(item["id"])
		if not GameState.has_relic(relic_id):
			available_items.append(item)

	available_items.shuffle()
	for i in range(mini(RELIC_OFFER_COUNT, available_items.size())):
		_current_shop_items.append(available_items[i].duplicate())

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
	if _current_shop_items.is_empty():
		var empty_label := Label.new()
		empty_label.text = Localization.t("shop.empty")
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		item_list.add_child(empty_label)
		return

	for item_data in _current_shop_items:
		var row := _create_item_row(item_data)
		item_list.add_child(row)

func _create_item_row(data: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 56
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.add_theme_constant_override("separation", 12)

	# Name label
	var name_label := Label.new()
	if data.has("name_key"):
		name_label.text = Localization.t(data["name_key"])
	elif data.has("name"):
		name_label.text = data["name"]
	else:
		name_label.text = data.get("id", "Unknown")
	name_label.custom_minimum_size.x = 110
	row.add_child(name_label)

	# Description / Stats label
	var desc_label := Label.new()
	var desc_text := ""
	if data.has("description_key"):
		desc_text = Localization.t(data["description_key"])
	elif data.has("description"):
		desc_text = data["description"]
	
	desc_label.text = desc_text
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(desc_label)

	# Price label
	var price_label := Label.new()
	price_label.text = "%d" % data["price"]
	price_label.custom_minimum_size.x = 52
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(price_label)

	# Buy button
	var buy_button := Button.new()
	buy_button.text = Localization.t("common.buy")
	buy_button.custom_minimum_size.x = 96
	buy_button.pressed.connect(_on_buy_pressed.bind(data))
	row.add_child(buy_button)

	_update_item_row(row, data, buy_button, price_label)

	return row

func _update_item_row(_row: HBoxContainer, data: Dictionary, buy_button: Button, price_label: Label) -> void:
	var item_id: String = data["id"]
	var is_purchased: bool = GameState.has_relic(StringName(item_id))
	var can_afford: bool = GameState.can_afford(data["price"])
	var can_buy: bool = not is_purchased and can_afford
	buy_button.disabled = not can_buy
	
	if is_purchased:
		buy_button.text = Localization.t("common.owned")
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
	var price: int = data["price"]

	if GameState.has_relic(StringName(item_id)):
		return

	if not GameState.can_afford(price):
		return

	if not GameState.spend_currency(price):
		return

	if not GameState.acquire_relic(StringName(item_id)):
		GameState.add_currency(price)
		return
	EventBus.relic_purchased.emit(item_id, price)
	_update_currency_display()
	_update_all_items()
