extends Control

## Victory screen shown when player defeats Layer 3 Boss.

@onready var result_label: Label = $VBoxContainer/ResultLabel
@onready var stats_label: Label = $VBoxContainer/StatsLabel
@onready var restart_button: Button = $VBoxContainer/RestartButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.game_over.connect(_on_game_over)
	restart_button.pressed.connect(_on_restart_pressed)
	_connect_localization()
	_apply_localization()
	hide()

func _connect_localization() -> void:
	if not Localization.language_changed.is_connected(_on_language_changed):
		Localization.language_changed.connect(_on_language_changed)

func _on_language_changed(_locale: String) -> void:
	if visible:
		_apply_localization()
	else:
		restart_button.text = Localization.t("common.restart")

func _on_game_over(won: bool) -> void:
	if won:
		_apply_localization()
		show()
		get_tree().paused = true

func _apply_localization() -> void:
	result_label.text = Localization.t("victory.title")
	stats_label.text = Localization.t("victory.stats", "", {
		"kills": GameState.kills,
		"layer": GameState.current_layer,
	})
	restart_button.text = Localization.t("common.restart")

func _on_restart_pressed() -> void:
	hide()
	var game_over_screen := get_parent().get_node_or_null("GameOver")
	if game_over_screen:
		game_over_screen.hide()
	GameState.reset_game()
