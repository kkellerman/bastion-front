extends SceneTree
## Rebuild after editing static level collision: godot --headless --path . --script res://tests/bake_navigation.gd

func _initialize() -> void:
	_bake.call_deferred()


func _bake() -> void:
	var mission: bool = "--mission" in OS.get_cmdline_user_args()
	var packed: PackedScene = load("res://scenes/missions/forest_command_post.tscn" if mission else "res://scenes/main.tscn") as PackedScene
	var main: Node3D = packed.instantiate() as Node3D
	main.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(main)
	var mesh: NavigationMesh = NavigationMesh.new()
	mesh.agent_radius = 0.4
	mesh.agent_height = 1.8
	mesh.agent_max_climb = 0.2
	mesh.agent_max_slope = 35.0
	mesh.cell_size = 0.2
	mesh.cell_height = 0.1
	if mission:
		# Sparse detail sampling produced overlapping shared edges on the hummocks.
		# Sample at 10 cm (cell_size * 0.5), with shorter contour edges.
		mesh.detail_sample_distance = 0.5
		mesh.edge_max_length = 3.0
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.geometry_collision_mask = 1
	var source: NavigationMeshSourceGeometryData3D = NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(mesh, source, main)
	NavigationServer3D.bake_from_source_geometry_data(mesh, source)
	var result: Error = ResourceSaver.save(mesh, "res://resources/missions/command_post_navigation.tres" if mission else "res://resources/missions/forest_navigation.tres")
	print("Navigation bake: ", mesh.get_polygon_count(), " polygons; save result ", result)
	main.queue_free()
	await process_frame
	quit(0 if result == OK and mesh.get_polygon_count() > 0 else 1)
