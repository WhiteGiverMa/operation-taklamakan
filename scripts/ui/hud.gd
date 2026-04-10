extends Control

## Simple HUD showing ship HP bar at top-left.

const ENEMY_ARROW_TEXTURE_PATH := "res://assets/ui/arrows/arrow_IsosRt_red.png"
const ENEMY_INDICATOR_SIZE := Vector2(28.0, 28.0)
const ENEMY_INDICATOR_EDGE_MARGIN: float = 48.0
const ENEMY_INDICATOR_SAFE_MARGIN: float = 32.0
const ENEMY_INDICATOR_COUNT_OFFSET := Vector2(22.0, 14.0)
const ENEMY_INDICATOR_CLOCK_SECTORS: int = 12
const MAX_ENEMY_INDICATORS: int = ENEMY_INDICATOR_CLOCK_SECTORS
const ENEMY_INDICATOR_WEIGHT_DISTANCE: float = 1600.0
const ENEMY_INDICATOR_LOW_THREAT_COLOR := Color(1.0, 0.93, 0.52, 1.0)
const ENEMY_INDICATOR_HIGH_THREAT_COLOR := Color(0.75, 0.12, 0.08, 1.0)
const ENEMY_INDICATOR_THREAT_COUNT_MAX: int = 6

@onready var hp_bar: ProgressBar = $HPBar
@onready var enemy_indicators: Control = $EnemyIndicators
@onready var input_hints_panel: PanelContainer = $InputHintsPanel
@onready var input_hints_title: Label = $InputHintsPanel/MarginContainer/VBoxContainer/TitleLabel
@onready var input_hints_hint: Label = $InputHintsPanel/MarginContainer/VBoxContainer/HintLabel
@onready var input_hints_rows: VBoxContainer = $InputHintsPanel/MarginContainer/VBoxContainer/Rows
@onready var movement_row: HBoxContainer = $InputHintsPanel/MarginContainer/VBoxContainer/Rows/MovementRow
@onready var movement_action_label: Label = $InputHintsPanel/MarginContainer/VBoxContainer/Rows/MovementRow/ActionLabel
@onready var movement_input_label: Label = $InputHintsPanel/MarginContainer/VBoxContainer/Rows/MovementRow/InputLabel
@onready var repair_row: HBoxContainer = $InputHintsPanel/MarginContainer/VBoxContainer/Rows/RepairRow
@onready var repair_action_label: Label = $InputHintsPanel/MarginContainer/VBoxContainer/Rows/RepairRow/ActionLabel
@onready var repair_input_label: Label = $InputHintsPanel/MarginContainer/VBoxContainer/Rows/RepairRow/InputLabel
@onready var interact_row: HBoxContainer = $InputHintsPanel/MarginContainer/VBoxContainer/Rows/InteractRow
@onready var interact_action_label: Label = $InputHintsPanel/MarginContainer/VBoxContainer/Rows/InteractRow/ActionLabel
@onready var interact_input_label: Label = $InputHintsPanel/MarginContainer/VBoxContainer/Rows/InteractRow/InputLabel
@onready var fire_row: HBoxContainer = $InputHintsPanel/MarginContainer/VBoxContainer/Rows/FireRow
@onready var fire_action_label: Label = $InputHintsPanel/MarginContainer/VBoxContainer/Rows/FireRow/ActionLabel
@onready var fire_input_label: Label = $InputHintsPanel/MarginContainer/VBoxContainer/Rows/FireRow/InputLabel
@onready var pause_row: HBoxContainer = $InputHintsPanel/MarginContainer/VBoxContainer/Rows/PauseRow
@onready var pause_action_label: Label = $InputHintsPanel/MarginContainer/VBoxContainer/Rows/PauseRow/ActionLabel
@onready var pause_input_label: Label = $InputHintsPanel/MarginContainer/VBoxContainer/Rows/PauseRow/InputLabel
@onready var toggle_row: HBoxContainer = $InputHintsPanel/MarginContainer/VBoxContainer/Rows/ToggleRow
@onready var toggle_action_label: Label = $InputHintsPanel/MarginContainer/VBoxContainer/Rows/ToggleRow/ActionLabel
@onready var toggle_input_label: Label = $InputHintsPanel/MarginContainer/VBoxContainer/Rows/ToggleRow/InputLabel

var _input_formatter: GUIDEInputFormatter = null
var _input_hints_enabled := false
var _enemy_arrow_texture: Texture2D = null
var _enemy_indicator_pool: Array[Dictionary] = []

const HINT_ACTIONS := [
	{
		"row": NodePath("MovementRow"),
		"action_label": NodePath("MovementRow/ActionLabel"),
		"input_label": NodePath("MovementRow/InputLabel"),
		"key": "hud.input_hints.move",
		"action": "move_action",
	},
	{
		"row": NodePath("RepairRow"),
		"action_label": NodePath("RepairRow/ActionLabel"),
		"input_label": NodePath("RepairRow/InputLabel"),
		"key": "hud.input_hints.repair",
		"action": "repair_action",
	},
	{
		"row": NodePath("InteractRow"),
		"action_label": NodePath("InteractRow/ActionLabel"),
		"input_label": NodePath("InteractRow/InputLabel"),
		"key": "hud.input_hints.interact",
		"action": "interact_action",
	},
	{
		"row": NodePath("FireRow"),
		"action_label": NodePath("FireRow/ActionLabel"),
		"input_label": NodePath("FireRow/InputLabel"),
		"key": "hud.input_hints.fire",
		"action": "fire_action",
	},
	{
		"row": NodePath("PauseRow"),
		"action_label": NodePath("PauseRow/ActionLabel"),
		"input_label": NodePath("PauseRow/InputLabel"),
		"key": "hud.input_hints.pause",
		"action": "pause_toggle_action",
	},
	{
		"row": NodePath("ToggleRow"),
		"action_label": NodePath("ToggleRow/ActionLabel"),
		"input_label": NodePath("ToggleRow/InputLabel"),
		"key": "hud.input_hints.toggle",
		"action": "input_hints_toggle_action",
	},
]

func _ready() -> void:
	EventBus.ship_health_changed.connect(_on_ship_health_changed)
	if not Localization.language_changed.is_connected(_on_language_changed):
		Localization.language_changed.connect(_on_language_changed)
	_load_enemy_arrow_texture()
	input_hints_panel.visible = false
	_apply_localization()
	_refresh_input_hints()

func _process(_delta: float) -> void:
	if not visible:
		_hide_enemy_indicators()
		return

	_update_enemy_indicators()

	if not _input_hints_enabled:
		return

	if InputManager.input_hints_toggle_action.is_triggered():
		input_hints_panel.visible = not input_hints_panel.visible

	if input_hints_panel.visible:
		_refresh_input_hints()

func set_input_hints_enabled(enabled: bool) -> void:
	_input_hints_enabled = enabled
	if not enabled:
		input_hints_panel.visible = false
		return
	_refresh_input_hints()

func _on_ship_health_changed(current: float, maximum: float) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = current

func _on_language_changed(_locale: String) -> void:
	_apply_localization()
	if input_hints_panel.visible:
		_refresh_input_hints()

func _apply_localization() -> void:
	input_hints_title.text = Localization.t("hud.input_hints.title")
	input_hints_hint.text = Localization.t(
		"hud.input_hints.hint",
		"",
		{"key": _get_action_text(InputManager.input_hints_toggle_action)}
	)
	for config in HINT_ACTIONS:
		var action_label := input_hints_rows.get_node(config.action_label) as Label
		action_label.text = Localization.t(config.key)

func _refresh_input_hints() -> void:
	_input_formatter = GUIDEInputFormatter.for_active_contexts()
	for config in HINT_ACTIONS:
		var row := input_hints_rows.get_node(config.row) as HBoxContainer
		var input_label := input_hints_rows.get_node(config.input_label) as Label
		var action: GUIDEAction = InputManager.get(config.action)
		var input_text := _get_action_text(action)
		var has_binding := not input_text.is_empty()
		row.visible = has_binding
		input_label.text = input_text if has_binding else Localization.t("hud.input_hints.unbound")
	input_hints_hint.text = Localization.t(
		"hud.input_hints.hint",
		"",
		{"key": _get_action_text(InputManager.input_hints_toggle_action)}
	)

func _get_action_text(action: GUIDEAction) -> String:
	if _input_formatter == null:
		_input_formatter = GUIDEInputFormatter.for_active_contexts()
	return _input_formatter.action_as_text(action)

func _update_enemy_indicators() -> void:
	if _enemy_arrow_texture == null:
		_hide_enemy_indicators()
		return

	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		_hide_enemy_indicators()
		return

	var safe_rect := Rect2(
		Vector2.ONE * ENEMY_INDICATOR_SAFE_MARGIN,
		viewport_size - Vector2.ONE * ENEMY_INDICATOR_SAFE_MARGIN * 2.0
	)
	var screen_center := viewport_size * 0.5
	var grouped_targets := _collect_enemy_indicator_groups(safe_rect, screen_center)
	var indicator_count := mini(grouped_targets.size(), MAX_ENEMY_INDICATORS)
	_ensure_enemy_indicator_pool(indicator_count)

	for i in range(_enemy_indicator_pool.size()):
		var indicator := _enemy_indicator_pool[i]
		if i >= indicator_count:
			_set_enemy_indicator_visible(indicator, false)
			continue
		_update_enemy_indicator(indicator, grouped_targets[i], viewport_size)

func _collect_enemy_indicator_groups(safe_rect: Rect2, screen_center: Vector2) -> Array[Dictionary]:
	var buckets: Array[Dictionary] = []
	for sector_index in range(ENEMY_INDICATOR_CLOCK_SECTORS):
		buckets.append({
			"sector_index": sector_index,
			"count": 0,
			"weighted_offset_sum": Vector2.ZERO,
			"weight_total": 0.0,
			"nearest_distance_sq": INF,
		})

	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy := enemy_node as Node2D
		if enemy == null or not is_instance_valid(enemy):
			continue

		var screen_position := enemy.get_global_transform_with_canvas().origin
		if safe_rect.has_point(screen_position):
			continue

		var offset := screen_position - screen_center
		if offset.length_squared() <= 0.001:
			continue

		var sector_index := _get_clock_sector_index(offset)
		var bucket := buckets[sector_index]
		var distance := maxf(offset.length(), 1.0)
		var weight := 1.0 + ENEMY_INDICATOR_WEIGHT_DISTANCE / distance
		bucket["count"] = int(bucket["count"]) + 1
		bucket["weighted_offset_sum"] = bucket["weighted_offset_sum"] + offset * weight
		bucket["weight_total"] = float(bucket["weight_total"]) + weight
		bucket["nearest_distance_sq"] = minf(float(bucket["nearest_distance_sq"]), offset.length_squared())
		buckets[sector_index] = bucket

	var grouped_targets: Array[Dictionary] = []
	for bucket in buckets:
		if int(bucket["count"]) <= 0:
			continue

		var weight_total := float(bucket["weight_total"])
		var weighted_offset_sum: Vector2 = bucket["weighted_offset_sum"]
		var weighted_offset := weighted_offset_sum / maxf(weight_total, 0.001)
		grouped_targets.append({
			"sector_index": int(bucket["sector_index"]),
			"count": int(bucket["count"]),
			"screen_position": screen_center + weighted_offset,
			"nearest_distance_sq": float(bucket["nearest_distance_sq"]),
		})

	grouped_targets.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["sector_index"]) < int(b["sector_index"])
	)
	return grouped_targets

func _get_clock_sector_index(direction: Vector2) -> int:
	var clock_angle := wrapf(direction.angle() + PI * 0.5, 0.0, TAU)
	var sector_size := TAU / float(ENEMY_INDICATOR_CLOCK_SECTORS)
	return int(floor((clock_angle + sector_size * 0.5) / sector_size)) % ENEMY_INDICATOR_CLOCK_SECTORS

func _ensure_enemy_indicator_pool(required_count: int) -> void:
	if _enemy_arrow_texture == null:
		return

	while _enemy_indicator_pool.size() < required_count:
		var arrow := TextureRect.new()
		arrow.texture = _enemy_arrow_texture
		arrow.custom_minimum_size = ENEMY_INDICATOR_SIZE
		arrow.size = ENEMY_INDICATOR_SIZE
		arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		arrow.pivot_offset = ENEMY_INDICATOR_SIZE * 0.5
		arrow.z_index = 20
		arrow.visible = false
		enemy_indicators.add_child(arrow)

		var count_label := Label.new()
		count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		count_label.add_theme_color_override("font_color", Color(1.0, 0.98, 0.92, 1.0))
		count_label.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.02, 0.95))
		count_label.add_theme_font_size_override("font_size", 16)
		count_label.add_theme_constant_override("outline_size", 4)
		count_label.z_index = 21
		count_label.visible = false
		enemy_indicators.add_child(count_label)

		_enemy_indicator_pool.append({
			"arrow": arrow,
			"count_label": count_label,
		})

func _update_enemy_indicator(indicator: Dictionary, group: Dictionary, viewport_size: Vector2) -> void:
	var arrow := indicator["arrow"] as TextureRect
	var count_label := indicator["count_label"] as Label
	_place_enemy_indicator(arrow, group["screen_position"], viewport_size)
	if not arrow.visible:
		count_label.visible = false
		return

	var count := int(group["count"])
	var color := _get_enemy_indicator_color(count)
	arrow.modulate = color
	count_label.text = str(count)
	count_label.position = arrow.position + ENEMY_INDICATOR_COUNT_OFFSET
	count_label.modulate = color
	count_label.visible = true

func _get_enemy_indicator_color(count: int) -> Color:
	var threat_ratio := clampf(float(count - 1) / float(max(ENEMY_INDICATOR_THREAT_COUNT_MAX - 1, 1)), 0.0, 1.0)
	return ENEMY_INDICATOR_LOW_THREAT_COLOR.lerp(ENEMY_INDICATOR_HIGH_THREAT_COLOR, threat_ratio)

func _set_enemy_indicator_visible(indicator: Dictionary, visible_state: bool) -> void:
	(indicator["arrow"] as TextureRect).visible = visible_state
	(indicator["count_label"] as Label).visible = visible_state

func _place_enemy_indicator(indicator: TextureRect, enemy_screen_position: Vector2, viewport_size: Vector2) -> void:
	var screen_center := viewport_size * 0.5
	var direction := enemy_screen_position - screen_center
	if direction.length_squared() <= 0.001:
		indicator.visible = false
		return

	var normalized_direction := direction.normalized()
	var half_extents := viewport_size * 0.5 - Vector2.ONE * ENEMY_INDICATOR_EDGE_MARGIN
	var scale_to_edge := INF

	if absf(normalized_direction.x) > 0.001:
		scale_to_edge = minf(scale_to_edge, half_extents.x / absf(normalized_direction.x))
	if absf(normalized_direction.y) > 0.001:
		scale_to_edge = minf(scale_to_edge, half_extents.y / absf(normalized_direction.y))
	if scale_to_edge == INF:
		indicator.visible = false
		return

	indicator.position = screen_center + normalized_direction * scale_to_edge - ENEMY_INDICATOR_SIZE * 0.5
	indicator.rotation = normalized_direction.angle() - PI * 0.5
	indicator.visible = true

func _hide_enemy_indicators() -> void:
	for indicator in _enemy_indicator_pool:
		_set_enemy_indicator_visible(indicator, false)

func _load_enemy_arrow_texture() -> void:
	_enemy_arrow_texture = load(ENEMY_ARROW_TEXTURE_PATH) as Texture2D
	if _enemy_arrow_texture == null:
		push_warning("HUD: 无法读取屏外敌人箭头贴图: %s" % ENEMY_ARROW_TEXTURE_PATH)
