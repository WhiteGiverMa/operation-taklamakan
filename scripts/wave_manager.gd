extends Node

## Wave manager with state machine for wave progression and enemy spawning.
## Handles INACTIVE, BETWEEN_WAVES, ACTIVE_WAVE, and COMPLETE states.

# Signals
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal all_waves_completed()
signal wave_state_changed(state: State)
signal intermission_started(duration: float)
signal intermission_ended()
signal enemy_spawned(enemy_type: String, spawn_point: int)
signal wave_progress_updated(enemies_remaining: int, total_enemies: int)

# State Machine States
enum State {
	INACTIVE,       # Combat session not started
	BETWEEN_WAVES,  # Intermission between waves
	ACTIVE_WAVE,    # Currently spawning/fighting
	COMPLETE        # All waves completed
}

# Configuration
@export_category("Wave Configuration")
@export var total_waves: int = 5
@export var spawn_interval: float = 2.0
@export var intermission_duration: float = 10.0
@export var use_wave_set: bool = true
@export var chapter_wave_plan: Resource

@export_category("Spawn Area")
@export var offscreen_spawn_margin: float = 260.0
@export var offscreen_spawn_jitter: float = 120.0
@export var minimum_spawn_distance: float = 1180.0
# WaveSet resource - using Resource type to avoid parse order issues
@export var wave_set: Resource

@export_category("Enemy Scenes")
@export var tank_scene: PackedScene
@export var mechanical_dog_scene: PackedScene
@export var boss_tank_scene: PackedScene

# Runtime State
var current_wave: int = 0
var enemies_remaining: int = 0
var enemies_spawned: int = 0
var total_enemies_in_wave: int = 0
var _state: State = State.INACTIVE

# Spawn Management
var _spawn_points: Array[Marker2D] = []
var _spawn_timer: float = 0.0
var _intermission_timer: float = 0.0
var _current_wave_config: Dictionary = {}
# WaveData resource - using Resource type to avoid parse order issues
var _current_wave_data: Resource = null
var _spawn_queue: Array[Dictionary] = []
var _wave_sequence: Array[int] = []
var _session_progress_wave: int = 0
var _current_wave_number: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_find_spawn_points()
	_connect_signals()
	if chapter_wave_plan == null:
		chapter_wave_plan = load("res://resources/waves/chapter_wave_plan.tres")
	
	# Load default wave set if not assigned
	if use_wave_set and not wave_set:
		wave_set = load("res://resources/waves/wave_data.tres")
		if wave_set and wave_set.has_method("get_wave_count"):
			total_waves = wave_set.get_wave_count()

func _process(delta: float) -> void:
	match _state:
		State.ACTIVE_WAVE:
			_process_active_wave(delta)
		State.BETWEEN_WAVES:
			_process_intermission(delta)

func _process_active_wave(delta: float) -> void:
	if _spawn_queue.is_empty():
		return
	
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_next_enemy()
		_spawn_timer = _get_next_spawn_interval()

func _process_intermission(delta: float) -> void:
	if _intermission_timer > 0.0:
		_intermission_timer -= delta
		if _intermission_timer <= 0.0:
			_end_intermission()

# State Management

func get_state() -> State:
	return _state

func get_state_name() -> String:
	match _state:
		State.INACTIVE:
			return "INACTIVE"
		State.BETWEEN_WAVES:
			return "BETWEEN_WAVES"
		State.ACTIVE_WAVE:
			return "ACTIVE_WAVE"
		State.COMPLETE:
			return "COMPLETE"
		_:
			return "UNKNOWN"

func set_state(new_state: State) -> void:
	if _state == new_state:
		return
	
	var old_state = _state
	_state = new_state
	wave_state_changed.emit(new_state)
	
	print("WaveManager: State changed from ", _get_state_name(old_state), " to ", get_state_name())

func _get_state_name(state: State) -> String:
	match state:
		State.INACTIVE:
			return "INACTIVE"
		State.BETWEEN_WAVES:
			return "BETWEEN_WAVES"
		State.ACTIVE_WAVE:
			return "ACTIVE_WAVE"
		State.COMPLETE:
			return "COMPLETE"
		_:
			return "UNKNOWN"

# Combat Session Management

func start_combat_session(chapter: int = 1) -> void:
	_wave_sequence = _get_wave_sequence_for_chapter(chapter)
	total_waves = _wave_sequence.size()
	_session_progress_wave = 0
	_current_wave_number = 0
	print("WaveManager: Starting combat session for chapter ", chapter, " with ", total_waves, " waves")
	_find_spawn_points()
	current_wave = 0
	set_state(State.BETWEEN_WAVES)
	_start_intermission(0.0)

func end_combat_session() -> void:
	print("WaveManager: Ending combat session")
	set_state(State.INACTIVE)
	_spawn_queue.clear()
	_wave_sequence.clear()
	_session_progress_wave = 0
	_current_wave_number = 0

# Wave Management

func start_next_wave() -> void:
	if _session_progress_wave >= total_waves:
		_complete_all_waves()
		return
	
	_session_progress_wave += 1
	current_wave = _session_progress_wave
	_current_wave_number = _wave_sequence[_session_progress_wave - 1] if not _wave_sequence.is_empty() else _session_progress_wave
	print("WaveManager: Starting wave ", _current_wave_number)
	
	# Load wave data from WaveSet or generate
	if use_wave_set and wave_set and wave_set.has_method("get_wave"):
		_current_wave_data = wave_set.get_wave(_current_wave_number)
	if not _current_wave_data:
		_generate_wave_config(_current_wave_number)
	else:
		# Copy WaveData to _current_wave_config
		if _current_wave_data.has_method("get_enemy_counts"):
			var enemy_counts = _current_wave_data.get_enemy_counts()
			var spawn_intvl = spawn_interval
			if _current_wave_data.has_method("get"):
				var si = _current_wave_data.get("spawn_interval")
				if si != null:
					spawn_intvl = si
			_current_wave_config = {
				"tank_count": enemy_counts.get("tank", 0),
				"dog_count": enemy_counts.get("mechanical_dog", 0),
				"boss_tank_count": enemy_counts.get("boss_tank", 0),
				"spawn_interval": spawn_intvl
			}
			if _current_wave_data.has_method("get_total_enemies"):
				total_enemies_in_wave = _current_wave_data.get_total_enemies()
		else:
			_generate_wave_config(current_wave)
	
	enemies_spawned = 0
	enemies_remaining = total_enemies_in_wave
	wave_progress_updated.emit(enemies_remaining, total_enemies_in_wave)
	
	set_state(State.ACTIVE_WAVE)
	wave_started.emit(_current_wave_number)
	EventBus.wave_started.emit(_current_wave_number)
	
	# Start spawning
	var prep_time = 0.5
	if _current_wave_data:
		var pt = _current_wave_data.get("preparation_time")
		if pt != null:
			prep_time = pt
	_spawn_timer = prep_time
	_populate_spawn_queue()

func _complete_wave() -> void:
	print("WaveManager: Wave ", _current_wave_number, " completed")
	set_state(State.BETWEEN_WAVES)
	wave_completed.emit(_current_wave_number)
	EventBus.wave_complete.emit(_current_wave_number)
	
	if _session_progress_wave >= total_waves:
		_complete_all_waves()
	else:
		_start_intermission(0.0)

func _complete_all_waves() -> void:
	print("WaveManager: All waves completed!")
	set_state(State.COMPLETE)
	all_waves_completed.emit()
	EventBus.wave_all_complete.emit()
	
	# Check for victory condition: Chapter 3 (index 2) boss defeated
	# MapManager uses 0-based chapters: 0=chapter1, 1=chapter2, 2=chapter3
	if MapManager.current_chapter >= 2:
		await get_tree().create_timer(1.0).timeout
		GameState.end_game(true)

# Intermission Management

func _start_intermission(duration: float) -> void:
	_intermission_timer = maxf(duration, 0.0)
	intermission_started.emit(duration)
	print("WaveManager: Intermission started (manual continue)")

func _end_intermission() -> void:
	intermission_ended.emit()
	print("WaveManager: Intermission ended")

func skip_intermission() -> void:
	if _state == State.BETWEEN_WAVES:
		_intermission_timer = 0.0
		start_next_wave()

func continue_to_next_wave() -> void:
	if _state == State.BETWEEN_WAVES:
		start_next_wave()

# Enemy Spawning

func _find_spawn_points() -> void:
	_spawn_points.clear()
	
	# Try to find SpawnPoints node in current scene
	var spawn_parent = get_tree().root.find_child("SpawnPoints", true, false)
	if not spawn_parent:
		# Try alternative paths
		var main = get_tree().root.find_child("Main", true, false)
		if main:
			spawn_parent = main.find_child("SpawnPoints", false, false)
	
	if spawn_parent:
		for child in spawn_parent.get_children():
			if child is Marker2D:
				_spawn_points.append(child)
		print("WaveManager: Found ", _spawn_points.size(), " spawn points")
	else:
		push_warning("WaveManager: No SpawnPoints node found in scene")

func _generate_wave_config(wave_num: int) -> void:
	# Generate wave configuration based on wave number
	# Wave 1: Only tanks, low count
	# Wave 2: Mix of tanks and dogs
	# Wave 3+: More enemies, more dogs
	
	var tank_count := 0
	var dog_count := 0
	
	match wave_num:
		1:
			tank_count = 3
			dog_count = 0
		2:
			tank_count = 4
			dog_count = 2
		3:
			tank_count = 5
			dog_count = 4
		4:
			tank_count = 6
			dog_count = 6
		5:
			tank_count = 8
			dog_count = 8
		_:
			tank_count = 5 + wave_num
			dog_count = 3 + wave_num * 2
	
	_current_wave_config = {
		"tank_count": tank_count,
		"dog_count": dog_count,
		"spawn_interval": max(0.5, spawn_interval - (wave_num * 0.2))
	}
	
	total_enemies_in_wave = tank_count + dog_count
	print("WaveManager: Wave ", wave_num, " config - Tanks: ", tank_count, ", Dogs: ", dog_count)

func _populate_spawn_queue() -> void:
	_spawn_queue.clear()
	
	var tank_count: int = _current_wave_config.get("tank_count", 0)
	var dog_count: int = _current_wave_config.get("dog_count", 0)
	var boss_tank_count: int = _current_wave_config.get("boss_tank_count", 0)
	
	# Add tanks to queue
	for i in range(tank_count):
		_spawn_queue.append({
			"type": "tank",
			"scene": tank_scene,
			"spawn_point": randi() % _spawn_points.size() if not _spawn_points.is_empty() else 0
		})
	
	# Add dogs to queue
	for i in range(dog_count):
		_spawn_queue.append({
			"type": "mechanical_dog",
			"scene": mechanical_dog_scene,
			"spawn_point": randi() % _spawn_points.size() if not _spawn_points.is_empty() else 0
		})

	for i in range(boss_tank_count):
		_spawn_queue.append({
			"type": "boss_tank",
			"scene": boss_tank_scene,
			"spawn_point": randi() % _spawn_points.size() if not _spawn_points.is_empty() else 0
		})
	
	# Shuffle spawn queue for variety
	_spawn_queue.shuffle()

func _get_wave_sequence_for_chapter(chapter: int) -> Array[int]:
	if chapter_wave_plan != null and chapter_wave_plan.has_method("get_sequence"):
		return chapter_wave_plan.get_sequence(chapter)

	match chapter:
		1:
			return [1, 2]
		2:
			return [3, 4]
		3:
			return [5]
		_:
			return [5]

func _get_next_spawn_interval() -> float:
	var base_interval: float = _current_wave_config.get("spawn_interval", spawn_interval)
	# Add some randomness
	return base_interval + randf_range(-0.2, 0.5)

func _spawn_next_enemy() -> void:
	if _spawn_queue.is_empty() or _spawn_points.is_empty():
		return
	
	var spawn_data = _spawn_queue.pop_front()
	var scene: PackedScene = spawn_data["scene"]
	var spawn_point_idx: int = spawn_data["spawn_point"]
	var enemy_type: String = spawn_data["type"]
	
	if not scene:
		push_warning("WaveManager: Cannot spawn enemy - scene is null")
		return
	
	# Clamp spawn point index
	spawn_point_idx = clamp(spawn_point_idx, 0, _spawn_points.size() - 1)
	var spawn_position: Vector2 = _get_spawn_position(_spawn_points[spawn_point_idx])
	
	# Instantiate enemy
	var enemy = scene.instantiate() as Node2D
	enemy.global_position = spawn_position
	
	# Add to scene
	get_tree().root.add_child(enemy)
	
	enemies_spawned += 1
	enemy_spawned.emit(enemy_type, spawn_point_idx)
	EventBus.enemy_spawned.emit(enemy)
	
	print("WaveManager: Spawned ", enemy_type, " at spawn point ", spawn_point_idx)

func _get_spawn_position(spawn_marker: Marker2D) -> Vector2:
	var anchor := _get_spawn_anchor()
	var lane_direction := spawn_marker.global_position - anchor
	if lane_direction.length_squared() <= 0.001:
		lane_direction = Vector2.RIGHT.rotated(randf() * TAU)

	var direction := lane_direction.normalized()
	var distance_to_screen_edge := _get_distance_to_screen_edge(anchor, direction)
	var desired_distance := maxf(
		distance_to_screen_edge + offscreen_spawn_margin + randf_range(0.0, offscreen_spawn_jitter),
		minimum_spawn_distance
	)
	return anchor + direction * desired_distance

func _get_spawn_anchor() -> Vector2:
	var ship := get_tree().get_first_node_in_group("ship") as Node2D
	if ship != null:
		return ship.global_position
	return get_viewport().get_visible_rect().size * 0.5

func _get_distance_to_screen_edge(anchor: Vector2, direction: Vector2) -> float:
	var camera := get_viewport().get_camera_2d()
	var half_extents := _get_camera_world_half_extents(camera)
	var safe_direction := direction.normalized()
	var scale_to_edge := INF

	if absf(safe_direction.x) > 0.001:
		scale_to_edge = minf(scale_to_edge, half_extents.x / absf(safe_direction.x))
	if absf(safe_direction.y) > 0.001:
		scale_to_edge = minf(scale_to_edge, half_extents.y / absf(safe_direction.y))
	if scale_to_edge == INF:
		return minimum_spawn_distance

	var screen_center := camera.get_screen_center_position() if camera != null else get_viewport().get_visible_rect().position + half_extents
	var anchor_offset := anchor - screen_center
	return maxf(scale_to_edge - anchor_offset.dot(safe_direction), 0.0)

func _get_camera_world_half_extents(camera: Camera2D) -> Vector2:
	if camera != null and camera.has_method("get_world_half_extents"):
		return camera.call("get_world_half_extents")
	return get_viewport().get_visible_rect().size * 0.5

# Signal Handlers

func _connect_signals() -> void:
	# Connect to EventBus enemy died signal
	if not EventBus.enemy_died.is_connected(_on_enemy_died):
		EventBus.enemy_died.connect(_on_enemy_died)

func _on_enemy_died(_enemy: Node2D, _position: Vector2, _reward: int) -> void:
	if _state != State.ACTIVE_WAVE:
		return
	
	enemies_remaining = maxi(enemies_remaining - 1, 0)
	wave_progress_updated.emit(enemies_remaining, total_enemies_in_wave)
	
	print("WaveManager: Enemy died, ", enemies_remaining, "/", total_enemies_in_wave, " remaining")
	
	# Check if wave is complete
	if enemies_remaining <= 0 and _spawn_queue.is_empty():
		_complete_wave()

# Public API for UI

func get_wave_progress() -> float:
	if total_enemies_in_wave <= 0:
		return 0.0
	return float(enemies_spawned) / float(total_enemies_in_wave)

func get_enemies_remaining_ratio() -> float:
	if total_enemies_in_wave <= 0:
		return 0.0
	return float(enemies_remaining) / float(total_enemies_in_wave)

func get_intermission_time_remaining() -> float:
	return maxf(0.0, _intermission_timer)

func is_in_intermission() -> bool:
	return _state == State.BETWEEN_WAVES

func is_wave_active() -> bool:
	return _state == State.ACTIVE_WAVE

func get_current_wave_enemy_count() -> Dictionary:
	return _current_wave_config.duplicate()

func get_current_wave_data():
	return _current_wave_data
