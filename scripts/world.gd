extends Node2D

const PLAYER_SCENE = preload("res://scenes/entities/player.tscn")
const DEATH_SCENE = preload("res://scenes/entities/death.tscn")
@onready var player = $Player
@onready var ui = $UI
var room: Node2D
var room_id = "gate"
var transitioning = false
var recording = false
var recording_id = ""
var clip: Dictionary = {}
var echo: Node
var observing = false
var dodge_rewarded = false
var lever_step = 0
var rope: Node2D
var trolley: Node2D
var elapsed_save = 0.0
var playing = false
var room_width = 3200.0
var sfx: Dictionary = {}
var last_sound = {}
var last_echo_endpoint=Vector2.ZERO

func _ready() -> void:
	get_tree().auto_accept_quit=false
	if not get_tree().has_meta("margin_test_started"):
		for argument in OS.get_cmdline_user_args():
			if argument.begins_with("--self-test="):
				var runners={"integration":"qa_runner","traversal":"traversal_runner","routes":"route_runner","render":"render_runner"}
				var name=argument.trim_prefix("--self-test=")
				if runners.has(name):
					get_tree().set_meta("margin_test_started",true)
					launch_self_test.call_deferred(str(runners[name]))
					return
	$Music.finished.connect($Music.play)
	$MusicWarm.finished.connect($MusicWarm.play)
	for sound_id in ["jump","strike","hurt","dash","bell","page","warning"]:
		sfx[sound_id] = load("res://assets/audio/%s.wav" % sound_id)
	_load_room(str(State.data.checkpoint),Vector2(float(State.data.checkpoint_pos[0]),float(State.data.checkpoint_pos[1])))
	if "--qa" in OS.get_cmdline_user_args():
		playing=true
		ui.close_all()
	else:
		ui.show_home()
	if State.load_note!="":
		ui.toast(State.load_note)

func launch_self_test(runner: String) -> void:
	# Release templates do not support the editor-only --script switch.
	# An explicit, allowlisted test entry validates the actual shipped binary.
	var tree=get_tree()
	shutdown_audio()
	tree.current_scene=null
	get_parent().remove_child(self)
	queue_free()
	tree.set_script(load("res://tests/%s.gd" % runner))
	tree.call_deferred("run")

func begin(fresh: bool) -> void:
	if fresh:
		State.new_game()
	playing=true
	ui.close_all()
	change_room(str(State.data.checkpoint),Vector2(float(State.data.checkpoint_pos[0]),float(State.data.checkpoint_pos[1])))

func _process(delta: float) -> void:
	if not playing or transitioning:
		return
	State.data.seconds = float(State.data.seconds)+delta
	elapsed_save += delta
	if elapsed_save>30:
		State.save_game()
		elapsed_save=0
	if player.dash_left<=0:
		dodge_rewarded=false
	if Input.is_action_just_pressed("observe"):
		observing=not observing
		if observing and not State.knows("math"):
			ui.toast("你注意到装置在重复运动，但还无法准确读出其中的关系。")
	if Input.is_action_just_pressed("record"):
		if recording:
			finish_recording()
		else:
			begin_recording()
	if Input.is_action_just_pressed("replay"):
		play_echo()
	if is_instance_valid(rope) and is_instance_valid(trolley) and not State.has_flag("rope_cut"):
		var held = Input.is_action_pressed("interact") and player.position.distance_to(trolley.position)<90
		rope.position=Vector2(1340,575) if held else Vector2(1550,365)
	if room_id=="library":
		var restored = "archive" in State.data.bound
		$MusicWarm.volume_db = move_toward($MusicWarm.volume_db, -13.0 if restored else -40.0,delta*12)
	else:
		$MusicWarm.volume_db=move_toward($MusicWarm.volume_db,-50,delta*16)
	queue_redraw()

func _draw() -> void:
	if not playing or not is_instance_valid(player):
		return
	if observing and State.knows("math") and is_instance_valid(room):
		for platform in get_tree().get_nodes_in_group("moving_platforms"):
			var p: Vector2=platform.position
			draw_line(p,p+Vector2(0,-160),Color(0.7,0.88,0.73,0.65),1,true)
			draw_circle(p+Vector2(0,-160),5,Color("bad7b2"),false,1,true)
			draw_string(ui.font,p+Vector2(20,-55),"周期 %.1f 秒 · 距离 %.1f 格" % [platform.period,player.position.distance_to(p)/64.0],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("c7dec2"))
			var rise=Balance.JUMP_SPEED*Balance.JUMP_SPEED/(2.0*Balance.GRAVITY)
			draw_dashed_line(player.position+Vector2(-32,-rise),player.position+Vector2(50,-rise),Color(0.7,0.88,0.73,0.6),1,5)
	if recording:
		draw_arc(player.position+Vector2(0,-35),51,-PI/2,-PI/2+TAU*clip.frames.size()/480.0,40,Color("b6e4cc"),2,true)

func change_room(id: String, point: Vector2 = Vector2(150,580)) -> void:
	if transitioning or not RoomCatalog.ROOMS.has(id):
		return
	transitioning=true
	finish_recording()
	stop_echo()
	_load_room.call_deferred(id,point)

func _load_room(id: String, point: Vector2) -> void:
	stop_echo()
	if is_instance_valid(room):
		remove_child(room)
		room.queue_free()
	room_id=id
	room=load("res://scenes/rooms/%s.tscn" % id).instantiate()
	add_child(room)
	move_child(room,0)
	room_width=float(room.get_meta("width",3200))
	player.snapshot_reset(point)
	var camera: Camera2D=player.get_node("Camera2D")
	camera.limit_left=0
	camera.limit_right=int(room_width)
	camera.limit_top=-340 if id in ["junction","tower"] else 0
	camera.limit_bottom=720
	camera.reset_smoothing()
	if id not in State.data.visited:
		State.data.visited.append(id)
	ui.room_changed(id)
	rope=room.get_node_or_null("Rope")
	trolley=room.get_node_or_null("Trolley")
	var deaths: Array=[]
	for death in State.data.deaths:
		if death.room==id:
			deaths.append(death)
	for death in deaths.slice(maxi(0,deaths.size()-3)):
		var visual=DEATH_SCENE.instantiate()
		visual.poses=death.poses
		room.add_child(visual)
	if id=="bell" and not State.has_flag("boss_purified"):
		State.data.checkpoint="bell"
		State.data.checkpoint_pos=[310,580]
		State.restore()
	if id=="library":
		State.data.checkpoint="library"
		State.data.checkpoint_pos=[240,580]
		State.restore()
		update_library()
		if "archive" in State.data.bound and State.has_flag("boss_purified") and not State.data.completed:
			State.data.completed=true
			ui.dialogue("余页", "灯亮起来以后，图书馆不再只有你们两个。\n\n守兽蜷在门边，库珀给它留出了位置。你带回来的那一页，在书架上慢慢展开。\n\n外面仍然有许多没有走过的路。\n但现在，你知道自己可以回来。", "complete")
	if id=="research" and not State.has_flag("boss_purified") and not State.has_flag("sequence_break"):
		State.data.flags.sequence_break=true
		ui.annotation()
		var observer=room.get_node_or_null("Observer")
		if observer:
			observer.rotation=0.45
	State.save_game()
	transitioning=false

func update_library() -> void:
	if room_id!="library":
		return
	var restored="archive" in State.data.bound
	var painting=room.get_node_or_null("Painting")
	if painting:
		painting.modulate=Color.WHITE if restored else Color(0.62,0.72,0.78)
	var lamps=room.get_node_or_null("RestoredLight")
	if lamps:
		lamps.visible=restored
	var dog=room.get_node_or_null("GuardianHome")
	if dog:
		dog.visible=State.has_flag("boss_purified")

func nearest_interactable(actor: Node) -> Node:
	var best: Node=null
	var distance=91.0
	for item in get_tree().get_nodes_in_group("interactables"):
		if not item.visible or item.kind=="rope" or (actor.is_ghost and not item.echo_allowed):
			continue
		var d=actor.position.distance_to(item.position)
		if d<distance:
			distance=d
			best=item
	return best

func interact(actor: Node) -> void:
	if transitioning:
		return
	if not actor.is_ghost:
		for death in State.data.deaths:
			if death.room==room_id and not death.books.is_empty() and actor.position.distance_to(Vector2(death.point[0],death.point[1]))<100:
				for book in death.books:
					if not State.knows(book):
						State.data.held.append(book)
				death.books.clear()
				State.save_game()
				ui.toast("找回了未归还的书。亡响仍留在这里。")
				return
	var item=nearest_interactable(actor)
	if item==null:
		return
	if item.requirement!="" and not State.has_flag(item.requirement):
		if not actor.is_ghost:
			ui.toast(item.text if item.text!="" else "这条路还没有打开。")
		return
	match item.kind:
		"exit":
			change_room(item.target,item.entry)
		"cooper":
			if item.stable_id=="rescue":
				State.flag("cooper_rescued")
				ui.dialogue("校门外", "你抬起倾倒的架子，把最后一点面包放在它面前。\n\n狗没有立刻吃。它先看了看钟，又看了看你。\n\n学校里，铃声已经停了。")
			else:
				ui.dialogue("库珀", "“把书放回它原来的位置。”\n\n“你问我为什么会说话？”\n\n它把面包屑往爪子下面拨了拨。\n“先解决比较重要的问题。”")
		"ruler":
			State.flag("ruler")
			ui.dialogue("老式金属折尺", "折叠，展开，锁定。\n\n按 %s 挥尺。跳起后按住 %s 再挥尺，可以向下敲击。\n有些坚硬的表面，会把力还给你。" % [State.key_name("attack"),State.key_name("down")])
		"book":
			State.learn(item.stable_id)
			sound("page")
			ui.dialogue(RoomCatalog.BOOK_NAMES.get(item.stable_id,"书页"),item.text+"\n\n现在即可试读使用。归还图书馆后，知识将稳定保存。")
		"return":
			var books=State.bind_books()
			update_library()
			if books.is_empty():
				ui.toast("书架在等待下一本归来的书。")
			else:
				sound("page")
				ui.dialogue("归还", "你把书放回空缺的位置。\n\n"+("灯光沿着书架，一盏一盏亮了起来。" if "archive" in books else "散开的纸页终于安静下来。这些知识现在属于你了。"))
				if "archive" in State.data.bound and State.has_flag("boss_purified"):
					State.data.completed=true
					State.save_game()
					ui.dialogue("余页", "守兽在门边趴下。库珀抬起头，又低下头。\n\n重要的书已经归来。\n外面的路还没有走完，但这里终于又像一个家。\n\nDemo 已完成，你仍可以继续探索。", "complete")
		"major":
			ui.dialogue("选择主修", "数学帮助你看见关系，语言帮助你读懂信息。\n\n物理：在机电间调整支点，改变通路。\n政治：在安保室利用疏散规则的优先级。\n\n随时可回这里免费更换；已打开的道路保留。", "major")
		"checkpoint":
			State.data.checkpoint=room_id
			State.data.checkpoint_pos=[item.position.x,item.position.y-20]
			State.restore()
			State.save_game()
			ui.toast("已记住这里。身体与当前理智恢复，上限保持不变。")
		"anchor":
			ui.dialogue("因果锚点", "在锚点旁站稳，按 %s 开始或结束录制，最多八秒。\n按 %s 调用，每次消耗 12 点当前理智。\n\n它会重做你当时的动作。但现在的世界，可以不一样。\n\n这里的推车需要按住交互键才能保持位置。普通维护通路始终可走。" % [State.key_name("record"),State.key_name("replay")])
		"trolley":
			ui.toast("按住 %s 保持推车位置。松开后，弹簧会将绳索拉回去。" % State.key_name("interact"))
		"lever":
			if State.data.major!="physics":
				ui.toast("固定支点的刻度很精细。可以回图书馆研习物理，也可以走维护通道。")
			else:
				lever_step=(lever_step+1)%3
				ui.toast(["支点回到中央。两端仍不平衡。","支点靠近施力端。重物更难抬起了。","支点靠近负载端。桥板抬了起来。入口已永久打开。"][lever_step])
				if lever_step==2:
					State.flag("physics_open")
		"policy":
			if State.data.major!="politics":
				ui.toast("可以读懂条文，但缺少调用规则层级的方法。维护通道不需要这项权限。")
			else:
				ui.dialogue("规程控制台", "安保条款：无四级许可，封锁钟庭通道。\n消防条款：疏散状态优先于实验室安保。\n\n选择执行项：", "policy")
		"switch":
			State.flag(item.stable_id)
			ui.toast(item.text)
			if State.has_flag("service_a") and State.has_flag("service_b") and State.has_flag("service_c"):
				State.flag("service_open")
				ui.toast("三个手动断路器已复位。钟庭维护门打开了。")
		"bell":
			ring_bell(item.position)
		"terminal":
			ui.dialogue(item.title,item.text if State.knows("language") else "AX-17 / ██ ██\nCONTAINMENT ███\n\n角色暂时无法完整理解这些文字。")
		_:
			if item.stable_id not in State.data.notes:
				State.data.notes.append(item.stable_id)
				State.save_game()
			ui.dialogue(item.title,item.text)

func begin_recording() -> bool:
	var anchor: Node=null
	for item in get_tree().get_nodes_in_group("interactables"):
		if item.kind=="anchor" and player.position.distance_to(item.position)<110:
			anchor=item
	if anchor==null:
		ui.toast("需要在因果锚点附近录制。")
		return false
	if not player.is_on_floor() or absf(player.velocity.x)>25 or player.attack_cooldown>0 or player.dash_left>0:
		ui.toast("先站稳，再开始留下这段动作。")
		return false
	stop_echo()
	player.combo_window=0
	clip=EchoClip.create(room_id,player)
	recording=true
	recording_id=anchor.stable_id
	ui.toast("开始录制 · 再按 %s 结束" % State.key_name("record"))
	return true

func capture_frame(frame: Dictionary) -> void:
	if not recording:
		return
	clip.frames.append(frame.duplicate())
	if clip.frames.size()>=Balance.ECHO_MAX_FRAMES:
		finish_recording()

func finish_recording() -> void:
	if not recording:
		return
	recording=false
	if EchoClip.valid(clip):
		State.data.echoes[recording_id]=clip.duplicate(true)
		State.save_game()
		ui.toast("动作已留下 · %.1f 秒 · %s 调用" % [clip.frames.size()/60.0,State.key_name("replay")])

func play_echo() -> bool:
	if recording:
		finish_recording()
	var selected: Dictionary={}
	for value in State.data.echoes.values():
		if value.room==room_id and EchoClip.valid(value):
			selected=value
	if selected.is_empty():
		ui.toast("这个房间还没有留下可调用的动作。")
		return false
	var start=Vector2(selected.start[0],selected.start[1])
	var shape=RectangleShape2D.new()
	shape.size=Vector2(22,50)
	var query=PhysicsShapeQueryParameters2D.new()
	query.shape=shape
	query.transform=Transform2D(0,start+Vector2(0,-31))
	query.collision_mask=1
	if not get_world_2d().direct_space_state.intersect_shape(query,1).is_empty():
		ui.toast("残响的起点被挡住了。没有消耗理智。")
		return false
	if not State.spend(Balance.ECHO_COST):
		ui.toast("当前理智不足 12。普通攻击和维护通路仍可使用。")
		return false
	stop_echo()
	echo=PLAYER_SCENE.instantiate()
	echo.is_ghost=true
	echo.ghost_ruler=selected.get("has_ruler",true)
	echo.position=start
	echo.velocity=Vector2(selected.velocity[0],selected.velocity[1])
	echo.facing=float(selected.facing)
	echo.coyote=Balance.COYOTE_SECONDS
	for key in ["coyote","jump_buffer","dash_cooldown","attack_cooldown","combo","combo_window","stagger"]:
		if selected.get("initial",{}).has(key): echo.set(key,selected.initial[key])
	echo.frames=selected.frames.duplicate(true)
	add_child(echo)
	return true

func stop_echo() -> void:
	if is_instance_valid(echo):
		echo.queue_free()
	echo=null

func resolve_strike(actor: Node, down: bool, damage: int) -> void:
	var hit_rect: Rect2
	if down:
		hit_rect=Rect2(actor.position+Vector2(-25,-4),Vector2(50,68))
	else:
		hit_rect=Rect2(actor.position+Vector2(12 if actor.facing>0 else -100,-62),Vector2(88,62))
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.purified or enemy.get_instance_id() in actor.hits:
			continue
		var target_rect=Rect2(enemy.position+Vector2(-25,-58),Vector2(50,58))
		if enemy.kind=="boss":
			target_rect=Rect2(enemy.position+Vector2(-75,-148),Vector2(150,148))
		if hit_rect.intersects(target_rect):
			actor.hits.append(enemy.get_instance_id())
			enemy.hit(damage,actor)
			if down:
				actor.velocity.y=Balance.ENEMY_REBOUND
				actor.attack_left=0
	for item in get_tree().get_nodes_in_group("interactables"):
		if item.get_instance_id() in actor.hits or not item.visible:
			continue
		if item.kind=="rope" and hit_rect.has_point(item.position):
			actor.hits.append(item.get_instance_id())
			State.flag("rope_cut")
			ui.toast("同一个动作，切断了现在的绳索。侧门打开了。")
		if item.kind=="bell" and hit_rect.intersects(Rect2(item.position+Vector2(-38,-120),Vector2(76,120))):
			actor.hits.append(item.get_instance_id())
			ring_bell(item.position)
	if down:
		for metal in get_tree().get_nodes_in_group("metal"):
			if actor.hits.has(metal.get_instance_id()):
				continue
			var metal_rect=Rect2(metal.position-Vector2(42,8),Vector2(84,16))
			if hit_rect.intersects(metal_rect) and actor.velocity.y>=-100:
				actor.hits.append(metal.get_instance_id())
				actor.velocity.y=Balance.METAL_REBOUND
				actor.attack_left=0
				sound("bell")

func safe_ground(point: Vector2) -> bool:
	return point.x>40 and point.x<room_width-40 and point.y<680

func die() -> void:
	if transitioning:
		return
	finish_recording()
	State.register_death(room_id,player.safe_position,player.recent)
	ui.toast("一部分自己留在了这里。理智上限 %d / 100" % int(State.data.san_max),5)
	change_room(str(State.data.checkpoint),Vector2(State.data.checkpoint_pos[0],State.data.checkpoint_pos[1]))

func enemy_purified(enemy: Node) -> void:
	if enemy.kind=="boss":
		State.flag("boss_purified")
		State.restore()
		ui.dialogue("钟庭守兽", "控制结构一片片剥落。\n\n它没有再挡住你。\n\n旧钟停了很久，终于安静下来。通往下方的门已经打开。")
	else:
		State.flag(enemy.stable_id)
		State.recover(8)
		ui.toast("污染消退 · 当前理智恢复")

func can_hit_bell(point: Vector2) -> bool:
	if room_id!="bell":
		return false
	return absf(point.x-2080)<55

func ring_bell(point: Vector2) -> void:
	sound("bell")
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.purified:
			enemy.hear(point)

func sound(id: String) -> void:
	var now=Time.get_ticks_msec()
	if now-int(last_sound.get(id,0))<90:
		return
	last_sound[id]=now
	var audio=AudioStreamPlayer.new()
	audio.stream=sfx.get(id)
	audio.volume_db=-15
	add_child(audio)
	audio.finished.connect(audio.queue_free)
	audio.play()

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()

func shutdown_audio() -> void:
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream=null
	sfx.clear()

func quit_game() -> void:
	finish_recording()
	State.save_game()
	shutdown_audio()
	await get_tree().create_timer(0.15,true).timeout
	get_tree().quit()
