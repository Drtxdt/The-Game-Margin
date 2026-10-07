extends Control

func _draw() -> void:
	var world=get_tree().get_first_node_in_group("world")
	if world==null:
		return
	var font=preload("res://resources/chinese_font.tres")
	for link in RoomCatalog.LINKS:
		if link[0] in State.data.visited and link[1] in State.data.visited:
			var a: Vector2=RoomCatalog.ROOMS[link[0]][2]*Vector2(150,95)+Vector2(66,38)
			var b: Vector2=RoomCatalog.ROOMS[link[1]][2]*Vector2(150,95)+Vector2(66,38)
			draw_line(a,b,Color("668780"),2,true)
	for id in RoomCatalog.ROOMS:
		if id not in State.data.visited:
			continue
		var p: Vector2=RoomCatalog.ROOMS[id][2]*Vector2(150,95)+Vector2(10,12)
		draw_rect(Rect2(p,Vector2(112,52)),Color("607a69") if id==world.room_id else Color("263f43"))
		draw_rect(Rect2(p,Vector2(112,52)),Color("bbbd95"),false,1)
		draw_string(font,p+Vector2(10,33),RoomCatalog.ROOMS[id][0],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("e3dcc3"))
