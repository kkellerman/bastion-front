extends SceneTree
## Packs Poly Haven cutout maps into their diffuse alpha channel so foliage shaders
## sample one texture instead of two. Alpha-scissored foliage is the most overdrawn
## surface in the forest, so each avoided fetch is paid per overlapping layer.
const JOBS: Array[Dictionary] = [
	{
		"diffuse": "res://assets/textures/polyhaven/fir_twig/fir_twig_diff_1k.png",
		"alpha": "res://assets/textures/polyhaven/fir_twig/fir_twig_alpha_1k.png",
		"out": "res://assets/textures/fir_twig_packed.png",
	},
	{
		"diffuse": "res://assets/textures/polyhaven/ground_plants/grass_diff_1k.png",
		"alpha": "res://assets/textures/polyhaven/ground_plants/grass_alpha_1k.png",
		"out": "res://assets/textures/grass_packed.png",
	},
	{
		"diffuse": "res://assets/textures/polyhaven/ground_plants/fern_diff_1k.png",
		"alpha": "res://assets/textures/polyhaven/ground_plants/fern_alpha_1k.png",
		"out": "res://assets/textures/fern_packed.png",
	},
]

func _initialize() -> void:
	for job: Dictionary in JOBS:
		_pack(job["diffuse"], job["alpha"], job["out"])
	quit()

func _pack(diffuse_path: String, alpha_path: String, out_path: String) -> void:
	var diffuse: Image = load(diffuse_path).get_image()
	var cutout: Image = load(alpha_path).get_image()
	diffuse.decompress()
	cutout.decompress()
	diffuse.convert(Image.FORMAT_RGBA8)
	var size: Vector2i = diffuse.get_size()
	for y: int in range(size.y):
		for x: int in range(size.x):
			var colour: Color = diffuse.get_pixel(x, y)
			colour.a = cutout.get_pixel(x, y).r
			diffuse.set_pixel(x, y, colour)
	diffuse.save_png(out_path)
	print("Packed cutout into ", out_path)
