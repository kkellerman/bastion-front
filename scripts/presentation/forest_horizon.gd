extends RefCounted
## Fixed authored perimeter relief. Only tree/brush art varies with the operation.
const P = preload("res://scripts/presentation/dressing_parts.gd")

static func height_at(point: Vector3) -> float:
	var distance: float = maxf(maxf(absf(point.x) - 23, point.z - 32), -87 - point.z)
	if distance <= 0 or distance >= 24: return 0
	var crest: float = 5.8 + sin(point.x * 0.11 + point.z * 0.08) * 1.1 + sin(point.z * 0.23) * 0.4
	if point.z < -87:
		crest *= lerpf(0.62, 1.0, smoothstep(2.0, 9.0, absf(point.x - rear_track_x(point.z))))
	return pow(sin(distance / 24 * PI), 1.2) * crest

static func rear_track_x(z: float) -> float:
	return pow(maxf(0, -z - 87) * 0.12, 1.6)

static func banks() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners: Array[Vector3] = [Vector3(-23,0,32),Vector3(23,0,32),Vector3(23,0,-87),Vector3(-23,0,-87)]
	var outward: Array[Vector3] = [Vector3(-1,0,1),Vector3(1,0,1),Vector3(1,0,-1),Vector3(-1,0,-1)]
	for edge: int in range(4):
		var next: int = (edge + 1) % 4
		var segments: int = ceili(corners[edge].distance_to(corners[next]) / 2.5)
		for band: int in range(16):
			for segment: int in range(segments):
				var quad: Array[Vector3] = []
				for coordinate: Vector2i in [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)]:
					var offset: float = (band + coordinate.y) * 1.5
					var a: Vector3 = corners[edge] + outward[edge] * offset
					var b: Vector3 = corners[next] + outward[next] * offset
					var point: Vector3 = a.lerp(b, float(segment + coordinate.x) / segments)
					point.y = height_at(point)
					quad.append(point)
				for index: int in [0,1,2,1,3,2]:
					st.set_uv(Vector2(quad[index].x,quad[index].z) * 0.15)
					st.add_vertex(quad[index])
	st.generate_normals()
	st.index()
	return st.commit()

static func plant(parent: Node3D, operation_seed: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = operation_seed ^ 7119
	var groups: Dictionary[String, Array] = {}
	# Stratified irregular clusters on both slopes and behind the crest.
	for z: int in range(-127, 70, 5):
		for x: int in range(-65, 66, 5):
			var point: Vector3 = Vector3(x + rng.randf_range(-2,2), 0, z + rng.randf_range(-2,2))
			if absf(point.x) < 24 and point.z > -88 and point.z < 33: continue
			if point.z < -85 and point.z > -116 and absf(point.x - rear_track_x(point.z)) < 3: continue
			if rng.randf() < 0.18: continue
			point.y = height_at(point) - 0.08
			var variant: int = rng.randi_range(0,2)
			var key: String = "%d_%d_%d" % [floori(point.x/20),floori(point.z/20),variant]
			if not groups.has(key): groups[key] = []
			groups[key].append(Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*rng.randf_range(0.85,1.3)),point))
	var total: int = 0
	for key: String in groups:
		var transforms: Array = groups[key]
		total += transforms.size()
		var variant: String = key.get_slice("_",2)
		var center: Vector3 = Vector3((float(key.get_slice("_",0))+0.5)*20,0,(float(key.get_slice("_",1))+0.5)*20)
		for part: String in ["wood","foliage"]:
			var batch: MultiMeshInstance3D = MultiMeshInstance3D.new()
			batch.name = "Horizon_" + part + "_" + key
			batch.multimesh = MultiMesh.new()
			batch.multimesh.transform_format = MultiMesh.TRANSFORM_3D
			batch.multimesh.mesh = load("res://assets/environments/germany/forest/tree_%s_%s_lod.res" % [variant,part])
			batch.multimesh.instance_count = transforms.size()
			for i: int in range(transforms.size()):
				var placement: Transform3D = transforms[i]
				placement.origin -= center
				batch.multimesh.set_instance_transform(i,placement)
			parent.add_child(batch)
			batch.position = center
			batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			batch.add_to_group(&"quality_horizon")
			batch.visibility_range_end = 140
	parent.set_meta(&"horizon_tree_count", total)
	# Low shrubs and debris soften bank contacts; all lie outside playable corridors.
	for i: int in range(360):
		var point: Vector3 = Vector3(rng.randf_range(-35,35),0,rng.randf_range(-100,44))
		if height_at(point) < 0.1: continue
		if point.z < -85 and absf(point.x - rear_track_x(point.z)) < 2: continue
		point.y = height_at(point)
		var kind: String = "shrub" if i % 3 else "rock"
		var part: MeshInstance3D = P.shape(parent,point,load("res://assets/environments/germany/forest/"+kind+".res"),null)
		part.rotation.y = rng.randf()*TAU
		part.scale = Vector3.ONE*rng.randf_range(1.2,2.7)
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

