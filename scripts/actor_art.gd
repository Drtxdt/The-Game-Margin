@tool
extends Node2D

@export_enum("student", "collie", "charger", "flier", "watcher", "boss", "guardian") var kind: String = "student"
@export var facing: float = 1.0
@export var moving: float = 0.0
@export var attacking: bool = false
@export var peaceful: bool = false
@export var echo: bool = false
@export var downward: bool = false
var phase = 0.0
var vertical_speed = 0.0
var grounded = true
var hurt_pose = false
var dashing = false
var landing = 0.0
var painted_dog: Texture2D
var painted_student: Texture2D

func _ready() -> void:
	if kind in ["collie","guardian"]:
		painted_dog=load("res://assets/art/cooper.png" if kind=="collie" else "res://assets/art/guardian_clean.png")
	if kind=="student": painted_student=load("res://assets/art/student_clean.png")

func _process(delta: float) -> void:
	phase += delta * (10.0 if moving > 0.1 else 1.8)
	landing=maxf(0,landing-delta)
	queue_redraw()

func _draw() -> void:
	if kind in ["collie","guardian"] and painted_dog:
		draw_set_transform(Vector2.ZERO,0,Vector2(facing,1.0+sin(phase)*0.006))
		draw_texture_rect(painted_dog,Rect2(-38,-54,75,54) if kind=="collie" else Rect2(-72,-83,150,95),false)
		draw_set_transform(Vector2.ZERO)
		return
	if kind=="student" and painted_student:
		var bob=-absf(sin(phase))*moving*2
		var lean=0.30 if dashing else (-0.16 if hurt_pose else 0.07*moving)
		if not grounded: lean=0.12 if vertical_speed<0 else -0.07
		var squash=landing/0.13
		var tint=Color("a4e9d4") if echo else Color.WHITE
		# Two independently posed painted legs beneath a shared cutout torso.
		for leg in range(2):
			var hip=Vector2(-5 if leg==0 else 5,-25)
			var angle=sin(phase+(PI if leg==0 else 0))*moving*0.45
			if not grounded: angle=-0.35 if leg==0 else 0.32
			draw_set_transform(Vector2(hip.x*facing,-25),angle*facing,Vector2(facing,1))
			draw_texture_rect_region(painted_student,Rect2(-7,-1,12,26),Rect2(270+leg*225,1000,225,510),tint)
		draw_set_transform(Vector2(0,-25+bob),lean*facing,Vector2(facing*(1+squash*0.08),1-squash*0.08))
		draw_texture_rect_region(painted_student,Rect2(-12,-51,24,51),Rect2(270,10,450,990),tint)
		draw_set_transform(Vector2(0,bob),lean*facing,Vector2(facing,1))
		if attacking:
			var end=Vector2(0,39) if downward else Vector2(91,-31)
			draw_line(Vector2(8,-29),end,Color("d8ba78"),3,true)
			if downward:
				draw_arc(Vector2(0,5),30,0,PI,16,Color(0.93,0.85,0.63,0.7),2,true)
			else:
				draw_arc(Vector2(20,-36),67,-0.5,0.5,16,Color(0.93,0.85,0.63,0.7),2,true)
		draw_set_transform(Vector2.ZERO)
		return
	var ink = Color("182c32")
	var paper = Color("d5d4bf")
	var jade = Color("66867f")
	if echo:
		paper = Color("a4e9d4")
		jade = Color("6eb8ad")
	var swing = sin(phase) * minf(moving, 1.0) * 7.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1))
	if kind == "student":
		draw_line(Vector2(-6,-17), Vector2(-7+swing,0), ink, 6.0, true)
		draw_line(Vector2(6,-17), Vector2(7-swing,0), ink, 6.0, true)
		draw_line(Vector2(-10+swing,0), Vector2(-2+swing,0), paper, 3.0, true)
		draw_line(Vector2(4-swing,0), Vector2(12-swing,0), paper, 3.0, true)
		var coat = PackedVector2Array([Vector2(-10,-43),Vector2(10,-43),Vector2(14,-15),Vector2(-14,-15)])
		draw_colored_polygon(coat, jade)
		draw_polyline(PackedVector2Array([coat[0],coat[1],coat[2],coat[3],coat[0]]), ink, 2.0,true)
		draw_line(Vector2(0,-40),Vector2(0,-17),paper,1.0,true)
		draw_circle(Vector2(0,-53),10.5,paper)
		draw_arc(Vector2(-1,-54),11,PI,TAU+0.3,20,ink,5,true)
		draw_circle(Vector2(5,-53),1.4,ink)
		draw_line(Vector2(-10,-36), Vector2(-15,-22-swing*0.4), ink,4,true)
		var hand = Vector2(17,-31) if attacking else Vector2(13,-23+swing*0.4)
		draw_line(Vector2(9,-36),hand,jade,6,true)
		draw_line(hand,hand+Vector2(37 if attacking else 9, -2 if attacking else 25),Color("d8ba78"),4,true)
		for i in range(4):
			var mark = hand+Vector2(i*8,-2) if attacking else hand+Vector2(i*2, i*6)
			draw_line(mark,mark+Vector2(0,3),ink,1,true)
		draw_colored_polygon(PackedVector2Array([Vector2(-8,-43),Vector2(4,-39),Vector2(2,-33),Vector2(-14,-39)]),Color("b57665"))
	elif kind in ["collie", "charger", "boss"]:
		var fur = paper if peaceful or kind == "collie" else Color("4d525d")
		draw_set_transform(Vector2(0,-23),0,Vector2(facing*1.5,0.8))
		draw_circle(Vector2.ZERO,20,ink)
		draw_set_transform(Vector2.ZERO,0,Vector2(facing,1))
		for x in [-18,-7,12,22]:
			draw_line(Vector2(x,-18),Vector2(x+swing*0.35,0),fur,5,true)
		draw_line(Vector2(-24,-23),Vector2(-37,-38+sin(phase)*3),ink,7,true)
		draw_circle(Vector2(25,-39),15,ink)
		draw_colored_polygon(PackedVector2Array([Vector2(14,-49),Vector2(12,-67),Vector2(27,-51)]),ink)
		draw_colored_polygon(PackedVector2Array([Vector2(28,-51),Vector2(35,-65),Vector2(38,-44)]),ink)
		draw_colored_polygon(PackedVector2Array([Vector2(25,-50),Vector2(32,-43),Vector2(42,-34),Vector2(26,-28),Vector2(21,-39)]),fur)
		draw_circle(Vector2(30,-43),2,Color("d4bb7b") if peaceful else Color("ed9b89"))
		draw_line(Vector2(17,-28),Vector2(34,-28),Color("bb8064"),4,true)
		if not peaceful and kind != "collie":
			for i in range(3):
				draw_arc(Vector2(i*12-13,-26),14,3.5,6.0,12,Color("b17f79"),2,true)
	elif kind == "flier":
		draw_circle(Vector2(0,-20),12,paper if peaceful else ink)
		draw_colored_polygon(PackedVector2Array([Vector2(-6,-20),Vector2(-35,-30+sin(phase)*12),Vector2(-14,-9)]),jade)
		draw_colored_polygon(PackedVector2Array([Vector2(6,-20),Vector2(35,-30+sin(phase)*12),Vector2(14,-9)]),jade)
		draw_circle(Vector2(5,-23),2,Color("dfb77a"))
	else:
		draw_rect(Rect2(-20,-38,40,38),ink)
		draw_rect(Rect2(-15,-33,30,22),jade)
		draw_circle(Vector2(0,-23),7,Color("dcaa75"))
		draw_line(Vector2(-17,-4),Vector2(-24,0),paper,3,true)
		draw_line(Vector2(17,-4),Vector2(24,0),paper,3,true)
	draw_set_transform(Vector2.ZERO)
