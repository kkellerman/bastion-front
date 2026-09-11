@tool
class_name ForestAtmosphere
extends Resource
## One authored weather profile, shared by menu and mission. Seeds never change it.
@export var sun_rotation: Vector3 = Vector3(-32, -32, 0)
@export var sun_color: Color = Color(0.91, 0.93, 0.91)
@export var sun_energy: float = 0.85
@export var ambient_color: Color = Color(0.65, 0.70, 0.74)
@export var ambient_energy: float = 0.52
@export var haze_color: Color = Color(0.49, 0.55, 0.56)
@export var haze_density: float = 0.0035
@export var exposure: float = 1.02

func apply(environment: Environment, sun: DirectionalLight3D) -> void:
	sun.rotation_degrees = sun_rotation
	sun.light_color = sun_color
	sun.light_energy = sun_energy
	sun.light_angular_distance = 2.0
	environment.ambient_light_color = ambient_color
	environment.ambient_light_energy = ambient_energy
	environment.tonemap_exposure = exposure
	environment.fog_light_color = haze_color
	environment.fog_density = haze_density
	environment.fog_sky_affect = 0.6
	environment.volumetric_fog_density = 0.006
	environment.volumetric_fog_albedo = haze_color.lightened(0.24)
	environment.volumetric_fog_length = 95
	environment.adjustment_saturation = 0.88
	environment.adjustment_contrast = 1.02
	var material: ShaderMaterial = environment.sky.sky_material as ShaderMaterial
	material.set_shader_parameter("sun_direction", sun.basis.z.normalized())
	material.set_shader_parameter("horizon_color", haze_color)
