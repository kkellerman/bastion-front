extends Node3D
## One bounded, scene-owned effect; no damage logic or delayed combat callbacks.
var surface: StringName = &"dirt"
var age: float = 0.0
var light: OmniLight3D

func _ready() -> void:
	add_to_group(&"explosion_effects")

func start() -> void:
	var low: bool = get_node("/root/PlayerSettings").applied_preset == 0
	var count: int = 12 if low else 22
	var dust: Color = Color(0.28, 0.23, 0.16, 0.6) if surface in [&"dirt", &"wood"] else Color(0.37, 0.36, 0.33, 0.55)
	_cloud(5, 0.22, 0.7, 3.5, Color(1, 0.48, 0.1, 0.9), true)
	_cloud(count, 1.4, 1.25, 4.0, dust)
	_cloud(count, 3.6, 2.0, 1.4, Color(0.23, 0.24, 0.22, 0.55))
	var debris: CPUParticles3D = CPUParticles3D.new()
	debris.amount = count
	debris.lifetime = 1.3
	debris.one_shot = true
	debris.explosiveness = 1
	debris.direction = Vector3.UP
	debris.spread = 72
	debris.initial_velocity_min = 2
	debris.initial_velocity_max = 6
	debris.gravity = Vector3(0, -9.8, 0)
	debris.scale_amount_min = 0.025
	debris.scale_amount_max = 0.08
	debris.angular_velocity_min = -180
	debris.angular_velocity_max = 180
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(0.3, 0.15, 1) if surface == &"wood" else Vector3.ONE * 0.7
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(dust, 1)
	mesh.material = material
	debris.mesh = mesh
	add_child(debris)
	debris.emitting = true
	light = OmniLight3D.new()
	light.light_color = Color(1, 0.62, 0.3)
	light.light_energy = 2.0
	light.omni_range = 5
	light.shadow_enabled = false
	add_child(light)
	# A low outward dust skirt conveys pressure without screen distortion/camera shake.
	_cloud(8, 0.55, 0.45, 4.0, Color(dust, 0.3))

func _cloud(count: int, duration: float, size: float, speed: float, color: Color, fire: bool = false) -> void:
	var particles: CPUParticles3D = CPUParticles3D.new()
	particles.amount = count
	particles.lifetime = duration
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.direction = Vector3.UP
	particles.spread = 85
	particles.initial_velocity_min = speed * 0.3
	particles.initial_velocity_max = speed
	particles.gravity = Vector3(0, 0.3, 0)
	particles.scale_amount_min = size * 0.5
	particles.scale_amount_max = size
	var growth: Curve = Curve.new()
	growth.add_point(Vector2(0, 0.55))
	growth.add_point(Vector2(1, 1))
	particles.scale_amount_curve = growth
	var ramp: Gradient = Gradient.new()
	ramp.set_color(0, Color.WHITE)
	ramp.set_color(1, Color(1, 1, 1, 0))
	particles.color_ramp = ramp
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2.ONE * 2
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = load("res://shaders/combat_cloud.gdshader")
	material.set_shader_parameter("tint", color)
	material.set_shader_parameter("fire", fire)
	quad.material = material
	particles.mesh = quad
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(particles)
	particles.emitting = true

func _process(delta: float) -> void:
	age += delta
	if light != null: light.light_energy = maxf(0, 2.0 * (1.0 - age / 0.12))
	if age > 4.0: queue_free()
