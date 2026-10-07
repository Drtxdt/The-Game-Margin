@tool
extends StaticBody2D

@export var requirement = ""
@export var dimensions = Vector2(30,200)

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		var opened = State.has_flag(requirement)
		visible = not opened
		$CollisionShape2D.set_deferred("disabled",opened)
	queue_redraw()

func _draw() -> void:
	for i in range(int(dimensions.x/12)+1):
		draw_line(Vector2(i*12-dimensions.x/2,-dimensions.y),Vector2(i*12-dimensions.x/2,0),Color("849589"),4,true)
	draw_line(Vector2(-dimensions.x/2,-dimensions.y),Vector2(dimensions.x/2,-dimensions.y),Color("d0b27e"),5,true)
