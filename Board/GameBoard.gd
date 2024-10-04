class_name GameBoard
extends Node2D

const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]

## Resource of type Grid.
@export var grid: Resource

@onready var unit_overlay: UnitOverlay = $UnitOverlay
@onready var unit_path: UnitPath = $UnitPath
@onready var terrain: Terrain = $Terrain
@onready var turnCounter: Label = $Turn
@onready var playerTurn: Label = $PlayerTurn
@onready var cursor: Cursor = $Cursor
@onready var actionMenu: MarginContainer = $ActionMenu

## Mapping of coordinates of a cell to a reference to the unit it contains.
var units := {}
var active_unit:
	set(value):
		active_unit=value
		if value:
			active_unit_start=value.cell
var active_unit_start: Vector2
var walkable_cells := []
var attack_cells := []
var menu_on_screen := false

var action_phase=false

var turn := 1:
	set(value):
		turn = value
		turnCounter.text = "Turn: " + str(value)
		teamTurn = 1
var teamTurn := 1:
	set(value):
		teamTurn = value
		if value == 1:
			playerTurn.text = "Player Turn"
		elif value == 2:
			playerTurn.text = "Enemy Turn"
		else:
			turn+=1

func _ready() -> void:
	reinitialize()
	unit_overlay.tile_set.set_tile_size(grid.cell_size)
	unit_path.tile_set.set_tile_size(grid.cell_size)
	turnCounter.text = "Turn: " + str(turn)
	actionMenu.visible=false

func get_walkable_cells(unit: Unit)->Array:
	return walk_fill(unit.cell, unit.move_range+1)
func walk_fill(cell: Vector2, move_range: int) -> Array:
	var queue:=[cell]
	var rangeArr:=[]
	var push:=[]
	for x in range(move_range):
		var queueSize = queue.size()
		while push.size() != 0:
			queue.append(push.pop_front())
		
		for y in range(queueSize):
			var current = queue.pop_front()
			for direction in DIRECTIONS:
				var coordinates: Vector2 = current + direction
				if not grid.is_within_bounds(current) or is_occupied(coordinates):
					continue
				if coordinates in queue or coordinates in rangeArr:
					continue
				if terrain.reduce_movement(coordinates):
					push.append(coordinates)
					continue
				queue.append(coordinates)
			rangeArr.append(current)
	return rangeArr

var attackArr:=[]
func get_attackable_cells(_unit: Unit)->Array:
	return attack_fill(walkable_cells)
func attack_fill(walk: Array)->Array:
	var min_range=active_unit.min_range
	var max_range=active_unit.max_range
	
	for tile in walk:
		var arr = tiles_in_range(tile, min_range, max_range)
		var tile_pos = grid.calculate_map_position(tile)
		active_unit.raycast.global_position=tile_pos
		for i in arr:
			if wall_in_way(i, tile_pos):
				continue
			attackArr.append(i)
	return attackArr

func wall_in_way(attack_cell: Vector2, tile: Vector2)->bool:
	var ray = active_unit.raycast
	var target_pos = grid.calculate_map_position(attack_cell)-tile
	ray.target_position=target_pos
	ray.force_raycast_update()
	return ray.is_colliding()

#return attack range for a single tile
func tiles_in_range(cell: Vector2, min_range: int, max_range: int)->Array:
	var arr:=[]
	if min_range==max_range:
		return attack_in_range(cell, min_range, arr)
	for i in range(min_range, max_range+1):
		arr = attack_in_range(cell, i, arr)
	return arr

func attack_in_range(cell: Vector2, attack_range:int, arr: Array)->Array:
	var coordinates:=[]
	for x in range(attack_range):
		coordinates = [Vector2(cell.x+x, cell.y+(attack_range-x)), Vector2(cell.x+x, cell.y-(attack_range-x)),
					   Vector2(cell.x-x, cell.y+(attack_range-x)), Vector2(cell.x-x, cell.y-(attack_range-x))]
		for cord in coordinates:
			if in_arrays(cord, arr):
				continue
			arr.append(cord)
	
	coordinates = [Vector2(cell.x+attack_range, cell.y), Vector2(cell.x-attack_range, cell.y)]
	for cord in coordinates:
		if in_arrays(cord, arr):
			continue
		if cord==active_unit.cell:
			continue
		arr.append(cord)
	return arr

func in_arrays(cord: Vector2, arr: Array)->bool:
	if not grid.is_within_bounds(cord):
		return true
	if cord in walkable_cells or cord in attackArr or cord in arr:
		return true
	return false

func reinitialize() -> void:
	units.clear()
	for child in get_children():
		var unit := child as Unit
		if not unit:
			continue
		if unit:
			units[unit.cell] = unit

## Returns `true` if the cell is occupied by a unit. 
func is_occupied(cell: Vector2) -> bool:
	return units.has(cell) or terrain.can_pass(cell)

## Updates the _units dictionary with the target position for the unit and asks the _active_unit to walk to it.
func move_active_unit(new_cell: Vector2) -> void:
	if new_cell == active_unit.cell:
		deselect_active_unit()
		active_unit_action()
	if is_occupied(new_cell) or not new_cell in walkable_cells:
		return
	
	units.erase(active_unit.cell)
	units[new_cell] = active_unit
	
	deselect_active_unit()
	active_unit.walk_along(unit_path.current_path)
	await active_unit.walk_finished
	active_unit_action()

signal unit_attack(unit)
func active_unit_action():
	#start action phase
	clear_overlay()
	attack_cells=attack_fill([active_unit.cell])
	unit_overlay.draw_attack_range(attack_cells)
	action_phase=true
	
	while action_phase:
		
		actionMenu.visible=true
		
		var btn = await SignalBus.btn_pressed
		
		if btn == "WaitBtn":
			break
		if btn == "AttackBtn":
			actionMenu.visible=false
			active_unit.is_attacking=true
			
			var u = await unit_attack
			if u == Vector2(-1,-1):
				continue
			active_unit.is_attacking=false
		
		action_phase=false
	
	actionMenu.visible=false
	clear_active_unit()
	#teamTurn+=1

func active_unit_attack(attack_cell: Vector2):
	if not attack_cell in attack_cells or not units.has(attack_cell):
		return
	emit_signal("unit_attack", attack_cell)

## Selects the unit in the `cell` if there's one there.
## Sets it as the `_active_unit` and draws its walkable cells and interactive move path. 
func select_unit(cell: Vector2) -> void:
	if not units.has(cell) or not teamTurn==units[cell].team:
		return
	active_unit = units[cell]
	active_unit.is_selected = true
	draw_unit_range()

func draw_unit_range():
	walkable_cells=get_walkable_cells(active_unit)
	attack_cells=get_attackable_cells(active_unit)
	unit_overlay.draw_move_range(walkable_cells)
	unit_overlay.draw_attack_range(attack_cells)
	unit_path.initialize(walkable_cells)

## Deselects the active unit, clearing the cells overlay and interactive path drawing.
func deselect_active_unit() -> void:
	active_unit.is_selected = false
	clear_overlay()

func clear_active_unit() -> void:
	active_unit = null
	clear_overlay()
func clear_overlay():
	walkable_cells.clear()
	attack_cells.clear()
	unit_overlay.clear()
	unit_path.stop()

func _unhandled_input(event: InputEvent) -> void:
	#cancel can be pressed during moving phase or action phase
	if active_unit and event.is_action_pressed("cancel"):
		units.erase(active_unit.cell)
		units[active_unit_start] = active_unit
		active_unit.position = grid.calculate_map_position(active_unit_start)
		active_unit.cell = active_unit_start
		actionMenu.visible=false
		
		if active_unit.is_attacking:
			active_unit.is_attacking=false
			emit_signal("unit_attack", Vector2(-1,-1))
			return
		
		if active_unit.is_selected:
			clear_active_unit()
		
		SignalBus.btn_pressed.emit("cancel")

func _on_cursor_accept_pressed(cell: Vector2) -> void:
	if not active_unit:
		select_unit(cell)
	elif active_unit.is_attacking:
		active_unit_attack(cell)
	elif active_unit.is_selected:
		move_active_unit(cell)

func _on_cursor_moved(new_cell: Vector2) -> void:
	if active_unit and active_unit.is_selected:
		unit_path.draw(active_unit.cell, new_cell)

func _on_visible_on_screen_enabler_2d_screen_entered() -> void:
	menu_on_screen=true
	cursor.menu_on_screen=true
	actionMenu.get_first_button().grab_focus()

func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	menu_on_screen=false
	cursor.menu_on_screen=false
