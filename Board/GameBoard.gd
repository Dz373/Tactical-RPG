class_name GameBoard
extends Node2D

const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]

@export var grid: Resource

@onready var unit_overlay: UnitOverlay = $UnitOverlay
@onready var unit_path: UnitPath = $UnitPath
@onready var terrain: Terrain = $Terrain
@onready var cursor: Cursor = $Cursor
@onready var turnCounter: Label = $CanvasLayer/Turn
@onready var actionMenu: MarginContainer = $CanvasLayer/ActionMenu
@onready var statMenu: MarginContainer=$CanvasLayer/UnitStats

var units := {}
var player_units :=[]
var enemy_units :=[]
var active_unit: Unit
var active_unit_start: Vector2
var walkable_cells := []
var attack_cells := []
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
	cursor.cell=player_units[0].cell

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
			unit.end_turn=false
		elif unit.team==2:
			enemy_units.append(unit)

func _process(_delta: float) -> void:
	if player_units.size()==0:
		print("enemy win")
		set_process(false)
	elif enemy_units.size()==0:
		print("player win")
		set_process(false)
	elif finish_turn():
		enemy_turn()
		turn+=1
		reinitialize()

func finish_turn()->bool:
	for unit in player_units:
		if not unit.end_turn:
			return false
	return true

var move_cost:={}
func get_walkable_cells(unit: Unit)->Array:
	move_cost.clear()
	var arr:=[]
	walk_fill(unit.cell, unit.stats.mv_range, arr)
	return arr
func walk_fill(cell: Vector2, move_range: int, arr: Array):
	if not cell in arr:
		arr.append(cell)
	move_cost[cell]=move_range
	for dir in DIRECTIONS:
		var coord = cell+dir
		if not grid.is_within_bounds(coord) or is_occupied(coord):
			continue
		var new_range = move_range-terrain.cost(coord)
		if active_unit.stats.ign_tile:
			new_range=move_range-1
		if new_range < 0:
			continue
		if not move_cost.has(coord):
			walk_fill(coord, new_range, arr)
		elif new_range > move_cost[coord]:
			move_cost[coord]=new_range
			walk_fill(coord, new_range, arr)

func get_attackable_cells(walk: Array)->Array:
	var min_range=active_unit.stats.atk_range_min
	var max_range=active_unit.stats.atk_range_max
	var attackArr=[]
	for tile in walk:
		var arr = tiles_in_range(tile, min_range, max_range, attackArr)
		#var tile_pos = grid.calculate_map_position(tile)
		for i in arr:
			#if wall_in_way(i, tile_pos):
				#continue
			attackArr.append(i)
	return attackArr
func wall_in_way(attack_cell: Vector2, current_cell: Vector2)->bool:
	var ray = active_unit.raycast
	var target_pos = grid.calculate_map_position(attack_cell)-current_cell
	ray.global_position=current_cell
	ray.target_position=target_pos
	ray.force_raycast_update()
	return ray.is_colliding()
func tiles_in_range(cell: Vector2, min_range: int, max_range: int, attackArr:Array)->Array:
	var atk_in_range:=[]
	if min_range==max_range:
		return attack_in_range(cell, min_range, atk_in_range, attackArr)
	for i in range(min_range, max_range+1):
		atk_in_range = attack_in_range(cell, i, atk_in_range, attackArr)
	return atk_in_range
func attack_in_range(cell: Vector2, attack_range:int, atk_in_range:Array,attackArr:Array)->Array:
	var coordinates:=[]
	for x in range(attack_range):
		coordinates = [Vector2(cell.x+x, cell.y+(attack_range-x)), Vector2(cell.x+x, cell.y-(attack_range-x)),
					   Vector2(cell.x-x, cell.y+(attack_range-x)), Vector2(cell.x-x, cell.y-(attack_range-x))]
		for cord in coordinates:
			if not grid.is_within_bounds(cord):
				continue
			if cord==active_unit.cell or cord in attackArr or cord in atk_in_range:
				continue
			atk_in_range.append(cord)
	
	coordinates = [Vector2(cell.x+attack_range, cell.y), Vector2(cell.x-attack_range, cell.y)]
	for cord in coordinates:
		if not grid.is_within_bounds(cord):
			continue
		if cord==active_unit.cell or cord in attackArr or cord in atk_in_range:
			continue
		atk_in_range.append(cord)
	return atk_in_range

## Returns `true` if the cell is occupied by a unit. 
func is_occupied(cell: Vector2) -> bool:
	if cell==active_unit.cell:
		return false
	if units.has(cell) and units[cell].team!=active_unit.team:
		return true
	if active_unit.stats.ign_tile:
		return false
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
	
	cursor.menu_on_screen=true
	active_unit.walk_along(unit_path.current_path)
	await active_unit.walk_finished
	active_unit_action()

## Selects the unit in the `cell` if there's one there.
## Sets it as the `_active_unit` and draws its walkable cells and interactive move path. 
func select_unit(cell: Vector2) -> void:
	if not units.has(cell) or not units[cell].team==1:
		return
	if units[cell].end_turn:
		return
	active_unit = units[cell]
	active_unit_start=cell
	active_unit.is_selected = true
	draw_unit_range()

func draw_unit_range():
	walkable_cells=get_walkable_cells(active_unit)
	attack_cells=get_attackable_cells(walkable_cells)
	unit_overlay.draw_attack_range(attack_cells)
	unit_overlay.draw_move_range(walkable_cells)
	unit_path.initialize(walkable_cells,1, active_unit)

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
	if event.is_action_pressed("QUIT"):
		get_tree().quit()
	
	elif event.is_action_pressed("stats"):
		if cursor.cell in units:
			if statMenu.unit and statMenu.unit==units[cursor.cell]:
				statMenu.visible=false
				statMenu.unit=null
			else:
				statMenu.unit=units[cursor.cell]
				statMenu.showMenu()
		else: 
			statMenu.visible=false
			statMenu.unit=null
	
	elif active_unit and event.is_action_pressed("cancel"):
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

signal unit_attack(unit)
func active_unit_action():
	clear_overlay()
	attack_cells=get_attackable_cells([active_unit.cell])
	for unit in enemy_units:
		if unit.cell in attack_cells:
			actionMenu.atkButton.visible=true
			break
	unit_overlay.draw_attack_range(attack_cells)
	action_phase=true
	while action_phase:
		actionMenu.visible=true
		cursor.menu_on_screen=true
		var btn = await SignalBus.btn_pressed
		actionMenu.visible=false
		cursor.menu_on_screen=false
		if btn == "cancel":
			action_phase=false
			break
		if btn == "WaitBtn":
			active_unit.end_turn = true
			action_phase=false
			break
		elif btn == "AttackBtn":
			active_unit.is_attacking=true
			cursor.visible=true
			var attack_target = await unit_attack
			if attack_target == Vector2(-1,-1):#cancel attack
				continue
			var target_unit = units[attack_target]
			target_unit.hp -= calc_damage(target_unit, active_unit)
			active_unit.is_attacking=false
		
		action_phase=false
		active_unit.end_turn = true
	cursor.visible=true
	actionMenu.atkButton.visible=false
	clear_active_unit()
func active_unit_attack(attack_cell: Vector2):
	if not attack_cell in attack_cells or not units.has(attack_cell):
		return
	if units[attack_cell].team==1:
		return
	emit_signal("unit_attack", attack_cell)

func calc_damage(target_unit:Unit, attaking_unit:Unit)->int:
	if target_unit.stats.def > attaking_unit.stats.atk:
		return 0
	return (attaking_unit.stats.atk-target_unit.stats.def)

func enemy_turn():
	teamTurn=2
	for unit in enemy_units:
		active_unit=unit
		var mv_range=get_walkable_cells(unit)
		var atk_range=get_attackable_cells(mv_range)
		var target=find_target_unit(unit, atk_range,mv_range)
		var move_point = find_move_point(target, mv_range)
		
		unit.walk_along(unit_path.calculate_point_path(unit.cell,move_point))
		await unit.walk_finished
		
		if unit.is_attacking:
			target.hp-=calc_damage(target,unit)
			unit.is_attacking=false
		
		if player_units.size()==0:
			return
		unit_path.stop()
		active_unit=null

func find_target_unit(current_unit:Unit, atk_range:Array, mv_range:Array)->Unit:
	unit_path.initialize(mv_range, 2, active_unit)
	var closest_unit = get_closest_unit(current_unit)
	if closest_unit.cell in atk_range:
		var targets_in_range = get_targets_in_range(mv_range)
		for unit in targets_in_range:
			if not closest_unit in targets_in_range:
				closest_unit=unit
			if calc_damage(closest_unit, active_unit) < calc_damage(unit, active_unit):
				closest_unit=unit
			if not active_unit.is_attacking:
				active_unit.is_attacking=true
	return closest_unit
func find_move_point(target:Unit, mv_range:Array)->Vector2:
	unit_path.astar.set_point_solid(target.cell, false)
	var move_point = active_unit.cell
	var cost = unit_path.calculate_path_cost(active_unit.cell,target.cell)
	for tile in mv_range:
		if units.has(tile):
			continue
		var point_cost=unit_path.calculate_path_cost(tile,target.cell)
		if point_cost<cost:
			cost=point_cost
			move_point=tile
	units.erase(active_unit.cell)
	units[move_point] = active_unit
	unit_path.astar.set_point_solid(target.cell)
	return move_point
func get_targets_in_range(mv_range:Array):
	var targets_in_range=[]
	for unit in player_units:
		var atk_arr=get_attack_tiles(unit, mv_range)
		for tile in atk_arr:
			if tile in mv_range:
				targets_in_range.append(unit)
				break
	return targets_in_range
func get_attack_tiles(target:Unit, mv_range:Array)->Array:
	var arr=[]
	for tile in mv_range:
		if units.has(tile) and not active_unit.cell==tile:
			continue
		var atk=get_attackable_cells([tile])
		for atk_tile in atk:
			if target.cell == atk_tile:
				arr.append(tile)
				break
	return arr
func get_closest_unit(current:Unit)->Unit:
	var closest_unit = player_units[0]
	var close_dis = unit_path.calculate_path_cost(closest_unit.cell, current.cell)
	for unit in player_units:
		var distance=unit_path.calculate_path_cost(unit.cell, current.cell)
		if  distance < close_dis:
			closest_unit=unit
			close_dis=distance
	return closest_unit
	
