extends Camera2D
class_name Camera

@onready var grid = get_parent().grid

func _ready() -> void:
	limit_right=grid.size.x * grid.cell_size.x
	limit_bottom=grid.size.y * grid.cell_size.y

func get_mouse_pos():
	return grid.calculate_grid_coordinates(get_local_mouse_position()+grid.half_size)
