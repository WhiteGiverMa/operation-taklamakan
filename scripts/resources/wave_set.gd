class_name WaveSet
extends Resource

## Resource containing all wave configurations for a combat session.
## Holds 3-5 waves with increasing difficulty.

## Array of WaveData resources defining each wave
@export var waves: Array[WaveData] = []

## Get total number of waves
func get_wave_count() -> int:
	return waves.size()

## Get wave data for specific wave number (1-based)
func get_wave(wave_number: int) -> WaveData:
	if wave_number < 1 or wave_number > waves.size():
		return null
	return waves[wave_number - 1]

## Get total enemies across all waves
func get_total_enemies() -> int:
	var total := 0
	for wave in waves:
		if wave:
			total += wave.get_total_enemies()
	return total

## Validate all wave data
func is_valid() -> bool:
	if waves.is_empty():
		return false
	for wave in waves:
		if not wave or not wave.is_valid():
			return false
	return true
