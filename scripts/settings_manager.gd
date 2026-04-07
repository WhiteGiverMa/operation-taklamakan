extends Node

signal settings_changed

const CONFIG_PATH := "user://settings.cfg"

enum WindowMode {
	WINDOWED,
	FULLSCREEN,
}

const DEFAULT_LANGUAGE := "zh"
const DEFAULT_MASTER_VOLUME := 0.8
const DEFAULT_WINDOW_MODE := WindowMode.WINDOWED
const DEFAULT_VSYNC_ENABLED := true

var language: String = DEFAULT_LANGUAGE
var master_volume: float = DEFAULT_MASTER_VOLUME
var window_mode: WindowMode = DEFAULT_WINDOW_MODE
var vsync_enabled: bool = DEFAULT_VSYNC_ENABLED

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	apply_settings()

func load_settings() -> void:
	var config := ConfigFile.new()
	var result := config.load(CONFIG_PATH)
	if result != OK:
		_save_defaults(config)
		return

	language = str(config.get_value("general", "language", DEFAULT_LANGUAGE))
	master_volume = clampf(float(config.get_value("audio", "master_volume", DEFAULT_MASTER_VOLUME)), 0.0, 1.0)
	window_mode = int(config.get_value("display", "window_mode", DEFAULT_WINDOW_MODE)) as WindowMode
	vsync_enabled = bool(config.get_value("display", "vsync_enabled", DEFAULT_VSYNC_ENABLED))

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("general", "language", language)
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("display", "window_mode", window_mode)
	config.set_value("display", "vsync_enabled", vsync_enabled)
	config.save(CONFIG_PATH)

func apply_settings() -> void:
	Localization.set_language(language)
	_apply_audio_settings()
	_apply_display_settings()
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

func _save_defaults(config: ConfigFile) -> void:
	config.set_value("general", "language", DEFAULT_LANGUAGE)
	config.set_value("audio", "master_volume", DEFAULT_MASTER_VOLUME)
	config.set_value("display", "window_mode", DEFAULT_WINDOW_MODE)
	config.set_value("display", "vsync_enabled", DEFAULT_VSYNC_ENABLED)
	config.save(CONFIG_PATH)

func _linear_to_db(value: float) -> float:
	if value <= 0.0:
		return -80.0
	return linear_to_db(value)
