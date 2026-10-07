class_name DeathImprint
extends RefCounted

static func create(room_id: String, point: Vector2, poses: Array, debt: float, books: Array) -> Dictionary:
	return {"id": "%s_%d" % [room_id, Time.get_ticks_usec()], "room": room_id, "point": [point.x, point.y], "poses": poses.duplicate(true), "debt": debt, "books": books.duplicate(), "recovered": false}
