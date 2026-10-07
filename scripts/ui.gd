extends CanvasLayer

@onready var world = get_parent()
@onready var font: Font = preload("res://resources/chinese_font.tres")
var toast_time = 0.0
var room_time = 0.0
var rebinding = ""
var dialogue_kind = ""
var home_mode = false
var confirm_new = false
var action_names = {"left":"向左","right":"向右","down":"向下 / 下劈","jump":"跳跃","dodge":"闪避","attack":"折尺攻击","interact":"交互","observe":"知识观察","record":"录制残响","replay":"调用残响","map":"地图","pause":"暂停"}

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	$Home/Panel/Body/Continue.pressed.connect(func(): world.begin(false))
	$Home/Panel/Body/New.pressed.connect(request_new)
	$Home/Panel/Body/Settings.pressed.connect(show_settings)
	$Home/Panel/Body/Quit.pressed.connect(world.quit_game)
	$Pause/Panel/Body/Resume.pressed.connect(close_all)
	$Pause/Panel/Body/Settings.pressed.connect(show_settings)
	$Pause/Panel/Body/Home.pressed.connect(show_home)
	$Pause/Panel/Body/Quit.pressed.connect(world.quit_game)
	$Dialogue/Panel/Body/Choices/First.pressed.connect(func(): choose(0))
	$Dialogue/Panel/Body/Choices/Second.pressed.connect(func(): choose(1))
	$Dialogue/Panel/Body/Choices/Third.pressed.connect(func(): choose(2))
	$Map/Panel/Body/Close.pressed.connect(close_all)
	$Settings/Panel/Body/Close.pressed.connect(func(): show_home() if home_mode else show_pause())
	$Settings/Panel/Body/Volume.value_changed.connect(func(value): State.settings.volume=value; AudioServer.set_bus_volume_db(0,linear_to_db(value)); State.save_settings())
	$Settings/Panel/Body/Fullscreen.toggled.connect(func(value): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if value else DisplayServer.WINDOW_MODE_WINDOWED); State.settings.fullscreen=value; State.save_settings())
	for action in action_names:
		var button=get_node("Settings/Panel/Body/Scroll/Bindings/"+action)
		button.pressed.connect(func(): rebinding=action; button.text=action_names[action]+"    按下新的按键…（Esc 取消）")
	refresh_settings()
	State.changed.connect(refresh_hud)
	refresh_hud()

func _process(delta: float) -> void:
	if toast_time>0:
		toast_time-=delta
		$Toast.modulate.a=minf(1,toast_time*2)
	else:
		$Toast.visible=false
	if not get_tree().paused:
		room_time=maxf(0,room_time-delta)
		$RoomTitle.modulate.a=minf(1,room_time)
		refresh_hud()
		refresh_prompt()
		$Map/Panel/Body/MapDrawing.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if rebinding!="" and event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode!=KEY_ESCAPE:
			var conflict=""
			for action in action_names:
				if action!=rebinding and int(State.settings.keys[action])==event.physical_keycode:
					conflict=action
					break
			var old_key=int(State.settings.keys[rebinding])
			State.set_key(rebinding,event.physical_keycode)
			if conflict!="":
				State.set_key(conflict,old_key)
		rebinding=""
		refresh_settings()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause"):
		if $Settings.visible:
			show_home() if home_mode else show_pause()
		elif $Home.visible:
			pass
		elif get_tree().paused:
			close_all()
		else:
			show_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("map") and world.playing and not $Dialogue.visible:
		if $Map.visible:
			close_all()
		else:
			show_map()
		get_viewport().set_input_as_handled()

func refresh_hud() -> void:
	$HUD/Top/Health.text="身体  "+"● ".repeat(maxi(0,int(State.data.hp)))+"○ ".repeat(maxi(0,6-int(State.data.hp)))
	$HUD/Top/Sanity.text="理智  %02d / %d" % [int(State.data.san),int(State.data.san_max)]
	$HUD/Top/Branch.text="物理 · 主修" if State.data.major=="physics" else "政治 · 主修"
	$HUD/Top/SanityBar.max_value=float(State.data.san_max)
	$HUD/Top/SanityBar.value=float(State.data.san)
	var objective="寻找校园中的出路"
	if not State.has_flag("cooper_rescued"):
		objective="校门旁传来了动静"
	elif not State.has_flag("ruler"):
		objective="探索教学楼与器材室"
	elif not State.knows("math"):
		objective="寻找图书馆 · 探索旧书库"
	elif not State.data.held.is_empty():
		objective="带着未归还的书 · 返回图书馆可稳定知识"
	elif not State.has_flag("boss_purified"):
		objective="寻找通往钟庭的道路"
	elif "archive" not in State.data.bound:
		objective="探索钟庭下方的研究层"
	else:
		objective="回到图书馆 · 仍有余页可寻"
	$HUD/Objective.text=objective
	$HUD/Footer.text="%s 交互    %s 观察    %s 地图    %s 暂停" % [State.key_name("interact"),State.key_name("observe"),State.key_name("map"),State.key_name("pause")]
	if world.room_id=="gate" and not State.has_flag("cooper_rescued"):
		$HUD/Footer.text="%s / %s 移动    %s 跳跃    %s 闪避    %s 交互" % [State.key_name("left"),State.key_name("right"),State.key_name("jump"),State.key_name("dodge"),State.key_name("interact")]
	if world.recording:
		$HUD/Echo.text="● 留下过去  %.1f / 8 秒" % (world.clip.frames.size()/60.0)
	elif is_instance_valid(world.echo):
		$HUD/Echo.text="残响正在执行历史动作"
	else:
		$HUD/Echo.text=""

func refresh_prompt() -> void:
	if not is_instance_valid(world.player):
		return
	var item=world.nearest_interactable(world.player)
	$Prompt.text="[%s]  %s" % [State.key_name("interact"),item.title] if item else ""
	for death in State.data.deaths:
		if death.room==world.room_id and not death.books.is_empty() and world.player.position.distance_to(Vector2(death.point[0],death.point[1]))<100:
			$Prompt.text="[%s] 找回散落的书" % State.key_name("interact")
	if world.observing:
		var message="观察 · 数学关系尚不可读"
		if State.knows("math"):
			message="观察 · 刻度显现：移动台按固定周期返回，硬质金属会返还冲击。"
			if world.room_id=="machine":
				message="观察 · 增大施力端力臂：将支点移向负载，所需力量会减小。"
			elif world.room_id=="security" and State.data.major=="politics":
				message="观察 · 消防疏散规定的执行优先级，高于本地安保条款。"
		$HUD/Observation.text=message
	else:
		$HUD/Observation.text=""

func room_changed(id: String) -> void:
	$RoomTitle.text=RoomCatalog.ROOMS[id][0]+"\n"+RoomCatalog.ROOMS[id][1]
	room_time=4
	$RoomTitle.modulate.a=1

func toast(message: String, duration: float = 3.5) -> void:
	$Toast.text=message
	$Toast.visible=true
	$Toast.modulate.a=1
	toast_time=duration

func close_all() -> void:
	for name in ["Home","Pause","Dialogue","Map","Settings"]:
		get_node(name).visible=false
	get_tree().paused=false
	home_mode=false
	rebinding=""
	$HUD.visible=true

func show_home() -> void:
	close_all()
	home_mode=true
	$Home.visible=true
	$HUD.visible=false
	$Home/Panel/Body/Continue.disabled=not State.loaded and not world.playing
	get_tree().paused=true
	($Home/Panel/Body/Continue if not $Home/Panel/Body/Continue.disabled else $Home/Panel/Body/New).grab_focus()

func request_new() -> void:
	if State.loaded or world.playing:
		dialogue("重新开始", "这会开始新的旅程，并替换当前存档。", "new")
	else:
		world.begin(true)

func show_pause() -> void:
	close_all()
	$Pause.visible=true
	get_tree().paused=true
	State.save_game()
	$Pause/Panel/Body/Resume.grab_focus()

func show_settings() -> void:
	var was_home=home_mode
	close_all()
	home_mode=was_home
	$Settings.visible=true
	get_tree().paused=true
	refresh_settings()
	$Settings/Panel/Body/Scroll/Bindings/left.grab_focus()

func refresh_settings() -> void:
	for action in action_names:
		get_node("Settings/Panel/Body/Scroll/Bindings/"+action).text=action_names[action]+"    "+State.key_name(action)
	$Settings/Panel/Body/Volume.set_value_no_signal(float(State.settings.volume))
	$Settings/Panel/Body/Fullscreen.set_pressed_no_signal(bool(State.settings.fullscreen))

func dialogue(title: String, text: String, kind: String = "normal") -> void:
	close_all()
	dialogue_kind=kind
	$Dialogue.visible=true
	$Dialogue/Panel/Body/Title.text=title
	$Dialogue/Panel/Body/Text.text=text
	var first=$Dialogue/Panel/Body/Choices/First
	var second=$Dialogue/Panel/Body/Choices/Second
	var third=$Dialogue/Panel/Body/Choices/Third
	first.text="继续探索"
	second.visible=false
	third.visible=false
	match kind:
		"major":
			first.text="主修物理"
			second.text="主修政治"
			second.visible=true
		"policy":
			first.text="提高安保等级"
			second.text="进入疏散维护状态"
			third.text="关闭控制台"
			second.visible=true
			third.visible=true
		"new":
			first.text="保留旅程"
			second.text="确认重新开始"
			second.visible=true
	get_tree().paused=true
	first.grab_focus()

func choose(index: int) -> void:
	var kind=dialogue_kind
	close_all()
	if kind=="major":
		State.data.major="physics" if index==0 else "politics"
		State.save_game()
		toast("已更换主修。此前打开的道路仍然保留。")
	elif kind=="policy":
		if index==1:
			State.flag("politics_open")
			toast("依据疏散优先条款，钟庭通道开放。")
		elif index==0:
			toast("安保等级提高。它仍然没有理由开门。")
	elif kind=="new":
		if index==1:
			world.begin(true)
		else:
			show_home()

func show_map() -> void:
	close_all()
	$Map.visible=true
	get_tree().paused=true
	var notes="已探索 %d / 16 个房间    主修：%s\n" % [State.data.visited.size(),"物理" if State.data.major=="physics" else "政治"]
	for death in State.data.deaths:
		if not death.books.is_empty():
			notes+="未归还的书落在："+RoomCatalog.ROOMS[death.room][0]+"\n"
	$Map/Panel/Body/Notes.text=notes
	$Map/Panel/Body/MapDrawing.queue_redraw()
	$Map/Panel/Body/Close.grab_focus()

func annotation() -> void:
	$Annotation.text="结果：有效。\n方法：未登记。"
	$Annotation.modulate.a=0
	var tween=create_tween()
	tween.tween_interval(0.5)
	tween.tween_property($Annotation,"modulate:a",1.0,0.8)
	tween.tween_interval(3)
	tween.tween_property($Annotation,"modulate:a",0.0,1.3)

func shake_health() -> void:
	$HUD/Top/Health.modulate=Color("eb8c7a")
	create_tween().tween_property($HUD/Top/Health,"modulate",Color.WHITE,0.6)
