extends SceneTree

var world: Node
var state: Node
var output_dir="res://tests/output"

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output_dir=arg.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(output_dir)
	state=root.get_node("State");state.save_path="user://render_qa.json";state.new_game()
	state.flag("cooper_rescued");state.flag("ruler")
	state.learn("math");state.learn("language");state.bind_books()
	world=load("res://scenes/main.tscn").instantiate();root.add_child(world);current_scene=world
	world.playing=true;world.ui.close_all()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920,1080))
	AudioServer.set_bus_mute(0,true)
	var samples=[]
	for id in ["library","bell","archive"]:
		world.change_room(id,Vector2(900 if id=="library" else 1530,580))
		await create_timer(1).timeout
		world.player.invulnerable=100
		if id=="library":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output_dir+"/standalone-library-before.png")
			state.learn("archive");state.bind_books();state.flag("boss_purified");world.update_library()
			await create_timer(1).timeout
		var start=Time.get_ticks_usec()
		var last=start
		var times: Array[float]=[]
		while Time.get_ticks_usec()-start<5000000:
			await process_frame
			var now=Time.get_ticks_usec()
			times.append(float(now-last)/1000.0);last=now
		var sorted=times.duplicate();sorted.sort()
		var mean=times.reduce(func(a,b):return a+b,0.0)/times.size()
		var sample={"room":id,"window":str(DisplayServer.window_get_size()),"viewport":str(root.get_visible_rect().size),"frames":times.size(),"mean_ms":mean,"p95_ms":sorted[int(sorted.size()*0.95)],"worst_ms":sorted.back(),"average_fps":1000.0/mean,"process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000,"physics_ms":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"orphan_nodes":Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),"memory_mb":Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0}
		samples.append(sample);print("RENDER_SAMPLE ",JSON.stringify(sample))
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output_dir+"/standalone-"+id+".png")
		if id=="library": state.data.flags.erase("boss_purified")
	var file=FileAccess.open(output_dir+"/standalone-performance.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"renderer":RenderingServer.get_current_rendering_method(),"gpu":RenderingServer.get_video_adapter_name(),"engine":Engine.get_version_info().string,"samples":samples,"scope":"Standalone rendered scenes, five seconds per room, includes active boss simulation. Not a full-session performance guarantee."},"  "));file.close()
	world.shutdown_audio();await create_timer(0.2).timeout
	world.queue_free();await process_frame;await process_frame
	quit()
