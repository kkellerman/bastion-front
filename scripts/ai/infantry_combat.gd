class_name InfantryCombat
extends Node

@export var actor: CharacterBody3D
@export var eye: Node3D
@export var muzzle: Marker3D
@export var flash: MeshInstance3D
@export var firing_distance: float = 12.0
@export var burst_control: bool = false
@onready var weapon: WeaponBase = $WeaponBase
@onready var hitscan: HitscanShot = $HitscanShot

var enabled: bool = true
var _flash_remaining: float = 0.0
var _burst_remaining: int = 3
var _rest_remaining: float = 0.0


func _ready() -> void:
	hitscan.impact.connect(func(point: Vector3, normal: Vector3) -> void: CombatImpact.show(actor, point, normal))


func _process(delta: float) -> void:
	_flash_remaining = maxf(0.0, _flash_remaining - delta)
	_rest_remaining = maxf(0.0, _rest_remaining - delta)
	flash.visible = enabled and _flash_remaining > 0.0


func attack(aim_point: Vector3) -> void:
	if not enabled or (burst_control and _rest_remaining > 0.0):
		return
	if eye.global_position.distance_squared_to(aim_point) < 0.001:
		return
	eye.look_at(aim_point, Vector3.UP)
	if weapon.magazine == 0:
		if weapon.try_reload():
			get_node("/root/CombatAudio").play(&"reload", actor.global_position, actor, weapon.data.reload_audio)
	elif weapon.try_fire():
		hitscan.fire(weapon.data, eye, muzzle, actor, false)
		_flash_remaining = 0.07
		get_node("/root/CombatAudio").play(&"gunshot", muzzle.global_position, actor, weapon.data.muzzle_audio)
		if burst_control:
			_burst_remaining -= 1
			if _burst_remaining <= 0:
				_rest_remaining = randf_range(0.7, 1.3)
				_burst_remaining = randi_range(2, 4)


func disable() -> void:
	enabled = false
	flash.visible = false
	weapon.set_physics_process(false)
