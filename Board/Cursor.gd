class_name Cursor
extends Node2D

signal accept_pressed(cell)
signal moved(new_cell)

@export var grid: Resource

@onready var camera : Camera = $Camera

var menu_on_screen := false:
	set(value):
		if value:
			visible=false
		else:
			visible=true
		menu_on_screen=value

var cell := Vector2.ZERO:
	set(value):
		var new_cell: Vector2 = grid.grid_clamp(value)
		if new_cell.is_equal_approx(cell):
			return
		cell = new_cell
		position = grid.calculate_map_position(cell)	
		emit_signal("moved", cell)

func _ready() -> void:
	set_process(false)
	
func _process(_delta: float) -> void:
	
	cell += camera.get_mouse_pos()
	
func _unhandled_input(event: InputEvent):
	if menu_on_screen:
		return
	if event is InputEventMouseMotion:
		if event.position.x > 576 or event.position.x < 64:
			set_process(true)
		elif event.position.y > 576 or event.position.y < 64:
			set_process(true)
		else:
			set_process(false)
		cell += camera.get_mouse_pos()
	
	elif event.is_action_pressed("confirm"):
		emit_signal("accept_pressed", cell)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cell"):
		print(position)
	
	var should_move := event.is_pressed() 
	if event.is_echo():
		should_move = should_move
	if not should_move:
		return
	
	if event.is_action("right"):
		cell += Vector2.RIGHT
	if event.is_action("left"):
		cell += Vector2.LEFT
	if event.is_action("up"):
		cell += Vector2.UP
	if event.is_action("down"):
		cell += Vector2.DOWN
