class_name CombatImpact
extends RefCounted


static func show(context: Node3D, point: Vector3, normal: Vector3) -> void:
	var spark: MeshInstance3D = MeshInstance3D.new()
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = 0.035
	mesh.height = 0.07
	spark.mesh = mesh
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.8, 0.65, 0.4)
	spark.material_override = material
	var scene: Node = context.get_tree().current_scene
	if scene == null:
		scene = context.get_tree().root
	scene.add_child(spark)
	spark.global_position = point + normal * 0.01
	var tween: Tween = spark.create_tween()
	tween.tween_property(spark, "transparency", 1.0, 0.18)
	tween.tween_callback(spark.queue_free)
	context.get_node("/root/CombatAudio").play(&"impact", point)
