extends RefCounted
## Original neutral head with jaw, cheekbones, eye sockets, nose and mouth relief.
static func build() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring: int in range(48):
		for side: int in range(64):
			for corner: Vector2i in [Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(0,0), Vector2i(1,1), Vector2i(0,1)]:
				var t: float = float(ring + corner.y) / 48.0
				var angle: float = float(side + corner.x) * TAU / 64.0
				var y: float = lerpf(1.50, 1.755, t)
				# Jaw, cheek, temple and skull widths are authored separately; the old
				# sine profile pinched the temples into an egg-shaped mask.
				var profile: Vector2 = _profile(t)
				var width: float = profile.x
				var depth: float = profile.y
				var x: float = cos(angle) * width
				var z: float = sin(angle) * depth - 0.012
				if sin(angle) < -0.25:
					var front: float = smoothstep(0.25, 0.8, -sin(angle))
					var nose: float = _bump(x,y,0,1.617,0.014,0.027)*0.027 + _bump(x,y,0,1.639,0.008,0.03)*0.012
					var sockets: float = _bump(absf(x),y,0.031,1.646,0.019,0.013)*0.012
					var cheeks: float = _bump(absf(x),y,0.046,1.621,0.025,0.017)*0.009
					var lips: float = _bump(x,y,0,1.585,0.024,0.006)*0.008
					var chin: float = _bump(x,y,0,1.561,0.032,0.016)*0.012
					z += (sockets - nose - cheeks - lips - chin) * front
				st.set_uv(Vector2(float(side+corner.x)/64.0,t))
				st.set_bones(PackedInt32Array([4,0,0,0]))
				st.set_weights(PackedFloat32Array([1,0,0,0]))
				st.add_vertex(Vector3(x,y,z))
	# Ears are small volumes tucked beneath the helmet, not painted circles.
	for side: float in [-1.0,1.0]:
		var ear := SphereMesh.new()
		ear.radius = 1.0
		ear.height = 2.0
		ear.radial_segments = 12
		ear.rings = 8
		var arrays: Array = ear.get_mesh_arrays()
		var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for index: int in arrays[Mesh.ARRAY_INDEX]:
			st.set_bones(PackedInt32Array([4,0,0,0]))
			st.set_weights(PackedFloat32Array([1,0,0,0]))
			st.set_uv(Vector2.ZERO)
			st.add_vertex(Vector3(side*0.075,1.633,0.002)+points[index]*Vector3(0.012,0.025,0.015))
	st.generate_normals()
	st.index()
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = load("res://shaders/face_surface.gdshader")
	st.set_material(mat)
	return st.commit()

static func _profile(t: float) -> Vector2:
	var rings: Array[Vector2] = [Vector2(0.032,0.035),Vector2(0.043,0.056),Vector2(0.058,0.068),Vector2(0.066,0.076),Vector2(0.073,0.080),Vector2(0.074,0.085),Vector2(0.073,0.085),Vector2(0.077,0.090),Vector2(0.073,0.086),Vector2(0.050,0.060),Vector2(0.002,0.003)]
	var at: float = clampf(t,0,1)*(rings.size()-1)
	var i: int = mini(int(at),rings.size()-2)
	return rings[i].cubic_interpolate(rings[i+1],rings[maxi(0,i-1)],rings[mini(rings.size()-1,i+2)],at-i)

static func _bump(x: float, y: float, cx: float, cy: float, sx: float, sy: float) -> float:
	return exp(-pow((x-cx)/sx,2)-pow((y-cy)/sy,2))

static func remove_donor_head(mesh: ArrayMesh) -> ArrayMesh:
	var arrays: Array = mesh.surface_get_arrays(0)
	var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var kept: PackedInt32Array = PackedInt32Array()
	for triangle: int in range(0,indices.size(),3):
		if minf(points[indices[triangle]].y,minf(points[indices[triangle+1]].y,points[indices[triangle+2]].y)) > 1.505: continue
		kept.append_array(indices.slice(triangle,triangle+3))
	arrays[Mesh.ARRAY_INDEX] = kept
	var result: ArrayMesh = ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return result
