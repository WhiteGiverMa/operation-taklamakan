extends Node

## Global game state manager. Handles currency, progress, and game status.
## Use signals to react to state changes rather than polling.

signal currency_changed(new_amount: int, delta: int)
signal chapter_changed(new_chapter: int)
signal game_state_changed(state: int)

enum State { MENU, PLAYING, PAUSED, GAME_OVER }
enum TimeMode { GAME_TIME, REAL_TIME }

@export var currency: int = 50:
	set(value):
		var delta := value - currency
		currency = value
		currency_changed.emit(currency, delta)
		if is_inside_tree():
			EventBus.currency_changed.emit(currency, delta)

@export var current_chapter: int = 0
@export var kills: int = 0
@export var level: int = 1  # Display only - 1-based chapter progression

# Elapsed game time tracking
var elapsed_time: float = 0.0
var real_elapsed_time: float = 0.0
var time_mode: TimeMode = TimeMode.GAME_TIME

# Shop upgrade state
var turret_damage_multiplier: float = 1.0
var auto_fire_unlocked: bool = false
var has_active_run: bool = false
var speed_2x_active: bool = false

# Run relic state
var owned_relic_ids: Array[StringName] = []
var relic_turret_damage_multiplier: float = 1.0
var relic_currency_multiplier: float = 1.0
var relic_repair_multiplier: float = 1.0
var relic_fire_rate_multiplier: float = 1.0

# 炮塔类型专精倍率：{StringName: float}
# 每购买某类型炮塔，该类型伤害+5%
var turret_type_multipliers: Dictionary = {}

var _state: State = State.MENU
var _real_time_run_started_at_msec: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.enemy_died.connect(_on_enemy_died)
	if MapManager and not MapManager.chapter_changed.is_connected(_on_map_chapter_changed):
		MapManager.chapter_changed.connect(_on_map_chapter_changed)
	if SettingsManager:
		set_time_mode(int(SettingsManager.time_mode))

func _process(delta: float) -> void:
	if has_active_run:
		_update_real_elapsed_time()
	if _should_accumulate_game_time():
		elapsed_time += delta
	
	if _state == State.PLAYING and InputManager.pause_toggle_action.is_triggered():
		toggle_pause()
	if _state == State.PLAYING and InputManager.time_scale_toggle_action.is_triggered():
		toggle_speed_2x()

func get_state() -> State:
	return _state

func set_state(new_state: State) -> void:
	_state = new_state
	game_state_changed.emit(_state)
	EventBus.game_paused.emit(_state == State.PAUSED)

func set_time_mode(new_mode: int) -> void:
	if new_mode == TimeMode.REAL_TIME:
		time_mode = TimeMode.REAL_TIME
	else:
		time_mode = TimeMode.GAME_TIME

func get_elapsed_time() -> float:
	if time_mode == TimeMode.REAL_TIME:
		return real_elapsed_time
	return elapsed_time

func get_game_elapsed_time() -> float:
	return elapsed_time

func get_real_elapsed_time() -> float:
	return real_elapsed_time

func start_game() -> void:
	_reset_run_values()
	MapManager.reset_map()
	_sync_chapter_from_map(true)
	WaveManager.end_combat_session()
	_restore_ship_health()
	has_active_run = true
	_real_time_run_started_at_msec = Time.get_ticks_msec()
	real_elapsed_time = 0.0
	get_tree().paused = false
	set_state(State.PLAYING)
	EventBus.game_started.emit()

func toggle_pause() -> void:
	if _state == State.PLAYING:
		# 暂停时重置倍速，避免暂停菜单受 time_scale 影响
		Engine.time_scale = 1.0
		if is_inside_tree():
			EventBus.game_speed_changed.emit(1.0)
		set_state(State.PAUSED)
		get_tree().paused = true
	elif _state == State.PAUSED:
		set_state(State.PLAYING)
		get_tree().paused = false
		# 恢复倍速（如果之前已开启且仍处于战斗中）
		if speed_2x_active and _is_combat_active():
			Engine.time_scale = 2.0
			if is_inside_tree():
				EventBus.game_speed_changed.emit(2.0)

func end_game(won: bool) -> void:
	if _state == State.GAME_OVER:
		return
	_update_real_elapsed_time()
	_reset_speed_2x()
	WaveManager.end_combat_session()
	has_active_run = false
	set_state(State.GAME_OVER)
	get_tree().paused = true
	EventBus.game_over.emit(won)

func reset_game() -> void:
	start_game()

func return_to_menu(preserve_run: bool = true) -> void:
	if has_active_run:
		_update_real_elapsed_time()
	_reset_speed_2x()
	has_active_run = has_active_run and preserve_run
	set_state(State.MENU)
	get_tree().paused = preserve_run and has_active_run

func resume_game() -> void:
	if not has_active_run:
		return
	set_state(State.PLAYING)
	get_tree().paused = false

func _reset_run_values() -> void:
	currency = 50
	turret_damage_multiplier = 1.0
	auto_fire_unlocked = false
	turret_type_multipliers.clear()
	owned_relic_ids.clear()
	relic_turret_damage_multiplier = 1.0
	relic_currency_multiplier = 1.0
	relic_repair_multiplier = 1.0
	relic_fire_rate_multiplier = 1.0
	kills = 0
	current_chapter = 0
	level = 1
	elapsed_time = 0.0
	real_elapsed_time = 0.0
	_real_time_run_started_at_msec = 0
	_reset_speed_2x()

func _restore_ship_health() -> void:
	var ship = get_tree().get_first_node_in_group("ship")
	if ship and ship.has_node("HealthComponent"):
		var health_comp = ship.get_node("HealthComponent") as HealthComponent
		if health_comp:
			health_comp.current_health = health_comp.max_health
			EventBus.ship_health_changed.emit(health_comp.max_health, health_comp.max_health)

func reset_to_menu() -> void:
	return_to_menu(false)

func add_currency(amount: int) -> void:
	currency += amount

func add_enemy_reward(amount: int) -> void:
	if amount <= 0:
		return
	var adjusted_amount := int(round(float(amount) * relic_currency_multiplier))
	adjusted_amount = maxi(adjusted_amount, amount)
	add_currency(adjusted_amount)

func spend_currency(amount: int) -> bool:
	if currency >= amount:
		currency -= amount
		return true
	return false

func can_afford(amount: int) -> bool:
	return currency >= amount

func has_relic(relic_id: StringName) -> bool:
	return relic_id in owned_relic_ids

func acquire_relic(relic_id: StringName) -> bool:
	if has_relic(relic_id):
		return false
	match relic_id:
		&"gyro_sight":
			owned_relic_ids.append(relic_id)
			relic_turret_damage_multiplier *= 1.15
			EventBus.turret_stats_refresh_requested.emit()
		&"salvage_contract":
			owned_relic_ids.append(relic_id)
			relic_currency_multiplier *= 1.25
		&"field_toolkit":
			owned_relic_ids.append(relic_id)
			relic_repair_multiplier *= 1.5
		&"overclock_core":
			owned_relic_ids.append(relic_id)
			relic_fire_rate_multiplier *= 0.85
			EventBus.turret_stats_refresh_requested.emit()
		_:
			return false
	return true

func get_global_turret_damage_multiplier() -> float:
	return turret_damage_multiplier * relic_turret_damage_multiplier

func get_turret_fire_rate_multiplier() -> float:
	return relic_fire_rate_multiplier

func apply_repair_multiplier(base_amount: float) -> float:
	return base_amount * relic_repair_multiplier

## 获取指定炮塔类型的专精倍率
func get_turret_type_multiplier(type_id: StringName) -> float:
	return turret_type_multipliers.get(type_id, 1.0)

## 提升指定炮塔类型的专精倍率
func upgrade_turret_type(type_id: StringName, amount: float = 0.05) -> void:
	var current := get_turret_type_multiplier(type_id)
	turret_type_multipliers[type_id] = current + amount
	# 通知所有炮塔刷新属性
	EventBus.turret_stats_refresh_requested.emit()

func advance_chapter() -> void:
	_sync_chapter_from_map()

func get_display_chapter() -> int:
	return current_chapter + 1

func get_wave_chapter() -> int:
	return get_display_chapter()

func _on_map_chapter_changed(_new_chapter: int) -> void:
	_sync_chapter_from_map()

func _sync_chapter_from_map(force_emit: bool = false) -> void:
	if not MapManager:
		return
	var new_chapter := MapManager.current_chapter
	var changed := current_chapter != new_chapter
	current_chapter = new_chapter
	level = get_display_chapter()
	if changed or force_emit:
		chapter_changed.emit(current_chapter)

func _on_enemy_died(_enemy: Node2D, _position: Vector2, _reward: int) -> void:
	if _state == State.PLAYING:
		kills += 1
		if _reward > 0:
			add_enemy_reward(_reward)

## 切换2倍速。仅在战斗期间（波次进行中或波间期）生效。
func toggle_speed_2x() -> void:
	if _state != State.PLAYING:
		return
	if not _is_combat_active():
		return
	speed_2x_active = not speed_2x_active
	Engine.time_scale = 2.0 if speed_2x_active else 1.0
	if is_inside_tree():
		EventBus.game_speed_changed.emit(Engine.time_scale)

## 当前是否处于有"时间流逝"语义的战斗场景
func _is_combat_active() -> bool:
	var wm_state := WaveManager.get_state()
	return wm_state == WaveManager.State.ACTIVE_WAVE or wm_state == WaveManager.State.BETWEEN_WAVES

func _should_accumulate_game_time() -> bool:
	if _state != State.PLAYING:
		return false
	return _is_combat_active()

func _update_real_elapsed_time() -> void:
	if _real_time_run_started_at_msec <= 0:
		return
	real_elapsed_time = maxf(float(Time.get_ticks_msec() - _real_time_run_started_at_msec) / 1000.0, 0.0)

## 重置倍速状态到1x
func _reset_speed_2x() -> void:
	speed_2x_active = false
	Engine.time_scale = 1.0
	if is_inside_tree():
		EventBus.game_speed_changed.emit(1.0)
