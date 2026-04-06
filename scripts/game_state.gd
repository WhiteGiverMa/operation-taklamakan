extends Node

## Global game state manager. Handles currency, progress, and game status.
## Use signals to react to state changes rather than polling.

signal currency_changed(new_amount: int, delta: int)
signal layer_changed(new_layer: int)
signal game_state_changed(state: int)

enum State { MENU, PLAYING, PAUSED, GAME_OVER }

@export var currency: int = 50:
	set(value):
		var delta := value - currency
		currency = value
		currency_changed.emit(currency, delta)
		if is_inside_tree():
			EventBus.currency_changed.emit(currency, delta)

@export var current_layer: int = 1
@export var kills: int = 0
@export var level: int = 1  # Display only - represents run progression

# Shop upgrade state
var turret_damage_multiplier: float = 1.0
var auto_fire_unlocked: bool = false

var _state: State = State.MENU

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.enemy_died.connect(_on_enemy_died)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _state == State.PLAYING:
		toggle_pause()

func get_state() -> State:
	return _state

func set_state(new_state: State) -> void:
	_state = new_state
	game_state_changed.emit(_state)
	EventBus.game_paused.emit(_state == State.PAUSED)

func start_game() -> void:
	currency = 50
	current_layer = 1
	kills = 0
	level = 1
	turret_damage_multiplier = 1.0
	auto_fire_unlocked = false
	set_state(State.PLAYING)
	EventBus.game_started.emit()

func toggle_pause() -> void:
	if _state == State.PLAYING:
		set_state(State.PAUSED)
		get_tree().paused = true
	elif _state == State.PAUSED:
		set_state(State.PLAYING)
		get_tree().paused = false

func end_game(won: bool) -> void:
	set_state(State.GAME_OVER)
	get_tree().paused = true
	EventBus.game_over.emit(won)

func reset_game() -> void:
	# Reset currency and upgrades
	currency = 50
	turret_damage_multiplier = 1.0
	auto_fire_unlocked = false
	kills = 0
	current_layer = 1
	level = 1
	
	# Reset map to layer 1
	MapManager.reset_map()
	
	# Reset wave system
	WaveManager.end_combat_session()
	
	# Reset ship HP
	var ship = get_tree().get_first_node_in_group("ship")
	if ship and ship.has_node("HealthComponent"):
		var health_comp = ship.get_node("HealthComponent") as HealthComponent
		if health_comp:
			health_comp.current_health = health_comp.max_health
			EventBus.ship_health_changed.emit(health_comp.max_health, health_comp.max_health)
	
	# Resume game and start
	get_tree().paused = false
	set_state(State.PLAYING)
	EventBus.game_started.emit()

func reset_to_menu() -> void:
	set_state(State.MENU)
	get_tree().paused = false

func add_currency(amount: int) -> void:
	currency += amount

func spend_currency(amount: int) -> bool:
	if currency >= amount:
		currency -= amount
		return true
	return false

func can_afford(amount: int) -> bool:
	return currency >= amount

func advance_layer() -> void:
	current_layer += 1
	level = current_layer
	layer_changed.emit(current_layer)

func _on_enemy_died(_enemy: Node2D, _position: Vector2, _reward: int) -> void:
	if _state == State.PLAYING:
		kills += 1
		if _reward > 0:
			add_currency(_reward)
