extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var settings: Node = root.get_node("PlayerSettings")
	var preset_name: String = "auto"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--preset="): preset_name = argument.trim_prefix("--preset=")
	settings.values.graphics_preset = {"auto":0,"low":1,"medium":2,"high":3}.get(preset_name,0)
	var mission: Node3D = load("res://scenes/missions/forest_command_post.tscn").instantiate() as Node3D
	root.add_child(mission)
	current_scene = mission
	for enemy: Node in mission.get_node("Enemies").get_children():
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
	mission.get_node("DefensiveMG").process_mode = Node.PROCESS_MODE_DISABLED
	var player: Node3D = mission.get_node("Player") as Node3D
	player.set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var positions: Array[Vector3] = [Vector3(0, 0.05, 18), Vector3(0, 0.05, -55), Vector3(4, 0.05, -62), Vector3(-4, 0.05, -72)]
	var names: Array[String] = ["forest", "bunker", "radio", "operations"]
	var prefix: String = "polish_" + preset_name
	DirAccess.make_dir_recursive_absolute("res://.godot/validation")
	for i: int in range(positions.size()):
		player.position = positions[i]
		player.rotation.y = -0.5 if i == 2 else 0.0
		for frame: int in range(100):
			await process_frame
		var start: int = Time.get_ticks_usec()
		for frame: int in range(90):
			await process_frame
		print("%s %s: %.1f FPS / %d draw calls / %d primitives" % [prefix, names[i], 90000000.0 / float(Time.get_ticks_usec() - start), Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/validation/" + prefix + "_" + names[i] + ".png")
	mission.queue_free()
	await process_frame
	quit()
