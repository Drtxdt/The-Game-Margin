@tool
extends Node2D
@export var stable_id="hall_stairs_open"
var open=false

func _ready() -> void:
	if not Engine.is_editor_hint(): apply_state()

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() and open != State.has_flag(stable_id): apply_state()

func apply_state() -> void:
	open=State.has_flag(stable_id)
	for child in get_children():
		if child is StaticBody2D:
			child.visible=open
			child.get_node("CollisionShape2D").set_deferred("disabled",not open)
	queue_redraw()

func _draw() -> void:
	if open or Engine.is_editor_hint():
		draw_line(Vector2(2080,350),Vector2(2350,600),Color("897b58"),5,true)
		draw_line(Vector2(2100,347),Vector2(2370,597),Color("4b5548"),3,true)
	else:
		draw_rect(Rect2(2138,339,22,95),Color("766d52"))
		for i in range(6): draw_line(Vector2(2136,345+i*14),Vector2(2162,345+i*14),Color("b5a67c"),3,true)
