extends Node

enum FlowContext {
	NONE,
	MENU,
	MAP,
	COMBAT,
	SHOP,
	PAUSE,
	SETTINGS,
}

enum OverlayContext {
	NONE,
	PAUSE,
	SETTINGS,
}

const MOVE_ACTION := preload("res://resources/input/actions/move.tres")
const REPAIR_ACTION := preload("res://resources/input/actions/repair.tres")
const INTERACT_ACTION := preload("res://resources/input/actions/interact.tres")
const FIRE_ACTION := preload("res://resources/input/actions/fire.tres")
const PAUSE_TOGGLE_ACTION := preload("res://resources/input/actions/pause_toggle.tres")
const INPUT_HINTS_TOGGLE_ACTION := preload("res://resources/input/actions/input_hints_toggle.tres")
const UI_BACK_ACTION := preload("res://resources/input/actions/ui_back.tres")
const MAP_PAN_HOLD_ACTION := preload("res://resources/input/actions/map_pan_hold.tres")
const MAP_PAN_DELTA_ACTION := preload("res://resources/input/actions/map_pan_delta.tres")
const CAMERA_ZOOM_IN_ACTION := preload("res://resources/input/actions/camera_zoom_in.tres")
const CAMERA_ZOOM_OUT_ACTION := preload("res://resources/input/actions/camera_zoom_out.tres")
const CAMERA_ZOOM_RESET_ACTION := preload("res://resources/input/actions/camera_zoom_reset.tres")

const COMBAT_CONTEXT := preload("res://resources/input/contexts/combat.tres")
const TURRET_MANUAL_CONTEXT := preload("res://resources/input/contexts/turret_manual.tres")
const MAP_CONTEXT := preload("res://resources/input/contexts/map.tres")
const OVERLAY_BACK_CONTEXT := preload("res://resources/input/contexts/overlay_back.tres")

var _flow_context: FlowContext = FlowContext.NONE
var _overlay_context: OverlayContext = OverlayContext.NONE
var _turret_manual_active: bool = false

var move_action: GUIDEAction:
	get:
		return MOVE_ACTION

var repair_action: GUIDEAction:
	get:
		return REPAIR_ACTION

var interact_action: GUIDEAction:
	get:
		return INTERACT_ACTION

var fire_action: GUIDEAction:
	get:
		return FIRE_ACTION

var pause_toggle_action: GUIDEAction:
	get:
		return PAUSE_TOGGLE_ACTION

var input_hints_toggle_action: GUIDEAction:
	get:
		return INPUT_HINTS_TOGGLE_ACTION

var ui_back_action: GUIDEAction:
	get:
		return UI_BACK_ACTION

var map_pan_hold_action: GUIDEAction:
	get:
		return MAP_PAN_HOLD_ACTION

var map_pan_delta_action: GUIDEAction:
	get:
		return MAP_PAN_DELTA_ACTION

var camera_zoom_in_action: GUIDEAction:
	get:
		return CAMERA_ZOOM_IN_ACTION

var camera_zoom_out_action: GUIDEAction:
	get:
		return CAMERA_ZOOM_OUT_ACTION

var camera_zoom_reset_action: GUIDEAction:
	get:
		return CAMERA_ZOOM_RESET_ACTION

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_activate_for_current_state()

func activate_menu() -> void:
	_flow_context = FlowContext.MENU
	_overlay_context = OverlayContext.NONE
	_turret_manual_active = false
	_activate_for_current_state()

func activate_map() -> void:
	_flow_context = FlowContext.MAP
	_overlay_context = OverlayContext.NONE
	_turret_manual_active = false
	_activate_for_current_state()

func activate_combat() -> void:
	_flow_context = FlowContext.COMBAT
	_overlay_context = OverlayContext.NONE
	_turret_manual_active = false
	_activate_for_current_state()

func activate_shop() -> void:
	_flow_context = FlowContext.SHOP
	_overlay_context = OverlayContext.NONE
	_turret_manual_active = false
	_activate_for_current_state()

func activate_pause() -> void:
	_overlay_context = OverlayContext.PAUSE
	_activate_for_current_state()

func activate_settings() -> void:
	_overlay_context = OverlayContext.SETTINGS
	_activate_for_current_state()

func activate_turret_manual() -> void:
	if _flow_context != FlowContext.COMBAT:
		return
	_turret_manual_active = true
	_activate_for_current_state()

func deactivate_turret_manual() -> void:
	if not _turret_manual_active:
		return
	_turret_manual_active = false
	_activate_for_current_state()

func restore_flow_context() -> void:
	_overlay_context = OverlayContext.NONE
	_activate_for_current_state()

func _activate_for_current_state() -> void:
	if _overlay_context != OverlayContext.NONE:
		_apply_contexts([OVERLAY_BACK_CONTEXT])
		return

	match _flow_context:
		FlowContext.MENU:
			# Main menu currently relies on focused Control nodes rather than GUIDE actions.
			_apply_contexts([])
		FlowContext.MAP:
			_apply_contexts([MAP_CONTEXT])
		FlowContext.COMBAT:
			var contexts: Array[GUIDEMappingContext] = [COMBAT_CONTEXT]
			if _turret_manual_active:
				contexts.append(TURRET_MANUAL_CONTEXT)
			_apply_contexts(contexts)
		FlowContext.SHOP:
			# Shop currently uses button-driven UI only, so gameplay contexts stay disabled here.
			_apply_contexts([])
		_:
			_apply_contexts([])

func _apply_contexts(contexts: Array[GUIDEMappingContext]) -> void:
	GUIDE.set_enabled_mapping_contexts(contexts)
