extends SceneTree

var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var mission: Node3D = (load("res://scenes/missions/forest_command_post.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(mission)
	current_scene = mission
	var player: FirstPersonPlayer = mission.get_node("Player") as FirstPersonPlayer
	var health: HealthComponent = player.get_node("HealthComponent") as HealthComponent
	var gun: MountedWeapon = mission.get_node("DefensiveMG") as MountedWeapon
	var gunner: InfantryBrain = mission.get_node("Enemies/Gunner") as InfantryBrain
	for enemy: Node in mission.get_node("Enemies").get_children():
		if enemy != gunner:
			enemy.process_mode = Node.PROCESS_MODE_DISABLED
	player.position = Vector3(0, 0.05, -36)
	await _frames(180)
	_check(gunner.sees_target and gunner.state == InfantryBrain.State.ATTACK, "Gunner acquires the exposed approach")
	_check(health.current_health < 100.0 and health.current_health > 0.0, "Defensive MG damages the player in survivable bursts")
	gun.interact(player)
	_check(gun.occupant == null, "Living gunner prevents player mounting")
	gunner.get_node("DamageReceiver").take_damage(100.0, player)
	var rounds: int = gun.weapon.magazine
	await _frames(120)
	_check(gun.weapon.magazine == rounds, "Killing the gunner stops mounted fire")
	_check(gunner.collision_layer == 0, "Dead gunner releases collision")
	player.position = gun.position + Vector3(0, 0.05, 1.7)
	gun.interact(player)
	_check(gun.occupant == player, "Cleared defensive MG can be captured")
	health.take_damage(100.0)
	_check(gun.occupant == null, "Player death dismounts the gun")
	_check(not player.is_physics_processing(), "Dead player movement stays disabled after dismount")
	print("Defensive MG smoke: %d failure(s)" % failures)
	mission.queue_free()
	await _frames(45)
	quit(0 if failures == 0 else 1)


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
