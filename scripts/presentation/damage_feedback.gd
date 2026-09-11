extends Node
## Health-driven feedback covers hitscan, explosives and direct damage alike.
var actor: CharacterBody3D
var health: HealthComponent
var previous: float
var cooldown: float = 0.0
var pulse: float = 0.0
var vignette: ColorRect
var events: int = 0

func _ready() -> void:
	previous = health.current_health
	health.health_changed.connect(_changed)
	if actor is FirstPersonPlayer:
		var canvas: CanvasLayer = CanvasLayer.new()
		canvas.layer = 4
		add_child(canvas)
		vignette = ColorRect.new()
		canvas.add_child(vignette)
		vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = load("res://shaders/damage_vignette.gdshader")
		vignette.material = material
		vignette.hide()

func _changed(current: float, _maximum: float) -> void:
	var hurt: bool = current < previous
	previous = current
	if not hurt or cooldown > 0 or not actor.can_process(): return
	cooldown = 0.14
	pulse = 0.32
	events += 1
	var point: Vector3 = actor.global_position + Vector3.UP
	get_node("/root/CombatAudio").play(&"hit_flesh" if events % 3 != 0 else &"hit_gear", point)
	if not actor is FirstPersonPlayer:
		CombatEffects.burst(actor, point, Vector3.UP, &"flesh")

func _process(delta: float) -> void:
	cooldown = maxf(0, cooldown - delta)
	pulse = maxf(0, pulse - delta)
	if vignette != null:
		vignette.visible = pulse > 0
		vignette.material.set_shader_parameter("strength", pulse)
