extends Control

@onready var tab_container: TabContainer = $Panel/MarginContainer/VBoxContainer/TabContainer
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/Header/CloseButton

# ResourcesTab
@onready var gold_plus_100: Button = $Panel/MarginContainer/VBoxContainer/TabContainer/ResourcesTab/ResourcesVBox/GoldRow/GoldButtons/GoldPlus100
@onready var gold_plus_1000: Button = $Panel/MarginContainer/VBoxContainer/TabContainer/ResourcesTab/ResourcesVBox/GoldRow/GoldButtons/GoldPlus1000
@onready var gold_plus_10000: Button = $Panel/MarginContainer/VBoxContainer/TabContainer/ResourcesTab/ResourcesVBox/GoldRow/GoldButtons/GoldPlus10000
@onready var gold_custom_input: LineEdit = $Panel/MarginContainer/VBoxContainer/TabContainer/ResourcesTab/ResourcesVBox/GoldRow/GoldCustomInput
@onready var gold_add_button: Button = $Panel/MarginContainer/VBoxContainer/TabContainer/ResourcesTab/ResourcesVBox/GoldRow/GoldAddButton
@onready var heal_button: Button = $Panel/MarginContainer/VBoxContainer/TabContainer/ResourcesTab/ResourcesVBox/HealthRow/HealButton
@onready var skip_wave_button: Button = $Panel/MarginContainer/VBoxContainer/TabContainer/ResourcesTab/ResourcesVBox/SkipRow/SkipWaveButton
@onready var skip_floor_button: Button = $Panel/MarginContainer/VBoxContainer/TabContainer/ResourcesTab/ResourcesVBox/SkipRow/SkipFloorButton

# SpawnTab
@onready var enemy_type_option: OptionButton = $Panel/MarginContainer/VBoxContainer/TabContainer/SpawnTab/SpawnVBox/EnemyTypeRow/EnemyTypeOption
@onready var enemy_count_spin_box: SpinBox = $Panel/MarginContainer/VBoxContainer/TabContainer/SpawnTab/SpawnVBox/CountRow/EnemyCountSpinBox
@onready var spawn_enemy_button: Button = $Panel/MarginContainer/VBoxContainer/TabContainer/SpawnTab/SpawnVBox/SpawnButtonRow/SpawnEnemyButton
@onready var clear_enemies_button: Button = $Panel/MarginContainer/VBoxContainer/TabContainer/SpawnTab/SpawnVBox/SpawnButtonRow/ClearEnemiesButton

# DebugTab
@onready var toggle_collision_check: CheckButton = $Panel/MarginContainer/VBoxContainer/TabContainer/DebugTab/DebugVBox/ToggleCollisionCheck
@onready var toggle_paths_check: CheckButton = $Panel/MarginContainer/VBoxContainer/TabContainer/DebugTab/DebugVBox/TogglePathsCheck
@onready var toggle_ranges_check: CheckButton = $Panel/MarginContainer/VBoxContainer/TabContainer/DebugTab/DebugVBox/ToggleRangesCheck

# ConsoleTab
@onready var console_history: RichTextLabel = $Panel/MarginContainer/VBoxContainer/TabContainer/ConsoleTab/ConsoleVBox/ConsoleHistory
@onready var console_input: LineEdit = $Panel/MarginContainer/VBoxContainer/TabContainer/ConsoleTab/ConsoleVBox/ConsoleInputRow/ConsoleInput
@onready var console_execute_button: Button = $Panel/MarginContainer/VBoxContainer/TabContainer/ConsoleTab/ConsoleVBox/ConsoleInputRow/ConsoleExecuteButton

var _console_history: Array[String] = []
var _console_history_index: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	close_button.pressed.connect(hide_panel)
	visible = false

	# 设置 Tab 标题
	tab_container.set_tab_title(0, "资源")
	tab_container.set_tab_title(1, "生成")
	tab_container.set_tab_title(2, "调试")
	tab_container.set_tab_title(3, "控制台")

	# 初始化 SpawnTab 选项
	enemy_type_option.add_item("tank")
	enemy_type_option.add_item("dog")
	enemy_type_option.add_item("boss")
	enemy_type_option.select(0)

	# 连接 ResourcesTab 信号
	gold_plus_100.pressed.connect(_on_gold_plus_100_pressed)
	gold_plus_1000.pressed.connect(_on_gold_plus_1000_pressed)
	gold_plus_10000.pressed.connect(_on_gold_plus_10000_pressed)
	gold_add_button.pressed.connect(_on_gold_add_pressed)
	gold_custom_input.text_submitted.connect(_on_gold_add_pressed)
	heal_button.pressed.connect(_on_heal_pressed)
	skip_wave_button.pressed.connect(_on_skip_wave_pressed)
	skip_floor_button.pressed.connect(_on_skip_floor_pressed)

	# 连接 SpawnTab 信号
	spawn_enemy_button.pressed.connect(_on_spawn_enemy_pressed)
	clear_enemies_button.pressed.connect(_on_clear_enemies_pressed)

	# 连接 DebugTab 信号
	toggle_collision_check.toggled.connect(_on_toggle_collision)
	toggle_paths_check.toggled.connect(_on_toggle_paths)
	toggle_ranges_check.toggled.connect(_on_toggle_ranges)

	# 连接 ConsoleTab 信号
	console_input.text_submitted.connect(_on_console_input_submitted)
	console_execute_button.pressed.connect(_on_console_execute_pressed)
	console_input.gui_input.connect(_on_console_input_gui_input)

func _process(_delta: float) -> void:
	if visible and InputManager.ui_back_action.is_triggered():
		hide_panel()

func show_panel() -> void:
	visible = true

func hide_panel() -> void:
	visible = false

# ResourcesTab handlers
func _on_gold_plus_100_pressed() -> void:
	_execute_and_log("add_gold 100")

func _on_gold_plus_1000_pressed() -> void:
	_execute_and_log("add_gold 1000")

func _on_gold_plus_10000_pressed() -> void:
	_execute_and_log("add_gold 10000")

func _on_gold_add_pressed(_text: String = "") -> void:
	var amount_text = gold_custom_input.text.strip_edges()
	if amount_text.is_valid_int():
		_execute_and_log("add_gold " + amount_text)
		gold_custom_input.text = ""
	else:
		_execute_and_log("add_gold " + amount_text, "无效的数量")

func _on_heal_pressed() -> void:
	_execute_and_log("heal")

func _on_skip_wave_pressed() -> void:
	_execute_and_log("skip_wave")

func _on_skip_floor_pressed() -> void:
	_execute_and_log("skip_floor")

# SpawnTab handlers
func _on_spawn_enemy_pressed() -> void:
	var enemy_type = enemy_type_option.get_item_text(enemy_type_option.selected)
	var count = int(enemy_count_spin_box.value)
	_execute_and_log("spawn_enemy " + enemy_type + " " + str(count))

func _on_clear_enemies_pressed() -> void:
	_execute_and_log("clear_enemies")

# DebugTab handlers
func _on_toggle_collision(toggled: bool) -> void:
	_execute_and_log("toggle_collision")

func _on_toggle_paths(toggled: bool) -> void:
	_execute_and_log("toggle_paths")

func _on_toggle_ranges(toggled: bool) -> void:
	_execute_and_log("toggle_ranges")

# ConsoleTab handlers
func _on_console_input_submitted(text: String) -> void:
	_execute_command(text)
	console_input.text = ""

func _on_console_execute_pressed() -> void:
	var text = console_input.text.strip_edges()
	if text != "":
		_execute_command(text)
		console_input.text = ""

func _on_console_input_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.is_action("ui_up") and _console_history.size() > 0:
			_console_history_index = clampi(_console_history_index + 1, 0, _console_history.size() - 1)
			console_input.text = _console_history[_console_history.size() - 1 - _console_history_index]
			console_input.caret_column = console_input.text.length()
			get_viewport().set_input_as_handled()
		elif event.is_action("ui_down") and _console_history_index >= 0:
			_console_history_index -= 1
			if _console_history_index >= 0:
				console_input.text = _console_history[_console_history.size() - 1 - _console_history_index]
				console_input.caret_column = console_input.text.length()
			else:
				console_input.text = ""
				console_input.caret_column = 0
			get_viewport().set_input_as_handled()

func _execute_command(command: String) -> void:
	command = command.strip_edges()
	if command == "":
		return
	var result = DevMode.execute(command)
	_console_history.append(command)
	_console_history_index = -1
	_append_to_console(command, result)

func _execute_and_log(command: String, override_result: String = "") -> void:
	var result = override_result if override_result != "" else DevMode.execute(command)
	_append_to_console(command, result)

func _append_to_console(command: String, result: String) -> void:
	console_history.append_text("[color=#aaa]$ [/color][b]" + command + "[/b]\n" + result + "\n")
	# 滚动到底部
	console_history.scroll_to_line(console_history.get_line_count() - 1)
