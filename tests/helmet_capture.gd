extends SceneTree

const GERMAN_CHARACTER: PackedScene = preload("res://assets/characters/german/infantry_rigged.tscn")


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var mission: Node3D = load("res://scenes/missions/forest_command_post.tscn").instantiate()
	root.add_child(mission)
	current_scene = mission
	for frame: int in range(8):
		await process_frame

	for enemy: Node in mission.get_node("Enemies").get_children():
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
	mission.get_node("DefensiveMG").process_mode = Node.PROCESS_MODE_DISABLED
	mission.get_node("MissionUI").hide()
	mission.player.hide()
	mission.player.process_mode = Node.PROCESS_MODE_DISABLED

	var poses: Array[float] = [PI, PI + 0.72]
	for index: int in poses.size():
		var model: Node3D = GERMAN_CHARACTER.instantiate()
		mission.add_child(model)
		model.position = Vector3(-0.22 + index * 0.44, 0.0, 14.0)
		model.rotation.y = poses[index]
		model.get_node("AnimationPlayer").play("idle")

	var camera: Camera3D = Camera3D.new()
	mission.add_child(camera)
	camera.position = Vector3(0.0, 1.69, 15.55)
	camera.look_at(Vector3(0.0, 1.69, 14.0))
	camera.fov = 24.0
	camera.make_current()

	var key_light: OmniLight3D = OmniLight3D.new()
	mission.add_child(key_light)
	key_light.position = Vector3(-0.7, 2.25, 15.0)
	key_light.light_energy = 2.0
	key_light.omni_range = 4.0

	for frame: int in range(45):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/validation/german_helmet_fit.png")

	# A higher angle catches open crown geometry that the eye-level fit view hides.
	camera.position = Vector3(0.0, 2.08, 15.42)
	camera.look_at(Vector3(0.0, 1.74, 14.0))
	for frame: int in range(12):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/validation/german_helmet_top.png")
	mission.queue_free()
	for frame: int in range(5):
		await process_frame
	quit()
