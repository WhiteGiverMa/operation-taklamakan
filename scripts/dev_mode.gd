extends Node

## DevMode autoload. Provides runtime command execution for development/debugging.
## Currently a skeleton - command logic not yet implemented.

var is_enabled: bool:
	get:
		return SettingsManager.dev_mode_enabled

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SettingsManager.settings_changed.connect(_on_settings_changed)

func _on_settings_changed() -> void:
	# is_enabled getter automatically reads from SettingsManager.dev_mode_enabled
	pass

func execute(command: String) -> String:
	return "DevMode not fully implemented yet"
