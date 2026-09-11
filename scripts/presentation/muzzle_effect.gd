class_name MuzzleEffect
extends Node3D
## Actor-owned flash. Always-processing cleanup also handles disabled parents.
var actor: CollisionObject3D
var flash: MeshInstance3D
var light: OmniLight3D
var remaining: float = 0.0
var smoke_remaining: float = 0.0
var sparks: CPUParticles3D
var _first_frame: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"muzzle_effects")
	flash = MeshInstance3D.new()
	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = Vector2(0.13, 0.21)
	flash.mesh = mesh
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = load("res://shaders/muzzle_flash.gdshader")
	flash.material_override = material
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(flash)
	var side: MeshInstance3D = flash.duplicate() as MeshInstance3D
	side.rotation.y = PI * 0.5
	side.position.z = -0.08
	flash.add_child(side)
	light = OmniLight3D.new()
	light.light_color = Color(1, 0.64, 0.3)
	light.omni_range = 2.4
	light.shadow_enabled = false
	add_child(light)
	sparks = CPUParticles3D.new()
	sparks.amount = 2
	sparks.lifetime = 0.12
	sparks.one_shot = true
	sparks.explosiveness = 1
	sparks.direction = Vector3.FORWARD
	sparks.spread = 12
	sparks.initial_velocity_min = 2
	sparks.initial_velocity_max = 4
	sparks.gravity = Vector3(0, -2, 0)
	var spark_mesh: BoxMesh = BoxMesh.new()
	spark_mesh.size = Vector3(0.005, 0.005, 0.025)
	var spark_material: StandardMaterial3D = StandardMaterial3D.new()
	spark_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_material.albedo_color = Color(1, 0.6, 0.2)
	spark_mesh.material = spark_material
	sparks.mesh = spark_mesh
	sparks.emitting = false
	add_child(sparks)
	stop()

func trigger(data: WeaponData, shooter: CollisionObject3D) -> void:
	actor = shooter
	if not get_node("/root/CombatAudio").can_emit(actor):
		stop()
		return
	remaining = 0.035
	_first_frame = true
	# Presentation remains consistent when NPC damage is reduced for balance.
	(flash.mesh as QuadMesh).size = data.muzzle_flash_size
	flash.scale = Vector3.ONE * randf_range(0.85, 1.1)
	flash.rotation.z = randf_range(-PI, PI)
	flash.show()
	light.show()
	light.light_energy = 0.6
	if randf() < 0.15:
		sparks.show()
		sparks.restart()
	if smoke_remaining <= 0:
		CombatEffects.smoke(self, global_position)
		smoke_remaining = 0.16

func stop() -> void:
	remaining = 0
	_first_frame = false
	if flash != null: flash.hide()
	if light != null: light.hide()

func _process(delta: float) -> void:
	if not is_instance_valid(actor) or not get_node("/root/CombatAudio").can_emit(actor):
		stop()
		sparks.hide()
		sparks.emitting = false
		return
	if get_tree().paused: return
	# A slow rendered frame must not consume the whole flash before it is drawn.
	if _first_frame:
		_first_frame = false
		return
	smoke_remaining = maxf(0, smoke_remaining - delta)
	remaining -= delta
	if remaining <= 0: stop()
