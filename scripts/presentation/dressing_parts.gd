class_name DressingParts
extends RefCounted
## Visual-only furniture is placed inside existing collision envelopes.

static func material(color: Color, metallic: float = 0.0) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = 0.6 if metallic > 0 else 0.88
	return mat

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
	cylinder.radial_segments = 8
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
