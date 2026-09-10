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


func _process(delta: float) -> void:
	_flash_remaining = maxf(0.0, _flash_remaining - delta)
	flash.visible = _flash_remaining > 0.0
	flash_light.visible = flash.visible
	_kick = move_toward(_kick, 0.0, delta * 30.0)
	var desired: Vector3 = Vector3(0.22, -0.22, -0.46)
	if aiming:
		desired = Vector3(0.0, -0.04, -0.40)
	if reloading:
		desired.y -= 0.25
	position = position.lerp(desired, 1.0 - exp(-18.0 * delta))
	rotation.x = deg_to_rad(_kick)
	rotation.z = lerp_angle(rotation.z, -0.35 if reloading else 0.0, 1.0 - exp(-12.0 * delta))


func play_shot(data: WeaponData) -> void:
	_flash_remaining = 0.045
	_kick = minf(_kick + data.recoil, 12.0)
	_play_audio(data.muzzle_audio)


func set_reloading(active: bool, data: WeaponData) -> void:
	reloading = active
	if active:
		_play_audio(data.reload_audio)


func _play_audio(stream: AudioStream) -> void:
	if stream != null:
		audio.stream = stream
		audio.play()
