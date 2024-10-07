@tool
class_name Unit
extends Path2D

## Emitted when the unit reached the end of a path along which it was walking.
signal walk_finished
## Shared resource of type Grid, used to calculate map coordinates.
@export var grid: Resource
## Distance to which the unit can walk in cells.
@export var move_range := 6
## The unit's move speed when it's moving along a path.
@export var move_speed := 1
@export var min_range:= 1
@export var max_range:= 1
@export var team := 1

@export var stats: Resource
@export var class_type: Resource

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision: CharacterBody2D=$CharacterBody2D2
@onready var raycast: RayCast2D=$RayCast2D
@onready var _path_follow: PathFollow2D = $PathFollow2D

var cell := Vector2.ZERO:
	set(value):
		cell = grid.grid_clamp(value)
var is_selected := false:
	set(value):
		is_selected = value
var _is_walking := false:
	set(value):
		_is_walking = value
		set_process(_is_walking)
var is_attacking=false
var end_turn=false:
	set(value):
		end_turn=value
		if value:
			print(str(name)+" end turn")

var hp:
	set(value):
		if value <= 0:
			print(str(name) + " defeated")
			get_parent().units.erase(cell)
			if team==1:
				get_parent().player_units.erase(self)
			elif team==2:
				get_parent().enemy_units.erase(self)
			queue_free()
		hp = value
var atk
var def

func _ready() -> void:
	set_process(false)
	_path_follow.rotates=false
	cell = grid.calculate_grid_coordinates(position)
	position = grid.calculate_map_position(cell)
	set_stat()
	set_class()
	if not Engine.is_editor_hint():
		curve = Curve2D.new()

func set_stat():
	hp = stats.hp
	atk = stats.attack
	def = stats.defense

func set_class():
	pass

var previousProgress=0
var previousPosition=Vector2(0,0)
func _process(_delta: float) -> void:
	_path_follow.progress += move_speed
	
	if _path_follow.position.y > previousPosition.y:
		animation_player.play("walk-down")
	if _path_follow.position.y < previousPosition.y:
		animation_player.play("walk-up")
	if _path_follow.position.x > previousPosition.x:
		animation_player.play("walk-right")
	if _path_follow.position.x < previousPosition.x:
		animation_player.play("walk-left")
	
	if previousProgress > _path_follow.progress:
		_is_walking = false
		# Setting this value to 0.0 causes a Zero Length Interval error
		_path_follow.progress = 0.00001
		position = grid.calculate_map_position(cell)
		curve.clear_points()
		animation_player.play("idle")
		emit_signal("walk_finished")
	
	previousProgress = _path_follow.progress
	previousPosition = _path_follow.position

## Starts walking along the `path`.
## `path` is an array of grid coordinates that the function converts to map coordinates.
func walk_along(path: PackedVector2Array) -> void:
	if path.is_empty():
		return
	
	curve.add_point(Vector2.ZERO)
	for point in path:
		curve.add_point(grid.calculate_map_position(point) - position)
	cell = path[-1]
	_is_walking = true
