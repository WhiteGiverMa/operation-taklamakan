extends Control

enum LayoutMode {
	CLASSIC,
	MODERN,
}

@onready var presenter: Node = $Presenter
@onready var classic_header_layout: Control = $ClassicHeaderLayout
@onready var hud: Control = $HUD
@onready var wave_ui: Control = $WaveUI

var _layout_mode: int = LayoutMode.CLASSIC
var _header_requested_visible: bool = true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inject_presenter(classic_header_layout)
	_inject_presenter(hud)
	_inject_presenter(wave_ui)
	_apply_header_visibility()

func set_layout_mode(mode: int) -> void:
	_layout_mode = mode
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
	var should_show := _header_requested_visible and _layout_mode == LayoutMode.CLASSIC
	if classic_header_layout and classic_header_layout.has_method("set_header_visibility"):
		classic_header_layout.call("set_header_visibility", should_show)
	elif classic_header_layout:
		classic_header_layout.visible = should_show
