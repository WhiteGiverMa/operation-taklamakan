extends GutTest

const INPUT_HINTS_WIDGET_SCENE := preload("res://scenes/ui/input_hints_widget.tscn")

var _widget

func before_each() -> void:
	_widget = INPUT_HINTS_WIDGET_SCENE.instantiate()
	add_child_autofree(_widget)

func test_instantiation() -> void:
	assert_not_null(_widget, "Widget should instantiate")
	assert_true(_widget is Control, "Widget should be a Control")

func test_has_public_methods() -> void:
	assert_true(_widget.has_method("set_hints_visible"), "Should have set_hints_visible method")
	assert_true(_widget.has_method("refresh_hints"), "Should have refresh_hints method")

func test_set_hints_visible_toggles_panel() -> void:
	_widget.set_hints_visible(true)
	assert_true(_widget.panel.visible, "Panel should be visible after set_hints_visible(true)")
	_widget.set_hints_visible(false)
	assert_false(_widget.panel.visible, "Panel should be hidden after set_hints_visible(false)")

func test_refresh_hints_does_not_crash() -> void:
	# Should not crash when called
	_widget.refresh_hints()
	assert_not_null(_widget, "Widget should still exist after refresh_hints()")

func test_widget_has_required_nodes() -> void:
	assert_true(_widget.has_node("PanelContainer"), "Should have PanelContainer")
	assert_true(_widget.has_node("PanelContainer/MarginContainer"), "Should have MarginContainer")
	assert_true(_widget.has_node("PanelContainer/MarginContainer/VBoxContainer"), "Should have VBoxContainer")
	assert_true(_widget.has_node("PanelContainer/MarginContainer/VBoxContainer/Rows"), "Should have Rows")

func test_hints_rows_exist() -> void:
	var rows_path := "PanelContainer/MarginContainer/VBoxContainer/Rows"
	assert_true(_widget.has_node(rows_path + "/MovementRow"), "Should have MovementRow")
	assert_true(_widget.has_node(rows_path + "/RepairRow"), "Should have RepairRow")
	assert_true(_widget.has_node(rows_path + "/InteractRow"), "Should have InteractRow")
	assert_true(_widget.has_node(rows_path + "/FireRow"), "Should have FireRow")
	assert_true(_widget.has_node(rows_path + "/PauseRow"), "Should have PauseRow")
	assert_true(_widget.has_node(rows_path + "/ToggleRow"), "Should have ToggleRow")
	assert_true(_widget.has_node(rows_path + "/SpeedToggleRow"), "Should have SpeedToggleRow")
