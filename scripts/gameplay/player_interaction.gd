extends Node
@export var player: CharacterBody3D
@export var camera: Camera3D
var _pending: bool = false
var label: Label


func _ready() -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	add_child(canvas)
	label = Label.new()
	canvas.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	label.position += Vector2(-260, -125)
	label.size = Vector2(520, 40)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_constant_override("outline_size", 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_pending = true


func _physics_process(_delta: float) -> void:
	label.text = ""
	if player.get_node("HealthComponent").current_health <= 0.0:
		_pending = false
		return
	var rig: Node3D = player.get_meta(&"weapon_rig") as Node3D
	if rig.mounted != null:
		label.text = "Mouse: traverse  /  RMB: aim  /  LMB: fire  /  R: reload  /  E: dismount"
		if _pending:
			rig.mounted.dismount()
	else:
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position - camera.global_basis.z * 2.8, 17)
		query.collide_with_areas = true
		var hit: Dictionary = camera.get_world_3d().direct_space_state.intersect_ray(query)
		var interaction: Object = null
		if not hit.is_empty():
			interaction = hit["collider"]
			if interaction.has_meta(&"interactable"):
				interaction = interaction.get_meta(&"interactable")
		if interaction != null and interaction.has_method("interact"):
			label.text = interaction.get_prompt()
			if _pending:
				interaction.interact(player)
	_pending = false
