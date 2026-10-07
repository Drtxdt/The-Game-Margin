extends SceneTree

var world: Node
var state: Node
var checks: Array=[]
var failures: Array=[]

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, message: String) -> void:
	checks.append({"name":message,"passed":value})
	print(("PASS " if value else "FAIL ")+message)
	if not value: failures.append(message)

func frames(count: int) -> void:
	for i in range(count): await physics_frame

func visit(id: String, point: Vector2) -> void:
	world.ui.close_all()
	world.change_room(id,point)
	await frames(15)

func release() -> void:
	for a in ["left","right","jump","attack","down","dodge","interact"]: Input.action_release(a)

func run() -> void:
	state=root.get_node("State")
	state.save_path="user://traversal_qa.json"
	state.new_game()
	state.flag("ruler")
	world=load("res://scenes/main.tscn").instantiate()
	root.add_child(world);current_scene=world
	world.playing=true;world.ui.close_all()
	await visit("junction",Vector2(3300,580))
	# Only the starting position is a fixture. Every ascent uses actual player input and collisions.
	var targets=[Vector2(3300,515),Vector2(3470,355),Vector2(3650,195)]
	var next=0
	var bounces=0
	Input.action_press("jump")
	Input.action_press("down")
	for i in range(340):
		var target: Vector2=targets[next] if next<3 else Vector2(3800,35)
		var dx: float=target.x-world.player.position.x
		Input.action_release("left");Input.action_release("right")
		if absf(dx)>5: Input.action_press("right" if dx>0 else "left")
		if next<3 and absf(dx)<58 and world.player.velocity.y>=-90 and world.player.position.y<target.y+7 and world.player.position.y>target.y-72 and world.player.attack_cooldown<=0:
			Input.action_press("attack")
			await frames(3)
			Input.action_release("attack")
		await frames(1)
		if world.player.velocity.y < -600 and next<3 and world.player.position.y<targets[next].y:
			bounces+=1;next+=1
			print("BOUNCE ",bounces," ",world.player.position)
		if next==3 and world.player.is_on_floor() and world.player.position.y<70:
			break
	release()
	check(bounces==3,"three metal rebounds execute through real S+J input")
	check(world.player.position.y<70 and world.player.is_on_floor(),"hidden high landing reached without teleport or velocity overrides")
	# Move along the landing to its door and enter through the normal interact action.
	Input.action_press("right");await frames(10);Input.action_release("right")
	Input.action_press("interact");await frames(1);Input.action_release("interact");await frames(12)
	check(world.room_id=="tower","hidden landing door actually enters tower")
	# Boss combat fixture: isolate the arena; strike and bell logic remain real.
	await visit("bell",Vector2(1630,580))
	var boss: Node=get_nodes_in_group("enemies")[0]
	var initial_hp: int=boss.hp
	world.player.position=Vector2(1715,620)
	Input.action_press("attack");await frames(1);Input.action_release("attack");await frames(15)
	check(boss.hp<initial_hp,"real ruler input damages guardian")
	world.ring_bell(Vector2(2080,620))
	check(boss.mode=="stun" and boss.decoy==Vector2(2080,620),"bell creates guardian opening and temporary target")
	await frames(20)
	var ringing_timer: float=boss.timer
	world.ring_bell(Vector2(720,620))
	check(boss.timer<=ringing_timer and boss.decoy==Vector2(2080,620),"repeated bells cannot indefinitely refresh guardian stun")
	await frames(160)
	check(boss.decoy==Vector2.INF,"bell distraction expires and guardian resumes tracking player")
	# A charging guardian collides with the real bell zone and stuns itself.
	boss.position=Vector2(2020,620);boss.mode="attack";boss.attack_kind="charge";boss.facing=1;boss.timer=0.6
	await frames(4)
	check(boss.mode=="stun","guardian charge into bell frame creates environmental opening")
	state.data.hp=6
	world.player.position=Vector2(1980,620)
	boss.position=Vector2(2070,620);boss.stun(20)
	for i in range(22):
		boss.stun(20)
		Input.action_press("attack");await frames(1);Input.action_release("attack");await frames(19)
		if boss.purified: break
	check(boss.purified and state.has_flag("boss_purified"),"guardian purification is reached by repeated actual strikes")
	world.ui.close_all()
	state.learn("archive");state.bind_books()
	await visit("library",Vector2(240,580))
	check(state.data.completed,"guardian-first order closes correctly after returning book")
	world.ui.close_all()
	# An unfinished battle resets through a checkpoint on reload.
	state.data.flags.erase("boss_purified");state.data.completed=false
	state.data.checkpoint="bell";state.data.checkpoint_pos=[310,580];state.save_game()
	await visit("bell",Vector2(310,580))
	boss=get_nodes_in_group("enemies")[0];boss.hp=17
	state.save_game();state.reset_data();state.load_game()
	await visit(str(state.data.checkpoint),Vector2(310,580))
	boss=get_nodes_in_group("enemies")[0]
	check(boss.hp==180 and not boss.purified,"unfinished guardian resets at saved arena checkpoint")
	var report={"passed":checks.size()-failures.size(),"failed":failures.size(),"checks":checks,"scope":"Hidden route is traversed with real inputs from a fixture at its base. Boss combat tests use explicit positioning and state fixtures; they are not a skill or difficulty benchmark."}
	var path="res://tests/output/traversal-report.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="): path=arg.trim_prefix("--report=")
	var file=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
	print("TRAVERSAL_RESULT ",JSON.stringify({"passed":report.passed,"failed":report.failed}))
	world.shutdown_audio();await create_timer(0.2,true).timeout
	world.queue_free();await process_frame;await process_frame
	quit(0 if failures.is_empty() else 1)
