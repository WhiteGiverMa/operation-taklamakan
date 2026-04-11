extends Control

@onready var tab_container: TabContainer = $Panel/MarginContainer/VBoxContainer/TabContainer
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/Header/CloseButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	close_button.pressed.connect(hide_panel)
	visible = false

func _process(_delta: float) -> void:
	if visible and InputManager.ui_back_action.is_triggered():
		hide_panel()

func show_panel() -> void:
	visible = true

func hide_panel() -> void:
	visible = false
