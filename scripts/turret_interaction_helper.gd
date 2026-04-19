class_name TurretInteractionHelper
extends RefCounted

## 炮塔玩家交互辅助：集中处理玩家识别、维修推进与手动模式退出判定。

static func is_player(body: Node2D) -> bool:
	return body.is_in_group("player") or body.has_method("is_player") or body.name == "Player" or body.name == "PlayerCharacter"


static func resolve_player(tree: SceneTree) -> Node2D:
	if tree == null:
		return null

	var ship := tree.get_first_node_in_group("ship")
	if ship != null:
		var player_on_ship := ship.get_node_or_null("PlayerCharacter") as Node2D
		if player_on_ship != null:
			return player_on_ship

	return tree.get_first_node_in_group("player") as Node2D


static func should_exit_manual_mode(skip_manual_exit_once: bool, interact_triggered: bool, move_input_active: bool) -> Dictionary:
	if skip_manual_exit_once:
		return {
			"skip_manual_exit_once": false,
			"should_exit": false,
		}

	return {
		"skip_manual_exit_once": false,
		"should_exit": interact_triggered or move_input_active,
	}


static func step_repair_timer(
		current_timer: float,
		delta: float,
		player_in_range: bool,
		is_paralyzed: bool,
		repair_triggered: bool,
		repair_duration: float
	) -> Dictionary:
	if not player_in_range or not is_paralyzed:
		return {
			"timer": 0.0,
			"completed": false,
		}

	if not repair_triggered:
		return {
			"timer": 0.0,
			"completed": false,
		}

	var next_timer := current_timer + delta
	if next_timer >= repair_duration:
		return {
			"timer": 0.0,
			"completed": true,
		}

	return {
		"timer": next_timer,
		"completed": false,
	}
