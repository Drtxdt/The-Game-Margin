@tool
extends Node2D

@export var room_id = "hall"
@export var width = 3200.0
var time = 0.0

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	var underground = room_id in ["research","archive","maintenance"]
	var outdoors = room_id in ["gate","courtyard","bell","tower"]
	var base = Color("172f38") if underground else Color("294342")
	if outdoors:
		base=Color("344c55")
	draw_rect(Rect2(0,-700,width,1420),base)
	if room_id=="library":
		return
	for i in range(int(width/230)+1):
		var x = float(i)*230
		if outdoors:
			draw_rect(Rect2(x,-20,180,600),Color("223b43"))
			for row in range(4):
				draw_rect(Rect2(x+24,32+row*118,42,73),Color("476069"))
				draw_rect(Rect2(x+100,32+row*118,42,73),Color("476069"))
		else:
			draw_rect(Rect2(x+36,70,140,270),Color("132e36"))
			draw_rect(Rect2(x+41,75,130,260),Color("3b5557") if not underground else Color("243e47"))
			for bar in range(3):
				draw_line(Vector2(x+40,140+bar*65),Vector2(x+172,140+bar*65),Color("192e32"),5,true)
			draw_line(Vector2(x+105,75),Vector2(x+105,335),Color("1a3035"),6,true)
			draw_rect(Rect2(x,408,230,152),Color("243d3e"))
			draw_line(Vector2(x,408),Vector2(x+230,408),Color("667167"),2,true)
		if i%3==0:
			draw_line(Vector2(x+40,-50),Vector2(x+40,18),Color("142d33"),3,true)
			draw_colored_polygon(PackedVector2Array([Vector2(x+24,20),Vector2(x+56,20),Vector2(x+70,39),Vector2(x+10,39)]),Color("9a9473"))
			draw_colored_polygon(PackedVector2Array([Vector2(x+28,42),Vector2(x+53,42),Vector2(x+150,550),Vector2(x-65,550)]),Color(0.77,0.77,0.49,0.045))
	if room_id in ["stacks","archive"]:
		for i in range(int(width/180)):
			var x = i*180.0
			draw_rect(Rect2(x+20,185,130,350),Color("182e32"))
			for shelf in range(4):
				for book in range(9):
					var h=35+(i*13+book*7+shelf*5)%25
					draw_rect(Rect2(x+28+book*13,235+shelf*80-h,9,h),Color("738477") if book%3 else Color("aa9675"))
				draw_line(Vector2(x+24,238+shelf*80),Vector2(x+146,238+shelf*80),Color("736957"),4)
	if underground:
		for i in range(3):
			draw_line(Vector2(0,10+i*18),Vector2(width,10+i*18),Color("678581"),5,true)
		for x in range(200,int(width),600):
			draw_arc(Vector2(x,350),145,0,TAU,64,Color("355458"),13,true)
	if room_id=="bell":
		draw_arc(Vector2(width/2,260),220,PI,TAU,64,Color("658078"),12,true)
		draw_line(Vector2(width/2-220,260),Vector2(width/2-220,580),Color("1b3035"),25)
		draw_line(Vector2(width/2+220,260),Vector2(width/2+220,580),Color("1b3035"),25)
	for i in range(60):
		var x = fmod(i*151.7+time*(5+i%4),width)
		var y = 50+fmod(i*83.9,500)
		draw_circle(Vector2(x,y),1,Color(0.8,0.84,0.71,0.12))
	draw_rect(Rect2(0,665,width,55),Color("10282e"))
	# One bounded, local anomaly tier. It never changes collision or system UI.
	if not Engine.is_editor_hint() and State.data.san_max<=80 and room_id in ["hall","research","echo"]:
		var offset=7+sin(time*0.7)*3
		var phantom=Rect2(width*0.42+offset,380,58,190)
		draw_rect(phantom,Color(0.70,0.43,0.40,0.12+0.05*sin(time)),false,2)
		draw_line(phantom.position+Vector2(10,25),phantom.end-Vector2(10,25),Color(0.64,0.71,0.65,0.13),1,true)
