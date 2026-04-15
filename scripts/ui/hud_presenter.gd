## HUD 数据聚合层 - 职责：
## - 收集和格式化展示数据
## - 提供统一的展示数据接口（get_xxx_state）
## - 监听全局事件并通知 UI 刷新
## - 不包含 UI 渲染逻辑
extends Node

signal presentation_changed

var _selected_floor_override: int = -1

func _ready() -> void:
	EventBus.wave_started.connect(_on_presentation_source_changed)
	EventBus.wave_complete.connect(_on_presentation_source_changed)
	EventBus.wave_all_complete.connect(_on_presentation_source_changed)
	EventBus.game_started.connect(_on_game_started)
	EventBus.ship_health_changed.connect(_on_presentation_source_changed)
	EventBus.currency_changed.connect(_on_presentation_source_changed)
	EventBus.relic_purchased.connect(_on_presentation_source_changed)
	EventBus.upgrade_purchased.connect(_on_presentation_source_changed)
	EventBus.map_node_preview_selected.connect(_on_map_node_preview_selected)
	MapManager.current_node_changed.connect(_on_current_node_changed)
	MapManager.chapter_changed.connect(_on_presentation_source_changed)
	MapManager.map_generated.connect(_on_presentation_source_changed)

	_emit_presentation_changed()

func request_settings(return_target: int) -> void:
	EventBus.settings_requested.emit(return_target)

func clear_selected_floor_override() -> void:
	_selected_floor_override = -1
	_emit_presentation_changed()

func get_header_state() -> Dictionary:
	var current_floor := 1
	var current_node = MapManager.current_node
	if current_node:
		current_floor = current_node.row_index + 1

	return {
		"chapter": MapManager.current_chapter + 1 if MapManager else 1,
		"floor": current_floor,
		"selected_floor": _selected_floor_override,
		"current_wave": WaveManager.current_wave if WaveManager else 0,
		"total_waves": WaveManager.total_waves if WaveManager else 0,
		"elapsed_time": GameState.get_elapsed_time(),
	}

func get_ship_health_state() -> Dictionary:
	var ship = get_tree().get_first_node_in_group("ship")
	if ship and "health_component" in ship and ship.health_component:
		return {
			"current": ship.health_component.current_health,
			"maximum": ship.health_component.max_health,
			"has_ship": true,
		}

	return {
		"current": 0.0,
		"maximum": 100.0,
		"has_ship": false,
	}

func get_wave_overview_state() -> Dictionary:
	var ship_health := get_ship_health_state()
	return {
		"wave_state": WaveManager.get_state() if WaveManager else -1,
		"current_wave": WaveManager.current_wave if WaveManager else 0,
		"total_waves": WaveManager.total_waves if WaveManager else 0,
		"currency": GameState.currency,
		"read_only": is_maintenance_read_only(),
		"maintenance_enabled": can_perform_maintenance(),
		"ship_health": ship_health,
		"next_wave_enemy_counts": _get_next_wave_enemy_counts(),
	}

func get_relics_state(total_relics: int) -> Dictionary:
	return {
		"owned": GameState.owned_relic_ids.size(),
		"total": total_relics,
	}

func get_map_overview_state() -> Dictionary:
	return {
		"graph": MapManager.get_graph(),
		"current_chapter": MapManager.current_chapter,
		"visited_count": MapManager.visited_nodes.size(),
		"current_node": MapManager.current_node,
		"reachable_count": MapManager.get_current_choices().size(),
	}

func get_wave_state() -> int:
	if not WaveManager:
		return -1
	return WaveManager.get_state()

func get_game_state() -> int:
	return GameState.get_state()

func is_maintenance_read_only() -> bool:
	if not WaveManager:
		return true
	return WaveManager.get_state() == WaveManager.State.ACTIVE_WAVE

func can_perform_maintenance() -> bool:
	if not WaveManager:
		return false
	return WaveManager.get_state() == WaveManager.State.BETWEEN_WAVES

func _get_next_wave_enemy_counts() -> Dictionary:
	if not WaveManager or not WaveManager.wave_set or not WaveManager.wave_set.has_method("get_wave"):
		return {}

	var next_wave_data = WaveManager.wave_set.get_wave(WaveManager.current_wave + 1)
	if next_wave_data and next_wave_data.has_method("get_enemy_counts"):
		return next_wave_data.get_enemy_counts()

	return {}

func _on_game_started() -> void:
	_selected_floor_override = -1
	_emit_presentation_changed()

func _on_map_node_preview_selected(node_id: String) -> void:
	if node_id.is_empty():
		_selected_floor_override = -1
	else:
		var node = MapManager.get_map_node(node_id)
		_selected_floor_override = node.row_index + 1 if node else -1
	_emit_presentation_changed()

func _on_current_node_changed(_node) -> void:
	_selected_floor_override = -1
	_emit_presentation_changed()

func _on_presentation_source_changed(_value_a = null, _value_b = null) -> void:
	_emit_presentation_changed()

func _emit_presentation_changed() -> void:
	presentation_changed.emit()
