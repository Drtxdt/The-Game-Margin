@tool
extends Node2D
@export_enum("desk","bench","door") var kind = "desk"
var desk: Texture2D = preload("res://assets/art/library_desk.png")
var bench: Texture2D = preload("res://assets/art/library_bench.png")
var door: Texture2D = preload("res://assets/art/library_door.png")

func _draw() -> void:
	if kind=="desk":
		draw_texture_rect(desk,Rect2(-70,-62,140,62),false)
	elif kind=="bench":
		draw_texture_rect_region(bench,Rect2(-78,-48,156,48),Rect2(32,23,2110,659))
	else:
		draw_texture_rect_region(door,Rect2(-29,-108,58,108),Rect2(108,53,715,1574))
