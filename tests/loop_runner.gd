extends "res://tests/route_runner.gd"
## Room entry fixtures; all shelf, lift and shortcut traversal uses actual inputs.

func run() -> void:
	state=root.get_node("State");state.save_path="user://loop_v2_qa.json";state.new_game()
	world=load("res://scenes/main.tscn").instantiate();root.add_child(world);current_scene=world
	world.playing=true;world.ui.close_all();await frames(15)
	world.change_room("stacks",Vector2(150,580));await frames(20)
	await walk(470,526);await walk(630,441);await walk(1150,435)
	check(await use(1290,329) and "stacks_old_register" in state.data.notes,"optional upper archive is reachable and records discovery")
	for phase in [0.0,1.0,2.0,3.0]:
		if failed: break
		world.change_room("measure",Vector2(1320,580));await frames(20)
		world.room.get_node("PeriodLift").phase=phase
		await cross_measure_lift()
	if not failed:
		world.change_room("hall",Vector2(2170,290));await frames(25)
		await use(2170,321)
		check(state.has_flag("hall_stairs_open"),"upper latch permanently unfolds stairs")
		await walk(2390)
		await walk(2310,583);await walk(2210,495);await walk(2110,407)
		check(await walk(2170,321),"unfolded stairs climb from ground back to upper hall")
		state.save_game();state.reset_data();state.load_game()
		world.change_room("hall",Vector2(2390,580));await frames(20)
		check(world.room.get_node("FoldingStairs").open,"permanent stairs remain open after saved reload")
	await finish()

func finish() -> void:
	var path="res://tests/output/loop-report.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="): path=arg.trim_prefix("--report=")
	var file=FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":results,"failed":failed,"scope":"Room and lift phase fixtures; actual movement through optional shelf, four lift phases and permanent return staircase. Geometry audit suppresses combat damage."},"  "));file.close()
	world.shutdown_audio();await create_timer(0.2,true).timeout
	world.queue_free();await process_frame;await process_frame
	quit(1 if failed else 0)
