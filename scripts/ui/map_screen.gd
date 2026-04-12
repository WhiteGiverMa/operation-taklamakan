extends Control

## Map screen controller. Displays the floor graph with nodes and connections.
## Handles node selection, confirmation, and map navigation.

const MapNodeUIScript := preload("res://scripts/ui/map_node_ui.gd")
const MapNodeScript := preload("res://scripts/map_node.gd")

const FloorGraphScript := preload("res://scripts/floor_graph.gd")

# Map display settings
const MAP_VIEWPORT_WIDTH: float = 960.0
const MAP_VIEWPORT_HEIGHT: float = 720.0
const LAYER_VERTICAL_GAP: float = 840.0
const NODE_SCALE: float = 1.0
const TOTAL_LAYERS: int = 3

# Read-only mode for embedded map viewing
var read_only_mode: bool = false
var show_overlay_ui: bool = true
var allow_pan_in_read_only: bool = true  # 允许只读模式下平移

# Zoom settings
var _zoom_level: float = 1.0
const ZOOM_MIN: float = 0.5
const ZOOM_MAX: float = 2.0
const ZOOM_STEP: float = 0.1

# Connection colors
const COLOR_CONNECTION_ACTIVE := Color(0.8, 0.8, 0.8, 0.8)
const COLOR_CONNECTION_INACTIVE := Color(0.4, 0.4, 0.4, 0.3)
const COLOR_CONNECTION_PATH := Color(0.3, 0.9, 0.3, 1.0)

@onready var map_container: Control = $MapContainer
@onready var connections_layer: Control = $MapContainer/ConnectionsLayer
@onready var nodes_layer: Control = $MapContainer/NodesLayer
@onready var layer_info_label: Label = $UILayer/LayerInfo
@onready var node_info_label: Label = $UILayer/NodeInfo
@onready var confirm_button: Button = $UILayer/ConfirmButton
@onready var current_layer_indicator: Label = $UILayer/CurrentLayerIndicator

var _node_ui_map: Dictionary = {}  # node_id -> MapNodeUI
var _connection_lines: Array[Line2D] = []
var _selected_node_ui: MapNodeUIScript = null
var _is_panning: bool = false

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	resized.connect(_on_resized)
	_setup_ui()
	_connect_signals()
	_connect_localization()
	_refresh_map()
	_update_ui_layer_visibility()

func _process(_delta: float) -> void:
	if not visible:
		if _is_panning:
			_stop_pan()
		return

	# 只读模式下根据设置决定是否允许平移
	if read_only_mode and not allow_pan_in_read_only:
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

func _setup_ui() -> void:
	if is_instance_valid(confirm_button):
		confirm_button.disabled = true
		confirm_button.pressed.connect(_on_confirm_pressed)
	_update_layer_info()

func _connect_signals() -> void:
	MapManager.map_generated.connect(_on_map_generated)
	MapManager.current_node_changed.connect(_on_current_node_changed)
	MapManager.layer_changed.connect(_on_layer_changed)

func _connect_localization() -> void:
	if not Localization.language_changed.is_connected(_on_language_changed):
		Localization.language_changed.connect(_on_language_changed)

func _on_language_changed(_locale: String) -> void:
	_apply_localization()

func _on_map_generated(_seed: int, _graph) -> void:
	refresh_view()

func _on_current_node_changed(_node) -> void:
	_refresh_map()

func _on_layer_changed(_new_layer: int) -> void:
	_update_layer_info()
	_refresh_map()

func _update_layer_info() -> void:
	var current_layer := MapManager.current_layer
	layer_info_label.text = Localization.t("map.screen.layer_info", "", {
		"layer": current_layer + 1,
		"total_layers": TOTAL_LAYERS,
	})
	current_layer_indicator.text = Localization.t("map.screen.current_layer", "", {"layer": current_layer + 1})

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
	
	_selected_node_ui = null
	_update_confirm_button()

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
	node_ui.node_selected.connect(_on_node_selected)
	node_ui.node_confirmed.connect(_on_node_confirmed)
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
		if _selected_node_ui == node_ui:
			node_ui.set_selected(true)
		else:
			node_ui.set_selected(false)

func _on_node_selected(node_ui: MapNodeUIScript) -> void:
	if read_only_mode:
		return
	
	# Deselect previous
	if _selected_node_ui != null and _selected_node_ui != node_ui:
		_selected_node_ui.set_selected(false)
	
	_selected_node_ui = node_ui
	
	# Update info display
	_update_node_info(node_ui)
	
	# Enable confirm button if this is a reachable, unvisited node
	_update_confirm_button()

func refresh_view() -> void:
	_update_layer_info()
	_refresh_map()

func _update_node_info(node_ui: MapNodeUIScript) -> void:
	var info_text := ""
	
	if node_ui != null:
		info_text = Localization.t("map.screen.node_info.type", "", {"type": node_ui.get_type_name()}) + "\n"
		info_text += Localization.t("map.screen.node_info.position", "", {"layer": node_ui.layer_index + 1}) + "\n"
		
		if node_ui.is_visited:
			info_text += Localization.t("map.screen.node_info.state.visited")
		elif node_ui.is_reachable:
			info_text += Localization.t("map.screen.node_info.state.reachable")
		else:
			info_text += Localization.t("map.screen.node_info.state.locked")
	else:
		info_text = Localization.t("map.screen.select_node_hint")
	
	node_info_label.text = info_text

func _update_confirm_button() -> void:
	# 嵌入模式下 confirm_button 可能不存在或不可用
	if not is_instance_valid(confirm_button):
		return
	
	if read_only_mode:
		confirm_button.disabled = true
		return
	
	if _selected_node_ui == null:
		confirm_button.disabled = true
		confirm_button.text = Localization.t("map.screen.confirm.select")
		return
	
	var can_confirm := _can_enter_node(_selected_node_ui)
	confirm_button.disabled = not can_confirm
	
	if can_confirm:
		confirm_button.text = Localization.t("map.screen.confirm.go")
	elif _selected_node_ui.is_visited:
		confirm_button.text = Localization.t("map.screen.confirm.visited")
	elif not _selected_node_ui.is_reachable:
		confirm_button.text = Localization.t("map.screen.confirm.locked")
	else:
		confirm_button.text = Localization.t("map.screen.confirm.go")

func _apply_localization() -> void:
	_update_layer_info()
	_update_node_info(_selected_node_ui)
	_update_confirm_button()

func _on_confirm_pressed() -> void:
	if read_only_mode:
		return
	
	if _selected_node_ui == null:
		return
	
	if _can_enter_node(_selected_node_ui):
		_visit_selected_node()

func _visit_selected_node() -> void:
	if read_only_mode:
		return
	
	if _selected_node_ui == null:
		return
	
	var node_id := _selected_node_ui.node_id
	MapManager.visit_node(node_id)
	
	# Refresh the display
	_refresh_map()

func _on_node_confirmed(node_ui: MapNodeUIScript) -> void:
	if read_only_mode:
		return
	
	# Double-click or re-click to confirm
	if _can_enter_node(node_ui):
		_visit_selected_node()

func _can_enter_node(node_ui: MapNodeUIScript) -> bool:
	if node_ui == null or not node_ui.is_reachable:
		return false
	if not node_ui.is_visited:
		return true

	var current_node = MapManager.current_node
	if current_node == null:
		return false

	return current_node.type == MapNodeScript.TYPE_SHOP and node_ui.node_id == current_node.id

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

func set_read_only_mode(value: bool) -> void:
	read_only_mode = value
	_update_ui_layer_visibility()
	_update_confirm_button()

func set_show_overlay_ui(value: bool) -> void:
	show_overlay_ui = value
	_update_ui_layer_visibility()

func _update_ui_layer_visibility() -> void:
	# 使用 get_node_or_null 支持在 add_child 之前调用（场景树外节点查找）
	var ui_layer := get_node_or_null("UILayer")
	if ui_layer == null:
		return
	
	var should_show := show_overlay_ui and not read_only_mode
	ui_layer.visible = should_show
	
	# 禁用 UILayer 中所有控件的焦点，避免嵌入模式下 Tab 键被抢走
	# 这是 Godot 内置的焦点导航行为，必须在 visible=false 时同步禁用焦点
	for child in ui_layer.get_children():
		if child is Control:
			child.focus_mode = Control.FOCUS_NONE if not should_show else Control.FOCUS_ALL

func recenter_view() -> void:
	_center_on_current_layer()

func _apply_zoom() -> void:
	map_container.scale = Vector2(_zoom_level, _zoom_level)
	_center_on_current_layer()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_level = minf(_zoom_level + ZOOM_STEP, ZOOM_MAX)
			_apply_zoom()
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_level = maxf(_zoom_level - ZOOM_STEP, ZOOM_MIN)
			_apply_zoom()
			accept_event()
