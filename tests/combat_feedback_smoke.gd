extends SceneTree
var failures: int = 0
var hostile_events: int = 0
var hostile_lines: int = 0
var hostile_impacts: int = 0
var initial_wind_id: int = 0

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	root.get_node("PrototypeSession").checkpoint.clear()
	var mission: Node3D = load("res://scenes/missions/forest_command_post.tscn").instantiate()
	root.add_child(mission)
	current_scene = mission
	await _frames(10)
	if AudioServer.get_driver_name() != "Dummy": initial_wind_id = mission.get_node("Soundscape").wind.get_instance_id()
	var audio: Node = root.get_node("CombatAudio")
	var director: Node = mission.get_node("Presentation/DialogueDirector")
	var player: FirstPersonPlayer = mission.player
	var enemy: InfantryBrain = mission.get_node("Enemies/ForestPatrol")
	var animator: Node
	for child: Node in enemy.get_children():
		if child.get_script() == load("res://scripts/presentation/character_animation.gd"): animator = child
	# Observe the real patrol rather than setting a requested velocity on a frozen body.
	await _frames(100)
	var old_phase: float = animator.stride.phase
	await _frames(20)
	_check(animator.stride.phase != old_phase and animator.stride.blend > 0.1, "Actual navigation advances bound leg stride")
	enemy.motor.stop(1.0 / 60.0)
	enemy.set_physics_process(false)
	await _frames(35)
	_check(animator.stride.speed < 0.15, "Blocked/stopped infantry stops stepping")
	enemy.set_physics_process(true)
	var npc_feedback: Node = enemy.get_node("DamageReceiver/DamageFeedback")
	enemy.health.take_damage(1)
	enemy.health.take_damage(1)
	_check(npc_feedback.events == 1 and enemy.state == InfantryBrain.State.HURT, "NPC hits flinch with bounded feedback")
	enemy.combat.muzzle_effect.trigger(enemy.combat.weapon.data, enemy)
	_check(enemy.combat.flash.visible, "Live infantry muzzle can flash")
	audio.cue_started.connect(func(cue: StringName, source: CollisionObject3D) -> void:
		if source is InfantryBrain and cue in [&"gunshot", &"mounted"]: hostile_events += 1)
	director.actor_line_started.connect(func(actor: Node3D, _category: StringName) -> void:
		if actor is InfantryBrain: hostile_lines += 1)
	var index: int = 0
	for actor: InfantryBrain in mission.get_node("Enemies").get_children():
		actor.combat.hitscan.impact.connect(func(_point: Vector3, _normal: Vector3) -> void: hostile_impacts += 1)
		actor.get_node("CombatVoice").queue_line(&"casualty")
		if index == 0: actor.set_physics_process(false)
		elif index == 1: actor.process_mode = Node.PROCESS_MODE_DISABLED
		else: actor.health.take_damage(1000)
		index += 1
	await _frames(2)
	_check(not enemy.combat.flash.visible, "Disabling actor clears its muzzle flash")
	# Exercise stale callbacks directly, including bypasses of the normal AI path.
	for actor: InfantryBrain in mission.get_node("Enemies").get_children():
		actor.combat.attack(player.position + Vector3.UP)
		actor.combat.hitscan.fire(actor.combat.weapon.data, actor.get_node("Eyes"), actor.combat.muzzle, actor, true)
		audio.play(&"gunshot", actor.position, actor)
		_check(not actor.get_node("CombatVoice").say(&"spotting"), "Disabled/dead speaker rejects local event")
		_check(not director.request(actor.get_node("CombatVoice"), &"death"), "Scheduler rejects dead/disabled direct request")
		actor.combat.muzzle_effect.trigger(actor.combat.weapon.data, actor)
	create_timer(2).timeout.connect(func() -> void:
		enemy.combat.attack(player.position)
		director.request(enemy.get_node("CombatVoice"), &"reloading"))
	await create_timer(26).timeout
	_check(hostile_events == 0 and hostile_lines == 0 and hostile_impacts == 0, "No hostile shots, subtitles or impacts after 26s of cooldowns")
	_check(get_nodes_in_group(&"combat_audio_voices").is_empty(), "Old local one-shot tails retire")
	_check(enemy.get_node("CombatVoice")._pending == &"", "Suspended actor's queued casualty is discarded")
	for actor: InfantryBrain in mission.get_node("Enemies").get_children():
		_check(not actor.combat.flash.visible, "Inactive infantry flash stays off")
	for i: int in range(12): CombatEffects.burst(player, Vector3(-3, 0.1, 10), Vector3.UP, &"wood", true)
	_check(get_nodes_in_group(&"explosion_effects").size() == 6, "Explosion effects have a strict six-effect cap")
	await _frames(270)
	_check(get_nodes_in_group(&"explosion_effects").is_empty(), "Layered explosion nodes retire deterministically")
	var feedback: Node = player.get_node("DamageReceiver/DamageFeedback")
	player.get_node("HealthComponent").take_damage(1)
	player.get_node("HealthComponent").take_damage(1)
	_check(feedback.events == 1, "Automatic hits share a feedback cooldown")
	await _frames(12)
	player.get_node("HealthComponent").take_damage(1)
	_check(feedback.events == 2, "Hit feedback recovers after cooldown")
	if AudioServer.get_driver_name() != "Dummy": await _ambience(mission)
	player.get_node("HealthComponent").take_damage(1000)
	await _frames(65)
	_check(player.get_node("Head").position.y < 0.35, "Death settles camera at ground level")
	_check(not player.is_physics_processing() and not mission.rig.viewmodel.visible, "Death disables control and hides weapon/hands")
	_check(not mission.get_node("Soundscape").active, "Death shuts down environmental audio")
	if AudioServer.get_driver_name() != "Dummy":
		_check(not mission.get_node("Soundscape").wind.playing, "Wind stops on death")
	mission.queue_free()
	await _frames(5)
	_check(get_nodes_in_group(&"communications_audio").is_empty() and get_nodes_in_group(&"distant_combat_audio").is_empty(), "Scene unload retires communications and artillery")
	print("Combat feedback smoke: %d failure(s)" % failures)
	quit(0 if failures == 0 else 1)

func _ambience(mission: Node3D) -> void:
	var sound: Node = mission.get_node("Soundscape")
	# Already ran through two complete 11.5-second loop periods above.
	_check(sound.wind.playing and sound.wind.get_instance_id() == initial_wind_id, "Primary wind source persists across loop periods")
	var wav: AudioStreamWAV = sound.wind.stream
	var jump: float = absf(wav.data.decode_s16(0) - wav.data.decode_s16(wav.data.size() - 2)) / 32768.0
	_check(jump < 0.03 and wav.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Baked wind join has no discontinuity or silence fade")
	_check(sound.radio.playing and sound.radio.bus == &"Communications", "Radio bed uses dedicated positional communications bus")
	root.get_node("PlayerSettings").values.distant_combat = true
	root.get_node("PlayerSettings").apply()
	sound._distant_time = 0
	await _frames(2)
	var tails: Array[Node] = get_nodes_in_group(&"distant_combat_audio")
	_check(tails.size() == 1 and tails[0].global_position.distance_to(mission.player.position) > 200, "Artillery stays far outside combat area")
	mission.player.position = Vector3(0, 0.1, -65)
	await _frames(65)
	_check(sound._inside and tails[0].volume_db < -29, "Existing artillery tail filters/fades on entering bunker")
	mission.player.position = Vector3(0, 0.1, 18)
	await _frames(35)
	_check(not sound._inside and tails[0].volume_db > -29, "Existing artillery tail restores outdoors")

func _frames(count: int) -> void:
	for frame: int in range(count):
		await physics_frame
		await process_frame

func _check(ok: bool, message: String) -> void:
	print("PASS: " if ok else "FAIL: ", message)
	if not ok: failures += 1
