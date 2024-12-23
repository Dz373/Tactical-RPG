class_name Unit
extends Path2D

signal walk_finished

@export var grid: Resource

@export var team := 1
var move_speed = 5

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite:Sprite2D=$PathFollow2D/Sprite2D
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
var stats:classStat
var lvl=1
var hp:int:
	set(value):
		if value==stats.hp:
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

func _ready() -> void:
	set_process(false)
	_path_follow.rotates=false
	cell = grid.calculate_grid_coordinates(position)
	position = grid.calculate_map_position(cell)
	
	stats=ClassStats.classes[class_type]
	hp = stats.hp
	hp_bar.max_value=stats.hp
	set_sprite()
	
	if not Engine.is_editor_hint():
		curve = Curve2D.new()

func set_sprite()->void:
	sprite.texture=stats.texture
	sprite.vframes=stats.texture.get_height()/grid.cell_size.x
	sprite.hframes=stats.texture.get_width()/grid.cell_size.y

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
	
func get_stat(stat: String):
	match stat:
		"Hp":
			return " "+str(hp)
		"Atk":
			return str(stats.atk)
		"Mag":
			return str(stats.mag)
		"Def":
			return str(stats.def)
		"Res":
			return str(stats.res)
		"Skl":
			return str(stats.skl)
		"Spd":
			return str(stats.spd)
		"Lck":
			return str(stats.lck)
		"Mov":
			return str(stats.mv_range)
		"Rng":
			if stats.atk_range_min==stats.atk_range_max:
				return str(stats.atk_range_min)
			return str(stats.atk_range_min)+"-"+str(stats.atk_range_max)
