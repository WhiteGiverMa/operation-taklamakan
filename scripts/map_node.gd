class_name MapNode
extends RefCounted

## Lightweight data object for a generated map node.
## Stores graph links, UI position, and visit state.

enum NodeType {
	START,
	COMBAT,
	ELITE,
	SHOP,
	EVENT,
	REST,
	END,
	BOSS,
}

const TYPE_START: int = NodeType.START
const TYPE_COMBAT: int = NodeType.COMBAT
const TYPE_ELITE: int = NodeType.ELITE
const TYPE_SHOP: int = NodeType.SHOP
const TYPE_EVENT: int = NodeType.EVENT
const TYPE_REST: int = NodeType.REST
const TYPE_END: int = NodeType.END
const TYPE_BOSS: int = NodeType.BOSS

const TYPE_IDS := {
	NodeType.START: "start",
	NodeType.COMBAT: "combat",
	NodeType.ELITE: "elite",
	NodeType.SHOP: "shop",
	NodeType.EVENT: "event",
	NodeType.REST: "rest",
	NodeType.END: "end",
	NodeType.BOSS: "boss",
}

var id: String = ""
var chapter_index: int = 0
var row_index: int = 0
var column_index: int = 0
var position: Vector2 = Vector2.ZERO
var type: NodeType = NodeType.COMBAT
var connections: Array[String] = []
var incoming_connections: Array[String] = []
var visited: bool = false

func _init(
	node_id: String = "",
	p_chapter_index: int = 0,
	p_row_index: int = 0,
	p_column_index: int = 0,
	p_position: Vector2 = Vector2.ZERO,
	p_type: NodeType = NodeType.COMBAT
) -> void:
	id = node_id
	chapter_index = p_chapter_index
	row_index = p_row_index
	column_index = p_column_index
	position = p_position
	type = p_type

func add_connection(target_id: String) -> void:
	if target_id.is_empty() or target_id == id or connections.has(target_id):
		return
	connections.append(target_id)

func add_incoming_connection(source_id: String) -> void:
	if source_id.is_empty() or source_id == id or incoming_connections.has(source_id):
		return
	incoming_connections.append(source_id)

func set_visited(value: bool = true) -> void:
	visited = value

func get_type_name() -> String:
	return TYPE_IDS.get(type, "unknown")

func get_type_translation_key() -> String:
	return "map.node_type.%s" % get_type_name()

func is_terminal() -> bool:
	return type == NodeType.END or type == NodeType.BOSS

func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"chapter_index": chapter_index,
		"row_index": row_index,
		"column_index": column_index,
		"position": [position.x, position.y],
		"type": get_type_name(),
		"connections": connections.duplicate(),
		"incoming_connections": incoming_connections.duplicate(),
		"visited": visited,
	}

func serialize() -> String:
	return JSON.stringify(to_dictionary())
