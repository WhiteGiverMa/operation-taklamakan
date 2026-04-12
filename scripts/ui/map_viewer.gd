class_name MapViewer
extends Control

## 嵌入式地图浏览器：包装 MapGraphView，只读、可平移、无 UI 覆盖层。
## 用于信息界面中的地图标签页。

const MapGraphViewScene := preload("res://scenes/ui/map_graph_view.tscn")

@onready var graph_view: Control = $MapGraphView

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	_setup_graph_view()
	# 防御性刷新：确保 graph_view 初始化后有内容
	call_deferred("refresh_view")

func _setup_graph_view() -> void:
	if graph_view:
		# 只读模式：禁用选择，允许平移
		graph_view.allow_selection = false
		graph_view.allow_pan = true

## 刷新视图
func refresh_view() -> void:
	if graph_view:
		graph_view.refresh_view()

## 重新居中视图
func recenter_view() -> void:
	if graph_view:
		graph_view.recenter_view()
