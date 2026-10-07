@tool
extends Node2D

var elapsed=0.0

func _process(delta: float) -> void:
	elapsed+=delta
	queue_redraw()

func _draw() -> void:
	var restored=false
	if not Engine.is_editor_hint(): restored="archive" in State.data.bound
	for i in range(38):
		var x=fmod(i*137.7+sin(elapsed*0.21+i)*17,1900)
		var y=110+fmod(i*63.9-elapsed*(3+i%3)+2000,460)
		var alpha=(0.16+0.13*sin(elapsed+i))*(1.0 if restored else 0.4)
		draw_circle(Vector2(x,y),1.0+i%2,Color(0.91,0.79,0.53,alpha))
	if restored:
		for x in [330,1010,1540]:
			draw_set_transform(Vector2(x,620),0,Vector2(1,0.15))
			draw_circle(Vector2.ZERO,90,Color(0.88,0.67,0.35,0.08))
		draw_set_transform(Vector2.ZERO)
