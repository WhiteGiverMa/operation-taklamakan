## 现代 HUD 布局 - 职责：
## - 未来实现不同的 UI 排列方式
## - 与 ClassicHeaderLayout 平级，通过 HudRoot 切换
## - 从 HudPresenter 获取数据
##
## 当前状态：空壳骨架，等待实现
extends Control

var _hud_presenter: Node = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false  # 默认隐藏，等待布局切换

func set_hud_presenter(presenter: Node) -> void:
	var presenter_changed := Callable(self, "_on_presenter_changed")
	if _hud_presenter and _hud_presenter.has_signal("presentation_changed") and _hud_presenter.is_connected("presentation_changed", presenter_changed):
		_hud_presenter.disconnect("presentation_changed", presenter_changed)

	_hud_presenter = presenter
	if _hud_presenter and _hud_presenter.has_signal("presentation_changed") and not _hud_presenter.is_connected("presentation_changed", presenter_changed):
		_hud_presenter.connect("presentation_changed", presenter_changed)

func _on_presenter_changed() -> void:
	# 未来：更新 UI 显示
	pass

## 设置可见性
func set_layout_visibility(should_show: bool) -> void:
	visible = should_show
