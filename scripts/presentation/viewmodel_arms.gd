extends Node3D
const P = preload("res://scripts/presentation/dressing_parts.gd")
var support: Node3D
var _time: float = 0.0

func build(data: WeaponData, faction: FactionData) -> void:
	name = "Arms"
	var cloth: ShaderMaterial = ShaderMaterial.new()
	cloth.shader = load("res://shaders/uniform_fabric.gdshader")
	cloth.set_shader_parameter("cloth_color", faction.sleeve_color if faction != null else Color(0.38, 0.36, 0.25))
	var skin: Material = P.material(Color(0.48, 0.34, 0.25))
	var trigger: Vector3 = Vector3(0.027, -0.077, 0.074)
	var left: Vector3 = data.support_hand_position
	for side: int in [-1, 1]:
		var hand: Node3D = Node3D.new()
		add_child(hand)
		hand.position = left if side < 0 else trigger
		if side < 0: support = hand
		_segment(hand, Vector3(side * 0.20, -0.25, 0.40), Vector3(side * 0.04, -0.025, 0.065), 0.065, 0.038, cloth)
		_segment(hand, Vector3(side * 0.04, -0.025, 0.065), Vector3.ZERO, 0.031, 0.033, skin)
		var palm: MeshInstance3D = _segment(hand, Vector3(0, -0.018, 0.015), Vector3(0, 0.012, -0.042), 0.032, 0.027, skin)
		palm.scale.z = 0.75
		for finger: int in range(4):
			var start: Vector3 = Vector3(0, 0.015 - finger * 0.013, -0.024)
			var joint: Vector3 = start + Vector3(-side * 0.031, -0.006, -0.007)
			_segment(hand, start, joint, 0.0085, 0.0075, skin)
			_segment(hand, joint, joint + Vector3(0, -0.012, 0.022), 0.0075, 0.006, skin)
		_segment(hand, Vector3(side * 0.018, 0.015, 0.018), Vector3(-side * 0.020, 0.030, -0.010), 0.011, 0.008, skin)

func _process(delta: float) -> void:
	_time += delta
	if support != null:
		var active: bool = get_parent().reloading
		support.rotation.x = lerpf(support.rotation.x, -0.7 if active else 0.0, minf(delta * 8, 1))

func _segment(parent: Node3D, start: Vector3, end: Vector3, radius: float, tip: float, material: Material) -> MeshInstance3D:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = tip
	mesh.height = start.distance_to(end)
	mesh.radial_segments = 16
	mesh.rings = 3
	var part: MeshInstance3D = P.shape(parent, (start + end) * 0.5, mesh, material)
	var axis: Vector3 = (end - start).normalized()
	var right: Vector3 = axis.cross(Vector3.FORWARD).normalized()
	part.basis = Basis(right, axis, right.cross(axis))
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return part
