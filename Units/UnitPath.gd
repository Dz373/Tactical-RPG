## Draws the unit's movement path using an autotile.
class_name UnitPath
extends TileMapLayer

@export var grid: Resource

var pathfinder: PathFinder
var current_path := PackedVector2Array()

## Creates a new PathFinder that uses the AStar algorithm to find a path between two cells among
## the `walkable_cells`.
func initialize(walkable_cells: Array) -> void:
	pathfinder = PathFinder.new(grid, walkable_cells)
	


## Finds and draws the path between `cell_start` and `cell_end`
func draw(cell_start: Vector2, cell_end: Vector2) -> void:
	clear()
	current_path = pathfinder.calculate_point_path(cell_start, cell_end)
	set_cells_terrain_connect(current_path, 0, 0)


## Stops drawing, clearing the drawn path and the `_pathfinder`.
func stop() -> void:
	pathfinder = null
	clear()
