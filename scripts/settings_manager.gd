extends Node

signal settings_changed

const CONFIG_DIR := "user://config"
const CONFIG_PATH := CONFIG_DIR + "/settings.cfg"
const LEGACY_CONFIG_PATH := "user://settings.cfg"

enum WindowMode {
	WINDOWED,
	FULLSCREEN,
}

enum TimeMode {
	GAME_TIME,
	REAL_TIME,
}

const DEFAULT_LANGUAGE := "zh"
const DEFAULT_MASTER_VOLUME := 0.8
const DEFAULT_WINDOW_MODE := WindowMode.WINDOWED
const DEFAULT_VSYNC_ENABLED := true
const DEFAULT_MANUAL_FIRE_FULL_AUTO := true
const DEFAULT_DEV_MODE_ENABLED := false
const DEFAULT_TIME_MODE := TimeMode.GAME_TIME

var language: String = DEFAULT_LANGUAGE
var master_volume: float = DEFAULT_MASTER_VOLUME
var window_mode: WindowMode = DEFAULT_WINDOW_MODE
var vsync_enabled: bool = DEFAULT_VSYNC_ENABLED
var manual_fire_full_auto: bool = DEFAULT_MANUAL_FIRE_FULL_AUTO
var dev_mode_enabled: bool = DEFAULT_DEV_MODE_ENABLED
var time_mode: TimeMode = DEFAULT_TIME_MODE

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	apply_settings()

func load_settings() -> void:
	_ensure_config_dir()
	_migrate_legacy_config()

	var config := ConfigFile.new()
	var result := config.load(CONFIG_PATH)
	if result != OK:
		_save_defaults(config)
		return

	language = str(config.get_value("general", "language", DEFAULT_LANGUAGE))
	master_volume = clampf(float(config.get_value("audio", "master_volume", DEFAULT_MASTER_VOLUME)), 0.0, 1.0)
	window_mode = int(config.get_value("display", "window_mode", DEFAULT_WINDOW_MODE)) as WindowMode
	vsync_enabled = bool(config.get_value("display", "vsync_enabled", DEFAULT_VSYNC_ENABLED))
	manual_fire_full_auto = bool(config.get_value("gameplay", "manual_fire_full_auto", DEFAULT_MANUAL_FIRE_FULL_AUTO))
	dev_mode_enabled = bool(config.get_value("developer", "dev_mode_enabled", DEFAULT_DEV_MODE_ENABLED))
	time_mode = _sanitize_time_mode(int(config.get_value("gameplay", "time_mode", DEFAULT_TIME_MODE)))

func save_settings() -> void:
	_ensure_config_dir()

	var config := ConfigFile.new()
	config.set_value("general", "language", language)
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("display", "window_mode", window_mode)
	config.set_value("display", "vsync_enabled", vsync_enabled)
	config.set_value("gameplay", "manual_fire_full_auto", manual_fire_full_auto)
	config.set_value("gameplay", "time_mode", time_mode)
	config.set_value("developer", "dev_mode_enabled", dev_mode_enabled)
	config.save(CONFIG_PATH)

func apply_settings() -> void:
	Localization.set_language(language)
	_apply_audio_settings()
	_apply_display_settings()
	_apply_gameplay_settings()
	settings_changed.emit()

func set_language_setting(locale: String) -> void:
	language = locale.to_lower()
	Localization.set_language(language)
	save_settings()
	settings_changed.emit()

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_audio_settings()
	save_settings()
	settings_changed.emit()

func set_window_mode_setting(value: int) -> void:
	window_mode = value as WindowMode
	_apply_display_settings()
	save_settings()
	settings_changed.emit()

func set_vsync_enabled_setting(value: bool) -> void:
	vsync_enabled = value
	_apply_display_settings()
	save_settings()
	settings_changed.emit()

func set_manual_fire_full_auto(value: bool) -> void:
	manual_fire_full_auto = value
	save_settings()
	settings_changed.emit()

func set_time_mode_setting(value: int) -> void:
	time_mode = _sanitize_time_mode(value)
	_apply_gameplay_settings()
	save_settings()
	settings_changed.emit()

func set_dev_mode_enabled(value: bool) -> void:
	dev_mode_enabled = value
	save_settings()
	settings_changed.emit()

func _apply_audio_settings() -> void:
	var bus_index := AudioServer.get_bus_index("Master")
	if bus_index < 0:
		return
	AudioServer.set_bus_volume_db(bus_index, _linear_to_db(master_volume))

func _apply_display_settings() -> void:
	match window_mode:
		WindowMode.FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	var vsync_mode := DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(vsync_mode)

func _apply_gameplay_settings() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("set_time_mode"):
		game_state.call("set_time_mode", int(time_mode))

func _save_defaults(config: ConfigFile) -> void:
	config.set_value("general", "language", DEFAULT_LANGUAGE)
	config.set_value("audio", "master_volume", DEFAULT_MASTER_VOLUME)
	config.set_value("display", "window_mode", DEFAULT_WINDOW_MODE)
	config.set_value("display", "vsync_enabled", DEFAULT_VSYNC_ENABLED)
	config.set_value("gameplay", "manual_fire_full_auto", DEFAULT_MANUAL_FIRE_FULL_AUTO)
	config.set_value("gameplay", "time_mode", DEFAULT_TIME_MODE)
	config.set_value("developer", "dev_mode_enabled", DEFAULT_DEV_MODE_ENABLED)
	config.save(CONFIG_PATH)

func _ensure_config_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CONFIG_DIR))

func _migrate_legacy_config() -> void:
	if FileAccess.file_exists(CONFIG_PATH):
		return

	if not FileAccess.file_exists(LEGACY_CONFIG_PATH):
		return

	var legacy_absolute_path := ProjectSettings.globalize_path(LEGACY_CONFIG_PATH)
	var config_absolute_path := ProjectSettings.globalize_path(CONFIG_PATH)
	var rename_result := DirAccess.rename_absolute(legacy_absolute_path, config_absolute_path)
	if rename_result == OK:
		return

	var legacy_config := ConfigFile.new()
	if legacy_config.load(LEGACY_CONFIG_PATH) != OK:
		return

	if legacy_config.save(CONFIG_PATH) != OK:
		return

	DirAccess.remove_absolute(legacy_absolute_path)

func _sanitize_time_mode(value: int) -> TimeMode:
	if value == TimeMode.REAL_TIME:
		return TimeMode.REAL_TIME
	return TimeMode.GAME_TIME

func _linear_to_db(value: float) -> float:
	if value <= 0.0:
		return -80.0
	return linear_to_db(value)
