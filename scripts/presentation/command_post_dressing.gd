extends RefCounted
const P = preload("res://scripts/presentation/dressing_parts.gd")

static func dress(level: Node3D, art: Node3D) -> void:
	var wood: Material = P.worn(Color(0.27, 0.22, 0.145), 0.0, true)
	var iron: Material = P.material(Color(0.075, 0.085, 0.077), 0.65)
	var canvas: ShaderMaterial = ShaderMaterial.new()
	canvas.shader = load("res://shaders/uniform_fabric.gdshader")
	canvas.set_shader_parameter("cloth_color", Color(0.32, 0.29, 0.20))
	for body: Node3D in level.get_node("Fortifications").get_children():
		body.set_meta(&"surface", &"dirt")
		var size: Vector3 = body.get_node("Mesh").mesh.size
		if "Trench" in body.name or body.name == &"Traverse":
			body.get_node("Mesh").material_override = load("res://assets/materials/presentation/soil.tres")
			for z: int in range(int(size.z / 0.35)):
				for side: int in [-1, 1]:
					P.box(art, body.position + Vector3(side * size.x * 0.5, 0, -size.z * 0.5 + z * 0.35), Vector3(0.08, size.y, 0.3), wood)
		else:
			body.get_node("Mesh").visible = false
			var bag: ArrayMesh = preload("res://scripts/presentation/crafted_mesh.gd").sack()
			for row: int in range(4):
				for column: int in range(int(size.x / 0.55)):
					var point: Vector3 = body.position + Vector3(-size.x * 0.5 + 0.3 + column * 0.55 + (row % 2) * 0.12, -size.y * 0.5 + 0.16 + row * 0.3, 0)
					var sack: MeshInstance3D = P.shape(art, point, bag, canvas)
					sack.scale = Vector3(0.60, 0.30, size.z * 0.91)
					sack.rotation = Vector3(sin(column * 3.7 + row) * 0.035, sin(column * 7.1 + row) * 0.065, cos(column * 4.3 + row) * 0.025)
	for node: Node in level.get_children():
		if node is Label3D:
			node.visible = false
	_board(art, Vector3(3.2, 1.6, 8), "GEFECHTSSTAND\n200 m  ↑", wood)
	_board(art, Vector3(-11, 1.6, 17), "FIRING POINT\n←", wood)
	_board(art, Vector3(0, 2.8, -58.42), "GEFECHTSSTAND", iron)
	_board(art, Vector3(-6, 3.02, -79.35), "LAGE / MELDUNGEN", iron)
	# Original side boundaries retain collision; rock banks visually read as raised terrain.
	for side: int in [-1, 1]:
		for segment: int in range(14):
			var x: float = side * (6.0 + segment * 0.5)
			P.rod(art, Vector3(x, 0, -54), Vector3(x + 0.15, 1.15, -54), 0.035, iron)
			if segment < 13:
				for strand: float in [0.4, 0.75, 1.0]:
					P.rod(art, Vector3(x, strand, -54), Vector3(x + side * 0.5, strand, -54), 0.008, iron)
					P.rod(art, Vector3(x, strand - 0.07, -54.07), Vector3(x + 0.1, strand + 0.07, -53.93), 0.006, iron)
	# Slung camouflage strips above the gun, outside its firing and interaction rays.
	# Sagged rope mesh and irregular hanging scrim replace the rigid overhead grid.
	for strip: int in range(24):
		var x: float = -2.8 + strip * 0.24
		for section: int in range(8):
			var z: float = -53.2 + section * 0.4
			var y: float = 2.78 - (1.0 - pow(absf(x) / 2.9, 2)) * 0.25
			P.rod(art, Vector3(x,y,z), Vector3(x+0.02,y-0.015,z+0.4),0.008,canvas)
			if (strip + section) % 3 == 0:
				var scrim: MeshInstance3D = P.shape(art, Vector3(x,y-0.07,z), preload("res://scripts/presentation/crafted_mesh.gd").sack(), canvas)
				scrim.scale = Vector3(0.19,0.012,0.26)
				scrim.rotation = Vector3(section*0.37,strip*2.4,strip*0.41)
	for section: int in range(9):
		for strip: int in range(12):
			var x: float = -2.8 + strip*0.47
			P.rod(art,Vector3(x,2.78-(1-pow(absf(x)/2.9,2))*0.25,-53.2+section*0.4),Vector3(x+0.47,2.78-(1-pow(absf(x+0.47)/2.9,2))*0.25,-53.2+section*0.4),0.008,canvas)
	for x: float in [-2.8, 2.8]:
		P.rod(art, Vector3(x, 0, -53), Vector3(x, 2.8, -53), 0.06, wood)
	_interior(level, art, wood, iron)

static func _board(art: Node3D, point: Vector3, words: String, mat: Material) -> void:
	P.box(art, point, Vector3(2.4, 0.65, 0.06), mat)
	P.sign_text(art, point + Vector3(0, 0, 0.035), words, 0.0025)
	if point.z > 0:
		P.rod(art, point - Vector3.UP * 1.6, point, 0.06, mat)

static func _interior(level: Node3D, art: Node3D, wood: Material, iron: Material) -> void:
	var paper: Material = P.material(Color(0.66, 0.62, 0.47))
	var lower_paint: Material = load("res://assets/materials/presentation/concrete.tres").duplicate()
	lower_paint.albedo_color = Color(0.22, 0.29, 0.25)
	for wall: Node in level.get_node("Bunker").get_children():
		if wall is StaticBody3D and wall.has_node("Collision"):
			var size: Vector3 = wall.get_node("Collision").shape.size
			if size.y > 3.0 and wall.name != &"Roof":
				P.box(art, Vector3(wall.position.x, 0.55, wall.position.z), Vector3(size.x + 0.012, 1.1, size.z + 0.012), lower_paint)
	var map_mat: StandardMaterial3D = P.material(Color.WHITE)
	map_mat.albedo_texture = load("res://assets/props/operations_map.svg")
	for name: String in ["RadioDesk", "MapDesk"]:
		var body: Node3D = level.get_node("Bunker/" + name) as Node3D
		body.get_node("Mesh").visible = false
		body.set_meta(&"surface", &"wood")
		var size: Vector3 = body.get_node("Collision").shape.size
		P.box(art, body.position + Vector3(0, 0.37, 0), Vector3(size.x, 0.12, size.z), wood)
		for side: float in [-0.4, 0.4]:
			for back: float in [-0.35, 0.35]:
				P.box(art, body.position + Vector3(size.x * side, -0.03, size.z * back), Vector3(0.09, 0.7, 0.09), wood)
		for i: int in range(4):
			P.box(art, body.position + Vector3(-0.6 + i * 0.25, 0.442, 0.2), Vector3(0.21, 0.008, 0.28), paper).rotation.y = i * 0.14
	# Wall map, desk map and a field telephone beside the radio.
	P.box(art, Vector3(-6, 1.95, -79.43), Vector3(3.1, 2.1, 0.07), wood)
	var map_plane: QuadMesh = QuadMesh.new()
	map_plane.size = Vector2(2.9, 1.9)
	P.shape(art, Vector3(-6, 1.95, -79.38), map_plane, map_mat)
	var table_map: MeshInstance3D = P.shape(art, Vector3(-6, 0.862, -75), map_plane, map_mat)
	table_map.rotation.x = -PI * 0.5
	table_map.scale = Vector3(0.55, 0.4, 1)
	level.get_node("Bunker/Radio/Mesh").material_override = iron
	for dial: int in range(5):
		P.rod(art, Vector3(5.7 + dial * 0.14, 1.13, -63.73), Vector3(5.7 + dial * 0.14, 1.13, -63.69), 0.035, iron)
	P.box(art, Vector3(6, 1.26, -63.735), Vector3(0.32, 0.08, 0.02), paper)
	P.sign_text(art, Vector3(6, 1.26, -63.719), "0  20  40  60", 0.0005)
	P.box(art, Vector3(6.8, 0.95, -64), Vector3(0.35, 0.18, 0.24), iron)
	P.rod(art, Vector3(6.62, 1.08, -64), Vector3(6.98, 1.08, -64), 0.045, iron)
	P.rod(art, Vector3(6.8, 0.9, -64), Vector3(7.15, 0.87, -64.2), 0.014, iron)
	_board(art, Vector3(6, 2.3, -68.76), "FUNKRAUM\nRUHE BEWAHREN", iron)
	level.get_node("Bunker/StorageCrates/Mesh").visible = false
	for y: int in range(3):
		for z: int in range(2):
			P.crate(art, Vector3(6, y * 0.5, -75.5 + z), Vector3(1.45, 0.48, 0.95), wood, iron)
	# Shallow records cabinets hug the existing rear wall, leaving doors and navigation clear.
	for x: int in range(3):
		var center: Vector3 = Vector3(3.3 + x * 1.0, 1, -79.3)
		P.box(art, center, Vector3(0.9, 2, 0.35), iron)
		for drawer: int in range(5):
			P.box(art, center + Vector3(0, -0.8 + drawer * 0.38, 0.19), Vector3(0.8, 0.33, 0.04), wood)
			P.box(art, center + Vector3(0, -0.8 + drawer * 0.38, 0.22), Vector3(0.13, 0.04, 0.03), paper)
	for light: Node in level.get_node("Bunker").get_children():
		if light is OmniLight3D:
			light.light_energy = 1.6
			light.omni_range = 6.0
			P.rod(art, light.position + Vector3.UP * 0.65, light.position, 0.012, iron)
			var bulb: SphereMesh = SphereMesh.new()
			bulb.radius = 0.065
			bulb.height = 0.13
			var glow: StandardMaterial3D = P.material(Color(1, 0.78, 0.4))
			glow.emission_enabled = true
			glow.emission = Color(1, 0.66, 0.22)
			glow.emission_energy_multiplier = 2.0
			P.shape(art, light.position, bulb, glow).cast_shadow = 0
	for x: float in [-1.8, 1.8]:
		P.rod(art, Vector3(x, 3.1, -60), Vector3(x, 3.1, -79.5), 0.026, iron)
	P.box(art, Vector3(0, -0.002, -69.5), Vector3(17, 0.01, 20), load("res://assets/materials/presentation/concrete.tres"))
	_office(art, wood, iron, paper)

static func _office(art: Node3D, wood: Material, iron: Material, paper: Material) -> void:
	var desk: Vector3 = Vector3(-6, 0, -64)
	P.box(art, desk + Vector3.UP * 0.82, Vector3(1.8, 0.1, 0.85), wood)
	for x: float in [-0.78, 0.78]:
		for z: float in [-0.32, 0.32]:
			P.box(art, desk + Vector3(x, 0.4, z), Vector3(0.075, 0.8, 0.075), wood)
	_collision(art, desk + Vector3.UP * 0.425, Vector3(1.8, 0.85, 0.85))
	# A mechanical typewriter silhouette, papers and a shaded desk lamp.
	P.box(art, desk + Vector3(-0.15, 0.98, 0), Vector3(0.48, 0.22, 0.3), iron)
	P.box(art, desk + Vector3(-0.15, 1.16, -0.07), Vector3(0.34, 0.25, 0.015), paper)
	for key: int in range(18):
		P.box(art, desk + Vector3(-0.32 + (key % 6) * 0.065, 0.97, 0.16 + (key / 6) * 0.03), Vector3(0.035, 0.015, 0.024), paper)
	P.rod(art, desk + Vector3(0.6, 0.87, 0), desk + Vector3(0.6, 1.35, 0), 0.018, iron)
	var shade: CylinderMesh = CylinderMesh.new()
	shade.top_radius = 0.035
	shade.bottom_radius = 0.15
	shade.height = 0.11
	P.shape(art, desk + Vector3(0.6, 1.32, 0), shade, iron)
	_board(art, Vector3(-6, 2.6, -68.76), "DIENSTZIMMER", iron)
	for point: Vector3 in [Vector3(-6, 0, -62.9), Vector3(6, 0, -62.9)]:
		P.box(art, point + Vector3.UP * 0.46, Vector3(0.46, 0.06, 0.46), wood)
		for side: float in [-0.18, 0.18]:
			P.box(art, point + Vector3(side, 0.45, 0.19), Vector3(0.055, 0.9, 0.055), wood)
			P.box(art, point + Vector3(side, 0.22, -0.19), Vector3(0.055, 0.44, 0.055), wood)
		P.box(art, point + Vector3(0, 0.81, 0.19), Vector3(0.45, 0.14, 0.055), wood)
		_collision(art, point + Vector3.UP * 0.45, Vector3(0.46, 0.9, 0.46))

static func _collision(art: Node3D, point: Vector3, size: Vector3) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	art.add_child(body)
	body.position = point
	body.set_meta(&"surface", &"wood")
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
