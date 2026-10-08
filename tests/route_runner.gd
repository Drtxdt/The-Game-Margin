extends SceneTree
## Geometry and progression playthrough. Combat damage is disabled for this route-only audit.
var world: Node
var state: Node
var results: Array=[]
var failed=false

func _initialize() -> void:
	run.call_deferred()

func frames(count: int) -> void:
	for i in range(count): await physics_frame

func check(ok: bool, label: String) -> void:
	results.append({"name":label,"passed":ok})
	print(("PASS " if ok else "FAIL ")+label)
	failed=failed or not ok

func release() -> void:
	for a in ["left","right","jump","interact"]: Input.action_release(a)

func walk(x: float, y: float=623) -> bool:
	if failed: return false
	world.ui.close_all()
	await frames(3)
	var original_room: String=world.room_id
	var target=Vector2(x,y)
	var success=false
	for i in range(600):
		if world.room_id!=original_room: break
		world.player.invulnerable=1000
		var p: Vector2=world.player.position
		if i%120==119: print("WALK ",world.room_id," ",p," target ",target)
		var dx=x-p.x
		Input.action_release("left");Input.action_release("right")
		if absf(dx)>6: Input.action_press("right" if dx>0 else "left")
		if world.player.is_on_floor():
			if Input.is_action_pressed("jump"):
				Input.action_release("jump")
				await frames(3)
				continue
			if absf(dx)<13 and absf(p.y-y)<30:
				success=true;break
			var direction=signf(dx)
			var ahead=p+Vector2(direction*45,-6)
			var query=PhysicsRayQueryParameters2D.create(ahead,ahead+Vector2(0,100),1)
			var gap=world.get_world_2d().direct_space_state.intersect_ray(query).is_empty()
			if y<p.y-32 and absf(dx)<190 or gap:
				Input.action_press("jump")
		await frames(3)
	release()
	if not success:
		print("WALK_BLOCKED ",world.room_id," at ",world.player.position," target ",target)
		failed=true
	return success

func use(x: float, y: float=623) -> bool:
	if not await walk(x,y): return false
	await frames(3)
	Input.action_press("interact");await frames(3);Input.action_release("interact")
	await frames(6)
	world.ui.close_all()
	return true

func cross_measure_lift() -> void:
	if not await walk(1460): return
	var lift=world.room.get_node("PeriodLift")
	var boarded=false
	var jumped=false
	var jump_frame=-100
	for i in range(600):
		var p: Vector2=world.player.position
		Input.action_release("left");Input.action_release("right")
		if jumped and i-jump_frame>12 and world.player.is_on_floor() and p.y>610:
			Input.action_release("jump")
			jumped=false
			await frames(3)
			continue
		if not jumped and lift.position.y>525 and world.player.is_on_floor():
			Input.action_press("jump");jumped=true
			jump_frame=i
		if jumped:
			if world.player.is_on_floor() and p.y<570:
				boarded=true;break
		await frames(1)
	release()
	if not boarded: print("BOARD_FAILED ",world.player.position," lift=",lift.position)
	check(boarded,"moving lift boarded with real input")
	if not boarded: return
	for i in range(250):
		await frames(1)
		if world.player.is_on_floor() and world.player.position.y<502: break
	check(await walk(1615,426),"lift reaches transfer landing")
	check(await walk(1760,407),"counterweight housing crossed without knowledge gate")

func door(x: float, expected: String, y: float=623) -> void:
	var reached=await use(x,y)
	check(reached and world.room_id==expected,"normal traversal enters "+expected)

func finish() -> void:
	var path="res://tests/output/route-report.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="): path=arg.trim_prefix("--report=")
	var file=FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":results,"failed":failed,"scope":"Normal exploration uses actual input from the gate. Combat damage is suppressed to isolate reachability; boss purification is a fixture covered by traversal_runner. Alternate branches explicitly restart at junction. This is not first-time human timing."},"  "));file.close()
	world.shutdown_audio();await create_timer(0.2,true).timeout
	world.queue_free();await process_frame;await process_frame
	quit(1 if failed else 0)

func run() -> void:
	state=root.get_node("State");state.save_path="user://route_qa.json";state.new_game()
	world=load("res://scenes/main.tscn").instantiate();root.add_child(world);current_scene=world
	world.playing=true;world.ui.close_all()
	Engine.time_scale=1;Engine.physics_ticks_per_second=60
	await frames(15)
	if "--stacks-check" in OS.get_cmdline_user_args():
		world.change_room("stacks",Vector2(150,580));await frames(20)
		check(await walk(470,526),"first shelf step")
		check(await walk(630,441),"second shelf step")
		check(await use(920,435),"book shelf")
		await finish();return
	if "--measure-check" in OS.get_cmdline_user_args():
		world.change_room("measure",Vector2(150,580));await frames(20)
		await cross_measure_lift()
		check(await walk(1930,521),"measure first stair")
		check(await walk(2090,436),"measure second stair")
		check(await walk(2250,351),"measure third stair")
		check(await walk(2560,306),"measure middle landing")
		check(await walk(2840,271),"measure approach landing")
		await door(3260,"hall",267)
		await finish();return
	if "--maintenance-check" in OS.get_cmdline_user_args():
		world.change_room("maintenance",Vector2(150,580));await frames(20)
		await use(780)
		await walk(1490,526);await walk(1650,441);await walk(1810,356)
		check(await use(2050,351),"upper service breaker reachable")
		check(await use(3820),"last service breaker reachable across gaps")
		await door(4590,"bell")
		await finish();return
	if "--gap-check" in OS.get_cmdline_user_args():
		world.change_room("courtyard",Vector2(1300,580));await frames(20)
		check(await walk(3390),"gap fixture reaches courtyard exit")
		await finish();return
	await use(650);check(state.has_flag("cooper_rescued"),"Cooper rescued through normal interaction")
	await door(2190,"courtyard")
	await door(3390,"hall")
	await door(1110,"equipment")
	await use(1150);check(state.has_flag("ruler"),"ruler collected through real movement")
	await door(120,"hall")
	await door(2410,"library")
	await door(1740,"stacks")
	await walk(470,526);await walk(630,441)
	await use(920,435);check(state.knows("math"),"mathematics book reachable on shelf")
	await use(2310);check(state.knows("language"),"language book reachable beyond gap")
	await door(3340,"measure")
	await cross_measure_lift()
	await walk(1930,521);await walk(2090,436);await walk(2250,351)
	await walk(2560,306);await walk(2840,271)
	await door(3260,"hall",267)
	if failed: await finish();return
	await use(2170,321)
	check(state.has_flag("hall_stairs_open"),"first loop opens permanent folding stairs")
	await door(2410,"library")
	await use(1010);check(state.data.held.is_empty() and "math" in state.data.bound,"first loop returns and binds books")
	await door(1530,"echo")
	await door(2780,"junction")
	state.data.san=0
	await door(2510,"maintenance")
	await use(780)
	await walk(1490,526);await walk(1650,441);await walk(1810,356)
	await use(2050,351);await use(3820)
	check(state.has_flag("service_open"),"common route opens without any active echo or sanity")
	await door(4590,"bell")
	await use(310);check(state.data.checkpoint=="bell","boss checkpoint reached through ordinary route")
	state.flag("boss_purified")
	await frames(3)
	await door(2690,"research")
	await door(3240,"archive")
	await walk(2110,526);await walk(2270,441);await walk(2430,356)
	await use(2600,351);check(state.knows("archive"),"important archive reachable on upper shelf")
	await use(3240)
	await door(3510,"stacks")
	await door(130,"library")
	await use(1010);check(state.data.completed,"normal no-echo journey reaches library ending")
	if failed: await finish();return
	for major in ["physics","politics"]:
		state.new_game();state.flag("ruler");state.data.major=major;state.data.san=0
		world.change_room("junction",Vector2(560,580));await frames(20)
		await door(1050 if major=="physics" else 1740,"machine" if major=="physics" else "security")
		if major=="physics":
			await use(2190);await use(2190);await frames(300)
		else:
			await walk(2490)
			Input.action_press("interact");await frames(3);Input.action_release("interact");await frames(2)
			world.ui.choose(1);await frames(3)
		await door(3180,"bell")
		check(world.room_id=="bell",major+" route reaches arena from junction without active echo")
	await finish()
