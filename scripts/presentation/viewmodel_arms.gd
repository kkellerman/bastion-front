extends Node3D
const P = preload("res://scripts/presentation/dressing_parts.gd")
const Grip = preload("res://scripts/presentation/weapon_grip.gd")
const Hand = preload("res://scripts/presentation/grip_hand_mesh.gd")
var support: Node3D
var _wrists: Array[Node3D] = []
var _sleeves: Array[MeshInstance3D] = []
var _cuffs: Array[MeshInstance3D] = []
var _support_mesh: MeshInstance3D
var _cradle: bool = false

func build(data: WeaponData, faction: FactionData) -> void:
	name = "Arms"
	var cloth := ShaderMaterial.new()
	cloth.shader = load("res://shaders/uniform_fabric.gdshader")
	cloth.set_shader_parameter("cloth_color", faction.sleeve_color if faction != null else Color(0.38,0.36,0.25))
	cloth.set_shader_parameter("fabric_albedo", load("res://assets/textures/polyhaven/rough_linen/rough_linen_diff_1k.jpg"))
	cloth.set_shader_parameter("fabric_normal", load("res://assets/textures/polyhaven/rough_linen/rough_linen_nor_gl_1k.jpg"))
	cloth.set_shader_parameter("fabric_rough", load("res://assets/textures/polyhaven/rough_linen/rough_linen_rough_1k.jpg"))
	for left: bool in [false,true]:
		var wrist := Node3D.new()
		wrist.name = "SupportHand" if left else "TriggerHand"
		add_child(wrist)
		wrist.position = Grip.support(data) if left else Grip.trigger(data)
		if left: support = wrist
		_wrists.append(wrist)
		var hand_mesh: MeshInstance3D = P.shape(wrist, Vector3.ZERO, Hand.build(left, left and Grip.cradle(data)), Grip.skin())
		var joint := SphereMesh.new()
		joint.radius = 0.026
		joint.height = 0.052
		joint.radial_segments = 16
		joint.rings = 8
		P.shape(wrist,Vector3(0,0,0.004),joint,Grip.skin()).scale = Vector3(0.85,1.0,1.3)
		if left:
			_support_mesh = hand_mesh
			_cradle = Grip.cradle(data)
		_sleeves.append(P.shape(self,Vector3.ZERO,preload("res://scripts/presentation/crafted_mesh.gd").limb(1.0,0.058,0.028,true),cloth))
		_cuffs.append(P.shape(self,Vector3.ZERO,preload("res://scripts/presentation/crafted_mesh.gd").limb(1.0,0.028,0.023,false),Grip.skin()))
	_update_arms()

func _process(_delta: float) -> void:
	_update_arms()

func _update_arms() -> void:
	# Elbows stay below/outside the camera while hands follow the reload.
	for i: int in range(_wrists.size()):
		var wrist: Vector3 = _wrists[i].position
		var elbow := Vector3(-0.35 if i==1 else 0.35,-0.45,0.80)
		var cuff: Vector3 = wrist+(elbow-wrist).normalized()*0.055
		_place(_sleeves[i],elbow,cuff)
		_place(_cuffs[i],cuff,wrist+Vector3(0,0,-0.009))

func _place(part: MeshInstance3D, start: Vector3, end: Vector3) -> void:
	var axis: Vector3 = (end-start).normalized()
	var right: Vector3 = axis.cross(Vector3.FORWARD).normalized()
	if right.length_squared()<0.1: right=Vector3.RIGHT
	part.transform = Transform3D(Basis(right,axis*start.distance_to(end),right.cross(axis)),(start+end)*0.5)
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func set_support_reload(gripping_magazine: bool) -> void:
	_support_mesh.mesh = Hand.build(true,_cradle and not gripping_magazine)
