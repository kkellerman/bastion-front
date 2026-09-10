extends Node3D
## Input and scene composition only; ammunition and damage live in components.

@export var camera: Camera3D
@export var shooter: CollisionObject3D

@onready var weapon: WeaponBase = $WeaponBase
@onready var hitscan: HitscanShot = $HitscanShot
@onready var impact_marker: MeshInstance3D = $ImpactMarker

var viewmodel: WeaponViewModel
var _fire_pending: bool = false
var _fire_held: bool = false
var _aim_held: bool = false
var _reload_pending: bool = false
var _aiming: bool = false
var _base_fov: float = 78.0
var _impact_remaining: float = 0.0


func _ready() -> void:
	assert(camera != null and shooter != null, "Weapon rig requires camera and shooter")
	assert(weapon.data.hitscan_or_projectile == WeaponData.ShotType.HITSCAN, "Projectile component is deferred; do not equip projectile data yet")
	viewmodel = weapon.data.viewmodel_scene.instantiate() as WeaponViewModel
	add_child(viewmodel)
	_base_fov = camera.fov
	weapon.shot_fired.connect(_on_shot)
	weapon.reload_changed.connect(_on_reload)
	hitscan.impact.connect(_on_impact)
	$WeaponHUD.bind(weapon)


func _input(event: InputEvent) -> void:
	# Observe capture before MouseLook handles a recapture click in _unhandled_input.
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_clear_input()
		return
	if event.is_action("fire"):
		_fire_held = event.is_pressed()
		if event.is_action_pressed("fire"):
			_fire_pending = true
	if event.is_action("aim"):
		_aim_held = event.is_pressed()
	if event.is_action_pressed("reload"):
		_reload_pending = true


func _physics_process(delta: float) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_clear_input()
	_aiming = _aim_held and not weapon.is_reloading
	viewmodel.aiming = _aiming
	if _reload_pending:
		weapon.try_reload()
	if _fire_pending or (weapon.data.automatic and _fire_held):
		weapon.try_fire()
	_fire_pending = false
	_reload_pending = false
	_impact_remaining = maxf(0.0, _impact_remaining - delta)
	impact_marker.visible = _impact_remaining > 0.0
	camera.fov = lerpf(camera.fov, 62.0 if _aiming else _base_fov, 1.0 - exp(-15.0 * delta))


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_clear_input()


func _clear_input() -> void:
	_fire_pending = false
	_fire_held = false
	_aim_held = false
	_reload_pending = false


func _on_shot() -> void:
	hitscan.fire(weapon.data, camera, viewmodel.muzzle, shooter, _aiming)
	viewmodel.play_shot(weapon.data)


func _on_reload(active: bool) -> void:
	viewmodel.set_reloading(active, weapon.data)


func _on_impact(hit_position: Vector3, normal: Vector3) -> void:
	impact_marker.global_position = hit_position + normal * 0.008
	_impact_remaining = 0.18
