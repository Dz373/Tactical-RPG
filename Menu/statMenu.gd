extends MarginContainer

var unit

func showMenu():
	visible=true
	var stat_arr = $Container/Stats/Stat1.get_children()
	stat_arr.append_array($Container/Stats/Stat2.get_children())
	
	$Container/Name.text="Class: "+unit.class_type
	for lab in stat_arr:
		lab.text=lab.name+": "+unit.get_stat(lab.name)
