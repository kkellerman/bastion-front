class_name InfantryCombat
extends Node

@export var actor: CharacterBody3D
@export var eye: Node3D
@export var muzzle: Marker3D
@export var flash: MeshInstance3D
@export var firing_distance: float = 12.0
@onready var weapon: WeaponBase = $WeaponBase
@onready var hitscan: HitscanShot = $HitscanShot

var enabled: bool = true
var _flash_remaining: float = 0.0


func _process(delta: float) -> void:
	_flash_remaining = maxf(0.0, _flash_remaining - delta)
	flash.visible = enabled and _flash_remaining > 0.0


func attack(aim_point: Vector3) -> void:
	if not enabled:
		return
	if eye.global_position.distance_squared_to(aim_point) < 0.001:
		return
	eye.look_at(aim_point, Vector3.UP)
	if weapon.magazine == 0:
		weapon.try_reload()
	elif weapon.try_fire():
		hitscan.fire(weapon.data, eye, muzzle, actor, false)
		_flash_remaining = 0.07


func disable() -> void:
	enabled = false
	flash.visible = false
	weapon.set_physics_process(false)
