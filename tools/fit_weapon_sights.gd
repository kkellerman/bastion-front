extends SceneTree
## Add the missing sight pedestals without rebuilding the existing weapon art.
func _initialize() -> void:
	for id: String in ["m1911","p38","thompson","mp40","stg44"]:
		var data: WeaponData = load("res://resources/weapons/"+id+".tres")
		var scene: Node3D = data.viewmodel_scene.instantiate()
		var pistol: bool = data.weapon_class == &"pistol"
		var y: float = 0.032 if pistol else 0.052
		var model: Node3D = scene.get_node("WeaponMesh")
		for front: bool in [true,false]:
			var node_name: String = "SightFrontBase" if front else "SightRearBase"
			if model.has_node(node_name): continue
			var floor_height: float = 0.017 if pistol else 0.012 if front else 0.032
			var z: float = (-0.09 if front else 0.085) if pistol else (-0.37 if front else 0.08)
			var base := MeshInstance3D.new()
			base.name = node_name
			var shape := BoxMesh.new()
			shape.size = Vector3(0.018 if front else 0.029,y-0.006-floor_height,0.024)
			base.mesh = shape
			var material := StandardMaterial3D.new()
			material.albedo_color = Color(0.05,0.055,0.05)
			material.metallic = 0.6
			material.roughness = 0.6
			base.material_override = material
			base.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			model.add_child(base)
			base.position = Vector3(0,(floor_height+y-0.006)*0.5,z)
			base.owner = scene
		var packed := PackedScene.new()
		packed.pack(scene)
		ResourceSaver.save(packed,data.viewmodel_scene.resource_path)
		scene.free()
	quit()
