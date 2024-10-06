## Draws the unit's movement path using an autotile.
class_name UnitPath
extends TileMapLayer

@export var grid: Resource
@onready var terrain: Terrain=$"../Terrain"

var current_path := PackedVector2Array()
var astar : AStarGrid2D

## Creates a new PathFinder that uses the AStar algorithm to find a path between two cells among
## the `walkable_cells`.
func initialize(walkable_cells: Array) -> void:
	astar = AStarGrid2D.new()
	astar.region = Rect2i(Vector2.ZERO,grid.size)
	astar.cell_size = grid.cell_size
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.update()
	
	for y in grid.size.y:
		for x in grid.size.x:
			if not walkable_cells.has(Vector2(x,y)):
				astar.set_point_solid(Vector2(x,y))
				continue
			if terrain.terrain_cost(Vector2(x,y))!=1:
				astar.set_point_weight_scale(Vector2(x,y),terrain.terrain_cost(Vector2(x,y)))

## Finds and draws the path between `cell_start` and `cell_end`
func draw(cell_start: Vector2, cell_end: Vector2) -> void:
	clear()
	current_path = calculate_point_path(cell_start, cell_end)
	set_cells_terrain_connect(current_path, 0, 0)

## Stops drawing, clearing the drawn path and the `_pathfinder`.
func stop() -> void:
	astar = null
	clear()

func calculate_point_path(start: Vector2, end: Vector2) -> PackedVector2Array:
	# With an AStarGrid2D, we only need to call get_id_path to return
	#	the expected array
	return astar.get_id_path(start,end)
