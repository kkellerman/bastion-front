extends SceneTree
## Shared rig and original equipment around the credited CC0 donor body.
const P = preload("res://scripts/presentation/dressing_parts.gd")
var skeleton: Skeleton3D
var scene: Node3D
var surfaces: Array[SurfaceTool] = []
var materials: Array[Material] = []
var bone_positions: Array[Vector3] = []

func _initialize() -> void:
	for faction: String in ["allied", "german"]:
		var paths: Array[String] = []
		for face_variant: int in range(preload("res://tools/character_head.gd").variant_count()):
			var suffix: String = "" if face_variant == 0 else "_face_%d" % (face_variant + 1)
			var path: String = "res://assets/characters/%s/infantry_rigged%s.tscn" % [faction, suffix]
			_build(faction, face_variant, path)
			paths.append(path)
		var data: FactionData = load("res://resources/factions/" + faction + ".tres")
		data.uniform_scene = load(paths[0])
		data.visual_variants.clear()
		for path: String in paths:
			data.visual_variants.append(load(path))
		ResourceSaver.save(data, data.resource_path)
	print("Built shared rig, three face variants, faction clothing, sockets and animation libraries")
	quit()

func _build(faction: String, face_variant: int, output_path: String) -> void:
	var german: bool = faction == "german"
	scene = Node3D.new()
	scene.name = "CharacterBase"
	skeleton = Skeleton3D.new()
	skeleton.name = "Skeleton3D"
	scene.add_child(skeleton)
	bone_positions.clear()
	_bone("Hips", -1, Vector3(0, 0.94, 0))
	_bone("Spine", 0, Vector3(0, 1.18, 0))
	_bone("Chest", 1, Vector3(0, 1.39, 0))
	_bone("Neck", 2, Vector3(0, 1.51, 0))
	_bone("Head", 3, Vector3(0, 1.63, 0))
	for side: int in [-1, 1]:
		var prefix: String = "Left" if side < 0 else "Right"
		var thigh: int = skeleton.get_bone_count()
		_bone(prefix + "Thigh", 0, Vector3(side * 0.105, 0.9, 0))
		_bone(prefix + "Shin", thigh, Vector3(side * 0.105, 0.51, 0))
		_bone(prefix + "Foot", thigh + 1, Vector3(side * 0.105, 0.13, 0))
		var arm: int = skeleton.get_bone_count()
		_bone(prefix + "UpperArm", 2, Vector3(side * 0.21, 1.43, 0))
		_bone(prefix + "Forearm", arm, Vector3(-0.14, 1.20, -0.20) if side < 0 else Vector3(0.29, 1.18, 0.04))
		_bone(prefix + "Hand", arm + 1, Vector3(0.078, 1.36, -0.42) if side < 0 else Vector3(0.13, 1.34, -0.11))
	# Index 3 (skin: neck/ears and hands/fingers) previously used the flat, untextured
	# material() helper, unlike every other slot here; worn() adds the same procedural
	# noise/normal variation already used for weapon and prop skin tones elsewhere.
	materials = [P.material(Color(0.22, 0.265, 0.225) if german else Color(0.38, 0.36, 0.25)), P.material(Color(0.19, 0.22, 0.19) if german else Color(0.25, 0.26, 0.18)), P.material(Color(0.075, 0.066, 0.05)), P.worn(Color(0.47, 0.335, 0.255)), P.worn(Color(0.13, 0.17, 0.14), 0.4) if german else P.material(Color(0.13, 0.17, 0.14), 0.4), P.material(Color(0.10, 0.11, 0.085) if german else Color(0.43, 0.42, 0.28))]
	var sleeve: Color = materials[0].albedo_color
	for index: int in [0, 1, 5]:
		var cloth: ShaderMaterial = ShaderMaterial.new()
		cloth.shader = load("res://shaders/uniform_fabric.gdshader")
		cloth.set_shader_parameter("cloth_color", materials[index].albedo_color)
		cloth.set_shader_parameter("fabric_albedo", load("res://assets/textures/polyhaven/rough_linen/rough_linen_diff_1k.jpg"))
		cloth.set_shader_parameter("fabric_normal", load("res://assets/textures/polyhaven/rough_linen/rough_linen_nor_gl_1k.jpg"))
		cloth.set_shader_parameter("fabric_rough", load("res://assets/textures/polyhaven/rough_linen/rough_linen_rough_1k.jpg"))
		materials[index] = cloth
	surfaces.clear()
	for material: Material in materials:
		var st: SurfaceTool = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.set_material(material)
		surfaces.append(st)
	# Tunic profile: shaped waist, skirt, chest and shoulders, with restrained cloth folds.
	_loft(0, 1, Vector3.ZERO, [Vector3(0.84, 0.20, 0.115), Vector3(0.9, 0.205, 0.12), Vector3(1.03, 0.155, 0.10), Vector3(1.18, 0.18, 0.12), Vector3(1.34, 0.215, 0.125), Vector3(1.43, 0.21, 0.105), Vector3(1.48, 0.08, 0.073)], 24, 0.018)
	_loft(3, 3, Vector3.ZERO, [Vector3(1.46, 0.056, 0.06), Vector3(1.59, 0.054, 0.057)], 20)
	_loft(3, 4, Vector3(0, 0, -0.015), [Vector3(1.54, 0.029, 0.04), Vector3(1.555, 0.049, 0.063), Vector3(1.58, 0.069, 0.069), Vector3(1.61, 0.079, 0.078), Vector3(1.64, 0.074, 0.08), Vector3(1.665, 0.071, 0.084), Vector3(1.70, 0.073, 0.086), Vector3(1.735, 0.051, 0.063), Vector3(1.75, 0.002, 0.003)], 32)
	# Nose, ears and eye recesses give the head a readable face under the helmet brim.
	_loft(3, 4, Vector3(0, 0, -0.09), [Vector3(1.61, 0.018, 0.012), Vector3(1.62, 0.018, 0.031), Vector3(1.66, 0.008, 0.003)], 12)
	for side: int in [-1, 1]:
		_loft(3, 4, Vector3(side * 0.079, 0, 0), [Vector3(1.6, 0.008, 0.012), Vector3(1.63, 0.015, 0.019), Vector3(1.66, 0.008, 0.012)], 12)
		_detail(2, 4, Vector3(side * 0.033, 1.647, -0.089), Vector3(0.025, 0.006, 0.004))
		_detail(2, 4, Vector3(side * 0.033, 1.658, -0.087), Vector3(0.032, 0.006, 0.006))
		# Tunic collar, shoulder straps, chinstrap and pocket flaps break the flat silhouette.
		_detail(1, 2, Vector3(side * 0.057, 1.444, -0.086), Vector3(0.075, 0.052, 0.019))
		_detail(0, 2, Vector3(side * 0.155, 1.444, 0), Vector3(0.09, 0.017, 0.095))
		_limb(2, 4, Vector3(side * 0.084, 1.69, 0), Vector3(side * 0.045, 1.55, -0.045), 0.007, 0.007)
	_detail(2, 4, Vector3(0, 1.582, -0.088), Vector3(0.034, 0.003, 0.003))
	if german:
		_stahlhelm()
	else:
		# American M1's evenly tapering dome-to-rim profile.
		_loft(4, 4, Vector3(0, 0, 0.005), [Vector3(1.681, 0.116, 0.134), Vector3(1.686, 0.102, 0.118), Vector3(1.725, 0.091, 0.105), Vector3(1.769, 0.062, 0.072), Vector3(1.79, 0.003, 0.003)], 32)
	for side: int in [-1, 1]:
		var prefix: String = "Left" if side < 0 else "Right"
		var thigh: int = skeleton.find_bone(prefix + "Thigh")
		var shin: int = skeleton.find_bone(prefix + "Shin")
		var foot: int = skeleton.find_bone(prefix + "Foot")
		_loft(1, thigh, Vector3(side * 0.105, 0, 0), [Vector3(0.48, 0.076, 0.085), Vector3(0.57, 0.087, 0.088), Vector3(0.76, 0.102, 0.104), Vector3(0.91, 0.096, 0.10)], 20, 0.025)
		_loft(1, shin, Vector3(side * 0.105, 0, 0), [Vector3(0.21, 0.062, 0.062), Vector3(0.32, 0.073, 0.075), Vector3(0.45, 0.08, 0.078), Vector3(0.53, 0.075, 0.086)], 20, 0.025)
		_loft(2 if german else 5, shin, Vector3(side * 0.105, 0, 0), [Vector3(0.095, 0.066, 0.074), Vector3(0.18, 0.06, 0.069), Vector3(0.34 if german else 0.28, 0.073, 0.078)], 20)
		_loft(2, foot, Vector3(side * 0.105, 0, -0.045), [Vector3(0.025, 0.073, 0.135), Vector3(0.052, 0.075, 0.137), Vector3(0.10, 0.067, 0.12), Vector3(0.145, 0.045, 0.055)], 24)
		var upper: int = skeleton.find_bone(prefix + "UpperArm")
		var lower: int = skeleton.find_bone(prefix + "Forearm")
		var hand: int = skeleton.find_bone(prefix + "Hand")
		_limb(0, upper, bone_positions[upper], bone_positions[lower], 0.077, 0.064)
		_limb(0, lower, bone_positions[lower], bone_positions[hand], 0.069, 0.045)
		_limb(3, hand, bone_positions[hand], bone_positions[hand] + Vector3(0, -0.015, -0.075), 0.041, 0.035)
		for finger: int in range(4):
			_limb(3, hand, bone_positions[hand] + Vector3(side * 0.025, -0.02 - finger * 0.012, -0.03), bone_positions[hand] + Vector3(-side * 0.02, -0.027 - finger * 0.012, -0.047), 0.009, 0.007)
		for y: float in [1.1, 1.31]:
			_detail(0, 1, Vector3(side * 0.115, y, -0.12), Vector3(0.10, 0.115, 0.022))
			_detail(1, 1, Vector3(side * 0.115, y + 0.04, -0.134), Vector3(0.103, 0.025, 0.012))
		_detail(5, 1, Vector3(side * 0.105, 1.26, -0.143), Vector3(0.029, 0.34, 0.012))
		for pouch: int in range(3): _detail(5, 0, Vector3(side * (0.057 + pouch * 0.05), 1.00, -0.127), Vector3(0.043, 0.10, 0.045))
	_loft(2 if german else 5, 0, Vector3.ZERO, [Vector3(1.045, 0.162, 0.116), Vector3(1.087, 0.164, 0.116)], 24)
	_detail(4, 0, Vector3(0, 1.064, -0.124), Vector3(0.045, 0.036, 0.008))
	for y: float in [1.15, 1.23, 1.31, 1.39]: _detail(4, 1, Vector3(0, y, -0.132), Vector3(0.009, 0.009, 0.005))
	_detail(5, 1, Vector3(0, 1.24, 0.16), Vector3(0.26, 0.24, 0.12))
	_detail(5, 0, Vector3(0.19, 0.97, 0.05), Vector3(0.085, 0.14, 0.09))
	if german: _limb(4, 1, Vector3(-0.12, 1.05, 0.19), Vector3(0.10, 1.19, 0.19), 0.055, 0.055)
	_finish_mesh("UniformAndBody")
	var body_mesh: ArrayMesh = preload("res://tools/retarget_soldier.gd").body(skeleton, bone_positions)
	body_mesh = preload("res://tools/retarget_soldier.gd").remove_hands(body_mesh, skeleton)
	body_mesh = preload("res://tools/character_head.gd").remove_donor_head(body_mesh)
	var body_material: ShaderMaterial = ShaderMaterial.new()
	body_material.shader = load("res://shaders/soldier_surface.gdshader")
	body_material.set_shader_parameter("source_color_map", load("res://assets/characters/source/LowpolySoldier/LowpolySoldier_Texture.png"))
	body_material.set_shader_parameter("uniform_color", sleeve)
	body_material.set_shader_parameter("gaiter_color", Color(0.36, 0.35, 0.24))
	body_material.set_shader_parameter("short_gaiters", not german)
	body_material.set_shader_parameter("fabric_albedo", load("res://assets/textures/polyhaven/rough_linen/rough_linen_diff_1k.jpg"))
	body_material.set_shader_parameter("fabric_normal", load("res://assets/textures/polyhaven/rough_linen/rough_linen_nor_gl_1k.jpg"))
	body_material.set_shader_parameter("fabric_rough", load("res://assets/textures/polyhaven/rough_linen/rough_linen_rough_1k.jpg"))
	body_mesh.surface_set_material(0, body_material)
	var body_node: MeshInstance3D = scene.get_node("UniformAndBody")
	body_node.mesh = body_mesh
	var head: MeshInstance3D = MeshInstance3D.new()
	head.name = "AnatomicalHead"
	head.mesh = preload("res://tools/character_head.gd").build(face_variant)
	head.skin = body_node.skin
	head.skeleton = NodePath("../Skeleton3D")
	scene.add_child(head)
	# Original faction helmets and field equipment remain independently replaceable.
	var equipment_mesh: ArrayMesh = ArrayMesh.new()
	for index: int in [4, 5]: surfaces[index].commit(equipment_mesh)
	var equipment: MeshInstance3D = MeshInstance3D.new()
	equipment.name = "HelmetAndEquipment"
	equipment.mesh = equipment_mesh
	equipment.skin = body_node.skin
	equipment.skeleton = NodePath("../Skeleton3D")
	scene.add_child(equipment)
	var socket: BoneAttachment3D = BoneAttachment3D.new()
	socket.name = "WeaponSocket"
	socket.bone_name = "RightHand"
	skeleton.add_child(socket)
	_animations()
	_save(scene, output_path)

func _bone(bone_name: String, parent: int, point: Vector3) -> void:
	var index: int = skeleton.get_bone_count()
	skeleton.add_bone(bone_name)
	if parent >= 0: skeleton.set_bone_parent(index, parent)
	var rest: Transform3D = Transform3D(Basis.IDENTITY, point - (bone_positions[parent] if parent >= 0 else Vector3.ZERO))
	skeleton.set_bone_rest(index, rest)
	skeleton.set_bone_pose_position(index, rest.origin)
	bone_positions.append(point)

func _loft(material: int, bone: int, origin: Vector3, rings: Array[Vector3], segments: int = 16, folds: float = 0.0, basis: Basis = Basis.IDENTITY) -> void:
	var st: SurfaceTool = surfaces[material]
	for ring: int in range(rings.size() - 1):
		for side: int in range(segments):
			for corner: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var shape: Vector3 = rings[ring + corner.y]
				var angle: float = float(side + corner.x) * TAU / segments
				var ripple: float = 1.0 + folds * sin(angle * 7 + ring * 2.3)
				st.set_bones(PackedInt32Array([bone, 0, 0, 0]))
				st.set_weights(PackedFloat32Array([1, 0, 0, 0]))
				st.set_uv(Vector2(float(side + corner.x) / segments, float(ring + corner.y) / rings.size()))
				st.add_vertex(origin + basis * Vector3(cos(angle) * shape.y * ripple, shape.x, sin(angle) * shape.z * ripple))

func _stahlhelm() -> void:
	# A close lower band bridges the forehead to the shell in the same painted steel,
	# avoiding a dark gap that makes the helmet appear suspended above the head. The
	# shell then steps out at the rolled rim and drops farther over the ears and nape.
	# All vertices stay weighted to Head, so animation cannot separate the pieces.
	_loft(4, 4, Vector3(0, 0, -0.006), [
		Vector3(1.676, 0.083, 0.093), Vector3(1.686, 0.094, 0.105),
		Vector3(1.697, 0.106, 0.116)], 32)
	var rings: Array[Vector3] = [
		Vector3(1.688, 0.129, 0.145), Vector3(1.704, 0.118, 0.130),
		Vector3(1.724, 0.111, 0.121), Vector3(1.752, 0.102, 0.111),
		Vector3(1.784, 0.085, 0.094), Vector3(1.809, 0.057, 0.064),
		Vector3(1.823, 0.017, 0.018)]
	var st: SurfaceTool = surfaces[4]
	var segments: int = 40
	for ring: int in range(rings.size() - 1):
		for side: int in range(segments):
			for corner: Vector2i in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,0),Vector2i(1,1),Vector2i(0,1)]:
				var shape: Vector3 = rings[ring + corner.y]
				var angle: float = float(side + corner.x) * TAU / segments
				var side_drop: float = pow(absf(cos(angle)), 4.0)
				var rear_drop: float = smoothstep(-0.15, 0.75, sin(angle))
				var rim_influence: float = 1.0 - smoothstep(0.0, 2.0, float(ring + corner.y))
				var y: float = shape.x - (side_drop * 0.012 + rear_drop * 0.019) * rim_influence
				var point: Vector3 = Vector3(cos(angle) * shape.y, y, sin(angle) * shape.z - 0.006)
				st.set_bones(PackedInt32Array([4,0,0,0]))
				st.set_weights(PackedFloat32Array([1,0,0,0]))
				st.set_uv(Vector2(float(side + corner.x) / segments, float(ring + corner.y) / rings.size()))
				st.add_vertex(point)
	# _loft-style ring construction leaves both ends open. Close the crown with a
	# shallow triangle fan instead of shrinking the final ring until the hole is
	# merely hard to see. The slight rise keeps the dome rounded in silhouette.
	var crown: Vector3 = rings[-1]
	var crown_center: Vector3 = Vector3(0.0, crown.x + 0.004, -0.006)
	for side: int in range(segments):
		var angle: float = float(side) * TAU / segments
		var next_angle: float = float(side + 1) * TAU / segments
		var current_point: Vector3 = Vector3(cos(angle) * crown.y, crown.x, sin(angle) * crown.z - 0.006)
		var next_point: Vector3 = Vector3(cos(next_angle) * crown.y, crown.x, sin(next_angle) * crown.z - 0.006)
		for cap_point: Vector3 in [crown_center, next_point, current_point]:
			st.set_bones(PackedInt32Array([4,0,0,0]))
			st.set_weights(PackedFloat32Array([1,0,0,0]))
			st.set_uv(Vector2(
				0.5 + cap_point.x / (crown.y * 2.0),
				0.5 + (cap_point.z + 0.006) / (crown.z * 2.0)))
			st.add_vertex(cap_point)

func _limb(mat: int, bone: int, start: Vector3, end: Vector3, width: float, tip: float) -> void:
	var axis: Vector3 = (end - start).normalized()
	var right: Vector3 = axis.cross(Vector3.FORWARD).normalized()
	if right.length() < 0.1: right = Vector3.RIGHT
	var basis: Basis = Basis(right, axis, right.cross(axis))
	var length: float = start.distance_to(end)
	_loft(mat, bone, start, [Vector3(-0.01, width * 0.1, width * 0.1), Vector3(0.015, width * 0.86, width * 0.86), Vector3(length * 0.18, width, width), Vector3(length * 0.42, width * 0.94, width * 0.95), Vector3(length * 0.58, lerpf(width, tip, 0.6) * 1.07, lerpf(width, tip, 0.6)), Vector3(length * 0.72, lerpf(width, tip, 0.75), lerpf(width, tip, 0.7)), Vector3(length, tip, tip)], 20, 0.07, basis)

func _detail(mat: int, bone: int, point: Vector3, size: Vector3) -> void:
	_loft(mat, bone, point, [Vector3(-size.y * 0.5, size.x * 0.42, size.z * 0.42), Vector3(-size.y * 0.43, size.x * 0.55, size.z * 0.55), Vector3(size.y * 0.43, size.x * 0.55, size.z * 0.55), Vector3(size.y * 0.5, size.x * 0.42, size.z * 0.42)], 8)

func _finish_mesh(mesh_name: String) -> void:
	var mesh: ArrayMesh = ArrayMesh.new()
	for st: SurfaceTool in surfaces:
		st.generate_normals()
		st.index()
		st.commit(mesh)
	var model: MeshInstance3D = MeshInstance3D.new()
	model.name = mesh_name
	model.mesh = mesh
	var skin: Skin = Skin.new()
	for index: int in range(bone_positions.size()):
		skin.add_bind(index, Transform3D(Basis.IDENTITY, -bone_positions[index]))
	model.skin = skin
	model.skeleton = NodePath("../Skeleton3D")
	scene.add_child(model)

func _animations() -> void:
	var player: AnimationPlayer = AnimationPlayer.new()
	player.name = "AnimationPlayer"
	scene.add_child(player)
	var library: AnimationLibrary = AnimationLibrary.new()
	for clip: String in ["idle", "walk", "run", "aim", "fire", "reload", "hurt", "death", "switch"]:
		var animation: Animation = Animation.new()
		animation.length = 0.8 if clip in ["walk", "run"] else 1.8 if clip == "reload" else 1.0
		if clip in ["idle", "walk", "run", "aim"]: animation.loop_mode = Animation.LOOP_LINEAR
		for bone_name: String in ["Hips", "Spine", "LeftThigh", "RightThigh", "LeftShin", "RightShin", "LeftForearm", "RightForearm", "Head"]:
			var track: int = animation.add_track(Animation.TYPE_ROTATION_3D)
			animation.track_set_path(track, NodePath("Skeleton3D:" + bone_name))
			for key: int in range(5):
				var t: float = float(key) / 4
				var angle: float = 0.0
				if clip in ["walk", "run"]:
					if "Thigh" in bone_name: angle = sin(t * TAU) * (0.42 if clip == "walk" else 0.65) * (-1 if bone_name.begins_with("Left") else 1)
					if "Shin" in bone_name: angle = maxf(0, sin(t * TAU + (PI if bone_name.begins_with("Left") else 0))) * 0.7
				if clip == "death":
					# Begin a loose forward buckle without pre-folding the legs into a
					# crouch. The ragdoll takes over at 0.45 s and completes the fall.
					var fall: float = smoothstep(0.0, 0.7, t)
					if "Thigh" in bone_name: angle = -0.18 * fall
					if "Shin" in bone_name: angle = 0.22 * fall
					if bone_name == "Hips": angle = -0.42 * fall
				if bone_name == "Spine":
					angle = sin(t * TAU) * 0.015
					if clip == "fire": angle = -sin(t * PI) * 0.09
					if clip == "hurt": angle = sin(t * PI) * 0.22
					if clip == "death": angle = smoothstep(0.0, 0.7, t) * 0.10
				if clip == "reload" and bone_name == "LeftForearm": angle = sin(t * PI) * -0.7
				if clip == "switch" and "Forearm" in bone_name: angle = sin(t * PI) * 0.4
				var rotation: Quaternion = Quaternion(Vector3.RIGHT, angle)
				if bone_name == "Head" and clip == "idle": rotation *= Quaternion(Vector3.UP,sin(t*TAU)*0.045)
				if bone_name == "Hips" and clip in ["walk","run"]: rotation *= Quaternion(Vector3.UP,sin(t*TAU)*0.035)
				animation.rotation_track_insert_key(track, t * animation.length, rotation)
		if clip == "death":
			var drop: int = animation.add_track(Animation.TYPE_POSITION_3D)
			animation.track_set_path(drop, NodePath("Skeleton3D:Hips"))
			animation.position_track_insert_key(drop,0.0,bone_positions[0])
			animation.position_track_insert_key(drop,0.45,bone_positions[0]-Vector3(0,0.08,0))
			animation.position_track_insert_key(drop,1.0,bone_positions[0]-Vector3(0,0.18,0))
		library.add_animation(clip, animation)
	player.add_animation_library("", library)
	var tree: AnimationTree = AnimationTree.new()
	# Retained as an integration hook; AnimationPlayer is the current owner.
	tree.active = false
	tree.name = "AnimationTree"
	tree.anim_player = NodePath("../AnimationPlayer")
	var machine: AnimationNodeStateMachine = AnimationNodeStateMachine.new()
	for clip: StringName in library.get_animation_list():
		var node: AnimationNodeAnimation = AnimationNodeAnimation.new()
		node.animation = clip
		machine.add_node(clip, node)
	tree.tree_root = machine
	scene.add_child(tree)

func _save(root_node: Node, path: String) -> void:
	_owners(root_node, root_node)
	var packed: PackedScene = PackedScene.new()
	packed.pack(root_node)
	ResourceSaver.save(packed, path)
	root_node.free()

func _owners(node: Node, root_node: Node) -> void:
	for child: Node in node.get_children():
		child.owner = root_node
		_owners(child, root_node)
