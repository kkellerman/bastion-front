class_name WeaponViewModel
extends Node3D

@onready var muzzle: Marker3D = $Muzzle
@onready var flash: MeshInstance3D = $Muzzle/Flash
@onready var flash_light: OmniLight3D = $Muzzle/Light
@onready var audio: AudioStreamPlayer = $Audio

var aiming: bool = false
var reloading: bool = false
var _flash_remaining: float = 0.0
var _kick: float = 0.0
var _roll_kick: float = 0.0
var _draw_remaining: float = 0.25
var muzzle_effect: MuzzleEffect
var reload_motion: Node
var _sprint_blend: float = 0

func _ready() -> void:
	muzzle_effect = MuzzleEffect.new()
	muzzle.add_child(muzzle_effect)
	_install_arms.call_deferred()
	var flash_quad: QuadMesh = QuadMesh.new()
	flash_quad.size = Vector2(0.085, 0.085)
	flash.mesh = flash_quad
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = load("res://shaders/muzzle_flash.gdshader")
	flash.material_override = material
	flash.rotation = Vector3.ZERO
	flash.hide()
	flash_light.hide()
	# Keep the public flash/light handles used by integrations and regression tests.
	flash = muzzle_effect.flash
	flash_light = muzzle_effect.light


func _process(delta: float) -> void:
	_flash_remaining = maxf(0.0, _flash_remaining - delta)
	_kick = move_toward(_kick, 0.0, delta * 30.0)
	_roll_kick = move_toward(_roll_kick, 0.0, delta * 8.0)
	var desired: Vector3 = Vector3(0.22, -0.22, -0.46)
	var rig: Node3D = get_parent()
	var profile: WeaponHandlingData = rig.weapon.data.handling
	var movement: Vector3 = rig.shooter.global_basis.inverse() * rig.shooter.velocity
	var sprint: bool = movement.length() > 4.5 and not aiming and not reloading
	_sprint_blend = move_toward(_sprint_blend, 1.0 if sprint else 0.0, delta * 6)
	var motion: float = 0.2 if get_node("/root/PlayerSettings").values.reduced_motion else 1.0
	_draw_remaining = maxf(0, _draw_remaining - delta)
	desired.y -= _draw_remaining * 0.65
	if aiming:
		desired = Vector3(0.0, -0.04, -0.40)
	if reloading:
		desired = Vector3(0.15, 0.04, -0.55)
	if sprint:
		desired += Vector3(0.025, -0.09, 0.07)
	if rig.shooter.is_crouching: desired.y += 0.018
	var stability: float = (0.2 if aiming else 1.0) * motion
	desired += Vector3(-rig.handling.inertia.x - movement.x * 0.002, rig.handling.inertia.y + sin(rig.handling.clock * 1.9) * profile.breath, 0) * stability
	desired.z += _kick * 0.002
	position = position.lerp(desired, 1.0 - exp(-18.0 * delta))
	rotation.x = deg_to_rad(_kick) - 0.18 * _sprint_blend
	var settings: Node = get_node_or_null("/root/PlayerSettings")
	if settings != null and settings.values.reduced_motion: rotation.x *= 0.2
	rotation.z = lerp_angle(rotation.z, -0.35 if reloading else _roll_kick * 0.02, 1.0 - exp(-12.0 * delta))


func play_shot(data: WeaponData) -> void:
	var rig: Node = get_parent()
	if "shooter" in rig: muzzle_effect.trigger(data, rig.shooter)
	_flash_remaining = 0.035
	_kick = minf(_kick + data.recoil, 12.0)
	_roll_kick = randf_range(-0.7, 0.7)
	flash.rotation.z = randf_range(0, TAU)


func set_reloading(active: bool, _data: WeaponData) -> void:
	reloading = active


func _play_audio(stream: AudioStream) -> void:
	if stream != null:
		audio.stream = stream
		audio.play()

func _install_arms() -> void:
	var rig: Node = get_parent()
	if rig == null or not "inventory" in rig: return
	var arms: Node3D = load("res://scripts/presentation/viewmodel_arms.gd").new()
	add_child(arms)
	arms.build(rig.weapon.data, rig.inventory.faction)
	reload_motion = load("res://scripts/presentation/weapon_reload_motion.gd").new()
	add_child(reload_motion)
