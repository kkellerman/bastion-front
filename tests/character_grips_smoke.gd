extends SceneTree
const Grip = preload("res://scripts/presentation/weapon_grip.gd")
const Pose = preload("res://scripts/presentation/infantry_weapon_pose.gd")
var failures: int = 0
var capture: bool = false

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	capture = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	root.get_node("PlayerSettings").values.graphics_preset = 4
	var mission: Node3D = load("res://scenes/missions/forest_command_post.tscn").instantiate()
	root.add_child(mission)
	current_scene = mission
	await _frames(12)
	for enemy: InfantryBrain in mission.get_node("Enemies").get_children(): enemy.process_mode = Node.PROCESS_MODE_DISABLED
	mission.get_node("DefensiveMG").process_mode = Node.PROCESS_MODE_DISABLED
	mission.player.set_physics_process(false)
	mission.player.position = Vector3(0,0.05,18)
	for child: Node in mission.get_node("Presentation").get_children():
		if child is CanvasLayer: child.hide()
	var rig: Node3D = mission.rig
	for faction_id: String in ["allied","german"]:
		var faction: FactionData = load("res://resources/factions/"+faction_id+".tres")
		rig.inventory.configure(faction)
		await _frames(3)
		for slot: int in range(rig.inventory.weapons.size()):
			rig.inventory.select(slot)
			await _frames(20)
			var data: WeaponData = rig.weapon.data
			var arms: Node3D = rig.viewmodel.get_node("Arms")
			_check(arms.support.position.distance_to(Grip.support(data))<0.001,str(data.weapon_id)+" support wrist uses shared grip")
			_check(arms.get_node("TriggerHand").position.distance_to(Grip.trigger(data))<0.001,str(data.weapon_id)+" trigger wrist uses shared grip")
			if capture: await _capture(str(data.weapon_id)+"_grip")
			if capture:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				rig._aim_held = true
				await _frames(25)
				_check(rig.viewmodel.aiming and rig.camera.fov<=rig._base_fov,str(data.weapon_id)+" aims with both grips retained")
				await _capture(str(data.weapon_id)+"_aim_grip")
				rig._aim_held = false
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				await _frames(20)
			# Use the real production mesh/skin and support-arm modifier.
			var model: Node3D = faction.uniform_scene.instantiate()
			mission.add_child(model)
			model.position = Vector3(0,0,14)
			var preview: Node3D = data.viewmodel_scene.instantiate()
			var held: Node3D = preview.get_node("WeaponMesh").duplicate()
			preview.free()
			model.get_node("Skeleton3D/WeaponSocket").add_child(held)
			var modifier: SkeletonModifier3D = Pose.install(model,held,data)
			var skeleton: Skeleton3D = model.get_node("Skeleton3D")
			for clip: String in ["idle","aim","walk","fire"]:
				model.get_node("AnimationPlayer").play(clip)
				model.get_node("AnimationPlayer").advance(0.23)
				modifier._process_modification()
				var right: Transform3D = skeleton.get_bone_global_pose(skeleton.find_bone("RightHand"))
				var left: Transform3D = skeleton.get_bone_global_pose(skeleton.find_bone("LeftHand"))
				var target: Vector3 = right*(Grip.support(data)-Grip.trigger(data))
				_check(left.origin.distance_to(target)<0.025,str(data.weapon_id)+" "+clip+" support hand stays on weapon")
			model.queue_free()
			if data.explode_on_contact and data.hitscan_or_projectile == WeaponData.ShotType.PROJECTILE:
				await _rocket_directions(mission,data)
		# Validate the animated reload really restores the grip, not only its initial placement.
		rig.inventory.select(1)
		await _frames(3)
		rig.weapon.magazine -= 1
		rig.weapon.try_reload()
		await create_timer(rig.weapon.data.reload_time*0.55).timeout
		if capture: await _capture(faction_id+"_reload")
		await create_timer(rig.weapon.data.reload_time*0.55).timeout
		await _frames(3)
		_check(rig.viewmodel.get_node("Arms").support.position.distance_to(Grip.support(rig.weapon.data))<0.001,"Reload returns support wrist to grip")
	# A 60-degree preference must never zoom out when aiming.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	rig._base_fov = 60.0
	rig.camera.fov = 60.0
	rig._aim_held = true
	await _frames(25)
	_check(rig.camera.fov<=60.001,"Aim respects low FOV preference")
	rig._aim_held = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await _ragdoll_budget(mission)
	await _live_ragdoll(mission)
	mission.queue_free()
	await _frames(3)
	print("Character/grips smoke: %d failure(s)" % failures)
	quit(0 if failures==0 else 1)

func _rocket_directions(mission: Node3D, data: WeaponData) -> void:
	var origin := Node3D.new()
	mission.add_child(origin)
	origin.position = Vector3(0,20,10)
	for yaw: float in [0.0,PI*0.5,PI,-PI*0.5]:
		origin.rotation = Vector3(0.25,yaw,0)
		var rocket: ExplosiveProjectile = ProjectileLauncher.launch(data,origin,mission.player)
		_check((-rocket.global_basis.z).dot(-origin.global_basis.z)>0.999,"Rocket thrust aligned at yaw %.2f"%yaw)
		_check(rocket.angular_velocity.is_zero_approx(),"Rocket does not inherit grenade tumble")
		await _frames(6)
		_check(rocket.linear_velocity.normalized().dot(-origin.global_basis.z)>0.99,"Powered rocket stays on launch heading")
		rocket.queue_free()
	origin.queue_free()

func _ragdoll_budget(mission: Node3D) -> void:
	var budget: Node = load("res://scripts/systems/ragdoll_budget.gd").new()
	mission.add_child(budget)
	budget.set_physics_process(false)
	var models: Array[Node3D] = []
	var sims: Array[PhysicalBoneSimulator3D] = []
	for i: int in range(6):
		var model: Node3D = load("res://assets/characters/allied/infantry_rigged.tscn").instantiate()
		mission.add_child(model)
		model.position = Vector3(0,20+i*3,0)
		var sim: PhysicalBoneSimulator3D = Ragdoll.build(model.get_node("Skeleton3D"))
		budget.register(sim,model)
		models.append(model)
		sims.append(sim)
	_check(not budget.allows(),"Six simultaneously active ragdolls fill budget")
	budget._physics_process(0.1)
	# All bodies move laterally; no downward movement is necessary to remain active.
	for step: int in range(20):
		for sim: PhysicalBoneSimulator3D in sims:
			for bone: Node3D in sim.get_children(): bone.position.x += 0.04
		budget._physics_process(0.1)
	_check(not budget._active[0].get("frozen",false),"Sliding corpses do not settle early")
	var expected: Transform3D = sims[0].get_child(0).global_transform*sims[0].get_child(0).body_offset.affine_inverse()
	budget._physics_process(12.0)
	await _frames(3)
	_check(budget.allows() and budget._active.size()==0,"Deadline retires physics and releases all six slots")
	var skeleton: Skeleton3D = models[0].get_node("Skeleton3D")
	var baked: Transform3D = skeleton.global_transform*skeleton.get_bone_global_pose(0)
	print("Pose retirement expected ",expected.origin," actual ",baked.origin)
	_check(baked.origin.distance_to(expected.origin)<0.001,"Retiring simulation preserves corpse pose")
	await _frames(5)
	_check((skeleton.global_transform*skeleton.get_bone_global_pose(0)).origin.distance_to(expected.origin)<0.001,"Baked corpse does not return to standing pose")
	for model: Node3D in models: model.queue_free()
	budget.queue_free()

func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/validation/"+label+".png")

func _live_ragdoll(mission: Node3D) -> void:
	var actor: InfantryBrain = mission.get_node("Enemies/ForestPatrol")
	actor.process_mode = Node.PROCESS_MODE_INHERIT
	actor.set_physics_process(false)
	actor.global_position = Vector3(0,0.05,14)
	actor.combat.disable()
	var receiver: DamageReceiver = DamageReceiver.from_body(actor)
	var origin: Vector3 = actor.global_position+Vector3(2,0,0)
	receiver.take_damage(1.0,mission.player,&"grenade",origin)
	_check(actor.death_impulse.x<0 and absf(actor.death_impulse.z)<0.001,"Blast impulse points away from explosion, independently of shooter")
	var camera := Camera3D.new()
	mission.add_child(camera)
	camera.global_position = Vector3(-2,1.9,16)
	camera.look_at(Vector3(-1,0.5,14))
	if capture:
		mission.rig.hide()
		_hide_ui(mission)
		camera.make_current()
	receiver.take_damage(99.0,mission.player,&"pistol",origin)
	await create_timer(0.7).timeout
	var model: Node3D = actor.get_node("Visuals").get_child(actor.get_node("Visuals").get_child_count()-1)
	var skeleton: Skeleton3D = model.get_node("Skeleton3D")
	_check(skeleton.has_node("RagdollSimulator"),"Live death hands pose over to physical bones")
	if capture: await _capture("ragdoll_falling")
	await create_timer(3.5).timeout
	if capture: await _capture("ragdoll_landed")
	await create_timer(9.0).timeout
	_check(not skeleton.has_node("RagdollSimulator"),"Actual corpse retires all physical bodies by deadline")
	var pelvis: Vector3 = skeleton.global_transform*skeleton.get_bone_global_pose(0).origin
	print("Settled pelvis: ",pelvis)
	_check(pelvis.y<0.7 and pelvis.y> -0.3,"Actual corpse remains at ground level after physics retires")
	if capture: await _capture("ragdoll_settled")
	camera.queue_free()

func _hide_ui(node: Node) -> void:
	if node is CanvasLayer: node.hide()
	for child: Node in node.get_children(): _hide_ui(child)

func _frames(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame

func _check(value: bool, label: String) -> void:
	if value: print("PASS: ",label)
	else:
		failures += 1
		push_error("FAIL: "+label)
