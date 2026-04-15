extends GutTest

const SPEED_INDICATOR_WIDGET_SCENE := preload("res://scenes/ui/speed_indicator_widget.tscn")

var _widget

func before_each() -> void:
	_widget = SPEED_INDICATOR_WIDGET_SCENE.instantiate()
	add_child_autofree(_widget)

func test_instantiation() -> void:
	assert_not_null(_widget, "Widget should instantiate")
	assert_true(_widget is Control, "Widget should be a Control")

func test_has_public_methods() -> void:
	assert_true(_widget.has_method("set_speed"), "Should have set_speed method")
	assert_true(_widget.has_method("show_speed_notification"), "Should have show_speed_notification method")

func test_set_speed_hides_label_at_normal_speed() -> void:
	_widget.set_speed(1)
	assert_false(_widget.speed_label.visible, "SpeedLabel should be hidden at speed 1")

func test_set_speed_shows_label_at_2x() -> void:
	_widget.set_speed(2)
	assert_true(_widget.speed_label.visible, "SpeedLabel should be visible at speed 2")

func test_show_speed_notification_does_not_crash() -> void:
	# Should not crash when called
	_widget.show_speed_notification(2)
	assert_not_null(_widget, "Widget should still exist after show_speed_notification()")

func test_widget_has_required_nodes() -> void:
	assert_true(_widget.has_node("SpeedLabel"), "Should have SpeedLabel")
	assert_true(_widget.has_node("NotificationLabel"), "Should have NotificationLabel")
	assert_true(_widget.has_node("NotificationTimer"), "Should have NotificationTimer")

func test_notification_timer_is_one_shot() -> void:
	assert_true(_widget.notification_timer.one_shot, "NotificationTimer should be one_shot")
	assert_eq(_widget.notification_timer.wait_time, 2.0, "NotificationTimer wait_time should be 2.0")
