## Draws a selected unit's walkable tiles.
class_name UnitOverlay
extends TileMapLayer

## Fills the tilemap with the cells, giving a visual representation of the cells a unit can walk.
func draw_move_range(cells: Array) -> void:
	clear()
	#draw movement range
	for cell in cells:
		set_cell(cell, 0, Vector2i(1,0))
	
func draw_attack_range(cells: Array)->void:
	for cell in cells:
		set_cell(cell, 0, Vector2i(3,0))
