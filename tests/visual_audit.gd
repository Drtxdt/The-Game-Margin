extends "res://tests/qa_runner.gd"
## Render-only QA fixtures, separate from formal player saves.
var output_dir="res://tests/output"

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output_dir+"/"+name+".png")

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output_dir=arg.trim_prefix("--output=")
	state=root.get_node("State");state.save_path="user://visual_v2_qa.json";state.new_game()
	state.flag("cooper_rescued");state.flag("ruler")
	state.learn("math");state.learn("language")
	state.register_death("stacks",Vector2(600,623),[])
	state.data.echo_tool_level=2
	world=load("res://scenes/main.tscn").instantiate();root.add_child(world);current_scene=world
	world.playing=true;world.ui.close_all()
	DisplayServer.window_set_size(Vector2i(1920,1080))
	await visit("stacks",Vector2(570,580));await settle(35)
	world.ui.close_all();await shot("recovery-parcel")
	world.ui.show_map();await process_frame;await shot("recovery-map")
	check(world.ui.get_node("Map").visible,"map draws book parcels and separate echo markers")
	world.ui.close_all();state.collect_deaths([state.data.deaths[0].id])
	await visit("measure",Vector2(1320,580));await settle(25)
	world.observing=true;await process_frame;await shot("measure-observation")
	check(world.room.get_node("PeriodLift").observation().next_stop>=0,"live mathematical overlay renders current lift data")
	world.observing=false
	await visit("library",Vector2(900,580));world.ui.close_all();await settle(35)
	var camera=world.player.get_node("Camera2D")
	Input.action_press("right");await settle(30);Input.action_release("right");await settle(12)
	check(camera.look>90,"camera looks ahead during rightward movement")
	await shot("library-walk-right")
	Input.action_press("left");await settle(55);Input.action_release("left");await settle(12)
	check(camera.look< -90,"camera reverses ahead during leftward return")
	var feet=world.player.get_global_transform_with_canvas().origin.y/root.get_visible_rect().size.y
	check(feet>0.70 and feet<0.82,"standing feet stay around three quarters screen height")
	await shot("library-walk-left")
	Input.action_press("jump");await settle(16);Input.action_release("jump")
	await shot("library-jump")
	check(not world.player.is_on_floor(),"library jump renders with visible landing ground")
	var path=output_dir+"/visual-audit-report.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="): path=arg.trim_prefix("--report=")
	var file=FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failed":failures.size(),"scope":"Rendered audit with explicit room and inventory fixtures, including real camera movement and jump input. Screenshots require visual inspection."},"  "));file.close()
	world.shutdown_audio();await create_timer(0.2,true).timeout
	world.queue_free();await process_frame;await process_frame
	quit(0 if failures.is_empty() else 1)
