## Finds the path between two points among walkable cells using the AStar pathfinding algorithm.
class_name PathFinder
extends Resource

const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]

var grid: Resource
var astar := AStarGrid2D.new()

## Initializes the AstarGrid2D object upon creation.
func _init(grids: Grid, walkable_cells: Array) -> void:
	grid = grids
	astar.region = Rect2i(0,0,grid.size.x,grid.size.y)
	astar.cell_size = grid.cell_size
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.update()
	# Iterate over all points on the grid and disable any which are
	#	not in the given array of walkable cells
	for y in grid.size.y:
		for x in grid.size.x:
			if not walkable_cells.has(Vector2(x,y)):
				astar.set_point_solid(Vector2(x,y))

## Returns the path found between `start` and `end` as an array of Vector2 coordinates.
func calculate_point_path(start: Vector2, end: Vector2) -> PackedVector2Array:
	# With an AStarGrid2D, we only need to call get_id_path to return
	#	the expected array
	return astar.get_id_path(start, end)
