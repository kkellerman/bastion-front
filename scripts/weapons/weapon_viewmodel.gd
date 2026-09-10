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

func _ready() -> void:
	var flash_quad: QuadMesh = QuadMesh.new()
	flash_quad.size = Vector2(0.13, 0.13)
	flash.mesh = flash_quad
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = load("res://shaders/muzzle_flash.gdshader")
	flash.material_override = material
	flash.rotation = Vector3.ZERO


func _process(delta: float) -> void:
	_flash_remaining = maxf(0.0, _flash_remaining - delta)
	flash.visible = _flash_remaining > 0.0
	flash_light.visible = flash.visible
	_kick = move_toward(_kick, 0.0, delta * 30.0)
	_roll_kick = move_toward(_roll_kick, 0.0, delta * 8.0)
	var desired: Vector3 = Vector3(0.22, -0.22, -0.46)
	if aiming:
		desired = Vector3(0.0, -0.04, -0.40)
	if reloading:
		desired.y -= 0.25
	desired.z += _kick * 0.002
	position = position.lerp(desired, 1.0 - exp(-18.0 * delta))
	rotation.x = deg_to_rad(_kick)
	rotation.z = lerp_angle(rotation.z, -0.35 if reloading else _roll_kick * 0.02, 1.0 - exp(-12.0 * delta))


func play_shot(data: WeaponData) -> void:
	_flash_remaining = 0.045
	_kick = minf(_kick + data.recoil, 12.0)
	_roll_kick = randf_range(-0.7, 0.7)
	flash.rotation.z = randf_range(0, TAU)


func set_reloading(active: bool, _data: WeaponData) -> void:
	reloading = active


func _play_audio(stream: AudioStream) -> void:
	if stream != null:
		audio.stream = stream
		audio.play()
