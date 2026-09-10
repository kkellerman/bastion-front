extends SceneTree
const P = preload("res://scripts/presentation/dressing_parts.gd")
var steel: Material
var wood: Material
var black: Material

func _initialize() -> void:
	steel = P.material(Color(0.13, 0.15, 0.16), 0.85)
	wood = load("res://assets/materials/presentation/bark.tres").duplicate()
	wood.albedo_color = Color(0.5, 0.28, 0.13)
	wood.uv1_scale = Vector3(8, 2, 8)
	black = P.material(Color(0.02, 0.024, 0.026), 0.3)
	for id: String in ["m1911", "p38", "thompson", "mp40", "stg44", "bazooka", "panzerfaust"]:
		var data: WeaponData = load("res://resources/weapons/" + id + ".tres") as WeaponData
		var scene: Node3D = data.viewmodel_scene.instantiate() as Node3D
		for child: Node in scene.get_children():
			if child is MeshInstance3D or child.name == &"WeaponMesh":
				scene.remove_child(child)
				child.free()
		var model: Node3D = Node3D.new()
		model.name = "WeaponMesh"
		scene.add_child(model)
		if id in ["m1911", "p38"]:
			_pistol(model, id)
		elif id in ["bazooka", "panzerfaust"]:
			_launcher(model, id)
		else:
			_long_gun(model, id)
		if id in ["thompson", "mp40", "stg44"]:
			scene.get_node("Muzzle").position.z = -0.405
		elif id in ["bazooka", "panzerfaust"]:
			scene.get_node("Muzzle").position.z = -0.55
		_save(scene, data.viewmodel_scene.resource_path)
	for id: String in ["mg42", "m1919"]:
		var path: String = "res://scenes/mounted_weapons/" + id + ".tscn"
		var scene: Node3D = load(path).instantiate() as Node3D
		var gun: MeshInstance3D = scene.get_node("Pivot/Gun") as MeshInstance3D
		gun.mesh = null
		for child: Node in gun.get_children():
			gun.remove_child(child)
			child.free()
		_machine_gun(gun, id)
		_save(scene, path)
	_soldier()
	print("Built original equipment presentation")
	quit()

func _pistol(root: Node3D, id: String) -> void:
	P.box(root, Vector3(0, 0, 0), Vector3(0.038, 0.046, 0.22), steel)
	P.box(root, Vector3(0, -0.028, 0.018), Vector3(0.034, 0.018, 0.19), steel)
	P.box(root, Vector3(0, -0.079, 0.069), Vector3(0.036, 0.102, 0.054), black).rotation.x = -0.2
	for side: float in [-1, 1]:
		P.box(root, Vector3(side * 0.020, -0.079, 0.07), Vector3(0.007, 0.083, 0.042), wood if id == "m1911" else black).rotation.x = -0.2
		for rib: int in range(8):
			P.box(root, Vector3(side * 0.02, 0.003, 0.059 + rib * 0.005), Vector3(0.002, 0.034, 0.0015), black)
		for screw_y: float in [-0.05, -0.106]:
			P.rod(root, Vector3(side * 0.022, screw_y, 0.07), Vector3(side * 0.026, screw_y, 0.07), 0.003, steel)
	P.box(root, Vector3(0.02, 0.015, -0.02), Vector3(0.004, 0.018, 0.03), black)
	P.rod(root, Vector3(0, -0.004, -0.12), Vector3(0, -0.004, -0.07), 0.008, steel)
	P.rod(root, Vector3(0, -0.004, -0.122), Vector3(0, -0.004, -0.12), 0.0055, black)
	_guard(root, Vector3(0, -0.055, 0.01), Vector3(0.6, 1, 1))
	_sights(root, 0.032, -0.09, 0.085)
	P.box(root, Vector3(-0.023, -0.026, 0.055), Vector3(0.007, 0.008, 0.028), steel)
	P.box(root, Vector3(0, 0.019, 0.118), Vector3(0.012, 0.022, 0.014), steel)

func _long_gun(root: Node3D, id: String) -> void:
	var round_receiver: bool = id == "mp40"
	if round_receiver:
		P.rod(root, Vector3(0, 0, 0.12), Vector3(0, 0, -0.2), 0.032, steel)
	else:
		P.box(root, Vector3(0, 0, -0.025), Vector3(0.055, 0.065, 0.32), steel)
	P.rod(root, Vector3(0, 0, -0.19), Vector3(0, 0, -0.4), 0.012, steel)
	P.rod(root, Vector3(0, 0, -0.405), Vector3(0, 0, -0.402), 0.008, black)
	P.box(root, Vector3(0, -0.09, 0.07), Vector3(0.04, 0.13, 0.05), wood if id == "thompson" else black).rotation.x = -0.2
	_guard(root, Vector3(0, -0.055, 0.015), Vector3(0.8, 1.1, 1.2))
	P.box(root, Vector3(0, -0.15, -0.10), Vector3(0.032, 0.22, 0.055), steel).rotation.x = -0.15 if id == "stg44" else 0.0
	for side: float in [-1, 1]:
		for rib: int in range(3):
			P.box(root, Vector3(side * 0.017, -0.14, -0.118 + rib * 0.016), Vector3(0.003, 0.18, 0.003), black)
		P.rod(root, Vector3(side * 0.02, 0.012, -0.02), Vector3(side * 0.06, 0.012, -0.02), 0.006, steel)
	if id == "mp40":
		for side: float in [-1, 1]:
			P.rod(root, Vector3(side * 0.035, -0.03, 0.09), Vector3(side * 0.035, -0.08, 0.3), 0.007, steel)
		P.rod(root, Vector3(-0.035, -0.08, 0.3), Vector3(0.035, -0.08, 0.3), 0.008, steel)
	else:
		P.box(root, Vector3(0, -0.052, 0.22), Vector3(0.055, 0.10, 0.25), wood).rotation.x = 0.12
		P.box(root, Vector3(0, -0.03, -0.23), Vector3(0.05, 0.042, 0.12), wood if id == "thompson" else steel)
	if id == "stg44":
		P.rod(root, Vector3(0, 0.021, -0.18), Vector3(0, 0.021, -0.36), 0.01, steel)
		for vent: int in range(6):
			P.box(root, Vector3(0.027, -0.02, -0.18 - vent * 0.018), Vector3(0.003, 0.014, 0.008), black)
	_sights(root, 0.052, -0.37, 0.08)

func _launcher(root: Node3D, id: String) -> void:
	var olive: Material = P.material(Color(0.19, 0.21, 0.12), 0.3)
	var radius: float = 0.055 if id == "bazooka" else 0.026
	P.rod(root, Vector3(0, 0, 0.4), Vector3(0, 0, -0.48), radius, olive)
	P.rod(root, Vector3(0, 0, -0.483), Vector3(0, 0, -0.48), radius * 0.83, black)
	P.box(root, Vector3(0, -0.11, 0.03), Vector3(0.035, 0.13, 0.05), wood)
	if id == "panzerfaust":
		var head: SphereMesh = SphereMesh.new()
		head.radius = 0.075
		head.height = 0.15
		P.shape(root, Vector3(0, 0, -0.4), head, olive).scale = Vector3(1, 1, 1.7)
	P.box(root, Vector3(0.04, 0.08, 0), Vector3(0.006, 0.13, 0.018), steel)

func _machine_gun(root: Node3D, id: String) -> void:
	P.box(root, Vector3(0, 0, 0), Vector3(0.12, 0.13, 0.4), steel)
	P.rod(root, Vector3(0, 0, -0.18), Vector3(0, 0, -0.65), 0.046, steel)
	P.rod(root, Vector3(0, 0, -0.65), Vector3(0, 0, -0.73), 0.025, steel)
	for side: float in [-1, 1]:
		for hole: int in range(12):
			P.box(root, Vector3(side * 0.044, 0, -0.21 - hole * 0.034), Vector3(0.004, 0.045, 0.017), black)
	P.box(root, Vector3(0, -0.05, 0.28), Vector3(0.085, 0.15, 0.3), wood if id == "mg42" else steel)
	P.box(root, Vector3(0, -0.13, 0.08), Vector3(0.045, 0.13, 0.055), black)
	_sights(root, 0.09, -0.55, 0.07)
	for bullet: int in range(10):
		P.rod(root, Vector3(-0.1 - bullet * 0.028, -0.015, -0.07), Vector3(-0.1 - bullet * 0.028, -0.015, 0.015), 0.009, P.material(Color(0.4, 0.3, 0.12), 0.7))

func _guard(root: Node3D, point: Vector3, scaling: Vector3) -> void:
	var ring: TorusMesh = TorusMesh.new()
	ring.inner_radius = 0.023
	ring.outer_radius = 0.027
	ring.rings = 16
	ring.ring_segments = 8
	var node: MeshInstance3D = P.shape(root, point, ring, steel)
	node.rotation.z = PI * 0.5
	node.scale = scaling
	P.rod(root, point + Vector3(0, 0.017, 0), point + Vector3(0, -0.008, 0.008), 0.004, steel)

func _sights(root: Node3D, y: float, front: float, back: float) -> void:
	P.box(root, Vector3(0, y, front), Vector3(0.006, 0.012, 0.012), black)
	for side: float in [-1, 1]:
		P.box(root, Vector3(side * 0.009, y, back), Vector3(0.006, 0.012, 0.015), black)

func _soldier() -> void:
	var root: Node3D = Node3D.new()
	root.name = "InfantryVisual"
	var cloth: Material = P.material(Color(0.21, 0.25, 0.21))
	var leather: Material = P.material(Color(0.065, 0.058, 0.046))
	var skin: Material = P.material(Color(0.45, 0.33, 0.24))
	for x: float in [-0.13, 0.13]:
		_oval(root, Vector3(x, 0.62, 0), Vector3(0.2, 0.6, 0.23), cloth)
		_oval(root, Vector3(x, 0.25, 0), Vector3(0.19, 0.42, 0.2), leather)
		_oval(root, Vector3(x, 0.08, -0.07), Vector3(0.21, 0.16, 0.35), leather)
	_oval(root, Vector3(0, 1.15, 0), Vector3(0.49, 0.65, 0.29), cloth)
	_oval(root, Vector3(0, 1.61, 0), Vector3(0.25, 0.34, 0.25), skin)
	_oval(root, Vector3(0, 1.62, -0.13), Vector3(0.05, 0.075, 0.07), skin)
	var helmet: SphereMesh = SphereMesh.new()
	helmet.radius = 0.18
	helmet.height = 0.36
	helmet.is_hemisphere = true
	P.shape(root, Vector3(0, 1.71, 0), helmet, steel).scale = Vector3(1, 0.8, 1.13)
	_oval(root, Vector3(0, 1.71, 0.02), Vector3(0.38, 0.045, 0.43), steel)
	for side: float in [-1, 1]:
		_oval(root, Vector3(side * 0.29, 1.26, -0.01), Vector3(0.19, 0.4, 0.2), cloth)
		_oval(root, Vector3(side * 0.26, 1.06, -0.2), Vector3(0.17, 0.18, 0.37), cloth)
		_oval(root, Vector3(side * 0.23, 1.07, -0.4), Vector3(0.12, 0.12, 0.13), skin)
		P.box(root, Vector3(side * 0.12, 1.05, -0.17), Vector3(0.15, 0.16, 0.055), leather)
		P.rod(root, Vector3(side * 0.18, 1.43, -0.12), Vector3(side * 0.10, 0.93, -0.16), 0.019, leather)
	P.box(root, Vector3(0, 0.97, 0), Vector3(0.46, 0.06, 0.31), leather)
	P.box(root, Vector3(0, 0.97, -0.165), Vector3(0.07, 0.05, 0.01), steel)
	_oval(root, Vector3(0.16, 1.05, 0.24), Vector3(0.16, 0.22, 0.12), cloth)
	P.rod(root, Vector3(-0.18, 0.94, 0.22), Vector3(-0.12, 1.22, 0.22), 0.08, steel)
	_save(root, "res://assets/characters/german/infantry_field_uniform.tscn")

func _oval(root: Node3D, point: Vector3, size: Vector3, mat: Material) -> void:
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radial_segments = 20
	sphere.rings = 12
	P.shape(root, point, sphere, mat).scale = size

func _save(scene: Node3D, path: String) -> void:
	_own(scene, scene)
	var packed: PackedScene = PackedScene.new()
	packed.pack(scene)
	ResourceSaver.save(packed, path)
	scene.free()

func _own(node: Node, scene: Node) -> void:
	for child: Node in node.get_children():
		child.owner = scene
		if child is MeshInstance3D and child.mesh is BoxMesh:
			child.mesh = _bevel(child.mesh)
		if child is GeometryInstance3D and "viewmodel" in scene.scene_file_path:
			child.cast_shadow = 0
		_own(child, scene)

func _bevel(source: BoxMesh) -> ArrayMesh:
	var box: BoxMesh = source.duplicate() as BoxMesh
	box.subdivide_width = 2
	box.subdivide_height = 2
	box.subdivide_depth = 2
	var arrays: Array = box.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var bevel: float = minf(minf(box.size.x, box.size.y), box.size.z) * 0.12
	var half: Vector3 = box.size * 0.5 - Vector3.ONE * bevel
	for i: int in range(vertices.size()):
		var inner: Vector3 = vertices[i].clamp(-half, half)
		var normal: Vector3 = (vertices[i] - inner).normalized()
		vertices[i] = inner + normal * bevel
		normals[i] = normal
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	var result: ArrayMesh = ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return result
