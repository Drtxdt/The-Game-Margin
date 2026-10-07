extends Node2D
var poses: Array = []
var clock = 0.0

func _process(delta: float) -> void:
	if poses.is_empty():
		return
	clock += delta
	var p: Array = poses[int(clock*60)%poses.size()]
	position=Vector2(float(p[0]),float(p[1]))
	$Art.facing=float(p[2])
	$Art.moving=1.0 if p[3] else 0.0
	$Art.attacking=bool(p[4])
