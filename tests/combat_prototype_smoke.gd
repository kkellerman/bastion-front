extends SceneTree
var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var main: Node3D = (load("res://scenes/missions/forest_command_post.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(main)
	current_scene = main
	var player: FirstPersonPlayer = main.get_node("Player") as FirstPersonPlayer
	var rig: Node3D = player.get_node("Head/Camera3D/WeaponRig") as Node3D
	var camera: Camera3D = player.get_node("Head/Camera3D") as Camera3D
	var hp: HealthComponent = player.get_node("HealthComponent") as HealthComponent
	var target: HealthComponent = main.get_node("RangeTargetA/HealthComponent") as HealthComponent
	await _frames(10)
	_check(rig.inventory.weapons.size() == 3, "Default Allied loadout is installed")
	for enemy: Node in main.get_node("Enemies").get_children():
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
	main.get_node("DefensiveMG").process_mode = Node.PROCESS_MODE_DISABLED
	if DisplayServer.get_name() != "headless":
		await _capture("combat_staging.png")
	var nav_map: RID = main.get_world_3d().navigation_map
	var path: PackedVector3Array = NavigationServer3D.map_get_path(nav_map, Vector3(0, 0, 18), Vector3(-5, 0, -72.5), true)
	_check(path.size() > 1 and path[path.size() - 1].distance_to(Vector3(-5, 0, -72.5)) < 1.0, "Navigation connects forest start to operations room")
	path = NavigationServer3D.map_get_path(nav_map, Vector3(-5, 0, -72.5), Vector3(0, 0, -85), true)
	_check(path.size() > 1 and path[path.size() - 1].distance_to(Vector3(0, 0, -85)) < 1.0, "Navigation connects operations room to rear extraction")
	for faction: FactionData in [main.allied, main.german]:
		rig.inventory.configure(faction)
		player.get_node("DamageReceiver").set_faction(faction)
		await _frames(2)
		for slot: int in range(rig.inventory.weapons.size()):
			rig.inventory.select(slot)
			player.position = Vector3(-18, 0.03, 4)
			player.rotation = Vector3.ZERO
			player.get_node("Head").rotation = Vector3.ZERO
			camera.rotation = Vector3.ZERO
			await _frames(3)
			target.reset()
			var data: WeaponData = rig.weapon.data
			var magazine: int = rig.weapon.magazine
			_check(rig.weapon.try_fire(), data.display_name + " fires")
			_check(rig.weapon.magazine == magazine - 1, data.display_name + " consumes ammunition")
			if data.hitscan_or_projectile == WeaponData.ShotType.HITSCAN:
				_check(target.current_health == 100.0 - data.damage, data.display_name + " hitscan damages target")
			else:
				_check(get_nodes_in_group(&"explosive_projectiles").size() == 1, data.display_name + " launches a physical projectile")
				await _frames(90)
				_check(target.current_health == 0.0, data.display_name + " impact explosion destroys target")
				_check(get_nodes_in_group(&"explosive_projectiles").is_empty(), "Rocket is cleaned up after impact")
			await _frames(15)
		player.position = Vector3(-18, 0.03, 4)
		camera.rotation.x = 0.3
		var grenades: int = rig.inventory.pool.get_amount(faction.grenade.reserve_ammo_type)
		_check(rig.throw_grenade(), faction.grenade.display_name + " throws")
		_check(rig.inventory.pool.get_amount(faction.grenade.reserve_ammo_type) == grenades - 1, "Grenade inventory decrements once")
		_check(not rig.throw_grenade(), "Grenade throw cooldown blocks duplicate throw")
		await _frames(190)
		_check(get_nodes_in_group(&"explosive_projectiles").is_empty(), "Grenade fuse detonates and cleans up")
		hp.reset()

	var blast_data: WeaponData = main.allied.grenade.duplicate() as WeaponData
	blast_data.blast_radius = 8.0
	target.reset()
	var shielded: ExplosiveProjectile = blast_data.projectile_scene.instantiate() as ExplosiveProjectile
	shielded.data = blast_data
	shielded.source = player
	main.add_child(shielded)
	shielded.global_position = Vector3(-18, 1.65, -8)
	shielded.detonate()
	_check(target.current_health == 100.0, "Solid backstop shields target from explosion")
	await _frames(2)
	var second_target: HealthComponent = main.get_node("RangeTargetB/HealthComponent") as HealthComponent
	second_target.reset()
	var exposed: ExplosiveProjectile = blast_data.projectile_scene.instantiate() as ExplosiveProjectile
	exposed.data = blast_data
	exposed.source = player
	main.add_child(exposed)
	exposed.global_position = Vector3(-18, 1.65, -1.5)
	exposed.detonate()
	_check(target.current_health == 0.0 and second_target.current_health > 0.0 and second_target.current_health < 100.0, "Explosion damage falls off with distance")
	_check(hp.current_health < 100.0, "Explosions can damage their owner")
	hp.reset()
	await _frames(2)

	rig.inventory.configure(main.german)
	var pistol: WeaponBase = rig.inventory.weapons[0]
	var smg: WeaponBase = rig.inventory.weapons[1]
	pistol.reserve -= 8
	_check(smg.reserve == pistol.reserve, "P38 and MP40 share the 9mm reserve pool")
	pistol.magazine = 3
	rig.inventory.select(1)
	rig.inventory.select(0)
	_check(pistol.magazine == 3, "Switching preserves individual magazines")
	pistol.try_reload()
	_check(not rig.inventory.select(1), "Switching cannot bypass an active reload")
	await _frames(115)
	_check(pistol.magazine == 8, "Reload draws from the shared pool")
	player.position = Vector3(0, 0.03, 18)
	hp.take_damage(30)
	_check(main.get_node("Supplies/StagingHealth").collect(player) and hp.current_health == 100.0, "Health pickup restores missing health")
	var before: int = pistol.reserve
	_check(main.get_node("Supplies/StagingAmmo").collect(player) and pistol.reserve > before, "Ammo pickup replenishes shared reserves")
	_check(not main.get_node("Supplies/StagingAmmo").collect(player), "Pickup cannot be collected again during respawn cooldown")
	rig.inventory.pool.set_amount(main.german.grenade.reserve_ammo_type, 0)
	_check(main.get_node("Supplies/StagingGrenades").collect(player), "Grenade supply replenishes throws")

	for mount: MountedWeapon in [main.get_node("RangeM1919"), main.get_node("RangeMG42")]:
		player.position = mount.position + Vector3(0, 0.03, 1.7)
		player.get_node("Head").rotation = Vector3.ZERO
		camera.rotation = Vector3.ZERO
		mount.interact(player)
		_check(rig.mounted == mount and not player.is_physics_processing(), mount.data.display_name + " mounts")
		player.rotation.y = mount.global_rotation.y + PI
		await _frames(2)
		_check(absf(player.rotation.y - mount.global_rotation.y) <= deg_to_rad(mount.yaw_limit) + 0.01, "Mounted yaw is constrained")
		player.rotation.y = mount.global_rotation.y
		await _frames(2)
		var rounds: int = mount.weapon.magazine
		mount.fire(camera, player)
		_check(mount.weapon.magazine == rounds - 1, "Mounted weapon fires and consumes belt ammunition")
		mount.dismount()
		_check(rig.mounted == null and player.is_physics_processing(), "Dismount restores movement and handheld weapon")
	var enemy: InfantryBrain = main.get_node("Enemies/ForestPatrol") as InfantryBrain
	enemy.get_node("DamageReceiver").set_faction(main.german)
	player.get_node("DamageReceiver").set_faction(main.german)
	var enemy_hp: float = enemy.health.current_health
	enemy.get_node("DamageReceiver").take_damage(25.0, player)
	_check(enemy.health.current_health == enemy_hp, "Faction relationship prevents friendly fire")
	player.get_node("DamageReceiver").set_faction(main.allied)
	enemy.get_node("DamageReceiver").take_damage(25.0, player)
	_check(enemy.health.current_health == enemy_hp - 25.0, "Hostile damage is applied")
	enemy.sees_target = false
	enemy.process_mode = Node.PROCESS_MODE_INHERIT
	enemy.set_physics_process(true)
	root.get_node("CombatAudio").noise.emit(enemy.position + Vector3(5, 0, 0), 28.0, player)
	_check(enemy.state == InfantryBrain.State.HURT and enemy.last_known_position.distance_to(enemy.position + Vector3(5, 0, 0)) < 2.0, "Hearing records a nearby sound without cancelling hurt")
	enemy.set_physics_process(false)
	enemy.process_mode = Node.PROCESS_MODE_DISABLED
	main._extract(player)
	_check(not main.complete, "Extraction is locked until documents are recovered")
	player.position = Vector3(-5, 0.05, -72.5)
	player.rotation = Vector3.ZERO
	player.get_node("Head").rotation = Vector3.ZERO
	camera.rotation = Vector3.ZERO
	if DisplayServer.get_name() != "headless":
		await _frames(3)
		await _capture("command_post_interior.png")
	main.get_node("Interactions/Documents").interact(player)
	_check(main.objective_done, "Document interaction completes the objective")
	player.position = Vector3(0, 0.05, -85)
	await _frames(5)
	_check(main.complete, "Physical rear-exit trigger completes the mission")
	print("Combat prototype smoke: %d failure(s)" % failures)
	current_scene.queue_free()
	await _frames(45)
	quit(0 if failures == 0 else 1)


func _capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://.godot/validation")
	root.get_texture().get_image().save_png("res://.godot/validation/" + filename)


func _frames(count: int) -> void:
	for frame: int in range(count):
		await physics_frame
		await process_frame


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)
