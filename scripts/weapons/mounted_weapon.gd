class_name MountedWeapon
extends StaticBody3D

@export var data: WeaponData
@export var defender: InfantryBrain
@export var yaw_limit: float = 55.0
@export var pitch_limit: float = 25.0
@export var operator_position: Vector3 = Vector3(0, 0.05, 0.8)
@export var aim_eye_position: Vector3 = Vector3(0, 0.11, 0.65)
@onready var weapon: WeaponBase = $WeaponBase
@onready var pivot: Node3D = $Pivot
@onready var muzzle: Marker3D = $Pivot/Muzzle
@onready var flash: MeshInstance3D = $Pivot/Muzzle/Flash
@onready var hitscan: HitscanShot = $HitscanShot
var occupant: CharacterBody3D
var _return_position: Vector3
var _flash_time: float = 0.0
var _npc_rest: float = 0.0
var _npc_burst: int = 4
var _npc_data: WeaponData
var muzzle_effect: MuzzleEffect
var _camera_rest: Transform3D
var _aim_blend: float = 0.0


func _ready() -> void:
	$Base.material_override = preload("res://scripts/presentation/dressing_parts.gd").worn(Color(0.19, 0.21, 0.18), 0.6)
	muzzle_effect = MuzzleEffect.new()
	muzzle_effect.physics_emitter = self
	muzzle.add_child(muzzle_effect)
	flash.hide()
	flash = muzzle_effect.flash
	# The child is configured in the scene; the exported resource also labels the station.
	$Label.text = data.display_name + "\nF: mount / dismount"
	_npc_data = data.duplicate() as WeaponData
	_npc_data.damage = 8.0
	$InteractionArea.set_meta(&"interactable", self)
	hitscan.impact.connect(func(point: Vector3, normal: Vector3) -> void: CombatImpact.show(self, point, normal))


func get_prompt() -> String:
	if has_defender():
		return "Clear the gunner before mounting " + data.display_name
	return "F: mount " + data.display_name


func interact(player: CharacterBody3D) -> void:
	if occupant != null or player.is_crouching:
		return
	if has_defender():
		return
	var rig: Node3D = player.get_meta(&"weapon_rig") as Node3D
	if rig.weapon.is_reloading:
		return
	occupant = player
	rig.handling.reset()
	_camera_rest = (player.get_node("Head/Camera3D") as Camera3D).transform
	_aim_blend = 0
	_return_position = player.global_position
	player.global_position = to_global(Vector3(0, 0, 1.1))
	player.rotation.y = global_rotation.y
	player.velocity = Vector3.ZERO
	player.set_physics_process(false)
	rig.mounted = self
	rig._clear_input()
	rig._aiming = false
	rig.viewmodel.visible = false
	rig.get_node("WeaponHUD").bind(weapon)


func dismount() -> void:
	if not is_instance_valid(occupant):
		return
	var rig: Node3D = occupant.get_meta(&"weapon_rig") as Node3D
	var camera: Camera3D = occupant.get_node("Head/Camera3D")
	camera.transform = _camera_rest
	camera.fov = rig._base_fov
	_aim_blend = 0
	rig._clear_input()
	rig._aiming = false
	rig.mounted = null
	rig.viewmodel.visible = true
	rig.get_node("WeaponHUD").bind(rig.weapon)
	occupant.global_position = _return_position
	if occupant.get_node("HealthComponent").current_health > 0.0:
		occupant.set_physics_process(true)
	occupant = null


func _physics_process(delta: float) -> void:
	_flash_time = maxf(0.0, _flash_time - delta)
	$Pivot/Gun.position.z = move_toward($Pivot/Gun.position.z, 0.0, delta * 0.5)
	_npc_rest = maxf(0.0, _npc_rest - delta)
	if is_instance_valid(occupant):
		var relative: float = wrapf(occupant.rotation.y - global_rotation.y, -PI, PI)
		occupant.rotation.y = global_rotation.y + clampf(relative, -deg_to_rad(yaw_limit), deg_to_rad(yaw_limit))
		var head: Node3D = occupant.get_node("Head") as Node3D
		head.rotation.x = clampf(head.rotation.x, -deg_to_rad(pitch_limit), deg_to_rad(pitch_limit))
		pivot.rotation = Vector3(head.rotation.x, occupant.rotation.y - global_rotation.y, 0)
		var rig: Node3D = occupant.get_meta(&"weapon_rig")
		_aim_blend = move_toward(_aim_blend, 1.0 if rig._aiming else 0.0, delta * 7)
		var camera: Camera3D = head.get_node("Camera3D")
		camera.position = _camera_rest.origin.lerp(head.to_local(pivot.to_global(aim_eye_position)), _aim_blend)
	elif has_defender():
		defender.rotation.y = global_rotation.y + pivot.rotation.y
		if can_engage() and defender.state == InfantryBrain.State.ATTACK:
			var direction: Vector3 = global_basis.inverse() * (defender.target_aim.global_position - pivot.global_position)
			pivot.rotation = Vector3(atan2(direction.y, Vector2(direction.x, direction.z).length()), atan2(-direction.x, -direction.z), 0)
			if _npc_rest <= 0: fire(pivot, defender)
	elif is_instance_valid(defender):
		release_defender()


func fire(origin: Node3D, shooter: CollisionObject3D, aiming: bool = true) -> void:
	if not can_process() or not is_physics_processing() or not get_node("/root/CombatAudio").can_emit(shooter): return
	if shooter is InfantryBrain and (shooter != defender or not can_engage() or defender.state != InfantryBrain.State.ATTACK or _npc_rest > 0): return
	if weapon.magazine <= 0:
		if weapon.try_reload():
			get_node("/root/CombatAudio").play(&"reload", muzzle.global_position, shooter, data.reload_audio)
	elif weapon.try_fire():
		hitscan.fire(data if occupant != null else _npc_data, origin, muzzle, shooter, aiming)
		_flash_time = 0.06
		muzzle_effect.trigger(data, shooter)
		$Pivot/Gun.position.z = 0.04
		if occupant != null:
			var head: Node3D = occupant.get_node("Head")
			head.rotation.x = clampf(head.rotation.x + deg_to_rad(0.12), -deg_to_rad(pitch_limit), deg_to_rad(pitch_limit))
		get_node("/root/CombatAudio").play(&"mounted", muzzle.global_position, shooter, data.muzzle_audio)
		if occupant == null:
			_npc_burst -= 1
			if _npc_burst <= 0:
				_npc_burst = 4
				_npc_rest = 1.0


func bind_defender(actor: InfantryBrain) -> void:
	defender = actor
	actor.mounted_weapon = self
	actor.combat.enabled = false
	actor.patrol_points.clear()
	# Authored operator points avoid pathfinding through the tripod.
	actor.global_position = to_global(operator_position)
	actor.rotation.y = global_rotation.y
	actor.velocity = Vector3.ZERO
	actor.health.died.connect(release_defender)


func has_defender() -> bool:
	return is_instance_valid(defender) and get_node("/root/CombatAudio").can_emit(defender)


func release_defender() -> void:
	if is_instance_valid(defender):
		defender.mounted_weapon = null
		if defender.health.died.is_connected(release_defender):
			defender.health.died.disconnect(release_defender)
	defender = null
	_flash_time = 0
	muzzle_effect.stop()


func can_engage() -> bool:
	if not has_defender() or not defender.sees_target or not is_instance_valid(defender.target_aim): return false
	if not FactionData.hostile(defender, defender.target): return false
	var offset: Vector3 = defender.target_aim.global_position - pivot.global_position
	if offset.length() > defender.vision.visual_range: return false
	var local: Vector3 = global_basis.inverse() * offset
	if absf(atan2(-local.x, -local.z)) > deg_to_rad(yaw_limit): return false
	if absf(atan2(local.y, Vector2(local.x, local.z).length())) > deg_to_rad(pitch_limit): return false
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(muzzle.global_position, defender.target_aim.global_position, 7, [get_rid(), defender.get_rid()])
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.collider == defender.target
