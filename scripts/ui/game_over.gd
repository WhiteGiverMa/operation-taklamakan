extends Control

## Game over screen with restart button and stats display.

@onready var result_label: Label = $VBoxContainer/ResultLabel
@onready var stats_label: Label = $VBoxContainer/StatsLabel
@onready var restart_button: Button = $VBoxContainer/RestartButton

func _ready() -> void:
	EventBus.game_over.connect(_on_game_over)
	restart_button.pressed.connect(_on_restart_pressed)
	hide()

func _on_game_over(won: bool) -> void:
	result_label.text = "VICTORY" if won else "DEFEAT"
	stats_label.text = "Kills: %d" % GameState.kills
	show()
	get_tree().paused = true

func _on_restart_pressed() -> void:
	hide()
	var victory_screen := get_parent().get_node_or_null("VictoryScreen")
	if victory_screen:
		victory_screen.hide()
	GameState.reset_game()
