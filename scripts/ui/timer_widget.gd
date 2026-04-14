class_name TimerWidget
extends Control

@onready var time_label: Label = $TimeLabel

func set_elapsed_time(elapsed_time: float) -> void:
	var minutes := int(elapsed_time / 60.0)
	var seconds := int(elapsed_time) % 60
	time_label.text = "%02d:%02d" % [minutes, seconds]
