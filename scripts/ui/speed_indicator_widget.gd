class_name SpeedIndicatorWidget
extends Control

## 速度指示器 Widget.
## 显示常驻 2x 速度指示器和切换通知（带淡出动画）.
## 自动连接 EventBus.game_speed_changed 信号.

@export var auto_connect_signals: bool = true

@onready var speed_label: Label = $SpeedLabel
@onready var notification_label: Label = $NotificationLabel
@onready var notification_timer: Timer = $NotificationTimer

func _ready() -> void:
	if auto_connect_signals:
		if not EventBus.game_speed_changed.is_connected(_on_game_speed_changed):
			EventBus.game_speed_changed.connect(_on_game_speed_changed)
	speed_label.visible = false
	notification_label.visible = false

func set_speed(speed: int) -> void:
	## 设置常驻速度指示器.
	if speed > 1:
		speed_label.text = Localization.t("hud.speed_2x.indicator")
		speed_label.visible = true
	else:
		speed_label.visible = false

func show_speed_notification(speed: int) -> void:
	## 显示速度切换通知（带 2 秒自动淡出）.
	var is_2x := speed > 1
	var key := "hud.speed_2x.toggle_enabled" if is_2x else "hud.speed_2x.toggle_disabled"
	notification_label.text = Localization.t(key)
	notification_label.modulate.a = 1.0
	notification_label.visible = true
	notification_timer.start(2.0)

func _on_game_speed_changed(new_speed: float) -> void:
	set_speed(int(new_speed))
	show_speed_notification(int(new_speed))

func _on_notification_timeout() -> void:
	## 通知淡出动画.
	var tween := create_tween()
	tween.tween_property(notification_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func() -> void:
		notification_label.visible = false
		notification_label.modulate.a = 1.0
	)
