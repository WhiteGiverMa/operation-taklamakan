class_name MapGraphView
extends Control

## 纯地图显示组件：只负责节点/连线绘制、居中、缩放、平移。
## 不包含任何 UI 覆盖层（选择按钮、状态标签等）。
## 使用者通过信号接收节点交互事件，自行决定如何响应。

const MapNodeUIScript := preload("res://scripts/ui/map_node_ui.gd")
const FloorGraphScript := preload("res://scripts/floor_graph.gd")

# Map display settings
const MAP_VIEWPORT_WIDTH: float = 960.0
const MAP_VIEWPORT_HEIGHT: float = 720.0
const LAYER_VERTICAL_GAP: float = 840.0
const TOTAL_LAYERS: int = 3

# Zoom settings
var zoom_level: float = 1.0:
	set(value):
		zoom_level = clampf(value, ZOOM_MIN, ZOOM_MAX)
		_apply_zoom()
const ZOOM_MIN: float = 0.5
const ZOOM_MAX: float = 2.0
const ZOOM_STEP: float = 0.1

# Connection colors
const COLOR_CONNECTION_ACTIVE := Color(0.8, 0.8, 0.8, 0.8)
const COLOR_CONNECTION_INACTIVE := Color(0.4, 0.4, 0.4, 0.3)
const COLOR_CONNECTION_PATH := Color(0.3, 0.9, 0.3, 1.0)

# Signals - 让使用者决定如何响应
signal node_selected(node_id: String)
signal node_confirmed(node_id: String)

# 允许平移（只读模式下也可配置）
var allow_pan: bool = true

# 允许节点选择（只读模式下应禁用）
var allow_selection: bool = true

@onready var map_container: Control = $MapContainer
@onready var connections_layer: Control = $MapContainer/ConnectionsLayer
@onready var nodes_layer: Control = $MapContainer/NodesLayer

var _node_ui_map: Dictionary = {}  # node_id -> MapNodeUI
var _connection_lines: Array[Line2D] = []
var _selected_node_id: String = ""
var _is_panning: bool = false

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	resized.connect(_on_resized)
	_connect_signals()
	# 初始绘制：如果地图已生成，立即刷新视图
	call_deferred("refresh_view")

func _process(_delta: float) -> void:
	if not visible:
		if _is_panning:
			_stop_pan()
		return

	if not allow_pan:
		if _is_panning:
			_stop_pan()
		return

	var pan_is_active := InputManager.map_pan_hold_action.is_triggered()
	if pan_is_active:
		if not _is_panning:
			_start_pan()
		var pan_delta := InputManager.map_pan_delta_action.value_axis_2d
		if pan_delta != Vector2.ZERO:
			_do_pan_delta(pan_delta)
	elif _is_panning:
		_stop_pan()

func _connect_signals() -> void:
	MapManager.map_generated.connect(_on_map_generated)
	MapManager.current_node_changed.connect(_on_current_node_changed)
	MapManager.layer_changed.connect(_on_layer_changed)

func _on_map_generated(_seed: int, _graph) -> void:
	refresh_view()

func _on_current_node_changed(_node) -> void:
	_refresh_map()

func _on_layer_changed(_new_layer: int) -> void:
	_refresh_map()

## 刷新地图视图
func refresh_view() -> void:
	_refresh_map()

## 重新居中到当前层
func recenter_view() -> void:
	_center_on_current_layer()

## 获取当前选中的节点ID
func get_selected_node_id() -> String:
	return _selected_node_id

## 设置选中的节点ID（用于外部控制）
func set_selected_node_id(node_id: String) -> void:
	if _selected_node_id == node_id:
		return
	
	# 取消之前的选中
	if _selected_node_id != "" and _node_ui_map.has(_selected_node_id):
		var old_ui: MapNodeUIScript = _node_ui_map[_selected_node_id]
		if is_instance_valid(old_ui):
			old_ui.set_selected(false)
	
	_selected_node_id = node_id
	
	# 设置新的选中
	if _selected_node_id != "" and _node_ui_map.has(_selected_node_id):
		var new_ui: MapNodeUIScript = _node_ui_map[_selected_node_id]
		if is_instance_valid(new_ui):
			new_ui.set_selected(true)

func _refresh_map() -> void:
	_clear_map()
	
	var graph = MapManager.get_graph()
	if graph == null:
		return
	
	_draw_connections(graph)
	_draw_nodes(graph)
	_update_node_states()
	_center_on_current_layer()

func _clear_map() -> void:
	# Clear connection lines
	for line in _connection_lines:
		line.queue_free()
	_connection_lines.clear()
	
	# Clear node UIs
	for node_ui in _node_ui_map.values():
		if is_instance_valid(node_ui):
			node_ui.queue_free()
	_node_ui_map.clear()
	
	_selected_node_id = ""

func _draw_connections(graph) -> void:
	var floor_graph = graph as FloorGraphScript
	if floor_graph == null:
		return
	
	# Draw connections for all layers
	for layer_index in range(TOTAL_LAYERS):
		var layer_nodes = floor_graph.get_layer_nodes(layer_index)
		for node in layer_nodes:
			for target_id in node.connections:
				var target_node = floor_graph.get_node(target_id)
				if target_node != null:
					_draw_connection(node, target_node)

func _draw_connection(from_node, to_node) -> void:
	var line := Line2D.new()
	line.width = 3.0
	line.default_color = _get_connection_color(from_node, to_node)
	line.add_point(from_node.position)
	line.add_point(to_node.position)
	connections_layer.add_child(line)
	_connection_lines.append(line)

func _get_connection_color(from_node, to_node) -> Color:
	var current_node = MapManager.current_node
	if current_node == null:
		return COLOR_CONNECTION_INACTIVE
	
	# Highlight path from current node
	if from_node.id == current_node.id:
		return COLOR_CONNECTION_PATH
	
	# Highlight path to visited nodes
	if from_node.visited and to_node.visited:
		return COLOR_CONNECTION_ACTIVE
	
	return COLOR_CONNECTION_INACTIVE

func _draw_nodes(graph) -> void:
	var floor_graph = graph as FloorGraphScript
	if floor_graph == null:
		return
	
	for layer_index in range(TOTAL_LAYERS):
		var layer_nodes = floor_graph.get_layer_nodes(layer_index)
		for node in layer_nodes:
			_create_node_ui(node)

func _create_node_ui(node) -> void:
	var node_ui := MapNodeUIScript.new()
	node_ui.setup(node)
	node_ui.node_selected.connect(_on_node_ui_selected)
	node_ui.node_confirmed.connect(_on_node_ui_confirmed)
	nodes_layer.add_child(node_ui)
	_node_ui_map[node.id] = node_ui

func _update_node_states() -> void:
	var current_node = MapManager.current_node
	
	for node_id in _node_ui_map:
		var node_ui: MapNodeUIScript = _node_ui_map[node_id]
		var map_node = MapManager.get_map_node(node_id)
		
		if map_node == null:
			continue
		
		# Update visited state
		node_ui.set_visited(map_node.visited)
		
		# Update reachable state
		var is_reachable := false
		if current_node != null:
			is_reachable = current_node.connections.has(node_id) or node_id == current_node.id
		node_ui.set_reachable(is_reachable)
		
		# Update selection state
		node_ui.set_selected(node_id == _selected_node_id)

func _on_node_ui_selected(node_ui: MapNodeUIScript) -> void:
	if not allow_selection:
		return
	
	# 取消之前的选中
	if _selected_node_id != "" and _selected_node_id != node_ui.node_id:
		if _node_ui_map.has(_selected_node_id):
			var old_ui: MapNodeUIScript = _node_ui_map[_selected_node_id]
			if is_instance_valid(old_ui):
				old_ui.set_selected(false)
	
	_selected_node_id = node_ui.node_id
	node_selected.emit(node_ui.node_id)

func _on_node_ui_confirmed(node_ui: MapNodeUIScript) -> void:
	if not allow_selection:
		return
	
	node_confirmed.emit(node_ui.node_id)

func _center_on_current_layer() -> void:
	var current_layer := MapManager.current_layer
	var target_y := float(current_layer) * LAYER_VERTICAL_GAP
	
	# 获取实际容器尺寸
	var viewport_size := _get_host_size()
	
	# Center the map container
	var viewport_center := Vector2(viewport_size.x * 0.5, viewport_size.y * 0.5)
	var layer_center := Vector2(viewport_size.x * 0.5, target_y + viewport_size.y * 0.3)
	
	map_container.position = viewport_center - layer_center

func _get_host_size() -> Vector2:
	var parent := map_container.get_parent()
	if parent and parent is Control:
		return parent.size
	return Vector2(MAP_VIEWPORT_WIDTH, MAP_VIEWPORT_HEIGHT)

func _start_pan() -> void:
	_is_panning = true

func _stop_pan() -> void:
	_is_panning = false

func _do_pan_delta(delta: Vector2) -> void:
	map_container.position += delta

func _on_resized() -> void:
	_center_on_current_layer()

func _apply_zoom() -> void:
	if not is_instance_valid(map_container):
		return
	map_container.scale = Vector2(zoom_level, zoom_level)
	_center_on_current_layer()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_level = minf(zoom_level + ZOOM_STEP, ZOOM_MAX)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_level = maxf(zoom_level - ZOOM_STEP, ZOOM_MIN)
			accept_event()
