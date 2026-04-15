## HUD 容器层 - 职责：
## - 管理 HUD 布局模式（CLASSIC / MODERN）
## - 注入 HudPresenter 到子组件
## - 协调各布局的显隐状态
## - 不直接访问 GameState/WaveManager，通过 Presenter 获取数据
extends Control

enum LayoutMode {
	CLASSIC,
	MODERN,
}

@onready var presenter: Node = $Presenter
@onready var classic_header_layout: Control = $ClassicHeaderLayout
@onready var modern_hud_layout: Control = $ModernHudLayout
@onready var hud: Control = $HUD
@onready var wave_ui: Control = $WaveUI

var _layout_mode: int = LayoutMode.CLASSIC
var _header_requested_visible: bool = true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inject_presenter(classic_header_layout)
	_inject_presenter(modern_hud_layout)
	_inject_presenter(hud)
	_inject_presenter(wave_ui)
	_apply_header_visibility()

func set_layout_mode(mode: Variant) -> void:
	if mode is String:
		match mode.to_upper():
			"CLASSIC":
				_layout_mode = LayoutMode.CLASSIC
			"MODERN":
				_layout_mode = LayoutMode.MODERN
			_:
				push_warning("Unknown layout mode: %s" % mode)
				return
	elif mode is int:
		_layout_mode = mode
	else:
		push_warning("Invalid layout mode type: %s" % typeof(mode))
		return
	_apply_header_visibility()

func set_combat_visibility(should_show: bool) -> void:
	hud.visible = should_show
	if hud.has_method("set_input_hints_enabled"):
		hud.call("set_input_hints_enabled", should_show)

	if wave_ui and wave_ui.has_method("set_combat_visibility"):
		wave_ui.call("set_combat_visibility", should_show)
	elif wave_ui:
		wave_ui.visible = should_show

	_apply_header_visibility()

func set_header_visibility(should_show: bool) -> void:
	_header_requested_visible = should_show
	_apply_header_visibility()

func _inject_presenter(target: Node) -> void:
	if target and target.has_method("set_hud_presenter"):
		target.call("set_hud_presenter", presenter)

func _apply_header_visibility() -> void:
	# Classic 模式：顶部导航栏
	var should_show_classic := _header_requested_visible and _layout_mode == LayoutMode.CLASSIC
	if classic_header_layout and classic_header_layout.has_method("set_header_visibility"):
		classic_header_layout.call("set_header_visibility", should_show_classic)
	elif classic_header_layout:
		classic_header_layout.visible = should_show_classic

	# Modern 模式：使用不同的布局
	var should_show_modern := _header_requested_visible and _layout_mode == LayoutMode.MODERN
	if modern_hud_layout and modern_hud_layout.has_method("set_layout_visibility"):
		modern_hud_layout.call("set_layout_visibility", should_show_modern)
	elif modern_hud_layout:
		modern_hud_layout.visible = should_show_modern
