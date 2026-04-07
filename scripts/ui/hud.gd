extends Control

## Simple HUD showing ship HP bar at top-left.

@onready var hp_bar: ProgressBar = $HPBar
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
	input_hints_panel.visible = false
	_apply_localization()
	_refresh_input_hints()

func _process(_delta: float) -> void:
	if not visible or not _input_hints_enabled:
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
