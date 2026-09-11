extends RefCounted
const P = preload("res://scripts/presentation/dressing_parts.gd")
const RELIEF = preload("res://scripts/presentation/forest_relief.gd")
static func dress(parent: Node3D, option: MissionZoneOption, operation_seed: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = operation_seed
	var wood: Material = load("res://assets/materials/presentation/bark.tres")
	var steel: Material = P.worn(Color(0.15,0.17,0.15),0.6)
	for anchor: Vector3 in option.dressing_anchors:
		if option.label.begins_with("fortification"):
			_cover(parent, anchor, option.label.ends_with("1"), wood, steel)
		if anchor.z < -59 and anchor.z > -80:
			# Small supply/paper stacks at authored wall recesses, outside door/nav clearance.
			P.crate(parent, anchor, Vector3(0.5,0.45,0.45),wood,steel)
			if option.label.ends_with("1"): P.crate(parent, anchor + Vector3(0,0.45,0),Vector3(0.35,0.25,0.35),wood,steel)
			continue
		for i: int in range(14):
			var point: Vector3 = anchor + Vector3(rng.randf_range(-1.8,1.8),0,rng.randf_range(-1.8,1.8))
			point.y = RELIEF.height_at(point) + 0.02
			var kind: String = ["fern","shrub","rock","litter"][rng.randi_range(0,3)]
			var part: MeshInstance3D = P.shape(parent,point,load("res://assets/environments/germany/forest/" + kind + ".res"),null)
			part.rotation.y = rng.randf_range(0,TAU)
			part.scale = Vector3.ONE * rng.randf_range(0.4,0.9)
			part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var start: Vector3 = anchor + Vector3(0,RELIEF.height_at(anchor) + 0.13,0)
		P.rod(parent,start,start+Vector3(1.8,0.02,0.8).rotated(Vector3.UP,rng.randf_range(0,TAU)),0.12,wood)
		if option.label.ends_with("1") and anchor.z < -40 and not option.label.begins_with("fortification"):
			P.crate(parent,anchor,Vector3(0.7,0.65,0.6),wood,steel)
	P.batch_static(parent)

static func _cover(parent: Node3D, anchor: Vector3, crates: bool, wood: Material, steel: Material) -> void:
	# Both art kits fit the same fixed blocking volume, shared by the two prebakes.
	var body: StaticBody3D = StaticBody3D.new()
	parent.add_child(body)
	body.position = anchor + Vector3.UP * 0.325
	body.set_meta(&"surface", &"wood")
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(0.7,0.65,0.6)
	collision.shape = shape
	body.add_child(collision)
	if crates:
		P.crate(parent,anchor,shape.size,wood,steel)
	else:
		for y: float in [0.12,0.34,0.56]:
			for z: float in [-0.17,0.17]:
				P.rod(parent,anchor+Vector3(-0.35,y,z),anchor+Vector3(0.35,y,z),0.12,wood)
