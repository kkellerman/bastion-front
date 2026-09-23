extends RefCounted
## Wrist points in WeaponMesh space, shared by first and third person.
static func trigger(data: WeaponData) -> Vector3:
	return Vector3(0.035, -0.105, 0.115) if data.weapon_class == &"launcher" else Vector3(0.035, -0.092, 0.145)

static func support(data: WeaponData) -> Vector3:
	if data.weapon_class == &"pistol": return Vector3(-0.041, -0.099, 0.139)
	return data.support_hand_position + Vector3(-0.018, -0.022, 0.075)

static func cradle(data: WeaponData) -> bool:
	return data.weapon_class != &"pistol"

static func skin() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.43, 0.285, 0.205)
	material.roughness = 0.82
	return material
