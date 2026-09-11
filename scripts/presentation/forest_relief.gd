extends RefCounted
## Forest floor hummocks; road, range, flank track and bunker retain their level routes.
static func height_at(point: Vector3) -> float:
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = 924
	noise.frequency = 0.24
	var mask: float = smoothstep(3.5, 6.0, absf(point.x))
	mask *= 1.0 - smoothstep(8.5, 10.5, point.x) * (1.0 - smoothstep(14.0, 16.0, point.x))
	if point.z < -40 or (point.x < -8 and point.z > -10): mask = 0
	return noise.get_noise_2d(point.x, point.z) * 0.48 * mask

static func install(ground: StaticBody3D) -> void:
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(54, 126)
	plane.subdivide_width = 54
	plane.subdivide_depth = 126
	var arrays: Array = plane.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i: int in range(vertices.size()):
		var world: Vector3 = ground.position + vertices[i]
		vertices[i].y = 0.5 + height_at(world)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var st: SurfaceTool = SurfaceTool.new()
	st.create_from(mesh, 0)
	st.generate_normals()
	mesh = st.commit()
	ground.get_node("Mesh").mesh = mesh
	for child: Node in ground.get_children():
		if child is CollisionShape3D: child.shape = mesh.create_trimesh_shape()
