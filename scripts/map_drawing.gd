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
		var parcels=0
		var echoes=0
		for death in State.data.deaths:
			if death.room!=id: continue
			if not death.books.is_empty(): parcels+=1
			if not death.recovered: echoes+=1
		if parcels>0: draw_string(font,p+Vector2(4,49),"▣ %d" % parcels,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("f4ce8d"))
		if echoes>0: draw_string(font,p+Vector2(49,49),"◇ %d" % echoes,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("9fddc9"))
		if id==State.data.checkpoint: draw_circle(p+Vector2(103,8),4,Color("edcc8b"))
		for exit in RoomCatalog.exits():
			if exit.room!=id or exit.id not in State.data.discovered_exits: continue
			var direction: Vector2=(RoomCatalog.ROOMS[exit.target][2]-RoomCatalog.ROOMS[id][2]).normalized()
			var port=p+Vector2(56,26)+direction*Vector2(57,28)
			var locked=exit.requirement!="" and not State.has_flag(exit.requirement)
			draw_circle(port,4,Color("c08e73") if locked else Color("aad5bd"))
			if locked: draw_line(port-Vector2(3,3),port+Vector2(3,3),Color("f5dfc0"),1.5,true)
		if id=="hall" and State.has_flag("hall_stairs_open"):
			draw_string(font,p+Vector2(4,13),"↗",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("e7c781"))
		if id==world.room_id:
			var px=p.x+clampf(world.player.position.x/RoomCatalog.width_for(id),0,1)*112
			draw_colored_polygon(PackedVector2Array([Vector2(px-4,p.y-8),Vector2(px+4,p.y-8),Vector2(px,p.y-2)]),Color("f1dfad"))
