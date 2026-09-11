extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.get_node("PlayerSettings").values.graphics_preset = 3
	var mission: Node3D = load("res://scenes/missions/forest_command_post.tscn").instantiate()
	root.add_child(mission)
	current_scene = mission
	for i: int in range(8): await process_frame
	for enemy: Node in mission.get_node("Enemies").get_children(): enemy.process_mode = Node.PROCESS_MODE_DISABLED
	mission.get_node("DefensiveMG").process_mode = Node.PROCESS_MODE_DISABLED
	mission.player.set_physics_process(false)
	mission.get_node("MissionUI").hide()
	mission.player.get_node("PlayerVitals").hide()
	mission.rig.hide()
	mission.rig.get_node("WeaponHUD").hide()
	var camera: Camera3D = Camera3D.new()
	mission.add_child(camera)
	camera.position = Vector3(0, 1.3, 17)
	camera.look_at(Vector3(0, 0.95, 14))
	camera.fov = 50
	camera.make_current()
	for id: String in ["allied", "german"]:
		var faction: FactionData = load("res://resources/factions/" + id + ".tres")
		var model: Node3D = faction.uniform_scene.instantiate()
		mission.add_child(model)
		model.position = Vector3(-0.6 if id == "allied" else 0.6, 0, 14)
		model.rotation.y = PI
		model.get_node("AnimationPlayer").play("aim")
		var preview: Node3D = faction.weapons[1].viewmodel_scene.instantiate()
		var held: Node3D = preview.get_node("WeaponMesh").duplicate()
		preview.free()
		model.get_node("Skeleton3D/WeaponSocket").add_child(held)
		held.position = Vector3(0, 0.07, -0.06)
	var light: OmniLight3D = OmniLight3D.new()
	mission.add_child(light)
	light.position = Vector3(0, 3, 16)
	light.light_energy = 1.5
	light.omni_range = 6
	for i: int in range(90): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/validation/characters.png")
	mission.rig.show()
	mission.rig.get_node("WeaponHUD").show()
	mission.get_node("MissionUI").show()
	mission.player.get_node("PlayerVitals").show()
	mission.player.position = Vector3(0, 0.05, -14)
	mission.player.rotation.y = 0
	mission.player.get_node("Head/Camera3D").make_current()
	var target: InfantryBrain = mission.get_node("Enemies/ForestPatrol")
	target.position = Vector3(0, 0, -20)
	target.rotation.y = PI
	target.process_mode = Node.PROCESS_MODE_INHERIT
	target.set_physics_process(true)
	for i: int in range(120): await physics_frame
	print("Combat capture: player health ",mission.player.get_node("HealthComponent").current_health,"; enemy state ",target.state)
	mission.rig.weapon.try_fire()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/validation/combat.png")
	mission.queue_free()
	for i: int in range(20): await process_frame
	quit()
