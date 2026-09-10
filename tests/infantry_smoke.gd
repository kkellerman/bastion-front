extends SceneTree

var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var main: Node3D = (load("res://scenes/main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(main)
	current_scene = main
	var enemy: InfantryBrain = main.get_node("GermanInfantry") as InfantryBrain
	var player: FirstPersonPlayer = main.get_node("Player") as FirstPersonPlayer
	var player_health: HealthComponent = player.get_node("HealthComponent") as HealthComponent
	var camera: Camera3D = player.get_node("Head/Camera3D") as Camera3D
	var start: Vector3 = enemy.position
	await _frames(210)
	_check(enemy.position.distance_to(start) > 0.8, "Idle transitions into navigation patrol")
	_check(enemy.get_node("NavigationAgent3D").get_current_navigation_path().size() > 0, "NavigationAgent3D receives a baked path")
	enemy.set_physics_process(false)
	# Exercise the baked obstacle around the existing target board, not only open ground.
	enemy.position = Vector3(0, 0.03, -10)
	var destination: Vector3 = Vector3(0, 0.03, -2)
	var detour: float = 0.0
	for frame: int in range(330):
		await physics_frame
		enemy.motor.travel(destination, 1.0 / 60.0)
		detour = maxf(detour, absf(enemy.position.x))
		await process_frame
	_check(enemy.position.distance_to(destination) < 1.0 and detour > 0.8, "Baked navigation routes infantry around the solid target board")
	enemy.position = Vector3(3, 0.03, -12)
	enemy.rotation.y = PI
	player.position = Vector3(3, 0.03, -25)
	await _frames(2)
	_check(not enemy.vision.can_see(player, player.get_node("Head")), "Player behind enemy is outside FOV")
	player.position = Vector3(3, 0.03, 30)
	await _frames(2)
	_check(not enemy.vision.can_see(player, player.get_node("Head")), "Detection obeys visual range")
	player.position = Vector3(3, 0.03, 6)
	await _frames(2)
	_check(enemy.vision.can_see(player, player.get_node("Head")), "Unobstructed player in cone is visible")
	var cover: StaticBody3D = _cover(main)
	await _frames(2)
	_check(not enemy.vision.can_see(player, player.get_node("Head")), "World geometry blocks vision")
	cover.queue_free()
	await _frames(2)
	enemy.patrol_points.clear()
	enemy._set_state(InfantryBrain.State.IDLE)
	enemy.set_physics_process(true)
	await _frames(3)
	_check(enemy.state == InfantryBrain.State.ALERT, "Detection enters alert reaction delay")
	await _frames(48)
	_check(enemy.state == InfantryBrain.State.CHASE, "Alert transitions into chase")
	await _frames(160)
	_check(enemy.state == InfantryBrain.State.ATTACK, "Chase stops at firing distance and attacks")
	_check(enemy.position.distance_to(player.position) <= 12.2 and enemy.velocity.length() < 0.1, "Infantry holds firing distance")
	await _frames(85)
	_check(player_health.current_health < 100.0, "Enemy hitscan damages player health")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://.godot/validation")
		root.get_texture().get_image().save_png("res://.godot/validation/infantry_combat.png")
	var remembered: Vector3 = enemy.last_known_position
	cover = _cover(main)
	player.position = Vector3(15, 0.03, 8)
	await _frames(3)
	var ammo: int = enemy.combat.weapon.magazine
	var hp: float = player_health.current_health
	await _frames(80)
	_check(not enemy.sees_target and enemy.last_known_position.distance_to(remembered) < 0.01, "Hidden player does not update last known position")
	_check(enemy.combat.weapon.magazine == ammo and player_health.current_health == hp, "Enemy does not fire through cover after losing sight")
	await _frames(185)
	_check(enemy.state == InfantryBrain.State.IDLE, "Memory expires and enemy stops pursuit")
	cover.queue_free()
	await _frames(2)
	player.position = Vector3(3, 0.03, 6)
	player.velocity = Vector3.ZERO
	camera.look_at(enemy.global_position + Vector3(0, 1.1, 0), Vector3.UP)
	var weapon: WeaponBase = player.get_node("Head/Camera3D/WeaponRig/WeaponBase") as WeaponBase
	_check(weapon.try_fire(), "M1911 fires at enemy")
	_check(enemy.health.current_health == 75.0 and enemy.state == InfantryBrain.State.HURT, "M1911 damage enters hurt state")
	await _frames(20)
	_check(enemy.state == InfantryBrain.State.ALERT, "Hurt recovers through alert")
	for shot: int in range(3):
		camera.look_at(enemy.global_position + Vector3(0, 1.1, 0), Vector3.UP)
		weapon.try_fire()
		await _frames(14)
	_check(enemy.health.current_health == 0.0 and enemy.state == InfantryBrain.State.DEATH, "Four M1911 hits kill infantry")
	_check(enemy.collision_layer == 0 and enemy.collision_mask == 0 and enemy.get_node("BodyCollision").disabled, "Death disables physical and hitscan collision")
	_check(not enemy.combat.enabled and not enemy.is_physics_processing(), "Death permanently disables AI and combat")
	player_health.take_damage(100.0)
	_check(not player.is_physics_processing(), "Player death stops movement")
	_check(player.get_node("Head/Camera3D/WeaponRig").process_mode == Node.PROCESS_MODE_DISABLED, "Player death disables firing")
	_check(player.get_node("PlayerVitals/Health").text.contains("YOU DIED"), "Player death shows restart prompt")
	var restart: InputEventKey = InputEventKey.new()
	restart.physical_keycode = KEY_ENTER
	restart.pressed = true
	Input.parse_input_event(restart)
	await _frames(10)
	_check(current_scene != main and current_scene.get_node("Player/HealthComponent").current_health == 100.0, "Enter restarts the playable scene with full health")
	print("Infantry smoke: %d failure(s)" % failures)
	current_scene.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)


func _cover(main: Node3D) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	var collider: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(44, 4, 0.3)
	collider.shape = shape
	body.add_child(collider)
	main.add_child(body)
	body.position = Vector3(0, 2, 1)
	return body


func _frames(count: int) -> void:
	for frame: int in range(count):
		await physics_frame
		await process_frame


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error("FAIL: " + description)
