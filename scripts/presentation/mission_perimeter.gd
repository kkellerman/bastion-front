extends Node3D
## Scenery and collision share a berm mesh; safety walls sit behind the front slope.
const P = preload("res://scripts/presentation/dressing_parts.gd")
var warning: Label
var return_count: int = 0
var _warning_time: float = 0
var safe_start: Vector3 = Vector3(0, 0.1, 18)

func _ready() -> void:
	name = "MissionPerimeter"
	var soil: ShaderMaterial = load("res://assets/materials/presentation/forest_surface.tres").duplicate() as ShaderMaterial
	soil.set_shader_parameter("rear_trail", true)
	var ground: PlaneMesh = PlaneMesh.new()
	ground.size = Vector2(1000, 1000)
	P.shape(self, Vector3(0, -0.12, -27), ground, soil).visibility_range_end = 0
	var mesh: ArrayMesh = preload("res://scripts/presentation/forest_horizon.gd").banks()
	var bank: MeshInstance3D = P.shape(self, Vector3.ZERO, mesh, soil)
	bank.name = "TerrainBanks"
	bank.visibility_range_end = 0
	var body: StaticBody3D = StaticBody3D.new()
	bank.add_child(body)
	body.set_meta(&"surface", &"dirt")
	var collider: CollisionShape3D = CollisionShape3D.new()
	collider.shape = mesh.create_trimesh_shape()
	body.add_child(collider)
	_forest()
	var timber: Material = load("res://assets/materials/presentation/bark.tres")
	for x: float in [-2.6, 2.6]:
		P.rod(self, Vector3(x, 0, -85.5), Vector3(x, 2.8, -85.5), 0.13, timber)
	P.rod(self, Vector3(-2.6, 2.75, -85.5), Vector3(2.6, 2.75, -85.5), 0.12, timber)
	P.sign_text(self, Vector3(0, 2.4, -85.3), "REAR TRAIL  /  RENDEZVOUS", 0.0035)
	# Closed collection gate gives extraction an in-world stopping point.
	for y: float in [0.5, 1.05]:
		P.rod(self, Vector3(-2.5, y, -85.6), Vector3(2.5, y, -85.6), 0.065, timber)
	P.sign_text(self, Vector3(0, 1.35, -85.3), "WAIT FOR EXTRACTION", 0.002)
	P.crate(self, Vector3(3.3, 0, -84), Vector3(0.9, 0.7, 0.8), load("res://assets/materials/presentation/worn_planks.tres"), P.worn(Color(0.13, 0.15, 0.12), 0.6))
	for x: float in [-4.0, 4.0]:
		P.rod(self, Vector3(x, 0.35, -84), Vector3(x + 1.5, 0.4, -86), 0.28, timber)
	var canvas: CanvasLayer = CanvasLayer.new()
	add_child(canvas)
	warning = Label.new()
	canvas.add_child(warning)
	warning.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	warning.position += Vector2(-180, 100)
	warning.add_theme_constant_override("outline_size", 5)
	warning.text = "Outside mission area — returning to safe ground"
	warning.hide()

func _forest() -> void:
	preload("res://scripts/presentation/forest_horizon.gd").plant(self, get_node("/root/PrototypeSession").operation_seed)

func outside(point: Vector3) -> bool:
	return absf(point.x) > 28 or point.z < -92 or point.z > 38 or point.y < -4

func _physics_process(delta: float) -> void:
	var mission: Node3D = get_parent()
	_warning_time = maxf(0, _warning_time - delta)
	warning.visible = _warning_time > 0
	if mission.complete or mission.player.get_node("HealthComponent").current_health <= 0: return
	if not outside(mission.player.position): return
	if mission.rig.mounted != null: mission.rig.mounted.dismount()
	var checkpoint: Dictionary = get_node("/root/PrototypeSession").checkpoint
	var destination: Vector3 = checkpoint.get("position", safe_start)
	if outside(destination): destination = safe_start
	mission.player.position = destination + Vector3.UP * 0.1
	mission.player.velocity = Vector3.ZERO
	mission.rig._clear_input()
	_warning_time = 3
	return_count += 1

