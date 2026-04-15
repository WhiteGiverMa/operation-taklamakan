class_name InputHintsWidget
extends Control

## 输入提示面板 Widget.
## 独立实例化，支持显示/隐藏控制和本地化刷新.

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
	{
		"row": NodePath("SpeedToggleRow"),
		"action_label": NodePath("SpeedToggleRow/ActionLabel"),
		"input_label": NodePath("SpeedToggleRow/InputLabel"),
		"key": "hud.input_hints.speed_toggle",
		"action": "time_scale_toggle_action",
	},
]

@onready var panel: PanelContainer = $PanelContainer
@onready var title_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var hint_label: Label = $PanelContainer/MarginContainer/VBoxContainer/HintLabel
@onready var rows: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/Rows

var _input_formatter: GUIDEInputFormatter = null

func _ready() -> void:
	if not Localization.language_changed.is_connected(_on_language_changed):
		Localization.language_changed.connect(_on_language_changed)
	_apply_localization()

func set_hints_visible(visible: bool) -> void:
	panel.visible = visible

func refresh_hints() -> void:
	_refresh_input_hints()

func _apply_localization() -> void:
	title_label.text = Localization.t("hud.input_hints.title")
	hint_label.text = Localization.t(
		"hud.input_hints.hint",
		"",
		{"key": _get_action_text(InputManager.input_hints_toggle_action)}
	)
	for config in HINT_ACTIONS:
		var action_label: Label = rows.get_node(config.action_label)
		action_label.text = Localization.t(config.key)

func _refresh_input_hints() -> void:
	_input_formatter = GUIDEInputFormatter.for_active_contexts()
	for config in HINT_ACTIONS:
		var row: HBoxContainer = rows.get_node(config.row)
		var input_label: Label = rows.get_node(config.input_label)
		var action: GUIDEAction = InputManager.get(config.action)
		var input_text := _get_action_text(action)
		var has_binding := not input_text.is_empty()
		row.visible = has_binding
		input_label.text = input_text if has_binding else Localization.t("hud.input_hints.unbound")
	hint_label.text = Localization.t(
		"hud.input_hints.hint",
		"",
		{"key": _get_action_text(InputManager.input_hints_toggle_action)}
	)

func _get_action_text(action: GUIDEAction) -> String:
	if _input_formatter == null:
		_input_formatter = GUIDEInputFormatter.for_active_contexts()
	return _input_formatter.action_as_text(action)

func _on_language_changed(_locale: String) -> void:
	_apply_localization()
	_refresh_input_hints()
