class_name EchoClip
extends RefCounted

static func create(room_id: String, actor: CharacterBody2D) -> Dictionary:
	var initial={}
	for key in ["coyote","jump_buffer","dash_cooldown","attack_cooldown","combo","combo_window","stagger"]:
		initial[key]=actor.get(key)
	return {"version": 1, "room": room_id, "start": [actor.position.x, actor.position.y], "velocity": [actor.velocity.x, actor.velocity.y], "facing": actor.facing, "frames": [], "has_ruler": State.has_flag("ruler"),"initial":initial}

static func valid(clip: Dictionary) -> bool:
	if clip.get("version",0)!=1 or clip.get("room","") not in RoomCatalog.ROOMS: return false
	if not clip.get("frames") is Array or clip.frames.is_empty() or clip.frames.size()>Balance.ECHO_MAX_FRAMES: return false
	if not SaveData.pair(clip.get("start")) or not SaveData.pair(clip.get("velocity")) or not SaveData.number(clip.get("facing")): return false
	for frame in clip.frames:
		if not frame is Dictionary or not SaveData.number(frame.get("axis")): return false
		for key in ["jump","release","attack","dodge","down","interact"]:
			if not frame.get(key) is bool: return false
	if not clip.get("initial",{}) is Dictionary: return false
	for value in clip.get("initial",{}).values():
		if not SaveData.number(value): return false
	return true
