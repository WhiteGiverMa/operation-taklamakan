class_name ToughnessComponent
extends Node

## Turret toughness resource buffer.
## Depletion paralyzes the turret until enough toughness has recovered.

signal toughness_changed(old_value: float, new_value: float)
signal paralysis_started()
signal paralysis_ended()
signal repaired(amount: float)

@export var max_toughness: float = 50.0
@export var current_toughness: float = 50.0
@export var auto_recovery_rate: float = 5.0
@export var recovery_threshold: float = 20.0

var _is_paralyzed: bool = false

func _ready() -> void:
	current_toughness = clampf(current_toughness, 0.0, max_toughness)
	if current_toughness <= 0.0:
		_is_paralyzed = true


func _physics_process(delta: float) -> void:
	if auto_recovery_rate <= 0.0 or current_toughness >= max_toughness:
		return

	recover(auto_recovery_rate * delta)


func apply_damage(amount: float) -> float:
	## Reduce toughness. Returns actual toughness damage applied.
	if amount <= 0.0 or max_toughness <= 0.0:
		return 0.0

	var old_value := current_toughness
	var actual_damage := minf(amount, current_toughness)
	current_toughness = maxf(current_toughness - actual_damage, 0.0)

	_emit_toughness_changed(old_value)

	if current_toughness <= 0.0 and not _is_paralyzed:
		_is_paralyzed = true
		paralysis_started.emit()

	return actual_damage


func take_damage(data: DamageData) -> float:
	if data == null:
		return 0.0
	return apply_damage(data.amount)


func recover(amount: float) -> float:
	## Restore toughness. Returns actual amount recovered.
	if amount <= 0.0 or current_toughness >= max_toughness:
		return 0.0

	var old_value := current_toughness
	var actual_recovery := minf(amount, max_toughness - current_toughness)
	current_toughness += actual_recovery

	_emit_toughness_changed(old_value)
	_try_end_paralysis()

	return actual_recovery


func repair_full() -> float:
	var repaired_amount := recover(max_toughness)
	if repaired_amount > 0.0:
		repaired.emit(repaired_amount)
	return repaired_amount


func is_depleted() -> bool:
	return current_toughness <= 0.0


func is_paralyzed() -> bool:
	return _is_paralyzed


func get_toughness_ratio() -> float:
	if max_toughness <= 0.0:
		return 0.0
	return current_toughness / max_toughness


func _try_end_paralysis() -> void:
	if not _is_paralyzed:
		return

	var required_toughness := minf(recovery_threshold, max_toughness)
	if current_toughness >= required_toughness:
		_is_paralyzed = false
		paralysis_ended.emit()


func _emit_toughness_changed(old_value: float) -> void:
	if not is_equal_approx(old_value, current_toughness):
		toughness_changed.emit(old_value, current_toughness)
