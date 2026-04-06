extends Control

## Victory screen shown when player defeats Layer 3 Boss.

@onready var result_label: Label = $VBoxContainer/ResultLabel
@onready var stats_label: Label = $VBoxContainer/StatsLabel
@onready var restart_button: Button = $VBoxContainer/RestartButton

func _ready() -> void:
	EventBus.game_over.connect(_on_game_over)
	restart_button.pressed.connect(_on_restart_pressed)
	hide()

func _on_game_over(won: bool) -> void:
	if won:
		result_label.text = "VICTORY"
		stats_label.text = "Kills: %d\nLayer: %d" % [GameState.kills, GameState.current_layer]
		show()
		get_tree().paused = true

func _on_restart_pressed() -> void:
	hide()
	var game_over_screen := get_parent().get_node_or_null("GameOver")
	if game_over_screen:
		game_over_screen.hide()
	GameState.reset_game()
