class_name Terrain
extends TileMapLayer

@export var grid: Resource

@onready var obstacles: Obstacle=$Obstacle

func can_pass(cell: Vector2):
	return not obstacles.can_block(cell)

func terrain_cost(cell: Vector2)->int:
	return get_cell_tile_data(cell).get_custom_data("cost")
