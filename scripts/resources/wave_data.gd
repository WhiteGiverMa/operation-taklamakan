class_name WaveData
extends Resource

## Resource defining a single wave configuration.
## Contains enemy types, counts, and spawn intervals.

## Wave number identifier
@export var wave_number: int = 1

## Number of tank enemies to spawn
@export var tank_count: int = 0

## Number of mechanical dog enemies to spawn
@export var mechanical_dog_count: int = 0

## Number of boss tank enemies to spawn
@export var boss_tank_count: int = 0

## Time between individual enemy spawns (seconds)
@export var spawn_interval: float = 2.0

## Delay before wave starts after previous wave (seconds)
@export var preparation_time: float = 3.0

## Duration of intermission after this wave completes (seconds)
@export var intermission_duration: float = 10.0

## Get total enemy count for this wave
func get_total_enemies() -> int:
	return tank_count + mechanical_dog_count + boss_tank_count

## Validate wave data
func is_valid() -> bool:
	return wave_number > 0 and get_total_enemies() > 0

## Get enemy counts as dictionary
func get_enemy_counts() -> Dictionary:
	return {
		"tank": tank_count,
		"mechanical_dog": mechanical_dog_count,
		"boss_tank": boss_tank_count
	}
