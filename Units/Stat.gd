class_name classStat
extends Resource

@export var name:String

@export var hp := 5
@export var atk := 5
@export var mag := 3
@export var def := 2
@export var res := 0
@export var skl := 2
@export var spd := 5
@export var lck := 3

@export var mv_range:=7
@export var atk_range_min:=1
@export var atk_range_max:=1

@export var wep_num:=1
@export var acc_num:=1
@export var itm_num:=1

##ignore walls in line of sight
@export var ign_wall:=false
##ignore movement cost of tiles
@export var ign_tile:=false

@export var classification:Classification

@export var texture:Texture2D
