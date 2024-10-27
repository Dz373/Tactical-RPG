extends Node

var classes:={}
const path = "res://Units/Stats/"

func _init() -> void:
	var dir = DirAccess.open(path)
	if dir:
		var file_list = dir.get_files()
		for file in file_list:
			var file_path = path + "/" + file
			var stat = load(file_path)
			classes[stat.name]=stat
	else:
		print("An error occurred when trying to access the path.")
	
