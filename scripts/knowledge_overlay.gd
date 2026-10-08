extends Node2D
## World-space measurements must draw above room geometry, below the CanvasLayer HUD.
func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	get_parent().draw_overlay(self)
