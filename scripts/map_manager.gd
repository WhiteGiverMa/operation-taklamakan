extends Node

## Global map state manager. Owns the current generated graph and player traversal state.

const FloorGraphScript := preload("res://scripts/floor_graph.gd")
const MapNodeScript := preload("res://scripts/map_node.gd")

signal map_generated(seed: int, graph)
signal current_node_changed(node)
signal node_visited(node)
signal layer_changed(new_layer: int)
signal map_reset()

enum EncounterType {
	COMBAT,
	ELITE,
	SHOP,
	EVENT,
	REST,
}

@export var default_seed: int = 12345

var graph = null
var current_layer: int = 0
var current_node = null
var visited_nodes: Array[String] = []
var last_seed: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	generate_map(default_seed)

func generate_map(seed_value: int = -1):
	last_seed = seed_value if seed_value >= 0 else _generate_runtime_seed()
	graph = FloorGraphScript.new()
	graph.generate(last_seed)
	_sync_state_from_graph()
	map_generated.emit(last_seed, graph)
	return graph

func visit_node(node_id: String):
	var node: Variant = graph.call("mark_node_visited", node_id)
	if node == null:
		return null

	_sync_state_from_graph()
	current_node_changed.emit(node)
	node_visited.emit(node)

	match node.type:
		MapNodeScript.TYPE_SHOP:
			EventBus.shop_entered.emit()
		MapNodeScript.TYPE_END, MapNodeScript.TYPE_BOSS:
			EventBus.layer_completed.emit(node.layer_index + 1)
		_:
			EventBus.node_entered.emit(node.get_type_name())

	return node

func advance_to_next_layer():
	if current_node == null or not current_node.is_terminal():
		return current_node

	var next_layer := mini(current_node.layer_index + 1, 2)
	current_layer = next_layer
	layer_changed.emit(current_layer)

	if current_node.type == MapNodeScript.TYPE_BOSS:
		return current_node

	var next_start: Variant = graph.call("get_start_node", next_layer)
	if next_start != null:
		return visit_node(next_start.id)
	return null

func go_to_layer_start(layer_index: int):
	if graph == null:
		return null

	var clamped_layer := clampi(layer_index, 0, 2)
	current_layer = clamped_layer
	layer_changed.emit(current_layer)

	var start_node: Variant = graph.call("get_start_node", clamped_layer)
	if start_node != null:
		return visit_node(start_node.id)
	return null

func reset_map(seed_value: int = -1) -> void:
	generate_map(seed_value)
	map_reset.emit()

func get_graph():
	return graph

func get_map_node(node_id: String):
	return graph.call("get_node", node_id)

func get_current_choices() -> Array:
	var choices: Array = []
	if current_node == null:
		return choices
	for target_id in current_node.connections:
		var node: Variant = graph.call("get_node", target_id)
		if node != null:
			choices.append(node)
	return choices

func _sync_state_from_graph() -> void:
	current_layer = int(graph.get("current_layer"))
	current_node = graph.get("current_node")
	visited_nodes = (graph.get("visited_nodes") as Array[String]).duplicate()

func _generate_runtime_seed() -> int:
	return int(Time.get_ticks_usec() & 0x7fffffff)
