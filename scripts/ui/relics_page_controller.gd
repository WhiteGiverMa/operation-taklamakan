class_name RelicsPageController
extends Control

## 藏品页控制器 - 负责藏品页面的内容渲染

const RELIC_ITEMS: Array[Dictionary] = [
	{
		"id": "gyro_sight",
		"name_key": "shop.relic.gyro_sight.name",
		"description_key": "shop.relic.gyro_sight.desc",
	},
	{
		"id": "salvage_contract",
		"name_key": "shop.relic.salvage_contract.name",
		"description_key": "shop.relic.salvage_contract.desc",
	},
	{
		"id": "field_toolkit",
		"name_key": "shop.relic.field_toolkit.name",
		"description_key": "shop.relic.field_toolkit.desc",
	},
	{
		"id": "overclock_core",
		"name_key": "shop.relic.overclock_core.name",
		"description_key": "shop.relic.overclock_core.desc",
	}
]

var _hud_presenter: Node = null

var relic_summary_label: Label
var relic_list: VBoxContainer

func set_hud_presenter(presenter: Node) -> void:
	_hud_presenter = presenter

func update_page(relic_state: Dictionary) -> void:
	relic_summary_label.text = Localization.t("info.relics.summary", "", relic_state)
	for child in relic_list.get_children():
		child.queue_free()
	for relic_data in RELIC_ITEMS:
		relic_list.add_child(_create_relic_row(relic_data))

func _create_relic_row(data: Dictionary) -> VBoxContainer:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	container.custom_minimum_size.y = 78
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var relic_id := StringName(data["id"])
	var owned := GameState.has_relic(relic_id)
	var title := Label.new()
	title.text = "%s  [%s]" % [
		Localization.t(data["name_key"]),
		Localization.t("info.relics.owned_tag") if owned else Localization.t("info.relics.unowned_tag")
	]
	title.add_theme_font_size_override("font_size", 22)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(title)

	var desc := Label.new()
	desc.text = Localization.t(data["description_key"])
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc.modulate = Color(1, 1, 1, 1) if owned else Color(0.62, 0.62, 0.62, 1)
	container.add_child(desc)

	return container
