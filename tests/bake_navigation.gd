extends SceneTree
## Rebuild after editing static level collision: godot --headless --path . --script res://tests/bake_navigation.gd

func _initialize() -> void:
	_bake.call_deferred()


func _bake() -> void:
	var mission: bool = "--mission" in OS.get_cmdline_user_args()
	var restricted: bool = "--restricted" in OS.get_cmdline_user_args()
	if mission:
		root.get_node("PrototypeSession").operation_seed = 1944
		if restricted:
			for seed_value: int in range(100):
				var options: Array[MissionZoneOption] = preload("res://resources/missions/variants/forest_command_post.tres").select(seed_value)
				if options[2].restricted_flank:
					root.get_node("PrototypeSession").operation_seed = seed_value
					break
	var packed: PackedScene = load("res://scenes/missions/forest_command_post.tscn" if mission else "res://scenes/main.tscn") as PackedScene
	var main: Node3D = packed.instantiate() as Node3D
	main.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(main)
	var mesh: NavigationMesh = NavigationMesh.new()
	mesh.agent_radius = 0.5 if mission else 0.4
	mesh.agent_height = 1.8
	mesh.agent_max_climb = 0.2
	mesh.agent_max_slope = 35.0
	mesh.cell_size = 0.25 if mission else 0.2
	mesh.cell_height = 0.1
	if mission:
		# 25 cm voxels keep full-mission queries within the engine's default 4096
		# search polygons. Close detail samples preserve the fixed shallow relief.
		mesh.detail_sample_distance = 0.5
		# Scenery banks have collision but must not add exterior navigation islands.
		mesh.filter_baking_aabb = AABB(Vector3(-23,-1,-87), Vector3(46,12,119))
		mesh.edge_max_length = 3.0
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.geometry_collision_mask = 1
	var source: NavigationMeshSourceGeometryData3D = NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(mesh, source, main)
	NavigationServer3D.bake_from_source_geometry_data(mesh, source)
	var destination: String = "res://resources/missions/command_post_navigation.tres" if mission else "res://resources/missions/forest_navigation.tres"
	if restricted: destination = "res://resources/missions/variants/restricted_navigation.tres"
	var result: Error = ResourceSaver.save(mesh, destination)
	print("Navigation bake: ", mesh.get_polygon_count(), " polygons; save result ", result)
	main.queue_free()
	await process_frame
	quit(0 if result == OK and mesh.get_polygon_count() > 0 else 1)
