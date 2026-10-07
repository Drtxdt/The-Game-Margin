@tool
extends AnimatableBody2D

@export var travel = Vector2(0,-180)
@export var period = 4.0
var origin = Vector2.ZERO
var phase = 0.0

func _ready() -> void:
	origin=position

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	phase += delta
	position=origin+travel*(0.5-0.5*cos(phase*TAU/period))
