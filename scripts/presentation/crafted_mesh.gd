extends RefCounted
static func chipped_box(source: BoxMesh) -> ArrayMesh:
	var box: BoxMesh = source.duplicate() as BoxMesh
	box.subdivide_width = 6
	box.subdivide_depth = 6
	box.subdivide_height = 6
	var arrays: Array = box.get_mesh_arrays()
	var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var bevel: float = minf(minf(box.size.x,box.size.y),box.size.z)*0.08
	bevel = minf(bevel,0.065)
	var half: Vector3 = box.size*0.5-Vector3.ONE*bevel
	for i: int in range(points.size()):
		var inside: Vector3 = points[i].clamp(-half,half)
		var normal: Vector3 = (points[i]-inside).normalized()
		var chip: float = 0.78+0.22*sin(points[i].dot(Vector3(31,47,19)))
		points[i] = inside + normal*bevel*chip
		normals[i] = normal
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh

## Reusable visual meshes only; collision contracts remain with their owning scenes.
static func sack() -> ArrayMesh:
	var source: SphereMesh = SphereMesh.new()
	source.radial_segments = 32
	source.rings = 18
	var arrays: Array = source.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i: int in range(vertices.size()):
		var p: Vector3 = vertices[i] * 2.0
		p = Vector3(signf(p.x)*pow(absf(p.x),0.42), signf(p.y)*pow(absf(p.y),0.55), signf(p.z)*pow(absf(p.z),0.42))
		p.y *= 1.0 - 0.13 * cos(p.x * 9.0 + p.z * 4.0)
		p.z *= 1.0 - 0.12 * absf(p.x)
		vertices[i] = p * 0.5
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var st: SurfaceTool = SurfaceTool.new()
	st.create_from(mesh, 0)
	st.generate_normals()
	return st.commit()

static func limb(length: float, radius: float, tip: float, cloth: bool) -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring: int in range(12):
		for side: int in range(20):
			for corner: Vector2i in [Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(0,0), Vector2i(1,1), Vector2i(0,1)]:
				var t: float = float(ring + corner.y) / 12.0
				var angle: float = float(side + corner.x) * TAU / 20.0
				var r: float = lerpf(radius, tip, t) * (0.90 + 0.15 * sin(t * PI))
				if cloth: r *= 1.0 + sin(t * 26.0 + angle * 3.0) * 0.065 + sin(angle * 7.0) * 0.025
				else: r *= 1.0 + sin(t * PI * 3.0) * 0.08
				st.set_uv(Vector2(float(side + corner.x) / 20.0, t))
				st.add_vertex(Vector3(cos(angle) * r, (t - 0.5) * length, sin(angle) * r * (0.78 if not cloth else 0.95)))
	st.generate_normals()
	st.index()
	return st.commit()
