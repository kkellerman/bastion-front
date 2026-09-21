extends SceneTree
var failures: int = 0
var captures: bool = false

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	captures = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	root.get_node("PlayerSettings").values.graphics_preset = 4
	for faction: StringName in [&"allied", &"german"]:
		root.get_node("PrototypeSession").faction_id = faction
		root.get_node("PrototypeSession").checkpoint.clear()
		var mission: Node3D = load("res://scenes/missions/forest_command_post.tscn").instantiate()
		root.add_child(mission)
		current_scene = mission
		await _frames(10)
		if captures: _check(root.get_node("PlayerSettings").applied_preset == 2, "Rendered validation uses High")
		var gun: MountedWeapon = mission.get_node("DefensiveMG")
		var actor: InfantryBrain = mission.get_node("Enemies/Gunner")
		for enemy: InfantryBrain in mission.get_node("Enemies").get_children():
			if enemy != actor: enemy.set_physics_process(false)
		var player: FirstPersonPlayer = mission.player
		player.get_node("HealthComponent").max_health = 10000
		player.get_node("HealthComponent").reset()
		_check(gun.data.weapon_id == (&"mg42" if faction == &"allied" else &"m1919"), str(faction) + " faces correct faction emplacement")
		_check(actor.mounted_weapon == gun and not actor.combat.enabled, "Single mounted combat owner")
		_check(actor.position.distance_to(gun.to_global(gun.operator_position)) < 0.2, "Gunner stays at operator point")
		player.position = Vector3(0, 0.05, -36)
		await _frames(160)
		_check(gun.weapon.magazine < gun.data.magazine_capacity, "Visible in-arc target receives mounted fire")
		_check(not gun.get_prompt().begins_with("E:"), "Hostile operator blocks capture")
		gun.weapon.magazine = 0
		await _frames(90)
		_check(gun.weapon.is_reloading, "Gunner starts belt reload when empty")
		await create_timer(gun.data.reload_time).timeout
		_check(not gun.weapon.is_reloading and gun.weapon.magazine > 0, "Gunner reload completes and combat resumes")
		if captures:
			await _capture(mission, Vector3(2.6, 1.7, -48.0), actor.position + Vector3.UP * 1.3, "nest_" + str(gun.data.weapon_id))
		player.position = gun.to_global(Vector3(12, 0.05, 0))
		await _frames(10)
		var rounds: int = gun.weapon.magazine
		await _frames(80)
		_check(gun.weapon.magazine == rounds, "Flank outside yaw arc stays safe")
		player.position = gun.to_global(Vector3(0, 10, -3))
		player.set_physics_process(false)
		await _frames(10)
		_check(not gun.can_engage(), "Pitch limit rejects elevated target")
		player.position = Vector3(0, 0.05, -36)
		var cover: StaticBody3D = StaticBody3D.new()
		mission.add_child(cover)
		cover.position = Vector3(0, 2, -42)
		var collision: CollisionShape3D = CollisionShape3D.new()
		var shape: BoxShape3D = BoxShape3D.new()
		shape.size = Vector3(4, 4, 1)
		collision.shape = shape
		cover.add_child(collision)
		await _frames(15)
		rounds = gun.weapon.magazine
		await _frames(90)
		_check(not gun.can_engage() and gun.weapon.magazine == rounds, "Cover blocks detection and muzzle ray")
		cover.queue_free()
		actor.set_physics_process(false)
		await _frames(2)
		_check(not gun.has_defender() and gun.defender == null, "Disabled operator releases mount")
		gun.interact(player)
		_check(gun.occupant == player, "Disabled gunner permits capture")
		gun.dismount()
		actor.set_physics_process(true)
		gun.bind_defender(actor)
		actor.health.take_damage(10000)
		await _frames(3)
		_check(gun.defender == null and not gun.flash.visible, "Death releases mount and stops effects")
		gun.interact(player)
		_check(gun.occupant == player, "Dead gunner permits capture")
		gun.dismount()
		await _handling(mission)
		var perimeter: Node3D = mission.get_node("MissionPerimeter")
		_check(perimeter.has_node("TerrainBanks") and perimeter.get_meta(&"horizon_tree_count", 0) > 250, "Continuous banks and bounded forest backdrop installed")
		_check(mission.get_node("Extraction").position.z > -87, "Extraction precedes rear berm")
		var faces: PackedVector3Array = perimeter.get_node("TerrainBanks").mesh.get_faces()
		_check(faces.size() > 600, "Perimeter has continuous terrain geometry around all four sides")
		player.position = Vector3(80, 0.1, -20)
		await _frames(2)
		_check(perimeter.return_count == 1 and player.position.distance_to(Vector3(0, 0.2, 18)) < 0.2, "Unintended escape returns to safe start")
		root.get_node("PrototypeSession").checkpoint = {"position": Vector3(0, 0.05, -57)}
		player.position = Vector3(0, -8, -57)
		await _frames(2)
		_check(perimeter.return_count == 2 and player.position.distance_to(Vector3(0, 0.15, -57)) < 0.2, "Fall recovery uses checkpoint without resetting objective/ammo")
		if captures:
			perimeter._warning_time = 0
			await _frames(2)
			await _capture(mission, Vector3(0, 1.65, -81), Vector3(0, 1.8, -87), "extraction_boundary")
			await _capture(mission, Vector3(12, 1.65, -30), Vector3(27, 4, -38), "east_perimeter")
			await _capture(mission, Vector3(0, 1.65, 22), Vector3(0, 3, 35), "start_perimeter")
			await _capture(mission, Vector3(3.5, 1.65, -65), Vector3(6, 1.2, -64), "radio_room_high")
		mission.queue_free()
		await _frames(8)
	print("Handling/nests/perimeter smoke: %d failure(s)" % failures)
	quit(0 if failures == 0 else 1)

func _handling(mission: Node3D) -> void:
	var rig: Node3D = mission.rig
	mission.player.position = Vector3(0, 0.05, 18)
	mission.player.set_physics_process(false)
	for index: int in range(rig.inventory.weapons.size()):
		rig.inventory.select(index)
		await _frames(3)
		var weapon: WeaponBase = rig.weapon
		rig.handling.reset()
		rig.handling.shot(weapon.data)
		var first: float = rig.handling.kick.x
		for i: int in range(4): rig.handling.shot(weapon.data)
		_check(rig.handling.kick.x >= first and rig.handling.kick.x <= weapon.data.handling.max_climb, str(weapon.data.weapon_id) + " recoil accumulates within profile cap")
		await _frames(130)
		_check(rig.handling.kick.length() < 0.01, "Recoil recovers to player aim")
		weapon.magazine = maxi(0, weapon.data.magazine_capacity - 2)
		var before: int = weapon.magazine
		var reserve: int = weapon.reserve
		weapon.try_reload()
		await create_timer(weapon.data.reload_time * 0.55).timeout
		_check(weapon.magazine == before and rig.viewmodel.reload_motion.stage == &"insert", "Reload visual stage follows gameplay clock before transfer")
		if captures and index == 1: await _capture_view("reload_" + str(weapon.data.weapon_id))
		await create_timer(weapon.data.reload_time * 0.6).timeout
		_check(not weapon.is_reloading and weapon.magazine == weapon.data.magazine_capacity and weapon.reserve == reserve - (weapon.magazine - before), "Reload completes with exactly one ammo transfer")

func _capture(mission: Node3D, position: Vector3, target: Vector3, name: String) -> void:
	var camera: Camera3D = Camera3D.new()
	mission.add_child(camera)
	camera.global_position = position
	camera.look_at(target)
	camera.make_current()
	await _frames(20)
	await _capture_view(name)
	camera.queue_free()
	mission.player.get_node("Head/Camera3D").make_current()

func _capture_view(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/" + name + ".png")

func _frames(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame

func _check(ok: bool, message: String) -> void:
	print("PASS: " if ok else "FAIL: ", message)
	if not ok: failures += 1
