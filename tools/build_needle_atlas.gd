extends SceneTree
## Original botanical texture: irregular twig/needle clusters, transparent background.
var image: Image = Image.create(512, 1024, false, Image.FORMAT_RGBA8)
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _initialize() -> void:
	rng.seed = 87316
	image.fill(Color(0.15, 0.20, 0.095, 0))
	_line(Vector2(256, 1000), Vector2(244, 25), 3.5, Color(0.19, 0.14, 0.075))
	for branch: int in range(38):
		var y: float = 975.0 - branch * 24.0
		for side: int in [-1, 1]:
			var start: Vector2 = Vector2(250, y)
			var end: Vector2 = start + Vector2(side * rng.randf_range(140, 235) * (0.4 + y / 1500.0), -rng.randf_range(55, 130))
			_line(start, end, 1.7, Color(0.23, 0.19, 0.09))
			# Sub-twigs branching off the main stem thicken the silhouette beyond a
			# single row of needle strokes, closer to how real conifer clusters overlap.
			for sub: int in range(3):
				var sub_t: float = 0.25 + sub * 0.28
				var sub_start: Vector2 = start.lerp(end, sub_t)
				var sub_axis: Vector2 = (end - start).normalized().rotated(rng.randf_range(-0.5, 0.5))
				var sub_end: Vector2 = sub_start + sub_axis * rng.randf_range(28, 55)
				_line(sub_start, sub_end, 1.1, Color(0.21, 0.17, 0.085))
				for n: int in range(20):
					var t: float = float(n) / 20.0
					var base: Vector2 = sub_start.lerp(sub_end, t)
					var axis: Vector2 = sub_axis
					var lateral: Vector2 = Vector2(-axis.y, axis.x) * (1 if n % 2 == 0 else -1)
					var tip: Vector2 = base + (axis * 0.6 + lateral) * rng.randf_range(10, 24)
					_line(base, tip, rng.randf_range(0.8, 1.4), Color(0.11, 0.18, 0.075).lerp(Color(0.30, 0.36, 0.15), rng.randf()))
			for n: int in range(58):
				var t: float = float(n) / 58.0
				var base: Vector2 = start.lerp(end, t)
				var axis: Vector2 = (end - start).normalized()
				var lateral: Vector2 = Vector2(-axis.y, axis.x) * (1 if n % 2 == 0 else -1)
				var tip: Vector2 = base + (axis * 0.7 + lateral) * rng.randf_range(13, 33)
				_line(base, tip, rng.randf_range(1.0, 1.8), Color(0.12, 0.19, 0.08).lerp(Color(0.32, 0.38, 0.16), rng.randf()))
	image.save_png("res://assets/textures/spruce_branch.png")
	print("Original spruce needle atlas authored")
	quit()

func _line(start: Vector2, end: Vector2, radius: float, color: Color) -> void:
	var steps: int = ceili(start.distance_to(end) * 1.5)
	for i: int in range(steps + 1):
		var p: Vector2 = start.lerp(end, float(i) / maxf(steps, 1))
		for y: int in range(-2, 3):
			for x: int in range(-2, 3):
				var q: Vector2i = Vector2i(p) + Vector2i(x, y)
				if q.x < 0 or q.x >= 512 or q.y < 0 or q.y >= 1024: continue
				var alpha: float = clampf(radius - p.distance_to(Vector2(q)) + 0.5, 0, 1)
				if alpha > image.get_pixelv(q).a: image.set_pixelv(q, Color(color, alpha))
