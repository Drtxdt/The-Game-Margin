@tool
extends Node2D
@export_enum("ground","restoration","foreground") var layer = "ground"
var time = 0.0
var shelf: Texture2D = preload("res://assets/art/library_shelf.png")
var wood: Texture2D = preload("res://assets/art/library_desk.png")

func _process(delta: float) -> void:
	time+=delta
	queue_redraw()

func _draw() -> void:
	if layer=="ground":
		draw_rect(Rect2(0,620,1920,250),Color("242725"))
		draw_texture_rect_region(wood,Rect2(0,620,1920,9),Rect2(30,309,1820,25),Color("c5b28e"))
		draw_line(Vector2(0,621),Vector2(1920,621),Color("c5ac7c"),2,true)
		for row in range(7):
			var y=632+row*28
			draw_texture_rect_region(wood,Rect2(0,y,1920,26),Rect2(260,355,450,50),Color(0.23,0.27,0.26,1))
			draw_line(Vector2(0,y),Vector2(1920,y),Color("101e21"),3,true)
			for x in range(0,1920,180):
				var start=x+(row%2)*90
				draw_line(Vector2(start,y),Vector2(start,y+27),Color("283335"),2)
				for grain in range(3):
					draw_line(Vector2(start+13,y+6+grain*5),Vector2(start+120+(grain*17)%40,y+5+grain*5),Color(0.52,0.43,0.30,0.12),1,true)
	elif layer=="restoration":
		var books: Array=[] if Engine.is_editor_hint() else State.data.bound
		for n in range(3):
			var id=["math","language","archive"][n]
			var x=860+n*155
			draw_texture_rect_region(shelf,Rect2(x,550,106,70),Rect2(8,132,1350,884))
			if id not in books:
				for y in [560,589]: draw_rect(Rect2(x+7,y,92,23),Color("302e25"))
			else:
				for radius in [48,32,18]: draw_circle(Vector2(x+53,545),radius,Color(0.98,0.77,0.39,0.035))
				draw_rect(Rect2(x+49,543,8,7),Color("8c6b3e"))
				draw_circle(Vector2(x+53,541),4,Color("f0cc7d"))
	else:
		for x in [35,1875]:
			draw_rect(Rect2(x,80,14,540),Color("24332f"))
			draw_line(Vector2(x+14,80),Vector2(x+14,620),Color("6f6951"),2,true)
