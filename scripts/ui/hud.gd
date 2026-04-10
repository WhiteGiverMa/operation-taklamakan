extends Control

## Simple HUD showing ship HP bar at top-left.

const ENEMY_ARROW_TEXTURE_PATH := "res://assets/ui/arrows/arrow_IsosRt_red.png"
const ENEMY_INDICATOR_SIZE := Vector2(28.0, 28.0)
const ENEMY_INDICATOR_EDGE_MARGIN: float = 48.0
const ENEMY_INDICATOR_SAFE_MARGIN: float = 32.0
const MAX_ENEMY_INDICATORS: int = 8

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
var _enemy_indicator_pool: Array[TextureRect] = []

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
	var offscreen_targets: Array[Dictionary] = []

	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy := enemy_node as Node2D
		if enemy == null or not is_instance_valid(enemy):
			continue

		var screen_position := enemy.get_global_transform_with_canvas().origin
		if safe_rect.has_point(screen_position):
			continue

		offscreen_targets.append({
			"screen_position": screen_position,
			"distance_sq": screen_center.distance_squared_to(screen_position),
		})

	offscreen_targets.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["distance_sq"] < b["distance_sq"]
	)

	var indicator_count := mini(offscreen_targets.size(), MAX_ENEMY_INDICATORS)
	_ensure_enemy_indicator_pool(indicator_count)

	for i in range(_enemy_indicator_pool.size()):
		var indicator := _enemy_indicator_pool[i]
		if i >= indicator_count:
			indicator.visible = false
			continue
		_place_enemy_indicator(indicator, offscreen_targets[i]["screen_position"], viewport_size)

func _ensure_enemy_indicator_pool(required_count: int) -> void:
	if _enemy_arrow_texture == null:
		return

	while _enemy_indicator_pool.size() < required_count:
		var indicator := TextureRect.new()
		indicator.texture = _enemy_arrow_texture
		indicator.custom_minimum_size = ENEMY_INDICATOR_SIZE
		indicator.size = ENEMY_INDICATOR_SIZE
		indicator.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		indicator.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
		indicator.pivot_offset = ENEMY_INDICATOR_SIZE * 0.5
		indicator.z_index = 20
		indicator.visible = false
		enemy_indicators.add_child(indicator)
		_enemy_indicator_pool.append(indicator)

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
		indicator.visible = false

func _load_enemy_arrow_texture() -> void:
	var image := Image.load_from_file(ENEMY_ARROW_TEXTURE_PATH)
	if image == null or image.is_empty():
		push_warning("HUD: 无法读取屏外敌人箭头贴图: %s" % ENEMY_ARROW_TEXTURE_PATH)
		return
	_enemy_arrow_texture = ImageTexture.create_from_image(image)
