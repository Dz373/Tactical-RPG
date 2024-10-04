extends Button

func _on_mouse_entered() -> void:
	grab_focus()

func _on_pressed() -> void:
	SignalBus.btn_pressed.emit(name)
