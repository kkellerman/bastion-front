class_name DressingParts
extends RefCounted
## Visual-only furniture is placed inside existing collision envelopes.

static func material(color: Color, metallic: float = 0.0) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = 0.6 if metallic > 0 else 0.88
	return mat

static func worn(color: Color, metallic: float = 0.0, wood: bool = false) -> ShaderMaterial:
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = load("res://shaders/worn_surface.gdshader")
	mat.set_shader_parameter("base_color", color)
	mat.set_shader_parameter("metal", metallic)
	mat.set_shader_parameter("wood", wood)
	return mat

static func batch_static(parent: Node3D) -> void:
	# Consolidate stationary dressing by material; collision/light/sign nodes stay independent.
	var batches: Dictionary = {}
	for node: Node in parent.get_children():
		if not node is MeshInstance3D or node.mesh == null: continue
		for surface: int in range(node.mesh.get_surface_count()):
			var mat: Material = node.material_override if node.material_override != null else node.mesh.surface_get_material(surface)
			if not batches.has(mat):
				var st: SurfaceTool = SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				st.set_material(mat)
				batches[mat] = st
			batches[mat].append_from(node.mesh,surface,node.transform)
		parent.remove_child(node)
		node.free()
	for mat: Material in batches:
		var st: SurfaceTool = batches[mat]
		st.index()
		var merged: MeshInstance3D = shape(parent,Vector3.ZERO,st.commit(),null)
		# Spanning meshes use normal frustum culling, not distance from a single origin.
		merged.visibility_range_end = 0

static func box(parent: Node3D, point: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	return shape(parent, point, mesh, mat)

static func shape(parent: Node3D, point: Vector3, mesh: Mesh, mat: Material) -> MeshInstance3D:
	var part: MeshInstance3D = MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = mat
	parent.add_child(part)
	part.position = point
	part.visibility_range_end = 65.0
	return part

static func rod(parent: Node3D, start: Vector3, end: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = start.distance_to(end)
	cylinder.radial_segments = 16
	var part: MeshInstance3D = shape(parent, (start + end) * 0.5, cylinder, mat)
	var axis: Vector3 = (end - start).normalized()
	part.quaternion = Quaternion(Vector3.UP, axis)
	return part

static func sign_text(parent: Node3D, point: Vector3, words: String, size: float = 0.003) -> Label3D:
	var label: Label3D = Label3D.new()
	label.text = words
	label.font_size = 48
	label.pixel_size = size
	label.modulate = Color(0.79, 0.75, 0.59)
	label.no_depth_test = false
	label.shaded = true
	label.outline_size = 0
	parent.add_child(label)
	label.position = point
	return label

static func crate(parent: Node3D, point: Vector3, size: Vector3, wood: Material, iron: Material) -> void:
	box(parent, point + Vector3.UP * size.y * 0.5, size, wood)
	for x: float in [-0.35, 0.35]:
		box(parent, point + Vector3(x * size.x, size.y * 0.5, 0), Vector3(0.045, size.y + 0.025, size.z + 0.025), iron)
	for y: float in [0.18, 0.5, 0.82]:
		box(parent, point + Vector3(0, y * size.y, size.z * 0.5 + 0.005), Vector3(size.x, 0.012, 0.012), iron)
