class_name ActionFrame
extends RefCounted

static func capture() -> Dictionary:
	return {"axis": Input.get_axis("left", "right"), "jump": Input.is_action_just_pressed("jump"), "release": Input.is_action_just_released("jump"), "attack": Input.is_action_just_pressed("attack"), "dodge": Input.is_action_just_pressed("dodge"), "down": Input.is_action_pressed("down"), "interact": Input.is_action_just_pressed("interact")}

static func idle() -> Dictionary:
	return {"axis": 0.0, "jump": false, "release": false, "attack": false, "dodge": false, "down": false, "interact": false}
