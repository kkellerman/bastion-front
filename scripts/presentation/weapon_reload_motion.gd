extends Node
## Mesh hooks for interim geometry; production AnimationPlayer clips can replace this.
const P = preload("res://scripts/presentation/dressing_parts.gd")
var view: WeaponViewModel
var rig: Node3D
var magazine: Node3D
var mechanism: Node3D
var magazine_rest: Vector3
var mechanism_rest: Vector3
var progress: float = 0
var stage: StringName = &"ready"

func _ready() -> void:
	view = get_parent()
	rig = view.get_parent()
	var profile: WeaponHandlingData = rig.weapon.data.handling
	magazine = Node3D.new()
	magazine.name = "MagazineMotion"
	view.add_child(magazine)
	magazine_rest = profile.magazine_position
	magazine.position = magazine_rest
	# Separate the existing long-gun magazine and its ribs without duplicating geometry.
	if rig.weapon.data.weapon_class in [&"smg", &"rifle", &"assault_rifle"]:
		for part: Node3D in view.get_node("WeaponMesh").get_children():
			if part.position.y < -0.045 and part.position.z < -0.075 and part.position.z > -0.17:
				var rest: Vector3 = part.position
				part.reparent(magazine, false)
				part.position = rest - magazine_rest
	if magazine.get_child_count() == 0:
		P.box(magazine, Vector3.ZERO, profile.magazine_size, P.worn(Color(0.14, 0.15, 0.14), 0.8))
	mechanism = P.box(view, profile.mechanism_position, Vector3(0.035, 0.012, 0.02), P.worn(Color(0.15, 0.16, 0.15), 0.8))
	mechanism.name = "ChargingHandleMotion"
	mechanism_rest = mechanism.position

func _process(_delta: float) -> void:
	progress = rig.weapon.reload_progress
	stage = &"ready"
	var travel: float = 0
	var bolt: float = 0
	if rig.weapon.is_reloading:
		if progress < 0.18: stage = &"grip"
		elif progress < 0.45:
			stage = &"remove"
			travel = smoothstep(0.18, 0.45, progress)
		elif progress < 0.78:
			stage = &"insert"
			travel = 1 - smoothstep(0.45, 0.78, progress)
		else:
			stage = &"chamber"
			bolt = sin((progress - 0.78) / 0.22 * PI)
	magazine.position = magazine_rest + Vector3(0, -0.18 * travel, 0.05 * travel)
	mechanism.position = mechanism_rest + Vector3(0, 0, bolt * 0.06)
	var arms: Node3D = view.get_node_or_null("Arms")
	if arms != null and arms.support != null:
		var destination: Vector3 = rig.weapon.data.support_hand_position
		if rig.weapon.is_reloading:
			destination = mechanism.position if stage == &"chamber" else magazine.position + Vector3(-0.035, 0, 0)
			var blend: float = smoothstep(0, 0.18, progress) * (1 - smoothstep(0.94, 1, progress))
			destination = rig.weapon.data.support_hand_position.lerp(destination, blend)
		arms.support.position = destination
