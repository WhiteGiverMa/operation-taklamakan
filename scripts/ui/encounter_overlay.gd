extends Control

signal completed

enum Mode {
	NONE,
	EVENT,
	NOTICE,
}

@onready var title_label: Label = $Backdrop/Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var body_label: Label = $Backdrop/Panel/MarginContainer/VBoxContainer/BodyLabel
@onready var selection_label: Label = $Backdrop/Panel/MarginContainer/VBoxContainer/SelectionLabel
@onready var option_button_container: HBoxContainer = $Backdrop/Panel/MarginContainer/VBoxContainer/OptionButtonContainer
@onready var option_a_button: Button = $Backdrop/Panel/MarginContainer/VBoxContainer/OptionButtonContainer/OptionAButton
@onready var option_b_button: Button = $Backdrop/Panel/MarginContainer/VBoxContainer/OptionButtonContainer/OptionBButton
@onready var continue_button: Button = $Backdrop/Panel/MarginContainer/VBoxContainer/ContinueButton

var _mode: Mode = Mode.NONE
var _selected_option_key: String = ""
var _restored_amount: float = 0.0

func _ready() -> void:
	visible = false
	option_a_button.pressed.connect(func() -> void: _select_option("a"))
	option_b_button.pressed.connect(func() -> void: _select_option("b"))
	continue_button.pressed.connect(_on_continue_pressed)
	if not Localization.language_changed.is_connected(_on_language_changed):
		Localization.language_changed.connect(_on_language_changed)
	_apply_localization()

func show_event_placeholder() -> void:
	_mode = Mode.EVENT
	_selected_option_key = ""
	_restored_amount = 0.0
	visible = true
	continue_button.disabled = true
	option_button_container.visible = true
	selection_label.visible = true
	_apply_localization()
	option_a_button.grab_focus()

func show_rest_notice(restored_amount: float) -> void:
	_mode = Mode.NOTICE
	_selected_option_key = ""
	_restored_amount = restored_amount
	visible = true
	continue_button.disabled = false
	option_button_container.visible = false
	selection_label.visible = false
	_apply_localization()
	continue_button.grab_focus()

func hide_overlay() -> void:
	_mode = Mode.NONE
	_selected_option_key = ""
	_restored_amount = 0.0
	visible = false

func _select_option(option_key: String) -> void:
	_selected_option_key = option_key
	continue_button.disabled = false
	_apply_localization()

func _on_continue_pressed() -> void:
	hide_overlay()
	completed.emit()

func _on_language_changed(_locale: String) -> void:
	_apply_localization()

func _apply_localization() -> void:
	match _mode:
		Mode.EVENT:
			title_label.text = Localization.t("encounter.event.title")
			body_label.text = Localization.t("encounter.event.body")
			option_a_button.text = Localization.t("encounter.event.option_a")
			option_b_button.text = Localization.t("encounter.event.option_b")
			continue_button.text = Localization.t("encounter.event.continue")
			selection_label.text = _build_event_selection_text()
		Mode.NOTICE:
			title_label.text = Localization.t("encounter.rest.title")
			body_label.text = Localization.t("encounter.rest.body", "", {"amount": _format_amount(_restored_amount)})
			continue_button.text = Localization.t("encounter.rest.continue")
			selection_label.text = ""
		_:
			title_label.text = ""
			body_label.text = ""
			selection_label.text = ""

func _build_event_selection_text() -> String:
	if _selected_option_key.is_empty():
		return Localization.t("encounter.event.unselected")

	var option_text := Localization.t("encounter.event.option_a")
	if _selected_option_key == "b":
		option_text = Localization.t("encounter.event.option_b")
	return Localization.t("encounter.event.selected", "", {"option": option_text})

func _format_amount(value: float) -> String:
	var rounded := roundf(value)
	if is_equal_approx(value, rounded):
		return str(int(rounded))
	return "%.1f" % value
