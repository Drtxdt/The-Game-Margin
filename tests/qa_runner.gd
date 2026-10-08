extends SceneTree

var world: Node
var state: Node
var checks: Array = []
var failures: Array = []

func _initialize() -> void:
	run.call_deferred()

func check(condition: bool, message: String) -> void:
	checks.append({"name":message,"passed":condition})
	print(("PASS " if condition else "FAIL ")+message)
	if not condition:
		failures.append(message)

func settle(frames: int = 4) -> void:
	for i in range(frames):
		await physics_frame

func visit(id: String, point: Vector2 = Vector2(200,580)) -> void:
	world.ui.close_all()
	world.change_room(id,point)
	await settle(8)

func item(kind: String, id: String = "") -> Node:
	for node in get_nodes_in_group("interactables"):
		if node.kind==kind and (id=="" or node.stable_id==id):
			return node
	return null

func use(node: Node) -> void:
	world.ui.close_all()
	world.player.snapshot_reset(node.position+Vector2(-25,-4))
	await settle(1)
	world.interact(world.player)
	await settle(1)

func run() -> void:
	state=root.get_node("State")
	state.save_path="user://automated_qa.json"
	state.new_game()
	world=load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	current_scene=world
	world.playing=true
	world.ui.close_all()
	await settle(30)
	check(world.player.is_on_floor(),"player lands on real floor")
	var start: Vector2=world.player.position
	Input.action_press("right")
	await settle(30)
	Input.action_release("right")
	check(world.player.position.x>start.x+90,"keyboard action moves CharacterBody2D")
	var ground_y: float=world.player.position.y
	Input.action_press("jump")
	await settle(15)
	Input.action_release("jump")
	check(world.player.position.y<ground_y-70,"jump reaches useful platform height")
	await settle(35)
	check(world.player.is_on_floor(),"jump returns to collision floor")
	for id in RoomCatalog.ROOMS:
		await visit(id)
		check(is_instance_valid(world.room) and world.room_id==id,"room instantiates: "+id)
		check(world.room.get_child_count()>5,"room has editable content: "+id)
	# Book lifecycle, debt floor, and recoverable loss.
	await visit("stacks")
	await use(item("book","math"))
	check(state.knows("math") and "math" in state.data.held,"book immediately grants trial knowledge")
	world.ui.close_all()
	var loss=state.register_death("stacks",Vector2(450,620),[[450,620,1,false,false]])
	check(not state.knows("math") and "math" in loss.books,"death drops trial book and removes temporary knowledge")
	world.rebuild_recovery_points()
	world.player.position=Vector2(450,620)
	world.interact(world.player)
	check(state.knows("math") and loss.books.is_empty(),"dropped book can be reclaimed")
	state.bind_books()
	for i in range(12):
		state.register_death("stacks",Vector2(450,620),[])
	check(state.data.san_max==55.0,"repeated deaths stop at 55 percent")
	check(state.knows("math"),"bound knowledge survives repeated deaths")
	var sum=0.0
	for d in state.data.deaths: sum+=float(d.debt)
	check(sum==45.0,"recorded actual recoverable debt equals maximum loss")
	# Both specialist routes and ordinary route use actual interaction handlers.
	state.data.major="physics"
	await visit("machine")
	await use(item("lever"));await use(item("lever"))
	check(state.has_flag("physics_open"),"physics fulcrum opens mechanical route")
	state.data.major="politics"
	await visit("security")
	await use(item("policy"))
	world.ui.choose(1)
	check(state.has_flag("politics_open"),"politics emergency precedence opens security route")
	state.data.major="physics"
	check(state.has_flag("politics_open"),"changing major preserves previously opened roads")
	await visit("maintenance")
	for id in ["service_a","service_b","service_c"]:
		await use(item("switch",id))
	check(state.has_flag("service_open"),"zero-echo maintenance route opens all three breakers")
	# History is input, not position playback. Same recording, changed rope placement.
	state.data.flags.ruler=true
	state.data.echo_tool_level=1
	state.data.san=55.0
	await visit("echo",Vector2(1260,580))
	await settle(30)
	check(world.begin_recording(),"standing at anchor can begin recording")
	Input.action_press("attack")
	await settle(2)
	Input.action_release("attack")
	await settle(28)
	world.finish_recording()
	check(not state.has_flag("rope_cut"),"original recorded strike misses distant rope")
	check(state.data.echoes.get("echo_anchor",{}).get("frames",[]).size()>10,"clip stores fixed-frame input sequence")
	world.player.position=Vector2(1770,620)
	Input.action_press("interact")
	await settle(3)
	check(world.play_echo(),"valid echo activation succeeds")
	await settle(35)
	Input.action_release("interact")
	check(state.has_flag("rope_cut"),"same historical input cuts rope moved into current hit range")
	check(state.data.san==43.0,"successful echo spends exactly 12 current sanity")
	# Replaying a jump twice is stable; a newly introduced platform changes its landing.
	world.stop_echo()
	world.player.snapshot_reset(Vector2(1260,580))
	await settle(25)
	world.begin_recording()
	Input.action_press("right")
	Input.action_press("jump")
	await settle(36)
	Input.action_release("right")
	Input.action_release("jump")
	await settle(52)
	world.finish_recording()
	state.data.san=55.0
	world.player.position=Vector2(1770,620)
	world.play_echo()
	await settle(95)
	var baseline: Vector2=world.last_echo_endpoint
	world.play_echo()
	await settle(95)
	check(baseline.distance_to(world.last_echo_endpoint)<0.5,"same input and unchanged environment reproduce stable endpoint")
	var new_platform=StaticBody2D.new()
	var platform_collision=CollisionShape2D.new()
	var platform_shape=RectangleShape2D.new();platform_shape.size=Vector2(180,20)
	platform_collision.shape=platform_shape;new_platform.add_child(platform_collision)
	new_platform.position=Vector2(1420,550)
	world.add_child(new_platform)
	await settle(3)
	world.play_echo()
	await settle(95)
	check(world.last_echo_endpoint.y<baseline.y-40,"historical jump lands on newly introduced real platform")
	new_platform.queue_free()
	await settle(3)
	# A solid obstruction at the recorded origin rejects activation without charging.
	var origin: Array=state.data.echoes.echo_anchor.start
	var wall=StaticBody2D.new()
	var collision=CollisionShape2D.new()
	var shape=RectangleShape2D.new();shape.size=Vector2(50,80)
	collision.shape=shape;wall.add_child(collision)
	wall.position=Vector2(origin[0],origin[1]-31)
	world.add_child(wall)
	await settle(3)
	var prior_san: float=state.data.san
	check(not world.play_echo() and state.data.san==prior_san,"blocked echo origin rejects without spending sanity")
	wall.queue_free()
	await settle(3)
	world.play_echo()
	await visit("library")
	check(not is_instance_valid(world.echo),"room transition stops active echo")
	# Early book route and ending in either order.
	state.data.flags.erase("boss_purified")
	await visit("research")
	check(state.has_flag("sequence_break"),"early underground entry records unregistered method")
	await visit("archive")
	await use(item("book","archive"))
	world.ui.close_all()
	await visit("library")
	await use(item("return"))
	check("archive" in state.data.bound and not state.data.completed,"early book return does not prematurely complete demo")
	world.ui.close_all()
	state.flag("boss_purified")
	await visit("library")
	check(state.data.completed,"book-first order completes after guardian purification and return")
	world.ui.close_all()
	# Backup recovery verifies stored state, not just serialization success.
	state.data.major="politics"
	state.save_game()
	state.save_game()
	var corrupt=FileAccess.open(state.save_path,FileAccess.WRITE)
	corrupt.store_string("corrupted on purpose by isolated QA");corrupt.close()
	state.reset_data()
	check(state.load_game(),"corrupted primary save loads backup")
	check(state.data.completed and state.data.major=="politics" and "archive" in state.data.bound,"backup preserves ending, major, and stable books")
	# UI pauses physics and remains independent of in-world language.
	var before: Vector2=world.player.position
	world.ui.show_pause()
	Input.action_press("right")
	await settle(5)
	Input.action_release("right")
	check(world.player.position==before,"pause freezes gameplay")
	world.ui.close_all()
	var report={"checks":checks,"passed":checks.size()-failures.size(),"failed":failures.size(),"failures":failures,"scope":"Integration and physics tests; room changes and positioning in feature tests are explicit fixtures, not a timed human playthrough."}
	var report_path="res://tests/output/qa-report.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="): report_path=arg.trim_prefix("--report=")
	DirAccess.make_dir_recursive_absolute(report_path.get_base_dir())
	var output=FileAccess.open(report_path,FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"  "));output.close()
	print("QA_RESULT "+JSON.stringify({"passed":report.passed,"failed":report.failed}))
	world.shutdown_audio()
	await create_timer(0.2,true).timeout
	world.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)
