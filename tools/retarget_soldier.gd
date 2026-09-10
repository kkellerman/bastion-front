extends RefCounted
## Retarget the CC0 source's weighted rest geometry into the shared gameplay rig.
static func body(target: Skeleton3D, positions: Array[Vector3]) -> ArrayMesh:
	var source: Node3D = load("res://assets/characters/source/LowpolySoldier/LowpolySoldier.fbx").instantiate()
	var skeleton: Skeleton3D = source.get_node("Skeleton3D")
	var model: MeshInstance3D = skeleton.get_node("Soldier_1")
	var arrays: Array = model.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var turn: Basis = Basis(Vector3.UP, PI)
	for index: int in indices:
		var point: Vector3 = Vector3.ZERO
		var normal: Vector3 = Vector3.ZERO
		var mapped: PackedInt32Array = PackedInt32Array([0, 0, 0, 0, 0, 0, 0, 0])
		var influence: PackedFloat32Array = PackedFloat32Array([0, 0, 0, 0, 0, 0, 0, 0])
		for slot: int in range(8):
			var weight: float = weights[index * 8 + slot]
			if weight <= 0: continue
			var bind: int = bones[index * 8 + slot]
			var old_name: String = model.skin.get_bind_name(bind)
			var old_index: int = skeleton.find_bone(old_name)
			var transform: Transform3D = skeleton.get_bone_global_rest(old_index) * model.skin.get_bind_pose(bind)
			var neutral: Vector3 = turn * (transform * vertices[index])
			var n: Vector3 = turn * transform.basis * normals[index]
			var new_name: String = _map(old_name)
			var new_index: int = target.find_bone(new_name)
			if new_index < 0: new_index = 1
			if "arm" in new_name.to_lower() or "Hand" in new_name:
				var prefix: String = "Left" if new_name.begins_with("Left") else "Right"
				var old_base: String = prefix + ("Arm" if "UpperArm" in new_name else "ForeArm" if "Forearm" in new_name else "Hand")
				var anchor: Vector3 = turn * skeleton.get_bone_global_rest(skeleton.find_bone(old_base)).origin
				var direction: Vector3 = Vector3(-1 if prefix == "Left" else 1, 0, 0)
				var target_direction: Vector3 = Vector3.FORWARD
				if "UpperArm" in new_name: target_direction = positions[target.find_bone(prefix + "Forearm")] - positions[new_index]
				elif "Forearm" in new_name: target_direction = positions[target.find_bone(prefix + "Hand")] - positions[new_index]
				var rotation: Basis = Basis(Quaternion(direction, target_direction.normalized()))
				neutral = positions[new_index] + rotation * (neutral - anchor)
				if "Hand" in new_name:
					var along: float = maxf(0.0, positions[new_index].z - neutral.z - 0.035)
					neutral.y -= along * 0.65
					neutral.z += along * 0.25
				n = rotation * n
			point += neutral * weight
			normal += n * weight
			mapped[slot] = new_index
			influence[slot] = weight
		var merged: Dictionary[int, float] = {}
		for slot: int in range(8):
			if influence[slot] > 0: merged[mapped[slot]] = merged.get(mapped[slot], 0.0) + influence[slot]
		var ordered: Array = merged.keys()
		ordered.sort_custom(func(a: int, b: int) -> bool: return merged[a] > merged[b])
		var final_bones: PackedInt32Array = PackedInt32Array([0, 0, 0, 0])
		var final_weights: PackedFloat32Array = PackedFloat32Array([0, 0, 0, 0])
		var total: float = 0.0
		for slot: int in range(mini(4, ordered.size())):
			final_bones[slot] = ordered[slot]
			final_weights[slot] = merged[ordered[slot]]
			total += final_weights[slot]
		for slot: int in range(4): final_weights[slot] /= maxf(total, 0.001)
		st.set_bones(final_bones)
		st.set_weights(final_weights)
		st.set_uv(uvs[index])
		st.set_normal(normal.normalized())
		st.add_vertex(point)
	st.index()
	var result: ArrayMesh = st.commit()
	source.free()
	return result

static func _map(old: String) -> String:
	if old == "Hips": return "Hips"
	if old in ["Spine", "Spine1"]: return "Spine"
	if old == "Spine2" or "Shoulder" in old: return "Chest"
	if old == "Neck": return "Neck"
	if "Head" in old: return "Head"
	var prefix: String = "Left" if old.begins_with("Left") else "Right"
	if "Hand" in old: return prefix + "Hand"
	if "ForeArm" in old: return prefix + "Forearm"
	if "Arm" in old: return prefix + "UpperArm"
	if "UpLeg" in old: return prefix + "Thigh"
	if "Leg" in old: return prefix + "Shin"
	return prefix + "Foot"
