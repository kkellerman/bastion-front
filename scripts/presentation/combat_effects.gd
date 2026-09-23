class_name CombatEffects
extends RefCounted

static var _disc_cache: Dictionary[Color, GradientTexture2D] = {}

static func burst(context: Node3D, point: Vector3, normal: Vector3, surface: StringName, explosion: bool = false) -> void:
	var scene: Node = context.get_tree().current_scene
	if scene == null: return
	if explosion:
		if context.get_tree().get_nodes_in_group(&"explosion_effects").size() >= 6: return
		var effect: Node3D = load("res://scripts/presentation/explosion_effect.gd").new()
		effect.surface = surface
		scene.add_child(effect)
		effect.global_position = point
		effect.start()
		_decal(context, point, normal, true)
		return
	var effects: Array[Node] = context.get_tree().get_nodes_in_group(&"combat_effects")
	if effects.size() >= 24: return
	var particles: CPUParticles3D = CPUParticles3D.new()
	particles.add_to_group(&"combat_effects")
	particles.amount = 32 if explosion else 9
	particles.lifetime = 1.6 if explosion else 0.55
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.direction = normal
	particles.spread = 65
	particles.gravity = Vector3(0, -2, 0)
	particles.initial_velocity_min = 2.0 if explosion else 0.6
	particles.initial_velocity_max = 7.0 if explosion else 2.5
	particles.scale_amount_min = 0.05 if explosion else 0.012
	particles.scale_amount_max = 0.28 if explosion else 0.055
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(0.4, 0.18, 0.9) if surface == &"wood" else Vector3(0.5, 0.4, 0.4)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.36, 0.30, 0.21) if surface in [&"dirt", &"wood"] else Color(0.43, 0.43, 0.40)
	if surface == &"metal":
		material.albedo_color = Color(0.8, 0.58, 0.3)
		material.emission_enabled = true
		material.emission = Color(0.8, 0.4, 0.1)
	mesh.material = material
	particles.mesh = mesh
	scene.add_child(particles)
	particles.global_position = point + normal * 0.02
	particles.finished.connect(particles.queue_free)
	particles.emitting = true
	smoke(context, point, explosion)
	if surface != &"flesh": _decal(context, point, normal, explosion)

static func smoke(context: Node3D, point: Vector3, explosion: bool = false) -> void:
	var scene: Node = context.get_tree().current_scene
	if scene == null or context.get_tree().get_nodes_in_group(&"combat_smoke").size() >= 12: return
	var smoke_node: MeshInstance3D = MeshInstance3D.new()
	smoke_node.add_to_group(&"combat_smoke")
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2.ONE * (1.7 if explosion else 0.16)
	smoke_node.mesh = quad
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.albedo_texture = _disc(Color(0.22, 0.23, 0.21, 0.4))
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smoke_node.material_override = material
	smoke_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	scene.add_child(smoke_node)
	smoke_node.global_position = point
	var duration: float = 2.4 if explosion else 0.6
	var tween: Tween = smoke_node.create_tween().set_parallel()
	tween.tween_property(smoke_node, "position:y", point.y + (2.0 if explosion else 0.18), duration)
	tween.tween_property(smoke_node, "scale", Vector3.ONE * 2.5, duration)
	tween.tween_property(smoke_node, "transparency", 1.0, duration)
	tween.chain().tween_callback(smoke_node.queue_free)

static func _decal(context: Node3D, point: Vector3, normal: Vector3, explosion: bool) -> void:
	var decals: Array[Node] = context.get_tree().get_nodes_in_group(&"impact_decals")
	if decals.size() >= 40: return
	var decal: Decal = Decal.new()
	decal.add_to_group(&"impact_decals")
	decal.texture_albedo = _disc(Color(0.035, 0.028, 0.02, 0.8))
	decal.size = Vector3(1.5, 0.15, 1.5) if explosion else Vector3(0.09, 0.06, 0.09)
	context.get_tree().current_scene.add_child(decal)
	decal.global_position = point
	var right: Vector3 = normal.cross(Vector3.FORWARD).normalized()
	if right.length() < 0.1: right = Vector3.RIGHT
	decal.basis = Basis(right, normal, right.cross(normal))
	var tween: Tween = decal.create_tween()
	tween.tween_interval(10.0)
	tween.tween_property(decal, "modulate:a", 0.0, 2.0)
	tween.tween_callback(decal.queue_free)

static func _disc(color: Color) -> GradientTexture2D:
	if _disc_cache.has(color): return _disc_cache[color]
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, color)
	gradient.set_color(1, Color(color, 0))
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.width = 32
	texture.height = 32
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0)
	_disc_cache[color] = texture
	return texture
