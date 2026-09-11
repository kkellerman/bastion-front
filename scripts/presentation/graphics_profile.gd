class_name GraphicsProfile
extends RefCounted
## Capability hints select a safe starting point, never a promise of frame rate.
const PRESETS: Array[Dictionary] = [
	{"name": "Low", "scale": 0.8, "shadow_distance": 32.0, "shadow_size": 1024, "fog": false, "ssao": false, "ssil": false, "msaa": 0, "fxaa": true, "density": 0.45, "plants": 26.0, "trees": 65.0, "reflections": false, "mip_bias": 0.5},
	{"name": "Medium", "scale": 1.0, "shadow_distance": 45.0, "shadow_size": 2048, "fog": false, "ssao": true, "ssil": false, "msaa": 0, "fxaa": true, "density": 0.7, "plants": 36.0, "trees": 75.0, "reflections": false, "mip_bias": 0.0},
	{"name": "High", "scale": 1.0, "shadow_distance": 65.0, "shadow_size": 4096, "fog": true, "ssao": true, "ssil": true, "msaa": 1, "fxaa": false, "density": 1.0, "plants": 45.0, "trees": 85.0, "reflections": true, "mip_bias": -0.25}
]

static func audit() -> Dictionary:
	return {"renderer": RenderingServer.get_current_rendering_method(), "api": RenderingServer.get_video_adapter_api_version(), "adapter": RenderingServer.get_video_adapter_name(), "type": RenderingServer.get_video_adapter_type(), "headless": DisplayServer.get_name() == "headless", "graphics_memory_budget": "unknown (Godot exposes usage, not available VRAM)"}

static func recommend(capabilities: Dictionary) -> int:
	if capabilities.get("headless", false) or capabilities.get("renderer", "") != "forward_plus": return 0
	# Integrated, CPU, virtual and unknown adapters all start Low. Even discrete
	# devices start Medium because model name/type alone says little about speed.
	return 1 if int(capabilities.get("type", -1)) == RenderingDevice.DEVICE_TYPE_DISCRETE_GPU else 0

static func apply(scene: Node, viewport: Viewport, index: int, capabilities: Dictionary) -> void:
	var preset: Dictionary = PRESETS[clampi(index, 0, 2)]
	var forward: bool = capabilities.get("renderer", "") == "forward_plus"
	viewport.scaling_3d_scale = preset.scale
	viewport.msaa_3d = int(preset.msaa) as Viewport.MSAA
	viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if preset.fxaa else Viewport.SCREEN_SPACE_AA_DISABLED
	viewport.texture_mipmap_bias = preset.mip_bias
	RenderingServer.directional_shadow_atlas_set_size(preset.shadow_size, true)
	RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_LOW if index == 0 else RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM)
	if scene == null: return
	_apply_node(scene, preset, forward)

static func _apply_node(node: Node, preset: Dictionary, forward: bool) -> void:
	if node is WorldEnvironment and node.environment != null:
		node.environment.ssao_enabled = preset.ssao and forward
		node.environment.ssil_enabled = preset.ssil and forward
		node.environment.volumetric_fog_enabled = preset.fog and forward
		node.environment.ssr_enabled = preset.reflections and forward
		node.environment.ssr_max_steps = 32
	if node is DirectionalLight3D:
		node.directional_shadow_max_distance = preset.shadow_distance
		node.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS if preset.name == "Low" else DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	if node.is_in_group(&"quality_vegetation") and node is MultiMeshInstance3D:
		node.multimesh.visible_instance_count = int(node.multimesh.instance_count * float(preset.density))
		node.visibility_range_end = preset.plants
	if node.is_in_group(&"quality_tree_far") and node is GeometryInstance3D:
		node.visibility_range_end = preset.trees
	if node.is_in_group(&"quality_horizon") and node is MultiMeshInstance3D:
		# Keep near silhouettes on every tier; distant chunks can disappear into haze.
		node.visibility_range_end = 105.0 if preset.name == "Low" else 140.0
		node.multimesh.visible_instance_count = maxi(1, int(node.multimesh.instance_count * (0.75 if preset.name == "Low" else 1.0)))
	for child: Node in node.get_children(): _apply_node(child, preset, forward)
