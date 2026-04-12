extends Node

## Global event bus for decoupled cross-system communication.
## All signals are typed for compile-time validation.

# Enemy events
signal enemy_spawned(enemy: Node2D)
signal enemy_died(enemy: Node2D, position: Vector2, reward: int)
signal damage_dealt(amount: float, position: Vector2, source: Node, is_critical: bool)

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
signal turret_stats_refresh_requested()  # 请求所有炮塔刷新属性（全局升级后）

# Projectile events
signal projectile_hit(projectile: Node2D, target: Node2D, damage: float)

# Economy events
signal currency_changed(new_amount: int, delta: int)

# Map/Node events
signal node_entered(node_type: String)
signal chapter_completed(chapter: int)
signal shop_entered()

# Game time events
signal game_time_updated(elapsed: float)

# Player events
signal player_died()
signal player_respawned()
signal player_knockback_started(player: Node2D, source: Node)

# Game state events
signal game_paused(is_paused: bool)
signal game_over(won: bool)
signal game_started()
signal game_speed_changed(new_speed: float)

# Upgrade events
signal upgrade_purchased(upgrade_id: String, cost: int)

# Relic events
signal relic_purchased(relic_id: String, cost: int)

## DevMode events
signal dev_event(event_type: String, data: Dictionary)
