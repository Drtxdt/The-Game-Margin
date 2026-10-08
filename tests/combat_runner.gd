extends "res://tests/qa_runner.gd"
## Arena-start fixture. Once combat starts, only normal input is used: no HP,
## invulnerability, position, boss mode or purification overrides.
func run() -> void:
	state=root.get_node("State");state.save_path="user://combat_v2_qa.json";state.new_game()
	state.flag("ruler")
	state.data.checkpoint="bell";state.data.checkpoint_pos=[1630,580]
	world=load("res://scenes/main.tscn").instantiate();root.add_child(world);current_scene=world
	world.playing=true;world.ui.close_all();await settle(30)
	var boss=get_nodes_in_group("enemies")[0]
	var started=Time.get_ticks_msec()
	var least_hp=6
	var previous_hp=6
	for frame in range(3000):
		if state.data.total_deaths>0 or not is_instance_valid(boss) or boss.purified: break
		for action in ["left","right","attack","dodge","interact"]: Input.action_release(action)
		var dx: float=boss.position.x-world.player.position.x
		var distance=absf(dx)
		var direction=signf(dx)
		var axis=0.0
		var avoid_roar=boss.attack_kind=="roar" and boss.mode in ["tell","attack"]
		if avoid_roar:
			axis=-direction if distance<325 else 0.0
		elif boss.mode=="attack" and boss.attack_kind in ["charge","leap"]:
			if distance<125 and world.player.dash_cooldown<=0:
				axis=direction
				Input.action_press("dodge")
			else:
				var approaching=boss.facing==-direction
				axis=-direction if approaching else direction
		else:
			axis=direction if distance>135 else (-direction if distance<110 else 0.0)
			if distance<165 and boss.position.y>world.player.position.y-90:
				if world.player.facing!=direction: axis=direction
				if frame%19==0: Input.action_press("attack")
		if axis>0: Input.action_press("right")
		elif axis<0: Input.action_press("left")
		var nearest=world.nearest_interactable(world.player)
		if nearest!=null and nearest.kind=="bell" and boss.mode!="stun": Input.action_press("interact")
		least_hp=mini(least_hp,int(state.data.hp))
		if int(state.data.hp)<previous_hp: print("DAMAGE ",boss.attack_kind," player=",world.player.position," boss=",boss.position," dodge=",world.player.dash_left," dx=",dx)
		previous_hp=int(state.data.hp)
		if frame%180==0: print("COMBAT ",frame," hp=",state.data.hp," boss=",boss.hp," mode=",boss.mode," dx=",dx)
		await physics_frame
	for action in ["left","right","attack","dodge","interact"]: Input.action_release(action)
	world.ui.close_all()
	check(state.data.total_deaths==0,"normal-damage controller survives guardian without invulnerability override")
	check(is_instance_valid(boss) and boss.purified and state.has_flag("boss_purified"),"guardian purified through normal combat input and bell interaction")
	var report={"checks":checks,"failed":failures.size(),"passed":checks.size()-failures.size(),"lowest_health":least_hp,"elapsed_seconds":(Time.get_ticks_msec()-started)/1000.0,"scope":"Arena starting point and ruler are fixtures. Health, collision, attacks, stun, dodge and purification use production rules. Not a human difficulty benchmark."}
	var path="res://tests/output/combat-report.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="): path=arg.trim_prefix("--report=")
	var file=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
	world.shutdown_audio();await create_timer(0.2,true).timeout
	world.queue_free();await process_frame;await process_frame
	quit(0 if failures.is_empty() else 1)
