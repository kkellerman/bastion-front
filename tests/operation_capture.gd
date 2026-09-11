extends SceneTree
## Identical warm static views before/after; elapsed rendered frame times, not physics FPS.
func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var baseline: bool = "--baseline" in OS.get_cmdline_user_args()
	var boundaries: bool = "--boundaries" in OS.get_cmdline_user_args()
	var seeds: Array[int] = [1944]
	if not baseline: seeds.assign([1944, 1, 73])
	if boundaries: seeds.assign([1])
	for operation_seed: int in seeds:
		var session: Node = root.get_node("PrototypeSession")
		if "operation_seed" in session: session.operation_seed = operation_seed
		session.checkpoint.clear()
		var mission: Node3D = load("res://scenes/missions/forest_command_post.tscn").instantiate()
		root.add_child(mission)
		current_scene = mission
		await _frames(10)
		for enemy: Node in mission.get_node("Enemies").get_children(): enemy.set_physics_process(false)
		mission.player.set_physics_process(false)
		var camera: Camera3D = mission.player.get_node("Head/Camera3D")
		var views: Dictionary = {
			"forest": [Vector3(0, 0.05, 4), Vector3(0, 2, -22)],
			"fortification": [Vector3(1, 0.05, -39), Vector3(0, 1.8, -54)],
			"interior": [Vector3(2, 0.05, -65), Vector3(6, 1.3, -64)],
			"extraction": [Vector3(0, 0.05, -81), Vector3(0, 2, -88)]}
		if boundaries:
			views = {
				"east_boundary": [Vector3(12,0.05,-30),Vector3(27,3,-38)],
				"start_boundary": [Vector3(0,0.05,22),Vector3(0,3,35)],
				"west_boundary": [Vector3(-18,0.05,11),Vector3(-28,3,-5)]}
		for preset: int in [0, 3]:
			root.get_node("PlayerSettings").values.graphics_preset = preset
			root.get_node("PlayerSettings").apply()
			for key: String in views:
				mission.player.position = views[key][0]
				# Baseline benchmark faces north at each stop. Player handling owns
				# camera-local rotation, so aim the head/body for the separate captures.
				mission.player.rotation = Vector3.ZERO
				mission.player.get_node("Head").rotation = Vector3.ZERO
				await _frames(45)
				var times: Array[float] = []
				for i: int in range(90):
					var start: int = Time.get_ticks_usec()
					await process_frame
					await RenderingServer.frame_post_draw
					times.append((Time.get_ticks_usec() - start) / 1000.0)
				times.sort()
				print("BENCH seed=%d preset=%d view=%s median_ms=%.2f p95_ms=%.2f draws=%d primitives=%d" % [operation_seed, preset, key, times[45], times[85], Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])
				if not baseline:
					var offset: Vector3 = views[key][1] - camera.global_position
					mission.player.rotation.y = atan2(-offset.x,-offset.z)
					mission.player.get_node("Head").rotation.x = atan2(offset.y, Vector2(offset.x,offset.z).length())
					await _frames(45)
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png("res://docs/screenshots/operation_%d_%s_%s.png" % [operation_seed, "auto" if preset == 0 else "high", key])
		mission.queue_free()
		await _frames(5)
	quit()

func _frames(count: int) -> void:
	for i: int in range(count): await process_frame
