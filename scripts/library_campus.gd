@tool
extends Node2D
var campus: Texture2D=preload("res://assets/art/campus_distant.png")
var elapsed=0.0

func _process(delta: float) -> void:
	elapsed+=delta
	if not Engine.is_editor_hint():
		var world=get_tree().get_first_node_in_group("world")
		if world:
			var camera: Camera2D=world.player.get_node("Camera2D")
			position.x=(camera.get_screen_center_position().x-960)*0.15
	queue_redraw()

func _draw() -> void:
	draw_texture_rect(campus,Rect2(-100,-80,2200,600),false,Color(0.62,0.72,0.76,1))
	for i in range(90):
		var p=Vector2(fmod(i*73.17,2100),fmod(i*53.91+elapsed*(34+i%6),550))
		draw_line(p,p+Vector2(-2,13),Color(0.72,0.83,0.86,0.13),1,true)
