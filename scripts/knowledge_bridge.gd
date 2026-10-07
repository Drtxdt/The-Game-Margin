@tool
extends AnimatableBody2D

@export var requirement="physics_open"
var target=Vector2.ZERO

func _ready() -> void:
	target=position
	if not Engine.is_editor_hint() and not State.has_flag(requirement):
		position.y+=235

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var open=State.has_flag(requirement)
	position.y=move_toward(position.y,target.y if open else target.y+235,delta*150)
	$CollisionShape2D.set_deferred("disabled",not open)
