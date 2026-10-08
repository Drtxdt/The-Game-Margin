extends Camera2D
## Directional look-ahead is visual only: it never affects recorded physics.
var look = 0.0
var ground_height = 620.0

func _physics_process(delta: float) -> void:
	var actor = get_parent()
	if actor.is_ghost: return
	var desired = actor.facing * 125.0 if absf(actor.velocity.x)>25 else look
	look = move_toward(look,desired,delta*340)
	if actor.is_on_floor(): ground_height = actor.position.y
	var air_delta: float = actor.position.y-ground_height
	var vertical = -185.0-clampf(air_delta,-100,65)*0.65
	position = Vector2(look,vertical)

func reset_for_room() -> void:
	look=0
	ground_height=get_parent().position.y
	position=Vector2(0,-185)
	reset_smoothing()
