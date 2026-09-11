extends SceneTree
## Packs the Poly Haven fir twig cutout into the diffuse alpha channel so the foliage
## shader samples one texture instead of two. Alpha-scissored canopy cards are the most
## overdrawn surface in the forest, so each avoided fetch is paid per overlapping layer.
const DIR: String = "res://assets/textures/polyhaven/fir_twig/"

func _initialize() -> void:
	var diffuse: Image = load(DIR + "fir_twig_diff_1k.png").get_image()
	var cutout: Image = load(DIR + "fir_twig_alpha_1k.png").get_image()
	diffuse.decompress()
	cutout.decompress()
	diffuse.convert(Image.FORMAT_RGBA8)
	var size: Vector2i = diffuse.get_size()
	for y: int in range(size.y):
		for x: int in range(size.x):
			var colour: Color = diffuse.get_pixel(x, y)
			colour.a = cutout.get_pixel(x, y).r
			diffuse.set_pixel(x, y, colour)
	diffuse.save_png("res://assets/textures/fir_twig_packed.png")
	print("Packed fir twig diffuse + cutout into fir_twig_packed.png")
	quit()
