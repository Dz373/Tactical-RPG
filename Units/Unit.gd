class_name Unit
extends Path2D

signal walk_finished

@export var grid: Resource

@export var team := 1
var move_speed = 5

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision: CharacterBody2D=$CharacterBody2D2
@onready var raycast: RayCast2D=$RayCast2D
@onready var _path_follow: PathFollow2D = $PathFollow2D
@onready var hp_bar: TextureProgressBar=$PathFollow2D/TextureProgressBar

var cell := Vector2.ZERO:
	set(value):
		cell = grid.grid_clamp(value)
var is_selected = false
var _is_walking := false:
	set(value):
		_is_walking = value
		set_process(_is_walking)
var is_attacking=false
var end_turn=false

@export var class_type:String
var class_stat
var lvl=1
var hp:int:
	set(value):
		if value==class_stat.hp:
			hp_bar.visible=false
		else:
			hp_bar.visible=true
		if value <= 0:
			print(str(name) + " defeated")
			get_parent().units.erase(cell)
			if team==1:
				get_parent().player_units.erase(self)
			elif team==2:
				get_parent().enemy_units.erase(self)
			queue_free()
		hp = value
		hp_bar.value=value

var weapons:=[]
var accessories:=[]
var consumables:=[]
var skills:=[]
var flying:=false

func _ready() -> void:
	set_process(false)
	_path_follow.rotates=false
	cell = grid.calculate_grid_coordinates(position)
	position = grid.calculate_map_position(cell)
	
	class_stat=ClassStats.classes[class_type]
	hp = class_stat.hp
	
	if not Engine.is_editor_hint():
		curve = Curve2D.new()

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
	
	if previousProgress >= _path_follow.progress:
		_is_walking = false
		_path_follow.progress = 0.00001
		position = grid.calculate_map_position(cell)
		curve.clear_points()
		animation_player.play("idle")
		emit_signal("walk_finished")
	
	previousProgress = _path_follow.progress
	previousPosition = _path_follow.position

func walk_along(path: PackedVector2Array) -> void:
	if path.is_empty():
		return
	curve.add_point(Vector2.ZERO)
	for point in path:
		curve.add_point(grid.calculate_map_position(point) - position)
	cell = path[-1]
	_is_walking = true
	
