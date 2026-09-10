extends Node3D
const Soundscape = preload("res://scripts/presentation/mission_soundscape.gd")
@onready var camera: Camera3D = $Camera3D
var panel: Label
var _starting: bool = false
var soundscape: Node3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_node("/root/PlayerSettings").apply.call_deferred()
	camera.look_at(Vector3(-1, 2.0, -59))
	soundscape = Soundscape.new()
	soundscape.listener = camera
	add_child(soundscape)
	var canvas: CanvasLayer = CanvasLayer.new()
	add_child(canvas)
	var layout: Control = Control.new()
	canvas.add_child(layout)
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade: TextureRect = TextureRect.new()
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(0.025, 0.032, 0.033, 0.97))
	gradient.set_color(1, Color(0.025, 0.032, 0.033, 0.0))
	gradient.add_point(0.43, Color(0.025, 0.032, 0.033, 0.8))
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_to = Vector2(1, 0)
	shade.texture = texture
	layout.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var font: SystemFont = SystemFont.new()
	font.font_names = PackedStringArray(["Bahnschrift", "Arial"])
	_label(layout, "EUROPE  /  1944", Vector2(64, 62), 16, Color(0.64, 0.64, 0.55))
	var title: Label = _label(layout, "BASTION\nFRONT", Vector2(58, 107), 80, Color(0.86, 0.83, 0.72))
	title.add_theme_font_override("font", font)
	title.add_theme_constant_override("line_spacing", -16)
	_label(layout, "FOREST COMMAND POST  /  F10 SETTINGS", Vector2(65, 307), 17, Color(0.67, 0.66, 0.55))
	var line: ColorRect = ColorRect.new()
	layout.add_child(line)
	line.position = Vector2(65, 350)
	line.size = Vector2(315, 1)
	line.color = Color(0.57, 0.53, 0.39, 0.55)
	var labels: Array[String] = ["BEGIN  /  ALLIED", "GERMAN LOADOUT TEST", "FIELD MANUAL", "ASSET CREDITS", "QUIT"]
	for index: int in range(labels.size()):
		var button: Button = Button.new()
		button.name = "MenuButton%d" % index
		layout.add_child(button)
		button.position = Vector2(58, 378 + index * 47)
		button.size = Vector2(335, 41)
		button.text = labels[index]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 20)
		button.add_theme_color_override("font_color", Color(0.8, 0.78, 0.69))
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color(0.17, 0.19, 0.17, 0)
		style.content_margin_left = 10
		button.add_theme_stylebox_override("normal", style)
		var hover: StyleBoxFlat = style.duplicate() as StyleBoxFlat
		hover.bg_color = Color(0.37, 0.37, 0.28, 0.35)
		hover.border_width_left = 2
		hover.border_color = Color(0.7, 0.66, 0.47)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("focus", hover)
		button.pressed.connect(_select.bind(index))
		if index == 0: button.grab_focus()
	panel = _label(layout, "", Vector2(540, 405), 18, Color(0.9, 0.88, 0.79))
	panel.size = Vector2(650, 240)
	panel.add_theme_constant_override("outline_size", 5)
	_label(layout, "A FICTIONAL OPERATION  ·  VISUAL DEVELOPMENT BUILD", Vector2(64, 670), 13, Color(0.52, 0.55, 0.49))

func _label(parent: Control, words: String, point: Vector2, size: int, color: Color) -> Label:
	var label: Label = Label.new()
	parent.add_child(label)
	label.position = point
	label.text = words
	label.add_theme_font_size_override("font_size", size)
	label.modulate = color
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _select(index: int) -> void:
	if _starting: return
	match index:
		0, 1:
			get_node("/root/PrototypeSession").checkpoint.clear()
			_starting = true
			get_node("/root/PrototypeSession").faction_id = &"allied" if index == 0 else &"german"
			get_tree().change_scene_to_file("res://scenes/missions/forest_command_post.tscn")
		2:
			panel.text = "FIELD MANUAL\n\nWASD move · Mouse look · Shift sprint · Ctrl crouch\nSpace jump · LMB fire · RMB aim · R reload\n1–4 / wheel switch · G grenade · E interact / mount\nEsc release mouse · Enter restart after death\n\nRecover the operations documents. Reach the rear exit."
		3:
			panel.text = "ASSET CREDITS\n\nCC0 PBR materials: Poly Haven\nCC0 soldier base: nisu / OpenGameArt\n\nOriginal equipment, rig, map and effects: Bastion Front\nVoice recordings remain unfilled / silent\nFull source and license records: ASSET_ATTRIBUTION.md"
		4: soundscape.quit_game()
