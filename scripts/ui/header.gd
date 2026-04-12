extends Control

## 杀戮尖塔风格的顶部信息栏
## 显示：血量 | 章节/层/波进度 | 游戏时间 | 设置按钮

# === 配置常量 ===
const BAR_HEIGHT: float = 48.0
const HEALTH_BAR_WIDTH: float = 200.0
const HEALTH_BAR_HEIGHT: float = 20.0
const TIME_LABEL_WIDTH: float = 80.0
const SETTINGS_BUTTON_SIZE: float = 36.0
const HORIZONTAL_PADDING: float = 16.0
const VERTICAL_PADDING: float = 8.0

# === 节点引用 ===
@onready var background: ColorRect = $Background
@onready var health_section: HBoxContainer = $Content/HealthSection
@onready var health_bar: ProgressBar = $Content/HealthSection/HealthBar
@onready var health_label: Label = $Content/HealthSection/HealthLabel
@onready var progress_section: HBoxContainer = $Content/ProgressSection
@onready var progress_label: Label = $Content/ProgressSection/ProgressLabel
@onready var time_section: HBoxContainer = $Content/TimeSection
@onready var time_label: Label = $Content/TimeSection/TimeLabel
@onready var settings_button: Button = $Content/SettingsButton

# === 运行时状态 ===
var _current_health: float = 100.0
var _max_health: float = 100.0
var _current_chapter: int = 1
var _current_floor: int = 1
var _current_wave: int = 0
var _total_waves: int = 0
var _elapsed_time: float = 0.0
var _selected_floor: int = -1  # -1 表示未选中下一个节点

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_connect_localization()
	_initialize_state()
	_apply_localization()

func _process(delta: float) -> void:
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
	
	# 设置按钮
	settings_button.text = "⚙"
	settings_button.tooltip_text = Localization.t("header.settings.tooltip")
	settings_button.pressed.connect(_on_settings_pressed)

func _connect_signals() -> void:
	EventBus.ship_health_changed.connect(_on_ship_health_changed)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.wave_complete.connect(_on_wave_complete)
	EventBus.game_started.connect(_on_game_started)
	EventBus.map_node_preview_selected.connect(_on_node_selected)
	MapManager.current_node_changed.connect(_on_current_node_changed)
	MapManager.chapter_changed.connect(_on_chapter_changed)

func _connect_localization() -> void:
	if not Localization.language_changed.is_connected(_on_language_changed):
		Localization.language_changed.connect(_on_language_changed)

func _on_language_changed(_locale: String) -> void:
	_apply_localization()

func _initialize_state() -> void:
	# 初始化血量
	var ship := _get_ship()
	if ship and "health_component" in ship and ship.health_component:
		_current_health = ship.health_component.current_health
		_max_health = ship.health_component.max_health
	
	# 初始化章节
	_current_chapter = GameState.current_chapter + 1
	
	# 初始化层
	_update_floor_display()
	
	# 初始化波次
	if WaveManager:
		_current_wave = WaveManager.current_wave
		_total_waves = WaveManager.total_waves
	
	# 初始化时间
	_elapsed_time = GameState.elapsed_time
	
	_refresh_all_displays()

func _get_ship() -> Node:
	return get_tree().get_first_node_in_group("ship")

func _apply_localization() -> void:
	settings_button.tooltip_text = Localization.t("header.settings.tooltip")
	_refresh_all_displays()

# === 信号处理 ===

func _on_ship_health_changed(current: float, maximum: float) -> void:
	_current_health = current
	_max_health = maximum
	_update_health_display()

func _on_wave_started(wave_number: int) -> void:
	_current_wave = wave_number
	_total_waves = WaveManager.total_waves if WaveManager else 0
	_update_progress_display()

func _on_wave_complete(_wave_number: int) -> void:
	if WaveManager:
		_current_wave = WaveManager.current_wave
		_total_waves = WaveManager.total_waves
	_update_progress_display()

func _on_game_started() -> void:
	_initialize_state()

func _on_current_node_changed(_node) -> void:
	_update_floor_display()
	_update_progress_display()

func _on_chapter_changed(_new_chapter: int) -> void:
	_current_chapter = GameState.current_chapter + 1
	_update_progress_display()

func _on_node_selected(node_id: String) -> void:
	var node = MapManager.get_map_node(node_id)
	if node:
		_selected_floor = node.row_index + 1
	else:
		_selected_floor = -1
	_update_progress_display()

func _on_settings_pressed() -> void:
	GameState.toggle_pause()

# === 显示更新 ===

func _refresh_all_displays() -> void:
	_update_health_display()
	_update_progress_display()
	_update_time_display()

func _update_health_display() -> void:
	health_bar.max_value = _max_health
	health_bar.value = _current_health
	
	var current_int := int(round(_current_health))
	var max_int := int(round(_max_health))
	health_label.text = "%d/%d" % [current_int, max_int]

func _update_progress_display() -> void:
	# 格式：第X章 · 第Y层 · 波次 Z/W
	var parts: Array[String] = []
	
	# 章节
	parts.append(Localization.t("header.progress.chapter", "", {"chapter": _current_chapter}))
	
	# 层（显示选中或当前）
	var floor_to_show := _current_floor
	if _selected_floor > 0:
		floor_to_show = _selected_floor
		# 选中时变色提示
		progress_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	else:
		progress_label.remove_theme_color_override("font_color")
	
	parts.append(Localization.t("header.progress.floor", "", {"floor": floor_to_show}))
	
	# 波次
	if _total_waves > 0:
		parts.append(Localization.t("header.progress.wave", "", {
			"current": _current_wave,
			"total": _total_waves
		}))
	
	progress_label.text = " · ".join(parts)

func _update_floor_display() -> void:
	var current_node = MapManager.current_node
	if current_node:
		_current_floor = current_node.row_index + 1
	else:
		_current_floor = 1

func _update_time_display() -> void:
	_elapsed_time = GameState.elapsed_time
	var minutes := int(_elapsed_time) / 60
	var seconds := int(_elapsed_time) % 60
	time_label.text = "%02d:%02d" % [minutes, seconds]

# === 公共接口 ===

## 设置可见性
func set_header_visibility(should_show: bool) -> void:
	visible = should_show

## 重置选中状态
func clear_selection() -> void:
	_selected_floor = -1
	_update_progress_display()
