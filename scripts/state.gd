extends Node

signal changed
const SAVE_VERSION = SaveData.VERSION
const DEFAULT_KEYS = {"left": KEY_A, "right": KEY_D, "down": KEY_S, "jump": KEY_SPACE, "dodge": KEY_SHIFT, "attack": KEY_J, "interact": KEY_E, "observe": KEY_Q, "record": KEY_R, "replay": KEY_F, "map": KEY_TAB, "pause": KEY_ESCAPE}
var data: Dictionary = {}
var settings: Dictionary = {"volume": 0.55, "keys": {}, "fullscreen": false}
var save_path = "user://journey.json"
var loaded = false
var load_note = ""
var session_start = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if "--qa" in OS.get_cmdline_user_args():
		save_path = "user://qa_journey.json"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--self-test="): save_path="user://self_test_boot.json"
	reset_data()
	load_settings()
	loaded = load_game()
	session_start = Time.get_ticks_msec()

func reset_data() -> void:
	data = SaveData.fresh()

func has_flag(id: String) -> bool:
	return bool(data.flags.get(id, false))

func flag(id: String, value: bool = true) -> void:
	data.flags[id] = value
	save_game()
	changed.emit()

func knows(book: String) -> bool:
	return book in data.bound or book in data.held

func learn(book: String) -> void:
	if book not in RoomCatalog.BOOK_NAMES: return
	for death in data.deaths:
		if book in death.books: return
	if not knows(book):
		data.held.append(book)
		save_game()
		changed.emit()

func bind_books() -> Array:
	var result: Array = data.held.duplicate()
	for book in result:
		if book not in data.bound:
			data.bound.append(book)
	data.held.clear()
	save_game()
	changed.emit()
	return result

func restore() -> void:
	data.hp = Balance.MAX_HEALTH
	data.san = data.san_max
	changed.emit()

func recover(amount: float) -> void:
	data.san = minf(float(data.san_max), float(data.san) + amount)
	changed.emit()

func spend(amount: float) -> bool:
	if float(data.san) < amount:
		return false
	data.san = float(data.san) - amount
	changed.emit()
	return true

func register_death(room_id: String, point: Vector2, poses: Array) -> Dictionary:
	var old: float = data.san_max
	data.san_max = maxf(Balance.MIN_SANITY_CAP, old - Balance.DEATH_SANITY_LOSS)
	var death = DeathImprint.create(room_id, point, poses, old - float(data.san_max), data.held)
	data.total_deaths += 1
	death.id = "death_%d" % int(data.total_deaths)
	death.recovery_anchor_id = room_id + "_safe_ground"
	data.deaths.append(death)
	data.held.clear()
	restore()
	save_game()
	return death

func meet_librarian() -> String:
	var message = ""
	if int(data.echo_tool_level) == 0 or has_flag("tool_gift_pending"):
		data.echo_tool_level = maxi(1, int(data.echo_tool_level))
		data.flags.erase("tool_gift_pending")
		message = "库珀从登记台下推来一个旧盒子。\n“录响器。它能留下你做过的动作。”\n\n在因果锚点旁按 %s 录制，按 %s 调用。每次调用消耗 12 点当前理智。" % [key_name("record"), key_name("replay")]
	if int(data.total_deaths) >= 6 and int(data.echo_tool_level) < 2:
		data.echo_tool_level = 2
		message += ("\n\n" if message != "" else "") + "库珀看着你身后的空处，打开了盒子里另一道扣。\n“有些落下的自己，现在可以带回来了。”\n\n录响器已开启缝页功能：走到亡响的固定标记旁，按 %s 回收失去的理智上限。" % key_name("interact")
	if message != "":
		save_game()
		changed.emit()
	return message

func collect_deaths(ids: Array) -> Dictionary:
	# Book ownership and debt settlement are committed together once per interaction.
	var before = data.duplicate(true)
	var books: Array = []
	var debt = 0.0
	var settled = 0
	for death in data.deaths:
		if death.id not in ids: continue
		for book in death.books:
			if not knows(book):
				data.held.append(book)
				books.append(book)
		death.books.clear()
		if int(data.echo_tool_level) >= 2 and not death.recovered:
			debt += float(death.debt)
			death.recovered = true
			settled += 1
	data.san_max = minf(100.0, float(data.san_max) + debt)
	data.san = minf(float(data.san_max), float(data.san) + debt)
	if not save_game():
		data = before
		return {"ok":false,"books":[],"debt":0.0,"settled":0}
	changed.emit()
	return {"ok":true,"books":books,"debt":debt,"settled":settled}

func migrate_save(value: Dictionary) -> Dictionary:
	var result = value.duplicate(true)
	result.version = SAVE_VERSION
	result.total_deaths = result.deaths.size()
	result.echo_tool_level = 1 if "library" in result.visited else 0
	result.discovered_exits = []
	result.checkpoints = [result.checkpoint]
	if result.echo_tool_level == 1: result.flags.tool_gift_pending = true
	var owned: Array = []
	for key in ["bound", "held"]:
		var unique: Array = []
		for book in result[key]:
			if book not in owned:
				owned.append(book)
				unique.append(book)
		result[key] = unique
	for index in range(result.deaths.size()):
		var death: Dictionary = result.deaths[index]
		death.id = "death_%d" % (index + 1)
		death.recovered = bool(death.get("recovered", false))
		death.recovery_anchor_id = "legacy_revalidate"
		var unique: Array = []
		for book in death.books:
			if book not in owned:
				owned.append(book)
				unique.append(book)
		death.books = unique
	return result

func validate_save(value: Variant, legacy: bool = false) -> bool:
	if not value is Dictionary or value.get("version", 0) != (1 if legacy else SAVE_VERSION):
		return false
	if not legacy:
		if not SaveData.number(value.get("total_deaths")) or value.total_deaths < 0 or value.total_deaths != int(value.total_deaths): return false
		if not SaveData.number(value.get("echo_tool_level")) or value.echo_tool_level < 0 or value.echo_tool_level > 2 or value.echo_tool_level != int(value.echo_tool_level): return false
		if not value.get("discovered_exits") is Array or not value.get("checkpoints") is Array: return false
	for key in ["flags", "echoes"]:
		if not value.get(key) is Dictionary:
			return false
	for key in ["bound", "held", "visited", "deaths", "notes"]:
		if not value.get(key) is Array:
			return false
	if value.get("major", "") not in ["physics", "politics"]:
		return false
	if not value.get("san_max") is float and not value.get("san_max") is int:
		return false
	if float(value.san_max) < 55.0 or float(value.san_max) > 100.0:
		return false
	if not value.get("checkpoint_pos") is Array or value.checkpoint_pos.size() != 2:
		return false
	for key in ["san", "hp", "seconds"]:
		if not value.get(key) is float and not value.get(key) is int:
			return false
	if float(value.san)<0 or float(value.san)>float(value.san_max) or int(value.hp)<1 or int(value.hp)>6:
		return false
	for point in value.checkpoint_pos:
		if not point is float and not point is int:
			return false
	for book in value.bound+value.held:
		if book not in RoomCatalog.BOOK_NAMES:
			return false
	for id in value.visited:
		if id not in RoomCatalog.ROOMS:
			return false
	for death in value.deaths:
		if not death is Dictionary or death.get("room", "") not in RoomCatalog.ROOMS or not death.get("poses") is Array or not death.get("books") is Array or not death.get("point") is Array or death.point.size()!=2:
			return false
		if not SaveData.pair(death.point) or not SaveData.number(death.get("debt")) or not death.get("id") is String:
			return false
		if death.debt < 0 or death.debt > Balance.DEATH_SANITY_LOSS: return false
		if not legacy and (not death.get("recovered") is bool or not death.get("recovery_anchor_id") is String): return false
		for book in death.books:
			if book not in RoomCatalog.BOOK_NAMES: return false
		for pose in death.poses:
			if not pose is Array or pose.size()!=5: return false
			if not SaveData.number(pose[0]) or not SaveData.number(pose[1]) or not SaveData.number(pose[2]): return false
	for clip in value.echoes.values():
		if not clip is Dictionary or not EchoClip.valid(clip): return false
	if not legacy:
		var owned: Array=[]
		for book in value.bound+value.held:
			if book in owned: return false
			owned.append(book)
		var ids: Array=[]
		for death in value.deaths:
			if death.id in ids: return false
			ids.append(death.id)
			for book in death.books:
				if book in owned: return false
				owned.append(book)
		if value.total_deaths < value.deaths.size(): return false
	return value.get("checkpoint", "") in RoomCatalog.ROOMS

func read_json(path: String) -> Variant:
	var parser=JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK:
		return null
	return parser.data

func load_game() -> bool:
	for path in [save_path, save_path + ".bak"]:
		if not FileAccess.file_exists(path):
			continue
		var parsed = read_json(path)
		if validate_save(parsed, true):
			var backup = save_path + ".v1-backup"
			if not FileAccess.file_exists(backup):
				if DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(backup)) != OK:
					load_note = "旧旅程备份失败，请检查存档目录权限。"
					return false
			parsed = migrate_save(parsed)
			load_note = "旧旅程已升级，书籍和往日的亡响仍在。"
		if validate_save(parsed):
			data.merge(parsed, true)
			if path.ends_with(".bak"):
				load_note = "上次的书页受损，已从备份恢复旅程。"
			return true
	return false

func save_game() -> bool:
	if not validate_save(data):
		push_error("Refusing to replace a save with invalid journey state")
		return false
	var temporary = save_path + ".tmp"
	var f = FileAccess.open(temporary, FileAccess.WRITE)
	if f == null:
		push_error("Cannot save journey: " + str(FileAccess.get_open_error()))
		return false
	f.store_string(JSON.stringify(data))
	f.flush()
	f.close()
	if FileAccess.file_exists(save_path):
		var prior = read_json(save_path)
		if validate_save(prior):
			DirAccess.copy_absolute(ProjectSettings.globalize_path(save_path), ProjectSettings.globalize_path(save_path + ".bak"))
	var err = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(save_path))
	if err != OK:
		push_error("Save replacement failed: " + str(err))
	return err == OK

func new_game() -> void:
	reset_data()
	# Explicit new-game confirmation also replaces the backup.
	save_game()
	DirAccess.copy_absolute(ProjectSettings.globalize_path(save_path), ProjectSettings.globalize_path(save_path + ".bak"))
	loaded = true

func load_settings() -> void:
	if FileAccess.file_exists("user://settings.json"):
		var parsed = read_json("user://settings.json")
		if parsed is Dictionary:
			settings.merge(parsed, true)
	for action in DEFAULT_KEYS:
		set_key(action, int(settings.keys.get(action, DEFAULT_KEYS[action])), false)
	AudioServer.set_bus_volume_db(0, linear_to_db(float(settings.volume)))
	if DisplayServer.get_name()!="headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

func set_key(action: String, key: int, persist: bool = true) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	var event = InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)
	settings.keys[action] = key
	if persist:
		save_settings()

func key_name(action: String) -> String:
	return OS.get_keycode_string(int(settings.keys.get(action, DEFAULT_KEYS.get(action, KEY_NONE))))

func save_settings() -> void:
	var f = FileAccess.open("user://settings.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(settings))
