class_name FloorGraph
extends RefCounted

## Generates and stores a deterministic three-floor route graph.
## Each floor contains a start node, 10-15 intermediate nodes, and a terminal node.

const MapNodeScript := preload("res://scripts/map_node.gd")

const FLOOR_COUNT: int = 3
const MIN_NODES_PER_LAYER: int = 10
const MAX_NODES_PER_LAYER: int = 15
const ROW_COUNT: int = 6
const MIN_INTERMEDIATE_ROWS: int = 3
const MAX_INTERMEDIATE_ROWS: int = 5
const MIN_ROW_WIDTH: int = 1
const MAX_ROW_WIDTH: int = 5
const LAYER_WIDTH: float = 960.0
const LAYER_HEIGHT: float = 720.0
const FLOOR_VERTICAL_GAP: float = 840.0
const ROW_VERTICAL_SPACING: float = 132.0
const COLUMN_HORIZONTAL_SPACING: float = 160.0
const ROW_JITTER_X: float = 28.0
const ROW_JITTER_Y: float = 12.0
const TYPE_ROLLS := [
	{"weight": 50, "type": MapNodeScript.TYPE_COMBAT},
	{"weight": 15, "type": MapNodeScript.TYPE_ELITE},
	{"weight": 10, "type": MapNodeScript.TYPE_SHOP},
	{"weight": 15, "type": MapNodeScript.TYPE_EVENT},
	{"weight": 10, "type": MapNodeScript.TYPE_REST},
]

var seed: int = 0
var layers: Array[Array] = []
var layer_rows: Array[Array] = []
var current_layer: int = 0
var current_node: Variant = null
var visited_nodes: Array[String] = []

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _node_lookup: Dictionary = {}

func generate(map_seed: int) -> void:
	seed = map_seed
	_rng.seed = seed
	layers.clear()
	layer_rows.clear()
	_node_lookup.clear()
	visited_nodes.clear()
	current_layer = 0
	current_node = null

	for layer_index in range(FLOOR_COUNT):
		_generate_layer(layer_index)

	var start_node: Variant = get_start_node(0)
	if start_node != null:
		mark_node_visited(start_node.id)

func _generate_layer(layer_index: int) -> void:
	var target_count := _rng.randi_range(MIN_NODES_PER_LAYER, MAX_NODES_PER_LAYER)
	var row_counts := _build_row_counts(target_count)
	var layer_nodes: Array = []
	var rows: Array[Array] = []
	var floor_y_offset := float(layer_index) * FLOOR_VERTICAL_GAP

	var start_node: Variant = _create_node(
		layer_index,
		0,
		0,
		Vector2(LAYER_WIDTH * 0.5, floor_y_offset),
		MapNodeScript.TYPE_START
	)
	rows.append([start_node])
	layer_nodes.append(start_node)

	for row_index in range(row_counts.size()):
		var row_number := row_index + 1
		var row_width: int = row_counts[row_index]
		var row_nodes: Array = []
		var row_y := floor_y_offset + float(row_number) * ROW_VERTICAL_SPACING
		var total_width := float(max(row_width - 1, 0)) * COLUMN_HORIZONTAL_SPACING
		var row_x_start := (LAYER_WIDTH - total_width) * 0.5
		for column_index in range(row_width):
			var jitter_x := _rng.randf_range(-ROW_JITTER_X, ROW_JITTER_X)
			var jitter_y := _rng.randf_range(-ROW_JITTER_Y, ROW_JITTER_Y)
			var position := Vector2(
				row_x_start + float(column_index) * COLUMN_HORIZONTAL_SPACING + jitter_x,
				row_y + jitter_y
			)
			var node: Variant = _create_node(
				layer_index,
				row_number,
				column_index,
				position,
				_draw_node_type()
			)
			row_nodes.append(node)
			layer_nodes.append(node)
		rows.append(row_nodes)

	var terminal_type := MapNodeScript.TYPE_BOSS if layer_index == FLOOR_COUNT - 1 else MapNodeScript.TYPE_END
	var terminal_row_index := rows.size()
	var terminal_position := Vector2(LAYER_WIDTH * 0.5, floor_y_offset + float(terminal_row_index) * ROW_VERTICAL_SPACING)
	var terminal_node: Variant = _create_node(layer_index, terminal_row_index, 0, terminal_position, terminal_type)
	rows.append([terminal_node])
	layer_nodes.append(terminal_node)

	_connect_rows(rows)
	_ensure_all_nodes_have_path(rows)

	layers.append(layer_nodes)
	layer_rows.append(rows)

func _build_row_counts(target_count: int) -> Array[int]:
	var intermediate_total := target_count - 2
	var row_count := _rng.randi_range(MIN_INTERMEDIATE_ROWS, MAX_INTERMEDIATE_ROWS)
	var counts: Array[int] = []
	for _i in range(row_count):
		counts.append(MIN_ROW_WIDTH)

	var remaining := intermediate_total - row_count
	while remaining > 0:
		var index := _rng.randi_range(0, counts.size() - 1)
		if counts[index] >= MAX_ROW_WIDTH:
			continue
		counts[index] += 1
		remaining -= 1

	return counts

func _connect_rows(rows: Array[Array]) -> void:
	for row_index in range(rows.size() - 1):
		var current_row: Array = rows[row_index]
		var next_row: Array = rows[row_index + 1]

		for source_node in current_row:
			var targets := _pick_forward_targets(source_node, next_row)
			for target_node in targets:
				_connect_nodes(source_node, target_node)

		for target_node in next_row:
			if target_node.incoming_connections.is_empty():
				var source_node: Variant = _pick_source_for_target(current_row, target_node)
				_connect_nodes(source_node, target_node)

func _ensure_all_nodes_have_path(rows: Array[Array]) -> void:
	for row_index in range(1, rows.size()):
		var row: Array = rows[row_index]
		for node in row:
			if node.incoming_connections.is_empty():
				var previous_row: Array = rows[row_index - 1]
				_connect_nodes(_pick_source_for_target(previous_row, node), node)

	for row_index in range(rows.size() - 1):
		var row: Array = rows[row_index]
		for node in row:
			if node.connections.is_empty():
				var next_row: Array = rows[row_index + 1]
				_connect_nodes(node, _pick_target_for_source(node, next_row))

func _pick_forward_targets(source_node, next_row: Array) -> Array:
	var targets: Array = []
	if next_row.is_empty():
		return targets

	var min_index := maxi(0, source_node.column_index - 1)
	var max_index := mini(next_row.size() - 1, source_node.column_index + 1)
	if min_index > max_index:
		min_index = 0
		max_index = next_row.size() - 1

	var first_index := _rng.randi_range(min_index, max_index)
	targets.append(next_row[first_index])

	var can_branch := next_row.size() > 1 and _rng.randf() < 0.45
	if can_branch:
		var second_index := _rng.randi_range(min_index, max_index)
		var attempts := 0
		while second_index == first_index and attempts < 4:
			second_index = _rng.randi_range(min_index, max_index)
			attempts += 1
		if second_index != first_index:
			targets.append(next_row[second_index])

	return targets

func _pick_source_for_target(previous_row: Array, target_node) -> Variant:
	var min_index := maxi(0, target_node.column_index - 1)
	var max_index := mini(previous_row.size() - 1, target_node.column_index + 1)
	if min_index > max_index:
		min_index = 0
		max_index = previous_row.size() - 1
	return previous_row[_rng.randi_range(min_index, max_index)]

func _pick_target_for_source(source_node, next_row: Array) -> Variant:
	var min_index := maxi(0, source_node.column_index - 1)
	var max_index := mini(next_row.size() - 1, source_node.column_index + 1)
	if min_index > max_index:
		min_index = 0
		max_index = next_row.size() - 1
	return next_row[_rng.randi_range(min_index, max_index)]

func _connect_nodes(source_node, target_node) -> void:
	if source_node == null or target_node == null:
		return
	source_node.add_connection(target_node.id)
	target_node.add_incoming_connection(source_node.id)

func _create_node(
	layer_index: int,
	row_index: int,
	column_index: int,
	position: Vector2,
	node_type: int
) -> Variant:
	var node_id: String = "L%s_R%s_C%s" % [layer_index, row_index, column_index]
	var node: Variant = MapNodeScript.new(node_id, layer_index, row_index, column_index, position, node_type)
	_node_lookup[node_id] = node
	return node

func _draw_node_type() -> int:
	var roll := _rng.randi_range(1, 100)
	var cumulative := 0
	for entry in TYPE_ROLLS:
		cumulative += int(entry.weight)
		if roll <= cumulative:
			return entry.type
	return MapNodeScript.TYPE_COMBAT

func get_start_node(layer_index: int) -> Variant:
	var row := get_layer_rows(layer_index)
	if row.is_empty() or row[0].is_empty():
		return null
	return row[0][0]

func get_terminal_node(layer_index: int) -> Variant:
	var rows := get_layer_rows(layer_index)
	if rows.is_empty():
		return null
	var last_row: Array = rows[rows.size() - 1]
	if last_row.is_empty():
		return null
	return last_row[0]

func get_layer_rows(layer_index: int) -> Array[Array]:
	if layer_index < 0 or layer_index >= layer_rows.size():
		return []
	return layer_rows[layer_index]

func get_layer_nodes(layer_index: int) -> Array:
	if layer_index < 0 or layer_index >= layers.size():
		return []
	return layers[layer_index]

func get_node(node_id: String) -> Variant:
	return _node_lookup.get(node_id, null)

func mark_node_visited(node_id: String) -> Variant:
	var node: Variant = get_node(node_id)
	if node == null:
		return null
	if not visited_nodes.has(node_id):
		visited_nodes.append(node_id)
	node.set_visited(true)
	current_node = node
	current_layer = node.layer_index
	return node

func get_reachable_node_ids(layer_index: int = -1) -> Array[String]:
	var result: Array[String] = []
	var queue: Array[String] = []
	var seen: Dictionary = {}

	if layer_index >= 0:
		var start_node: Variant = get_start_node(layer_index)
		if start_node == null:
			return result
		queue.append(start_node.id)
	else:
		for floor_index in range(FLOOR_COUNT):
			var floor_start: Variant = get_start_node(floor_index)
			if floor_start != null:
				queue.append(floor_start.id)

	while not queue.is_empty():
		var node_id: String = queue.pop_front()
		if seen.has(node_id):
			continue
		seen[node_id] = true
		result.append(node_id)
		var node: Variant = get_node(node_id)
		if node == null:
			continue
		for target_id in node.connections:
			if not seen.has(target_id):
				queue.append(target_id)

	return result

func reset_progress() -> void:
	visited_nodes.clear()
	current_layer = 0
	current_node = get_start_node(0)
	for node in _node_lookup.values():
		node.visited = false

func to_dictionary() -> Dictionary:
	var serialized_layers: Array = []
	for layer_index in range(layers.size()):
		var serialized_nodes: Array = []
		for node in layers[layer_index]:
			serialized_nodes.append(node.to_dictionary())
		serialized_layers.append(serialized_nodes)

	return {
		"seed": seed,
		"current_layer": current_layer,
		"current_node": current_node.id if current_node != null else "",
		"visited_nodes": visited_nodes.duplicate(),
		"layers": serialized_layers,
	}

func serialize() -> String:
	return JSON.stringify(to_dictionary())
