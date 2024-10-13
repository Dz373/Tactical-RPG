extends Control

@onready var btnContainer: VBoxContainer = $MenuContainer/BtnContainer
@onready var atkButton: Button=$MenuContainer/BtnContainer/AttackBtn

var buttons: Array

func _ready() -> void:
	for child in btnContainer.get_children():
		var btn := child as Button
		if not btn:
			continue
		if btn:
			buttons.append(btn)
	get_first_button().grab_focus()

func get_first_button()->Button:
	for btn in buttons:
		if not btn.visible:
			continue
		return btn
	return

func get_focus_button()->Button:
	for btn in buttons:
		if not btn.visible:
			continue
		if btn.has_focus():
			return btn
	return
