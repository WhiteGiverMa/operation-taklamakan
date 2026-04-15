## 战斗 HUD 组合层 - 职责：
## - 组合和管理子 Widget（InputHintsWidget, SpeedIndicatorWidget, EnemyIndicatorLayer）
## - 转发信号和事件到子 Widget
## - 不包含具体的渲染逻辑（委托给 Widget）
extends Control

@onready var input_hints_widget: Control = $InputHintsWidget
@onready var speed_indicator_widget: Control = $SpeedIndicatorWidget
@onready var enemy_indicator_layer: Control = $EnemyIndicatorLayer

var _input_hints_enabled := false

func _ready() -> void:
	input_hints_widget.visible = false
	speed_indicator_widget.visible = false

func _process(_delta: float) -> void:
	if not visible:
		return
	
	# 委托给 EnemyIndicatorLayer
	if enemy_indicator_layer.has_method("update_indicators"):
		enemy_indicator_layer.call("update_indicators")
	
	# 输入提示切换
	if _input_hints_enabled and InputManager.input_hints_toggle_action.is_triggered():
		input_hints_widget.visible = not input_hints_widget.visible
		if input_hints_widget.visible and input_hints_widget.has_method("refresh_hints"):
			input_hints_widget.call("refresh_hints")

func set_input_hints_enabled(enabled: bool) -> void:
	_input_hints_enabled = enabled
	if not enabled:
		input_hints_widget.visible = false
	elif input_hints_widget.has_method("refresh_hints"):
		input_hints_widget.call("refresh_hints")
