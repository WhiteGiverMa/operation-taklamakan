class_name MapSelectScreen
extends Control

## 全屏地图选择器：包装 MapGraphView + 选择确认 UI。
## 用于地图推进时的节点选择流程。

const MapNodeScript := preload("res://scripts/map_node.gd")
const MapGraphViewScript := preload("res://scripts/ui/map_graph_view.gd")
const MapGraphViewScene := preload("res://scenes/ui/map_graph_view.tscn")

# Zoom constants (passed to graph view)
const ZOOM_MIN: float = 0.5
const ZOOM_MAX: float = 2.0
const ZOOM_STEP: float = 0.1

@onready var graph_view: Control = $MapGraphView
@onready var layer_info_label: Label = $UILayer/LayerInfo
@onready var node_info_label: Label = $UILayer/NodeInfo
@onready var confirm_button: Button = $UILayer/ConfirmButton
@onready var current_layer_indicator: Label = $UILayer/CurrentLayerIndicator

var _selected_node_id: String = ""

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	_setup_ui()
	_connect_signals()
	_connect_localization()
	_update_layer_info()

func _setup_ui() -> void:
	if is_instance_valid(confirm_button):
		confirm_button.disabled = true
		confirm_button.pressed.connect(_on_confirm_pressed)

func _connect_signals() -> void:
	if graph_view:
		graph_view.node_selected.connect(_on_node_selected)
		graph_view.node_confirmed.connect(_on_node_confirmed)
	
	MapManager.layer_changed.connect(_on_layer_changed)

func _connect_localization() -> void:
	if not Localization.language_changed.is_connected(_on_language_changed):
		Localization.language_changed.connect(_on_language_changed)

func _on_language_changed(_locale: String) -> void:
	_apply_localization()

func _on_layer_changed(_new_layer: int) -> void:
	_update_layer_info()
	if graph_view:
		graph_view.refresh_view()

func _update_layer_info() -> void:
	var current_layer := MapManager.current_layer
	layer_info_label.text = Localization.t("map.screen.layer_info", "", {
		"layer": current_layer + 1,
		"total_layers": 3,
	})
	current_layer_indicator.text = Localization.t("map.screen.current_layer", "", {"layer": current_layer + 1})

func _on_node_selected(node_id: String) -> void:
	_selected_node_id = node_id
	_update_node_info()
	_update_confirm_button()

func _on_node_confirmed(node_id: String) -> void:
	# 双击确认
	if _can_enter_node(node_id):
		_visit_node(node_id)

func _update_node_info() -> void:
	if _selected_node_id == "":
		node_info_label.text = Localization.t("map.screen.select_node_hint")
		return
	
	var node = MapManager.get_map_node(_selected_node_id)
	if node == null:
		node_info_label.text = Localization.t("map.screen.select_node_hint")
		return
	
	var node_ui = _get_node_ui(_selected_node_id)
	var type_name := ""
	if node_ui:
		type_name = node_ui.get_type_name()
	else:
		type_name = str(node.type)
	
	var info_text := Localization.t("map.screen.node_info.type", "", {"type": type_name}) + "\n"
	info_text += Localization.t("map.screen.node_info.position", "", {"layer": node.layer_index + 1}) + "\n"
	
	var current_node = MapManager.current_node
	var is_reachable: bool = current_node != null and (current_node.connections.has(_selected_node_id) or _selected_node_id == current_node.id)
	
	if node.visited:
		info_text += Localization.t("map.screen.node_info.state.visited")
	elif is_reachable:
		info_text += Localization.t("map.screen.node_info.state.reachable")
	else:
		info_text += Localization.t("map.screen.node_info.state.locked")
	
	node_info_label.text = info_text

func _get_node_ui(node_id: String) -> Variant:
	if graph_view and graph_view._node_ui_map.has(node_id):
		return graph_view._node_ui_map[node_id]
	return null

func _update_confirm_button() -> void:
	if not is_instance_valid(confirm_button):
		return
	
	if _selected_node_id == "":
		confirm_button.disabled = true
		confirm_button.text = Localization.t("map.screen.confirm.select")
		return
	
	var can_confirm := _can_enter_node(_selected_node_id)
	confirm_button.disabled = not can_confirm
	
	if can_confirm:
		confirm_button.text = Localization.t("map.screen.confirm.go")
	else:
		var node = MapManager.get_map_node(_selected_node_id)
		var current_node = MapManager.current_node
		var is_reachable: bool = current_node != null and (current_node.connections.has(_selected_node_id) or _selected_node_id == current_node.id)
		
		if node and node.visited:
			confirm_button.text = Localization.t("map.screen.confirm.visited")
		elif not is_reachable:
			confirm_button.text = Localization.t("map.screen.confirm.locked")
		else:
			confirm_button.text = Localization.t("map.screen.confirm.go")

func _can_enter_node(node_id: String) -> bool:
	var node = MapManager.get_map_node(node_id)
	if node == null:
		return false
	
	var current_node = MapManager.current_node
	if current_node == null:
		return false
	
	# 检查是否可达
	var is_reachable: bool = current_node.connections.has(node_id) or node_id == current_node.id
	if not is_reachable:
		return false
	
	# 未访问的可达节点
	if not node.visited:
		return true
	
	# 商店节点可以重新进入
	return current_node.type == MapNodeScript.TYPE_SHOP and node_id == current_node.id

func _visit_node(node_id: String) -> void:
	MapManager.visit_node(node_id)
	_selected_node_id = ""
	if graph_view:
		graph_view.refresh_view()

func _on_confirm_pressed() -> void:
	if _selected_node_id == "":
		return
	
	if _can_enter_node(_selected_node_id):
		_visit_node(_selected_node_id)

func _apply_localization() -> void:
	_update_layer_info()
	_update_node_info()
	_update_confirm_button()

## 刷新视图（供外部调用）
func refresh_view() -> void:
	_update_layer_info()
	if graph_view:
		graph_view.refresh_view()

## 重新居中视图
func recenter_view() -> void:
	if graph_view:
		graph_view.recenter_view()
