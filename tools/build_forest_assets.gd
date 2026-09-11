extends SceneTree
const W = preload("res://scripts/presentation/mesh_workshop.gd")
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var folder: String = "res://assets/environments/germany/forest/"

func _initialize() -> void:
	rng.seed = 41894
	DirAccess.make_dir_recursive_absolute(folder)
	for variant: int in range(3):
		_tree(variant)
		_tree(variant, true)
	_ground_plants()
	print("Built original forest meshes")
	quit()

func _tree(variant: int, low: bool = false) -> void:
	var wood: SurfaceTool = W.surface()
	var leaves: SurfaceTool = W.surface()
	var height: float = 13.0 + variant
	for ring: int in range(12):
		var y: float = float(ring) / 12.0
		W.tube(wood, Vector3(sin(y * 3) * 0.16, y * height, 0), Vector3(sin((y + 1.0 / 12) * 3) * 0.16, (y + 1.0 / 12) * height, 0), 0.3 * (1.0 - y) + 0.015, 0.3 * (1.0 - y - 1.0 / 12) + 0.015, 12)
	for root_index: int in range(7):
		var angle: float = root_index * TAU / 7
		W.tube(wood, Vector3(0, 0.2, 0), Vector3(cos(angle), 0.015, sin(angle)) * 1.1, 0.11, 0.018)
	var branches: int = 24 if low else 48
	for branch: int in range(branches):
		var fraction: float = float(branch) / branches
		var angle: float = branch * 2.39996 + rng.randf_range(-0.3, 0.3)
		var y: float = 3.6 + fraction * (height - 3.8)
		var length: float = (1.0 - fraction) * rng.randf_range(2.1, 3.6) + 0.2
		var direction: Vector3 = Vector3(cos(angle), -0.16, sin(angle))
		if variant == 2:
			y = 7.5 + fraction * 7.0
			length = sin(fraction * PI) * 2.7 + 0.6
			direction.y = 0.22
		var base: Vector3 = Vector3(0.1, y, 0)
		var end: Vector3 = base + direction * length
		W.tube(wood, base, end, 0.045 * (1.0 - fraction) + 0.008, 0.006)
		var twigs: int = 3 if low else 7
		for twig: int in range(twigs):
			var along: float = float(twig + 1) / (twigs + 1)
			var center: Vector3 = base.lerp(end, along)
			var side: Vector3 = Vector3(-direction.z, 0.1, direction.x) * (1.0 if twig % 2 == 0 else -1.0)
			var twig_end: Vector3 = center + (side + direction * 0.35) * (1.0 - along * 0.6) * 0.65
			W.tube(wood, center, twig_end, 0.009, 0.002, 5)
			_card(leaves, center, twig_end + side * 0.22, 0.36 if low else 0.24)
			if not low: _card(leaves, center, twig_end + Vector3(0, -0.32, 0), 0.22)
	var suffix: String = "_lod" if low else ""
	_save(wood, "tree_%d_wood%s" % [variant, suffix], load("res://assets/materials/presentation/bark.tres"))
	var needles: ShaderMaterial = ShaderMaterial.new()
	needles.shader = load("res://shaders/needle_branch.gdshader")
	needles.set_shader_parameter("branch_atlas", load("res://assets/textures/spruce_branch.png"))
	_save(leaves, "tree_%d_foliage%s" % [variant, suffix], needles)

func _card(st: SurfaceTool, start: Vector3, end: Vector3, width: float) -> void:
	var side: Vector3 = (end - start).cross(Vector3.UP).normalized() * width
	var normal: Vector3 = side.cross(end - start).normalized()
	var points: Array[Vector3] = [start - side, start + side, end + side, end - side]
	var uvs: Array[Vector2] = [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
	st.set_color(Color(rng.randf_range(0.25, 0.9), 1, 1))
	for i: int in [0, 1, 2, 0, 2, 3]:
		st.set_normal(normal)
		st.set_uv(uvs[i])
		st.add_vertex(points[i])

func _ground_plants() -> void:
	var fern: SurfaceTool = W.surface()
	for frond: int in range(9):
		var angle: float = frond * TAU / 9
		var axis: Vector3 = Vector3(cos(angle), 0, sin(angle))
		var side: Vector3 = Vector3(-axis.z, 0, axis.x)
		for pair: int in range(14):
			var t: float = float(pair + 1) / 15
			var point: Vector3 = axis * t * 0.75 + Vector3.UP * sin(t * PI * 0.8) * 0.6
			for sign_value: float in [-1.0, 1.0]:
				W.leaf(fern, point, point + side * sign_value * sin(t * PI) * 0.22 + axis * 0.09, 0.032, Color(0.15 + t * 0.05, 0.24 + t * 0.09, 0.075))
	_save(fern, "fern", _foliage())
	var grass: SurfaceTool = W.surface()
	for blade: int in range(34):
		var base: Vector3 = Vector3(rng.randf_range(-0.2, 0.2), 0, rng.randf_range(-0.2, 0.2))
		W.leaf(grass, base, base + Vector3(rng.randf_range(-0.3, 0.3), rng.randf_range(0.18, 0.6), rng.randf_range(-0.3, 0.3)), 0.014, Color(0.24, 0.27, 0.11).lerp(Color(0.12, 0.18, 0.08), rng.randf()))
	_save(grass, "grass", _foliage())
	var litter: SurfaceTool = W.surface()
	for i: int in range(5):
		var point: Vector3 = Vector3(rng.randf_range(-0.2, 0.2), 0.012, rng.randf_range(-0.2, 0.2))
		W.leaf(litter, point, point + Vector3(rng.randf_range(-0.13, 0.13), 0.003, 0.12), 0.045, Color(0.32, 0.20, 0.08))
	_save(litter, "litter", _foliage())
	var shrub: SurfaceTool = W.surface()
	for branch: int in range(16):
		var direction: Vector3 = Vector3(cos(branch * 2.4), 0.5, sin(branch * 2.4))
		for leaf: int in range(12):
			var point: Vector3 = Vector3.UP * 0.1 + direction * float(leaf) * 0.055
			W.leaf(shrub, point, point + Vector3(-direction.z, 0.3, direction.x) * (0.19 if leaf % 2 == 0 else -0.19), 0.05, Color(0.15, 0.25, 0.10))
	_save(shrub, "shrub", _foliage())
	var rock: SphereMesh = SphereMesh.new()
	rock.radial_segments = 20
	rock.rings = 12
	var arrays: Array = rock.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.frequency = 3.0
	for i: int in range(vertices.size()):
		vertices[i] *= 1.0 + noise.get_noise_3dv(vertices[i]) * 0.5
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, load("res://assets/materials/presentation/rock.tres"))
	ResourceSaver.save(mesh, folder + "rock.res")

func _foliage() -> ShaderMaterial:
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = load("res://shaders/foliage.gdshader")
	return mat

func _save(st: SurfaceTool, file: String, material: Material) -> void:
	st.set_material(material)
	st.index()
	ResourceSaver.save(st.commit(), folder + file + ".res")
