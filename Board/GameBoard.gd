class_name GameBoard
extends Node2D

const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]

## Resource of type Grid.
@export var grid: Resource

@onready var unit_overlay: UnitOverlay = $UnitOverlay
@onready var unit_path: UnitPath = $UnitPath
@onready var terrain: Terrain = $Terrain
@onready var turnCounter: Label = $Turn
@onready var cursor: Cursor = $Cursor
@onready var actionMenu: MarginContainer = $ActionMenu

## Mapping of coordinates of a cell to a reference to the unit it contains.
var units := {}
var player_units :=[]
var enemy_units :=[]
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
var teamTurn := 1

func _ready() -> void:
	reinitialize()
	unit_overlay.tile_set.set_tile_size(grid.cell_size)
	unit_path.tile_set.set_tile_size(grid.cell_size)
	turnCounter.text = "Turn: " + str(turn)
	actionMenu.visible=false

func reinitialize() -> void:
	units.clear()
	player_units.clear()
	enemy_units.clear()
	for child in get_children():
		var unit := child as Unit
		if not unit:
			continue
		if unit:
			units[unit.cell] = unit
		if unit.team==1:
			player_units.append(unit)
		elif unit.team==2:
			enemy_units.append(unit)
		unit.end_turn=false

func _process(_delta: float) -> void:
	if finish_turn():
		enemy_turn()
		turn+=1
		reinitialize()

func finish_turn()->bool:
	for unit in player_units:
		if not unit.end_turn:
			return false
	return true

var range_track:={}
func get_walkable_cells(unit: Unit)->Array:
	range_track.clear()
	var arr:=[]
	walk_fill(unit.cell, unit.move_range, arr)
	return arr
func walk_fill(cell: Vector2, move_range: int, arr: Array):
	if not cell in arr:
		arr.append(cell)
	range_track[cell]=move_range
	for dir in DIRECTIONS:
		var coord = cell+dir
		if not grid.is_within_bounds(coord) or is_occupied(coord):
			continue
		var new_range = move_range-terrain.terrain_cost(coord)
		if new_range < 0:
			continue
		if not range_track.has(coord):
			walk_fill(coord, new_range, arr)
		elif new_range > range_track[coord]:
			range_track[coord]=new_range
			walk_fill(coord, new_range, arr)

var attackArr:=[]
func get_attackable_cells(walk:Array)->Array:
	attackArr.clear()
	return attack_fill(walk)
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
			if not grid.is_within_bounds(cord):
				continue
			if cord==active_unit.cell or cord in attackArr or cord in arr:
				continue
			arr.append(cord)
	
	coordinates = [Vector2(cell.x+attack_range, cell.y), Vector2(cell.x-attack_range, cell.y)]
	for cord in coordinates:
		if not grid.is_within_bounds(cord):
			continue
		if cord==active_unit.cell or cord in attackArr or cord in arr:
			continue
		arr.append(cord)
	return arr

## Returns `true` if the cell is occupied by a unit. 
func is_occupied(cell: Vector2) -> bool:
	if cell==active_unit.cell:
		return false
	if units.has(cell) and units[cell].team!=active_unit.team:
		return true
	return not terrain.can_pass(cell)

## Updates the _units dictionary with the target position for the unit and asks the _active_unit to walk to it.
func move_active_unit(new_cell: Vector2) -> void:
	if new_cell == active_unit.cell:
		deselect_active_unit()
		active_unit_action()
	if is_occupied(new_cell) or not new_cell in walkable_cells:
		return
	if units.has(new_cell) and player_units.has(units[new_cell]):
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
		actionMenu.visible=false
		if btn == "cancel":
			action_phase=false
			break
		if btn == "WaitBtn":
			active_unit.end_turn = true
			action_phase=false
			break
		elif btn == "AttackBtn":
			active_unit.is_attacking=true
			var attack_target = await unit_attack
			if attack_target == Vector2(-1,-1):
				continue
			var target_unit = units[attack_target]
			target_unit.hp -= calc_damage(target_unit, active_unit)
			active_unit.is_attacking=false
		
		action_phase=false
		active_unit.end_turn = true
		
	clear_active_unit()

func active_unit_attack(attack_cell: Vector2):
	if not attack_cell in attack_cells or not units.has(attack_cell):
		return
	if units[attack_cell].team==1:
		return
	emit_signal("unit_attack", attack_cell)

func calc_damage(target_unit:Unit, attaking_unit:Unit)->int:
	if target_unit.def > attaking_unit.atk:
		return 0
	return (attaking_unit.atk-target_unit.def)

## Selects the unit in the `cell` if there's one there.
## Sets it as the `_active_unit` and draws its walkable cells and interactive move path. 
func select_unit(cell: Vector2) -> void:
	if not units.has(cell) or not units[cell].team==1:
		return
	if units[cell].end_turn:
		return
	active_unit = units[cell]
	active_unit.is_selected = true
	active_unit.end_turn = false
	draw_unit_range()

func draw_unit_range():
	walkable_cells=get_walkable_cells(active_unit)
	attack_cells=get_attackable_cells(walkable_cells)
	unit_overlay.draw_attack_range(attack_cells)
	unit_overlay.draw_move_range(walkable_cells)
	unit_path.initialize(walkable_cells,1)

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
	if active_unit and event.is_action_pressed("cancel"):
		#cancel after selecting unit
		if active_unit.is_selected:
			deselect_active_unit()
			clear_active_unit()
		
		#cancel after selecting menu
		elif active_unit.is_attacking:
			active_unit.is_attacking=false
			emit_signal("unit_attack", Vector2(-1,-1))
		
		#cancel after moving unit with menu open
		elif action_phase:
			units.erase(active_unit.cell)
			units[active_unit_start] = active_unit
			active_unit.position = grid.calculate_map_position(active_unit_start)
			active_unit.cell = active_unit_start
			SignalBus.btn_pressed.emit("cancel")

func _on_cursor_accept_pressed(cell: Vector2) -> void:
	if not active_unit:
		select_unit(cell)
	elif active_unit.is_selected:
		move_active_unit(cell)
	elif active_unit.is_attacking:
		active_unit_attack(cell)
	else:
		print("press error")

func _on_cursor_moved(new_cell: Vector2) -> void:
	if active_unit and active_unit.is_selected:
		unit_path.draw(active_unit.cell, new_cell)

func _on_visible_on_screen_enabler_2d_screen_entered() -> void:
	menu_on_screen=true
	cursor.menu_on_screen=true
	cursor.position = active_unit.position
	actionMenu.get_first_button().grab_focus()

func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	menu_on_screen=false
	cursor.menu_on_screen=false

func enemy_turn():
	teamTurn=2
	for unit in enemy_units:
		active_unit=unit
		var mv_range=get_walkable_cells(unit)
		var atk_range=get_attackable_cells(mv_range)
		
		unit_path.initialize(mv_range, 2)
		var target=find_target_unit(unit, atk_range)
		
		unit_path.astar.set_point_solid(target.cell, false)
		var move_point = find_move_point(target.cell, mv_range,atk_range)
		unit_path.astar.set_point_solid(target.cell)
		
		active_unit.walk_along(unit_path.calculate_point_path(unit.cell,move_point))
		await active_unit.walk_finished
		
		units.erase(active_unit.cell)
		units[move_point] = active_unit
		
		unit_path.stop()
		active_unit=null

func find_target_unit(current_unit:Unit, unit_range:Array)->Unit:
	var closest_unit = player_units[0]
	var close_dis = unit_path.calculate_path_cost(closest_unit.cell, current_unit.cell)
	var close_arr = []
	for unit in player_units:
		var distance=unit_path.calculate_path_cost(unit.cell, current_unit.cell)
		if  distance < close_dis:
			closest_unit=unit
			close_dis=distance
		if unit.cell in unit_range:
			close_arr.append(unit)
	for unit in close_arr:
		if calc_damage(closest_unit, active_unit) < calc_damage(unit, active_unit):
			closest_unit=unit
	return closest_unit

func find_move_point(target:Vector2, mv_range:Array,atk_range:Array)->Vector2:
	var move_point = active_unit.cell
	var cost = unit_path.calculate_path_cost(active_unit.cell,target)
	var atk_tiles=[]
	
	if target in atk_range:
		for tile in mv_range:
			var atk=get_attackable_cells([tile])
			if target in atk:
				if not units.has(tile) or tile==active_unit.cell:
					atk_tiles.append(tile)
			if units.has(tile):
				continue
			var point_cost=unit_path.calculate_path_cost(tile,target)
			if point_cost<cost:
				cost=point_cost
				move_point=tile
		if atk_tiles.size()==0:
			var old_target=units[target]
			player_units.erase(units[target])
			var new_target=find_target_unit(active_unit,mv_range)
			player_units.append(old_target)
			return find_move_point(new_target.cell,mv_range,atk_range)
	else:
		for tile in mv_range:
			if units.has(tile):
				continue
			var point_cost=unit_path.calculate_path_cost(tile,target)
			if point_cost<cost:
				cost=point_cost
				move_point=tile
	
	return move_point
