extends Control

@onready var btnContainer: VBoxContainer = $MenuContainer/BtnContainer
@onready var atkButton: Button=$MenuContainer/BtnContainer/AttackBtn
@onready var cursor: Cursor=
var buttons: Array

func _ready() -> void:
	for child in btnContainer.get_children():
		var btn := child as Button
		if not btn:
			continue
		if btn:
			buttons.append(btn)

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

func _on_action_menu_screen_entered() -> void:
	cursor.menu_on_screen=true
	get_first_button().grab_focus()
func _on_action_menu_screen_exited() -> void:
	cursor.menu_on_screen=false


func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	pass # Replace with function body.


func _on_visible_on_screen_enabler_2d_screen_entered() -> void:
	pass # Replace with function body.
