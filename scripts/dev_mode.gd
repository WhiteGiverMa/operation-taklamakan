extends Node

## DevMode autoload. Provides runtime command execution for development/debugging.
## Command registry with parser and Phase 1 command implementations.

var is_enabled: bool:
	get:
		return SettingsManager.dev_mode_enabled

# Debug toggle fields
var show_collision_boxes: bool = false
var show_paths: bool = false
var show_attack_ranges: bool = false

# Command registry: { "cmd_name": { "callable": Callable, "description": "...", "usage": "..." } }
var _commands: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SettingsManager.settings_changed.connect(_on_settings_changed)
	_register_commands()
	var overlay := preload("res://scripts/dev_mode/debug_overlay.gd").new()
	get_tree().root.add_child.call_deferred(overlay)

func _on_settings_changed() -> void:
	# is_enabled getter automatically reads from SettingsManager.dev_mode_enabled
	pass

func execute(input: String) -> String:
	if not is_enabled:
		return "DevMode 未启用。请在设置中开启。"
	
	var trimmed := input.strip_edges()
	if trimmed.is_empty():
		return "请输入命令。输入 'help' 查看可用命令。"
	
	var parts := trimmed.split(" ", false)
	if parts.is_empty():
		return "请输入命令。输入 'help' 查看可用命令。"
	
	var cmd_name := parts[0]
	var args: Array[String] = []
	for i in range(1, parts.size()):
		args.append(parts[i])
	
	var cmd_info = _commands.get(cmd_name)
	if cmd_info == null:
		return "未知命令: '%s'。输入 'help' 查看可用命令。" % cmd_name
	
	var callable: Callable = cmd_info["callable"]
	var result: Variant
	
	# 使用 if/else 进行错误防护（GDScript 无 try/except）
	if callable.get_object() == null or not is_instance_valid(callable.get_object()):
		return "命令 '%s' 的调用对象无效。" % cmd_name
	
	# 将 string 数组传给命令自身处理
	result = callable.call(args)
	
	if result == null:
		return "命令 '%s' 执行完成（无返回值）。" % cmd_name
	
	return str(result)

func register_command(name: String, callable: Callable, description: String, usage: String = "") -> void:
	_commands[name] = {
		"callable": callable,
		"description": description,
		"usage": usage
	}

func _register_commands() -> void:
	# 调试开关命令
	register_command("toggle_collision", _cmd_toggle_collision,
		"切换碰撞箱显示",
		"toggle_collision")
	register_command("toggle_paths", _cmd_toggle_paths,
		"切换路径显示",
		"toggle_paths")
	register_command("toggle_ranges", _cmd_toggle_ranges,
		"切换攻击范围显示",
		"toggle_ranges")
	
	# 资源命令
	register_command("add_gold", _cmd_add_gold,
		"增加金币",
		"add_gold <amount>")
	register_command("set_gold", _cmd_set_gold,
		"设置金币数量",
		"set_gold <amount>")
	register_command("heal", _cmd_heal,
		"恢复陆行舰至满血",
		"heal")
	register_command("skip_wave", _cmd_skip_wave,
		"跳过当前波间期或直接开始下一波",
		"skip_wave")
	register_command("skip_layer", _cmd_skip_layer,
		"跳过当前层数",
		"skip_layer")
	
	# 生成命令
	register_command("spawn_enemy", _cmd_spawn_enemy,
		"在生成点附近生成敌人",
		"spawn_enemy <type> [count]  (type: tank, dog, boss)")
	register_command("clear_enemies", _cmd_clear_enemies,
		"清除场景中所有敌人",
		"clear_enemies")
	register_command("spawn_wave", _cmd_spawn_wave,
		"开始下一波战斗",
		"spawn_wave [wave_num]")
	
	# 帮助命令
	register_command("help", _cmd_help,
		"显示所有可用命令",
		"help")

# ---------------------------------------------------------------------------
# 调试开关命令实现
# ---------------------------------------------------------------------------

func _cmd_toggle_collision(_args: Array[String]) -> String:
	show_collision_boxes = not show_collision_boxes
	EventBus.dev_event.emit("toggle_collision", { "enabled": show_collision_boxes })
	return "碰撞箱显示已 %s。" % ("开启" if show_collision_boxes else "关闭")

func _cmd_toggle_paths(_args: Array[String]) -> String:
	show_paths = not show_paths
	EventBus.dev_event.emit("toggle_paths", { "enabled": show_paths })
	return "路径显示已 %s。" % ("开启" if show_paths else "关闭")

func _cmd_toggle_ranges(_args: Array[String]) -> String:
	show_attack_ranges = not show_attack_ranges
	EventBus.dev_event.emit("toggle_ranges", { "enabled": show_attack_ranges })
	return "攻击范围显示已 %s。" % ("开启" if show_attack_ranges else "关闭")

# ---------------------------------------------------------------------------
# 资源命令实现
# ---------------------------------------------------------------------------

func _cmd_add_gold(args: Array[String]) -> String:
	if args.is_empty():
		return "用法: add_gold <amount>"
	var amount := args[0].to_int()
	if amount <= 0:
		return "错误: amount 必须是正整数。"
	GameState.add_currency(amount)
	return "金币增加 %d，当前金币: %d。" % [amount, GameState.currency]

func _cmd_set_gold(args: Array[String]) -> String:
	if args.is_empty():
		return "用法: set_gold <amount>"
	var amount := args[0].to_int()
	if amount < 0:
		amount = 0
	GameState.currency = amount
	return "金币已设置为 %d。" % GameState.currency

func _cmd_heal(_args: Array[String]) -> String:
	var ship := get_tree().get_first_node_in_group("ship")
	if not is_instance_valid(ship):
		return "错误: 场景中未找到陆行舰（ship 组为空）。"
	if not ship.has_node("HealthComponent"):
		return "错误: 陆行舰没有 HealthComponent 节点。"
	
	var health_comp := ship.get_node("HealthComponent") as HealthComponent
	if health_comp == null:
		return "错误: HealthComponent 类型不匹配。"
	
	var healed_amount := health_comp.max_health - health_comp.current_health
	if healed_amount <= 0.0:
		return "陆行舰已经是满血（%d/%d），无需恢复。" % [int(health_comp.max_health), int(health_comp.max_health)]
	
	health_comp.current_health = health_comp.max_health
	EventBus.ship_health_changed.emit(health_comp.max_health, health_comp.max_health)
	return "陆行舰已恢复 %d 点生命值，当前血量: %d/%d。" % [int(healed_amount), int(health_comp.max_health), int(health_comp.max_health)]

func _cmd_skip_wave(_args: Array[String]) -> String:
	var wm_state := WaveManager.get_state_name()
	if WaveManager.get_state() == WaveManager.State.BETWEEN_WAVES:
		WaveManager.skip_intermission()
		return "波间期已跳过，当前 WaveManager 状态: %s -> 已开始下一波。" % wm_state
	elif WaveManager.get_state() == WaveManager.State.ACTIVE_WAVE:
		# 战斗中无法直接跳过，尝试进入下一波的公共 API 效果有限
		return "当前处于战斗中（%s），无法直接跳过。请等待当前波次结束或击败所有敌人。" % wm_state
	elif WaveManager.get_state() == WaveManager.State.INACTIVE:
		WaveManager.start_combat_session(GameState.current_layer)
		WaveManager.start_next_wave()
		return "战斗会话尚未开始，已自动开启并进入第一波。当前状态: %s。" % WaveManager.get_state_name()
	else:
		return "当前 WaveManager 状态: %s，无法进行跳过操作。" % wm_state

func _cmd_skip_layer(_args: Array[String]) -> String:
	var old_layer := GameState.current_layer
	var old_map_layer := MapManager.current_layer
	# 先尝试推进地图层；只有当前节点为终点时 MapManager 才会真正推进
	MapManager.advance_to_next_layer()
	if MapManager.current_layer == old_map_layer:
		# 地图层未推进（当前节点不是终点，或已是 Boss 终点）
		if MapManager.current_node != null and MapManager.current_node.is_terminal() and MapManager.current_node.type == MapNode.TYPE_BOSS:
			return "已到达 Boss 终点，无法继续推进。"
		return "当前节点不是终点，无法跳过层级。请先完成当前节点。"
	# 地图层推进成功，同步游戏状态
	GameState.advance_layer()
	return "层数已从 %d 推进到 %d。" % [old_layer, GameState.current_layer]

# ---------------------------------------------------------------------------
# 生成命令实现
# ---------------------------------------------------------------------------

func _cmd_spawn_enemy(args: Array[String]) -> String:
	if args.is_empty():
		return "用法: spawn_enemy <type> [count]  (type: tank, dog, boss)"
	
	var enemy_type := args[0].to_lower()
	var count := 1
	if args.size() >= 2:
		count = args[1].to_int()
	if count <= 0:
		count = 1
	
	var scene: PackedScene = null
	match enemy_type:
		"tank":
			scene = WaveManager.tank_scene
		"dog":
			scene = WaveManager.mechanical_dog_scene
		"boss":
			scene = WaveManager.boss_tank_scene
		_:
			return "错误: 未知敌人类型 '%s'。可用类型: tank, dog, boss。" % enemy_type
	
	if scene == null:
		return "错误: %s 场景资源未配置。" % enemy_type
	
	var spawn_points := _find_spawn_points()
	if spawn_points.is_empty():
		return "错误: 场景中未找到有效的 SpawnPoints/Marker2D。"
	
	var spawned := 0
	for i in range(count):
		var marker: Marker2D = spawn_points[randi() % spawn_points.size()]
		var enemy := scene.instantiate() as Node2D
		if enemy == null:
			continue
		enemy.global_position = marker.global_position
		get_tree().root.add_child(enemy)
		enemy.add_to_group("enemies")
		spawned += 1
	
	return "成功生成 %d 个 %s，目标请求 %d 个。" % [spawned, enemy_type, count]

func _cmd_clear_enemies(_args: Array[String]) -> String:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var cleared := 0
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
			cleared += 1
	return "已清除 %d 个敌人。" % cleared

func _cmd_spawn_wave(args: Array[String]) -> String:
	var wave_num := -1
	if args.size() >= 1:
		wave_num = args[0].to_int()
	
	var wm_state := WaveManager.get_state()
	
	if wm_state == WaveManager.State.INACTIVE:
		WaveManager.start_combat_session(GameState.current_layer)
		WaveManager.start_next_wave()
		if wave_num > 0:
			return "战斗会话已启动并开始第一波（指定波次 %d 的直接跳转暂不支持，当前波次: %d）。" % [wave_num, WaveManager.current_wave]
		return "战斗会话已启动，当前波次: %d。" % WaveManager.current_wave
	elif wm_state == WaveManager.State.BETWEEN_WAVES:
		WaveManager.start_next_wave()
		return "已开始下一波，当前波次: %d。" % WaveManager.current_wave
	elif wm_state == WaveManager.State.ACTIVE_WAVE:
		return "当前正处于战斗中（波次 %d），无法重复开始。" % WaveManager.current_wave
	else:
		return "当前 WaveManager 状态: %s，无法开始新波次。" % WaveManager.get_state_name()

# ---------------------------------------------------------------------------
# 辅助方法
# ---------------------------------------------------------------------------

func _cmd_help(_args: Array[String]) -> String:
	var lines: Array[String] = ["=== DevMode 命令列表 ==="]
	var names := _commands.keys()
	names.sort()
	for name in names:
		var info = _commands[name]
		var usage: String = info.get("usage", "")
		var desc: String = info.get("description", "")
		if usage.is_empty():
			lines.append("  %s - %s" % [name, desc])
		else:
			lines.append("  %s - %s" % [usage, desc])
	return "\n".join(lines)

func _find_spawn_points() -> Array[Marker2D]:
	var points: Array[Marker2D] = []
	var spawn_parent := get_tree().root.find_child("SpawnPoints", true, false)
	if not is_instance_valid(spawn_parent):
		var main := get_tree().root.find_child("Main", true, false)
		if is_instance_valid(main):
			spawn_parent = main.find_child("SpawnPoints", false, false)
	
	if is_instance_valid(spawn_parent):
		for child in spawn_parent.get_children():
			if child is Marker2D:
				points.append(child)
	return points
