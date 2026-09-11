@tool
extends Node3D
const P = preload("res://scripts/presentation/dressing_parts.gd")
const Interior = preload("res://scripts/presentation/command_post_dressing.gd")
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var art: Node3D

func _ready() -> void:
	if has_node("Presentation"):
		return
	rng.seed = 80143
	art = Node3D.new()
	art.name = "Presentation"
	add_child(art)
	_materials_and_light()
	_trees()
	# Collision placements above remain fixed to the baked navigation. Only art varies.
	if not Engine.is_editor_hint() and has_node("/root/PrototypeSession"):
		rng.seed = get_node("/root/PrototypeSession").operation_seed ^ 80143
	_undergrowth()
	Interior.dress(self, art)
	P.batch_static(art)

func _materials_and_light() -> void:
	var soil: Material = load("res://assets/materials/presentation/soil.tres")
	var concrete: Material = load("res://assets/materials/presentation/concrete.tres")
	for body: Node in $Terrain.get_children():
		body.set_meta(&"surface", &"dirt")
		body.get_node("Mesh").material_override = soil
		if "Boundary" in body.name:
			body.get_node("Mesh").visible = false
	$Terrain/Trail/Mesh.visible = false
	$Terrain/Ground/Mesh.material_override = load("res://assets/materials/presentation/forest_surface.tres")
	preload("res://scripts/presentation/forest_relief.gd").install($Terrain/Ground)
	for body: Node in $Bunker.get_children():
		if body is StaticBody3D:
			body.set_meta(&"surface", &"concrete")
			body.get_node("Mesh").material_override = concrete
			if body.get_node("Mesh").mesh is BoxMesh:
				body.get_node("Mesh").mesh = preload("res://scripts/presentation/crafted_mesh.gd").chipped_box(body.get_node("Mesh").mesh)
	var env: Environment = $Environment.environment.duplicate() as Environment
	$Environment.environment = env
	var sky: Sky = Sky.new()
	var sky_material: ShaderMaterial = ShaderMaterial.new()
	sky_material.shader = load("res://shaders/overcast_sky.gdshader")
	sky.sky_material = sky_material
	sky.radiance_size = Sky.RADIANCE_SIZE_128
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.fog_sky_affect = 0.35
	env.ambient_light_energy = 0.45
	env.ambient_light_color = Color(0.63, 0.69, 0.74)
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.95
	env.ssao_enabled = true
	env.ssao_radius = 1.1
	env.ssao_intensity = 1.4
	env.ssil_enabled = true
	env.ssil_intensity = 0.45
	env.fog_density = 0.003
	env.fog_light_color = Color(0.47, 0.53, 0.53)
	env.volumetric_fog_density = 0.011
	env.volumetric_fog_albedo = Color(0.7, 0.74, 0.72)
	env.volumetric_fog_length = 75.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 0.82
	env.adjustment_contrast = 1.04
	$Sun.rotation_degrees = Vector3(-32, -32, 0)
	$Sun.light_color = Color(1.0, 0.95, 0.87)
	$Sun.light_energy = 1.25
	$Sun.directional_shadow_max_distance = 65.0
	$Sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	$Sun.light_angular_distance = 1.2
	$Sun.shadow_blur = 1.4
	preload("res://resources/environments/cold_overcast.tres").apply(env, $Sun)

func _trees() -> void:
	var index: int = 0
	for tree: Node3D in $Forest.get_children():
		# Move the complete tree, including its existing collider, off the old grid.
		if not tree.has_meta(&"clustered"):
			tree.position.x += rng.randf_range(-1.25, 1.25)
			tree.position.z += rng.randf_range(-1.5, 1.5)
			if absf(tree.position.x) < 3.6: tree.position.x = signf(tree.position.x) * 3.6
			if tree.position.x > 10 and tree.position.x < 14: tree.position.x = 15.0
			tree.position.y = preload("res://scripts/presentation/forest_relief.gd").height_at(tree.position)
			tree.scale *= rng.randf_range(0.88, 1.1)
			tree.set_meta(&"clustered", true)
		tree.get_node("Trunk/Mesh").visible = false
		tree.get_node("LowerCanopy").visible = false
		tree.get_node("UpperCanopy").visible = false
		tree.get_node("Trunk").set_meta(&"surface", &"wood")
		var seed_value: int = 1944 if Engine.is_editor_hint() or not has_node("/root/PrototypeSession") else get_node("/root/PrototypeSession").operation_seed
		var variant: int = posmod(index + seed_value, 3)
		for part_name: String in ["wood", "foliage"]:
			var part: MeshInstance3D = MeshInstance3D.new()
			part.mesh = load("res://assets/environments/germany/forest/tree_%d_%s.res" % [variant, part_name])
			tree.add_child(part)
			part.rotation.y = index * 1.7 + float(seed_value % 31) * 0.2
			part.visibility_range_end = 34.0
			var distant: MeshInstance3D = MeshInstance3D.new()
			distant.mesh = load("res://assets/environments/germany/forest/tree_%d_%s_lod.res" % [variant, part_name])
			tree.add_child(distant)
			distant.rotation.y = part.rotation.y
			distant.visibility_range_begin = 34.0
			distant.visibility_range_end = 85.0
			distant.add_to_group(&"quality_tree_far")
			distant.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			part.lod_bias = 0.65
			if part_name == "foliage":
				part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		index += 1
	# Distant silhouettes and rock banks conceal the original perimeter collision.
	var rock: Mesh = load("res://assets/environments/germany/forest/rock.res")
	for z: int in range(-86, 36, 9):
		for side: int in [-1, 1]:
			var stone: MeshInstance3D = P.shape(art, Vector3(side * rng.randf_range(25, 27), 0.4, z + rng.randf_range(-2, 2)), rock, null)
			stone.scale = Vector3(rng.randf_range(2, 5), rng.randf_range(2, 4), rng.randf_range(3, 6))
			stone.rotation.y = rng.randf_range(-PI, PI)
	for x: int in range(-24, 26, 4):
		var stone: MeshInstance3D = P.shape(art, Vector3(x, 0.3, 35), rock, null)
		stone.scale = Vector3(6, 5, 6)
		stone.rotation.y = rng.randf_range(-PI, PI)

func _undergrowth() -> void:
	for chunk_z: int in range(-5, 4):
		for chunk_x: int in range(-3, 3):
			for kind: String in ["fern", "grass", "rock", "litter", "shrub"]:
				var transforms: Array[Transform3D] = []
				for item: int in range(70 if kind in ["grass", "litter"] else 15):
					var point: Vector3 = Vector3(chunk_x * 8 + rng.randf_range(0, 8), 0.025, chunk_z * 10 + rng.randf_range(0, 10))
					if absf(point.x) < 3.1 or (point.x < -8 and point.z > -10 and point.z < 24):
						continue
					if point.z < -36 and absf(point.x) < 11:
						continue
					if point.x > 10 and point.x < 14: continue
					# Broad patches leave pockets of litter between fern/shrub clusters.
					if kind in ["fern", "shrub"] and sin(point.x * 0.6 + sin(point.z * 0.3)) < -0.25: continue
					var scale_factor: float = rng.randf_range(0.6, 1.4) if kind != "rock" else rng.randf_range(0.12, 0.55)
					point.y += preload("res://scripts/presentation/forest_relief.gd").height_at(point)
					transforms.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * scale_factor), point))
				var batch: MultiMeshInstance3D = MultiMeshInstance3D.new()
				batch.multimesh = MultiMesh.new()
				batch.multimesh.transform_format = MultiMesh.TRANSFORM_3D
				batch.multimesh.mesh = load("res://assets/environments/germany/forest/" + kind + ".res")
				batch.multimesh.instance_count = transforms.size()
				for i: int in range(transforms.size()):
					batch.multimesh.set_instance_transform(i, transforms[i])
				art.add_child(batch)
				if kind != "rock": batch.add_to_group(&"quality_vegetation")
				batch.visibility_range_end = 45.0 if kind != "rock" else 65.0
				batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Fallen timber and roots stay beyond the clear combat lanes.
	for i: int in range(24):
		var point: Vector3 = Vector3(rng.randf_range(11, 22) * (-1 if i % 2 == 0 else 1), 0.18, rng.randf_range(-50, 30))
		point.y += preload("res://scripts/presentation/forest_relief.gd").height_at(point)
		P.rod(art, point, point + Vector3(rng.randf_range(1, 3), 0.05, 1.2), 0.18, load("res://assets/materials/presentation/bark.tres"))
