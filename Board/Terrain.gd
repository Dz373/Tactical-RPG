class_name Terrain
extends TileMapLayer

@export var grid: Resource

@onready var obstacles: Obstacle=$Obstacle

func can_pass(cell: Vector2):
	return not obstacles.get_cell_source_id(cell)==-1

func reduce_movement(cell: Vector2)->bool:
	if get_cell_source_id(cell) == 1:
		return true
	return false

func is_wall(cell: Vector2)->bool:
	return obstacles.get_cell_source_id(cell)==0

func terrain_cost(cell: Vector2)->int:
	return get_cell_source_id(cell)+1
