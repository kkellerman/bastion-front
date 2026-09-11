extends SceneTree
const CATALOG = preload("res://resources/missions/variants/forest_command_post.tres")
var failures: int = 0
var mission: Node3D
var covered: Dictionary[String, bool] = {}
var snapshots: Dictionary[int, int] = {}

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	var seeds: Array[int] = [1944, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 73, 90210, 1944]
	for zone: MissionZoneData in CATALOG.zones:
		for option: MissionZoneOption in zone.options:
			for point: Vector3 in option.dressing_anchors:
				_check(zone.bounds.has_point(point), option.label + " dressing anchor in zone")
			for id: StringName in option.actor_positions:
				_check(zone.bounds.has_point(option.actor_positions[id]), option.label + " actor in zone")
	for faction: StringName in [&"allied", &"german"]:
		for seed_value: int in seeds:
			var session: Node = root.get_node("PrototypeSession")
			session.set_operation_seed(seed_value)
			session.faction_id = faction
			mission = load("res://scenes/missions/forest_command_post.tscn").instantiate()
			root.add_child(mission)
			current_scene = mission
			var variant: MissionVariant = mission.get_node("MissionVariant")
			for option: MissionZoneOption in variant.options: covered[option.label] = true
			var fingerprint: int = _fingerprint(variant)
			if snapshots.has(seed_value): _check(snapshots[seed_value] == fingerprint, "Seed reproduces identical dressing across reload/factions")
			snapshots[seed_value] = fingerprint
			_check(variant.signature == CATALOG.signature(seed_value), "Reproducible authored selection")
			await _frames(8)
			_check(variant.can_regenerate(), "Staging regeneration initially allowed")
			_check(mission.player.is_on_floor() and mission.player.position.distance_to(Vector3(0,0,18)) < 0.25, "Safe grounded staging spawn")
			var nest: MountedWeapon = mission.get_node("DefensiveMG")
			_check(nest.data.weapon_id == (&"mg42" if faction == &"allied" else &"m1919") and nest.has_defender(), "Faction nest retains living operator")
			_check(nest.defender.position.distance_to(nest.to_global(nest.operator_position)) < 0.2, "Fixed nest binding unaffected")
			for enemy: InfantryBrain in mission.get_node("Enemies").get_children():
				enemy.set_physics_process(false)
				if enemy.name != &"Gunner":
					_check(_clear(enemy.position), "Enemy clear of world: " + str(enemy.name))
					_check(_near_nav(enemy.position), "Enemy on navigation: " + str(enemy.name))
					for point: Vector3 in enemy.patrol_points: _route(enemy.position, point, "patrol " + str(enemy.name))
			mission.player.set_physics_process(false)
			for supply: Node3D in mission.get_node("Supplies").get_children():
				_check(_near_nav(supply.position), "Reachable supply " + str(supply.name))
				_check(_clear(supply.position, 0.18), "Supply outside blocking props " + str(supply.name))
			var points: Array[Vector3] = [Vector3(0,0,18),Vector3(0,0,-18),Vector3(0,0,-40),Vector3(0,0,-56),Vector3(-5,0,-72.5),Vector3(0,0,-84)]
			for i: int in range(points.size()-1): _route(points[i],points[i+1],"mission route")
			_route(points[0],points[4],"full spawn to documents")
			_route(points[0],points[5],"full spawn to extraction")
			_route(Vector3(12,0,-20),Vector3(12,0,-48),"eastern flank")
			for marker: Node3D in get_nodes_in_group(&"infantry_cover"):
				_check(_near_nav(marker.position), "Cover anchor reachable " + str(marker.position) + " nearest " + str(NavigationServer3D.map_get_closest_point(mission.get_world_3d().navigation_map,marker.position)))
			var mesh: NavigationMesh = mission.get_node("NavigationRegion3D").navigation_mesh
			_check(mesh.resource_path.ends_with("restricted_navigation.tres") == variant.restricted_flank, "Obstacle and prebaked navigation agree")
			var documents: Node3D = mission.get_node("Interactions/Documents")
			var hit: Dictionary = mission.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-5,1.5,-72.5),documents.position+Vector3.UP*0.8,1))
			_check(hit.get("collider") == documents, "Documents approach ray reaches actual interaction collider")
			variant._noise(mission.player.position, 10, mission.player)
			_check(not variant.can_regenerate() and not variant.new_operation(), "Gunfire locks regeneration")
			var checkpoint: Node = mission.get_node("Checkpoints")
			mission.player.position = Vector3(0,0.05,-56)
			checkpoint.capture(1)
			mission.player.position = Vector3(0,0.05,18)
			checkpoint._restore()
			_check(session.checkpoint.operation_seed == seed_value and mission.player.position.z == -56, "Checkpoint restores within same operation")
			mission.player.position = Vector3(0,0.05,18)
			session.operation_seed = seed_value + 1
			checkpoint._restore()
			_check(mission.player.position.z == 18, "Different-seed checkpoint rejected")
			session.operation_seed = seed_value
			mission._interact(&"documents",mission.player)
			mission.player.position = Vector3(0,0.05,-84)
			await _frames(3)
			_check(mission.complete, "Documents and physical extraction area complete mission")
			print("VALIDATED seed=%d faction=%s flank=%s signature=%s" % [seed_value,faction,variant.restricted_flank,variant.signature])
			mission.queue_free()
			await _frames(3)
	for zone: MissionZoneData in CATALOG.zones:
		for option: MissionZoneOption in zone.options: _check(covered.has(option.label), "Exercised authored option " + option.label)
	_check(snapshots.size() > 5, "Multiple reproducible layouts tested")
	root.get_node("PrototypeSession").checkpoint.clear()
	print("Operation variants smoke: %d failure(s), %d authored options, %d seed/faction runs" % [failures,covered.size(),seeds.size()*2])
	quit(0 if failures == 0 else 1)

func _fingerprint(node: Node) -> int:
	# Unnamed Godot node names include transient instance IDs; only geometry counts.
	var values: Array = []
	if node is Node3D: values.append(node.transform)
	if node is MeshInstance3D: values.append(hash(node.mesh.get_faces()))
	for child: Node in node.get_children(): values.append(_fingerprint(child))
	return hash(values)

func _near_nav(point: Vector3) -> bool:
	return NavigationServer3D.map_get_closest_point(mission.get_world_3d().navigation_map,point).distance_to(point) < 0.8

func _query(point: Vector3, radius: float = 0.32) -> PhysicsShapeQueryParameters3D:
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = radius
	capsule.height = 1.6
	query.shape = capsule
	query.collision_mask = 1
	query.transform = Transform3D(Basis.IDENTITY,point+Vector3.UP*1.05)
	return query

func _clear(point: Vector3, radius: float = 0.32) -> bool:
	return mission.get_world_3d().direct_space_state.intersect_shape(_query(point,radius)).is_empty()

func _route(start: Vector3, end: Vector3, description: String) -> void:
	var path: PackedVector3Array = NavigationServer3D.map_get_path(mission.get_world_3d().navigation_map,start,end,true)
	_check(path.size() >= 2 and path[-1].distance_to(end) < 0.85, description + " connected")
	for i: int in range(path.size()-1):
		var query: PhysicsShapeQueryParameters3D = _query(path[i])
		query.motion = path[i+1]-path[i]
		var result: PackedFloat32Array = mission.get_world_3d().direct_space_state.cast_motion(query)
		_check(result[0] > 0.99, description + " capsule clearance " + str(path[i]))

func _frames(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL seed=%s: %s" % [root.get_node("PrototypeSession").operation_seed,message])
