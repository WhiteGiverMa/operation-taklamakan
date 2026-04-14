extends Control

## 经典顶部 HUD 布局
## 显示：血量 | 章节/层/波进度 | 游戏时间 | 设置按钮

# === 配置常量 ===
const BAR_HEIGHT: float = 48.0

# === 节点引用 ===
@onready var background: ColorRect = $Background
@onready var ship_health_widget: Control = $Content/ShipHealthWidget
@onready var run_progress_widget: Control = $Content/RunProgressWidget
@onready var timer_widget: Control = $Content/TimerWidget
@onready var settings_entry_widget: Control = $Content/SettingsEntryWidget

# === 运行时状态 ===
var _hud_presenter: Node = null
var _elapsed_time: float = 0.0

func _ready() -> void:
	_setup_ui()
	_connect_localization()
	if ship_health_widget.has_method("sync_from_ship"):
		ship_health_widget.call("sync_from_ship")
	_apply_localization()

func _process(_delta: float) -> void:
	if not visible:
		return
	_update_time_display()

func _setup_ui() -> void:
	# 设置全宽
	anchors_preset = Control.PRESET_TOP_WIDE
	anchor_right = 1.0
	offset_bottom = BAR_HEIGHT
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 设置背景
	background.color = Color(0.08, 0.08, 0.12, 0.9)
	
	if settings_entry_widget.has_signal("pressed") and not settings_entry_widget.is_connected("pressed", Callable(self, "_on_settings_pressed")):
		settings_entry_widget.connect("pressed", _on_settings_pressed)

func _connect_localization() -> void:
	if not Localization.language_changed.is_connected(_on_language_changed):
		Localization.language_changed.connect(_on_language_changed)

func _on_language_changed(_locale: String) -> void:
	_apply_localization()

func set_hud_presenter(presenter: Node) -> void:
	var presenter_changed := Callable(self, "_on_presenter_changed")
	if _hud_presenter and _hud_presenter.has_signal("presentation_changed") and _hud_presenter.is_connected("presentation_changed", presenter_changed):
		_hud_presenter.disconnect("presentation_changed", presenter_changed)

	_hud_presenter = presenter
	if _hud_presenter and _hud_presenter.has_signal("presentation_changed") and not _hud_presenter.is_connected("presentation_changed", presenter_changed):
		_hud_presenter.connect("presentation_changed", presenter_changed)

	_refresh_all_displays()

func _apply_localization() -> void:
	_refresh_all_displays()

# === 信号处理 ===

func _on_presenter_changed() -> void:
	_refresh_all_displays()

func _on_settings_pressed() -> void:
	if _hud_presenter and _hud_presenter.has_method("request_settings"):
		_hud_presenter.call("request_settings", EventBus.SettingsReturnTarget.PAUSE_MENU)
		return
	EventBus.settings_requested.emit(EventBus.SettingsReturnTarget.PAUSE_MENU)

# === 显示更新 ===

func _refresh_all_displays() -> void:
	_update_progress_display()
	_update_time_display()

func _update_progress_display() -> void:
	var header_state := _get_header_state()
	if run_progress_widget.has_method("set_progress_state"):
		run_progress_widget.call(
			"set_progress_state",
			int(header_state.get("chapter", 1)),
			int(header_state.get("floor", 1)),
			int(header_state.get("selected_floor", -1)),
			int(header_state.get("current_wave", 0)),
			int(header_state.get("total_waves", 0))
		)

func _update_time_display() -> void:
	var header_state := _get_header_state()
	_elapsed_time = float(header_state.get("elapsed_time", 0.0))
	if timer_widget.has_method("set_elapsed_time"):
		timer_widget.call("set_elapsed_time", _elapsed_time)

func _get_header_state() -> Dictionary:
	if _hud_presenter and _hud_presenter.has_method("get_header_state"):
		return _hud_presenter.call("get_header_state")

	var current_floor := 1
	var current_node = MapManager.current_node
	if current_node:
		current_floor = current_node.row_index + 1

	return {
		"chapter": MapManager.current_chapter + 1 if MapManager else 1,
		"floor": current_floor,
		"selected_floor": -1,
		"current_wave": WaveManager.current_wave if WaveManager else 0,
		"total_waves": WaveManager.total_waves if WaveManager else 0,
		"elapsed_time": GameState.get_elapsed_time(),
	}

# === 公共接口 ===

## 设置可见性
func set_header_visibility(should_show: bool) -> void:
	visible = should_show

## 重置选中状态
func clear_selection() -> void:
	if _hud_presenter and _hud_presenter.has_method("clear_selected_floor_override"):
		_hud_presenter.call("clear_selected_floor_override")
	_update_progress_display()
