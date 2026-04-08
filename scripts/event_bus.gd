extends Node

## Global event bus for decoupled cross-system communication.
## All signals are typed for compile-time validation.

# Enemy events
signal enemy_spawned(enemy: Node2D)
signal enemy_died(enemy: Node2D, position: Vector2, reward: int)

# Wave events
signal wave_started(wave_number: int)
signal wave_complete(wave_number: int)
signal wave_all_complete()

# Ship events
signal ship_damaged(amount: float, source: Node)
signal ship_health_changed(current: float, maximum: float)
signal ship_destroyed()

# Turret events
signal turret_placed(turret: Node2D, slot_index: int)
signal turret_destroyed(turret: Node2D, slot_index: int)
signal turret_fired(turret: Node2D, target: Node2D)

# Projectile events
signal projectile_hit(projectile: Node2D, target: Node2D)

# Economy events
signal currency_changed(new_amount: int, delta: int)

# Map/Node events
signal node_entered(node_type: String)
signal layer_completed(layer: int)
signal shop_entered()

# Player events
signal player_died()
signal player_respawned()
signal player_knockback_started(player: Node2D, source: Node)

# Game state events
signal game_paused(is_paused: bool)
signal game_over(won: bool)
signal game_started()

# Upgrade events
signal upgrade_purchased(upgrade_id: String, cost: int)
