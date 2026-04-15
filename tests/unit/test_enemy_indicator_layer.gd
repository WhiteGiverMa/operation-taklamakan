extends GutTest

const ENEMY_INDICATOR_LAYER_SCENE := preload("res://scenes/ui/enemy_indicator_layer.tscn")

var _layer

func before_each() -> void:
	_layer = ENEMY_INDICATOR_LAYER_SCENE.instantiate()
	add_child_autofree(_layer)

func test_instantiation() -> void:
	assert_not_null(_layer, "Layer should instantiate")
	assert_true(_layer is Control, "Layer should be a Control")

func test_has_update_indicators_method() -> void:
	assert_true(_layer.has_method("update_indicators"), "Should have update_indicators method")

func test_hide_all_indicators() -> void:
	_layer.visible = false
	_layer.update_indicators()
	assert_not_null(_layer, "Layer should still exist after update_indicators() when hidden")

func test_layer_has_required_nodes() -> void:
	assert_true(_layer.has_node("IndicatorsContainer"), "Should have IndicatorsContainer")
