extends Control

## Game over screen with restart button and stats display.

@onready var result_label: Label = $VBoxContainer/ResultLabel
@onready var stats_label: Label = $VBoxContainer/StatsLabel
@onready var restart_button: Button = $VBoxContainer/RestartButton

var _last_won: bool = false

func _ready() -> void:
	EventBus.game_over.connect(_on_game_over)
	restart_button.pressed.connect(_on_restart_pressed)
	_connect_localization()
	_apply_localization(false)
	hide()

func _connect_localization() -> void:
	if not Localization.language_changed.is_connected(_on_language_changed):
		Localization.language_changed.connect(_on_language_changed)

func _on_language_changed(_locale: String) -> void:
	if visible:
		_apply_localization(_last_won)
	else:
		restart_button.text = Localization.t("common.restart")

func _on_game_over(won: bool) -> void:
	_last_won = won
	_apply_localization(won)
	show()
	get_tree().paused = true

func _apply_localization(won: bool) -> void:
	result_label.text = Localization.t("game_over.victory") if won else Localization.t("game_over.defeat")
	stats_label.text = Localization.t("game_over.kills", "", {"kills": GameState.kills})
	restart_button.text = Localization.t("common.restart")

func _on_restart_pressed() -> void:
	hide()
	var victory_screen := get_parent().get_node_or_null("VictoryScreen")
	if victory_screen:
		victory_screen.hide()
	GameState.reset_game()
