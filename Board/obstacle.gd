class_name Obstacle
extends TileMapLayer

func can_block(cell:Vector2):
	if get_cell_source_id(cell)==-1:
		return false
	return get_cell_tile_data(cell).get_custom_data("block")
