extends "res://tests/qa_runner.gd"

func walk_to(x: float) -> void:
	world.ui.close_all()
	for i in range(400):
		var dx: float=x-world.player.position.x
		if absf(dx)<8: break
		Input.action_release("left");Input.action_release("right")
		Input.action_press("right" if dx>0 else "left")
		await physics_frame
	Input.action_release("left");Input.action_release("right")
	await settle(6)

func press_use() -> void:
	Input.action_press("interact");await settle(2)
	Input.action_release("interact");await settle(2)

func run() -> void:
	state=root.get_node("State")
	state.save_path="user://recovery_v2_qa.json";state.new_game()
	state.data.checkpoint="stacks";state.data.checkpoint_pos=[2100,580]
	world=load("res://scenes/main.tscn").instantiate();root.add_child(world);current_scene=world
	world.playing=true;world.ui.close_all();await settle(25)
	check(not world.begin_recording() and not world.play_echo(),"record and replay require librarian tool")
	await walk_to(2280);await press_use()
	check("language" in state.data.held,"real movement and E pick up language book")
	world.ui.close_all()
	var enemy=load("res://scenes/entities/enemy.tscn").instantiate()
	enemy.kind="watcher";enemy.stable_id="test_lethal_watcher";enemy.position=Vector2(2450,620)
	world.room.add_child(enemy)
	state.data.hp=1;world.player.invulnerable=0
	for i in range(240):
		await physics_frame
		if state.data.total_deaths>0 and not world.transitioning: break
	await settle(20)
	check(state.data.total_deaths==1 and state.data.held.is_empty(),"actual enemy attack kills carrier and respawns at checkpoint")
	check(get_nodes_in_group("recovery_points").size()==1,"death creates visible stationary recovery scene")
	var marker=get_nodes_in_group("recovery_points")[0]
	check(marker.visible and not marker.book_names.is_empty(),"parcel is visible and names its book")
	var before_cap: float=state.data.san_max
	await walk_to(marker.position.x-25);await press_use()
	check("language" in state.data.held,"walk back after respawn and E reclaim actual lost book")
	check(state.data.san_max==before_cap and not state.data.deaths[0].recovered,"books recover without unlocking debt recovery")
	state.save_game();state.reset_data();check(state.load_game() and "language" in state.data.held,"reclaimed book survives save reload")
	state.bind_books()
	for i in range(4): state.register_death("stacks",Vector2(450+i*140,623),[])
	await visit("library");world.ui.close_all()
	check(state.data.total_deaths==5 and state.data.echo_tool_level==1,"fifth death and library gift do not unlock stitching")
	state.register_death("stacks",Vector2(1200,623),[])
	check(state.data.echo_tool_level==1,"sixth death alone does not remotely upgrade tool")
	await visit("library");world.ui.close_all()
	check(state.data.echo_tool_level==2,"sixth death followed by librarian meeting unlocks stitching")
	check(state.meet_librarian()=="","librarian gift and upgrade are one-shot")
	for i in range(6): state.register_death("stacks",Vector2(1500,623),[])
	check(state.data.san_max==55,"cap reaches floor without blocking gameplay")
	await visit("stacks");world.ui.close_all()
	check(get_nodes_in_group("recovery_points").size()>3 and get_nodes_in_group("death_visuals").size()==3,"all recovery markers survive three-visual limit")
	var ids: Array=[]
	for death in state.data.deaths: ids.append(death.id)
	var hp: int=state.data.hp
	var result=state.collect_deaths(ids)
	check(result.debt==45 and state.data.san_max==100 and state.data.hp==hp,"actual debt restores exactly 45 cap and does not heal body")
	check(state.collect_deaths(ids).debt==0 and state.data.san_max==100,"repeat recovery cannot mint sanity")
	await settle(3)
	check(get_nodes_in_group("death_visuals").is_empty(),"recovered death playback stops")
	# Legacy duplicate ownership and unsafe position are repaired without resetting progress.
	var legacy=state.data.duplicate(true);legacy.version=1
	legacy.visited=["library","stacks"];legacy.held=["math"]
	legacy.deaths=[DeathImprint.create("stacks",Vector2(1800,950),[],5,["math","archive"])]
	legacy.san_max=95;legacy.san=80
	for key in ["total_deaths","echo_tool_level","discovered_exits","checkpoints"]: legacy.erase(key)
	var file=FileAccess.open(state.save_path,FileAccess.WRITE);file.store_string(JSON.stringify(legacy));file.close()
	state.reset_data();check(state.load_game(),"version one save migrates")
	check(state.data.version==2 and state.data.echo_tool_level==1 and state.data.total_deaths==1,"migration derives tool and death count")
	check(FileAccess.file_exists(state.save_path+".v1-backup"),"migration preserves independent original backup")
	check(state.data.deaths[0].books==["archive"] and "math" in state.data.held,"migration enforces unique book ownership")
	await visit("stacks");world.ui.close_all()
	check(state.data.deaths[0].point[1]<680 and world.safe_ground(Vector2(state.data.deaths[0].point[0],state.data.deaths[0].point[1])),"unsafe legacy drop moves to reachable floor")
	state.save_game();state.save_game()
	file=FileAccess.open(state.save_path,FileAccess.WRITE);file.store_string("broken");file.close()
	state.reset_data();check(state.load_game() and state.data.deaths[0].books==["archive"],"backup restores dropped books and migrated state")
	# Falling is driven by movement, with no repositioning after death. Inventory is a fixture.
	state.new_game();state.data.checkpoint="courtyard";state.data.checkpoint_pos=[1300,580]
	state.learn("math");state.learn("language")
	await visit("courtyard",Vector2(1300,580));await settle(25)
	Input.action_press("right")
	for i in range(100):
		await physics_frame
		if world.player.position.x>1460: break
	Input.action_release("right")
	for i in range(160):
		await physics_frame
		if state.data.total_deaths>0 and not world.transitioning: break
	await settle(20)
	check(state.data.total_deaths==1 and state.data.held.is_empty(),"actual pit fall drops multiple carried books")
	marker=get_nodes_in_group("recovery_points")[0]
	check(world.safe_ground(marker.position) and marker.book_names.size()==2,"pit parcel contains both books on stable reachable floor")
	await walk_to(marker.position.x-20);await press_use()
	check(state.knows("math") and state.knows("language"),"walk from checkpoint recovers both books without trial abilities")
	var anchors_valid=true
	for room_id in RoomCatalog.ROOMS:
		await visit(room_id)
		anchors_valid=anchors_valid and world.safe_ground(world.recovery_fallback())
	check(anchors_valid,"all sixteen authored fallback anchors pass ground and clearance checks")
	await visit("measure")
	check(not world.safe_ground(world.room.get_node("PeriodLift").position) and not world.safe_ground(Vector2(1760,623)),"moving lift and blocked housing floor reject recovery placement")
	await visit("bell")
	check(not world.safe_ground(Vector2(1500,623)),"active guardian arena relocates drops to approach side")
	state.new_game()
	for book in ["math","language","archive"]:
		state.learn(book);state.register_death("stacks",Vector2(400+state.data.total_deaths*160,623),[])
	for i in range(3): state.register_death("stacks",Vector2(1100+i*160,623),[])
	await visit("stacks");world.ui.close_all()
	var visible_books=0
	for point in get_nodes_in_group("recovery_points"): visible_books+=point.book_names.size()
	check(visible_books==3 and get_nodes_in_group("death_visuals").size()==3,"six consecutive deaths retain all three older book parcels")
	await visit("library");world.ui.close_all()
	check(state.data.echo_tool_level==2,"first librarian meeting after six deaths gifts and upgrades together")
	state.save_game();state.reset_data();state.load_game()
	check(state.data.echo_tool_level==2 and state.data.total_deaths==6,"gift and upgrade persist after reload")
	await visit("stacks",Vector2(280,580));world.ui.close_all();await settle(20)
	state.data.hp=3
	await walk_to(380);await press_use()
	check(state.knows("math") and state.data.deaths[0].recovered and state.data.san_max==75 and state.data.hp==3,"one E recovers book and debt together without healing body")
	state.reset_data();state.load_game()
	check(state.knows("math") and state.data.deaths[0].recovered and state.collect_deaths([state.data.deaths[0].id]).debt==0,"reload preserves settlement and rejects duplicate refund")
	var report={"passed":checks.size()-failures.size(),"failed":failures.size(),"checks":checks,"failures":failures}
	var path="res://tests/output/recovery-report.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="): path=arg.trim_prefix("--report=")
	file=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
	world.shutdown_audio();await create_timer(0.2,true).timeout
	world.queue_free();await process_frame;await process_frame
	quit(0 if failures.is_empty() else 1)
