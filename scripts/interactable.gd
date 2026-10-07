@tool
extends Node2D

@export var kind = "note"
@export var stable_id = ""
@export var title = ""
@export_multiline var text = ""
@export var target = ""
@export var entry = Vector2(150,580)
@export var requirement = ""
@export var echo_allowed = false
var pulse = 0.0

func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group("interactables")

func _process(delta: float) -> void:
	pulse += delta
	if not Engine.is_editor_hint():
		if kind=="book":
			visible = not State.knows(stable_id) and not dropped_elsewhere()
		elif kind=="ruler":
			visible = not State.has_flag("ruler")
		elif kind=="cooper" and stable_id=="rescue":
			visible = not State.has_flag("cooper_rescued")
		elif kind=="rope":
			visible = not State.has_flag("rope_cut")
	queue_redraw()

func dropped_elsewhere() -> bool:
	for death in State.data.deaths:
		if stable_id in death.get("books",[]):
			return true
	return false

func _draw() -> void:
	var light = Color("d6bc86")
	var jade = Color("8fb8aa")
	var ink = Color("203c43")
	match kind:
		"exit":
			draw_rect(Rect2(-31,-112,62,112),Color("10292e"))
			draw_rect(Rect2(-31,-112,62,112),Color("54756f"),false,3)
			draw_rect(Rect2(-22,-102,44,93),Color("17363c"))
			draw_line(Vector2(0,-90),Vector2(0,-15),light,1,true)
			draw_circle(Vector2(14,-52),3,light)
		"book", "return":
			draw_rect(Rect2(-19,-40,38,28),light)
			draw_line(Vector2(0,-40),Vector2(0,-13),ink,2,true)
			for i in range(3):
				draw_line(Vector2(5,-33+i*6),Vector2(14,-33+i*6),ink,1,true)
			if kind=="return":
				draw_rect(Rect2(-37,-10,74,10),Color("806d52"))
		"checkpoint":
			draw_line(Vector2(0,-10),Vector2(0,-80),jade,3,true)
			draw_rect(Rect2(-16,-81,32,26),Color("b9965f"))
			draw_circle(Vector2(0,-66),8,Color(1,0.8,0.4,0.4+sin(pulse)*0.1))
			draw_line(Vector2(-23,-5),Vector2(23,-5),jade,3,true)
		"anchor":
			for i in range(3):
				draw_arc(Vector2(0,-25),18+i*10,-PI+sin(pulse)*0.15,PI-0.4,36,Color(jade,0.75-i*0.15),1.5,true)
			draw_line(Vector2(0,-63),Vector2(0,0),jade,2,true)
		"ruler":
			draw_line(Vector2(-25,-26),Vector2(25,-26),light,7,true)
			for i in range(10):
				draw_line(Vector2(-23+i*5,-30),Vector2(-23+i*5,-23),ink,1,true)
		"rope":
			draw_line(Vector2(0,-130),Vector2.ZERO,light,3,true)
			draw_arc(Vector2(0,0),12,0,TAU,24,light,2,true)
		"trolley":
			draw_rect(Rect2(-25,-45,50,29),ink)
			draw_line(Vector2(-30,-50),Vector2(30,-50),jade,3,true)
			for x in [-19,19]:
				draw_circle(Vector2(x,-8),8,light)
		"bell":
			draw_colored_polygon(PackedVector2Array([Vector2(-24,-95),Vector2(24,-95),Vector2(38,-35),Vector2(-38,-35)]),Color("9c865c"))
			draw_line(Vector2(0,-105),Vector2(0,-140),jade,3,true)
			draw_circle(Vector2(0,-31),7,light)
		"lever", "policy", "switch":
			draw_rect(Rect2(-24,-43,48,38),ink)
			draw_rect(Rect2(-24,-43,48,38),jade,false,2)
			draw_line(Vector2(0,-15),Vector2(15,-55),light,4,true)
			draw_circle(Vector2(15,-55),6,light)
		"cooper":
			pass
		_:
			draw_rect(Rect2(-15,-52,30,40),Color("ccc6a8"))
			for i in range(4):
				draw_line(Vector2(-10,-44+i*7),Vector2(10,-44+i*7),ink,1,true)
