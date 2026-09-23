extends RefCounted
static var _cache: Dictionary[String, ArrayMesh] = {}
## Rounded palm and continuous curved fingers, relative to a wrist attachment.
static func build(left: bool, cradle: bool = false) -> ArrayMesh:
	var key: String = str(left)+":"+str(cradle)
	if _cache.has(key): return _cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	if cradle:
		_tube(st, [Vector3.ZERO, Vector3(0.006, 0.008, -0.025), Vector3(0.016, 0.012, -0.065), Vector3(0.019, 0.015, -0.092)], [Vector2(0.023, 0.017), Vector2(0.032, 0.018), Vector2(0.035, 0.017), Vector2(0.025, 0.013)])
		for finger: int in range(4):
			var z: float = -0.09 + finger * 0.018
			var r: float = 0.0085 - finger * 0.00065
			_tube(st, [Vector3(0.02, 0.014, z), Vector3(0.046, 0.023, z), Vector3(0.059, 0.041, z), Vector3(0.05, 0.059, z - 0.002)], [Vector2.ONE*r, Vector2.ONE*r, Vector2.ONE*r*0.88, Vector2.ONE*r*0.65])
		_tube(st, [Vector3(-0.012, 0.012, -0.025), Vector3(-0.021, 0.038, -0.045), Vector3(-0.014, 0.058, -0.067)], [Vector2.ONE*0.012, Vector2.ONE*0.010, Vector2.ONE*0.008])
	else:
		var side: float = -1.0 if left else 1.0
		_tube(st, [Vector3.ZERO, Vector3(0, 0.004, -0.027), Vector3(-side*0.004, 0.008, -0.065), Vector3(-side*0.007, 0.01, -0.086)], [Vector2(0.017, 0.024), Vector2(0.019, 0.033), Vector2(0.016, 0.039), Vector2(0.012, 0.032)])
		for finger: int in range(4):
			var y: float = 0.04 - finger * 0.021
			var r: float = 0.009 - finger * 0.0006
			var reach: float = 0.013 if finger == 0 and not left else 0.0
			_tube(st, [Vector3(-side*0.004, y, -0.073), Vector3(-side*0.022, y-0.003, -0.095-reach), Vector3(-side*0.047, y-0.006, -0.091-reach), Vector3(-side*0.052, y-0.007, -0.072-reach)], [Vector2.ONE*r, Vector2.ONE*r, Vector2.ONE*r*0.88, Vector2.ONE*r*0.65])
		_tube(st, [Vector3(-side*0.003, 0.019, -0.022), Vector3(-side*0.022, 0.048, -0.036), Vector3(-side*0.045, 0.045, -0.057)], [Vector2.ONE*0.013, Vector2.ONE*0.011, Vector2.ONE*0.008])
	st.generate_normals()
	st.index()
	var mesh: ArrayMesh = st.commit()
	_cache[key] = mesh
	return mesh

static func _tube(st: SurfaceTool, points: Array[Vector3], radii: Array[Vector2]) -> void:
	var centers: Array[Vector3] = []
	var widths: Array[Vector2] = []
	for segment: int in range(points.size()-1):
		for step: int in range(5):
			var t: float = step / 5.0
			centers.append(points[segment].cubic_interpolate(points[segment+1], points[maxi(0,segment-1)], points[mini(points.size()-1,segment+2)], t))
			widths.append(radii[segment].lerp(radii[segment+1], t))
	centers.append(points[-1])
	widths.append(radii[-1]*0.1)
	for ring: int in range(centers.size()-1):
		for side: int in range(12):
			for corner: Vector2i in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,0),Vector2i(1,1),Vector2i(0,1)]:
				var i: int = ring+corner.y
				var tangent: Vector3 = (centers[mini(i+1,centers.size()-1)]-centers[maxi(0,i-1)]).normalized()
				var across: Vector3 = tangent.cross(Vector3.UP).normalized()
				if across.length_squared()<0.1: across = Vector3.RIGHT
				var up: Vector3 = across.cross(tangent).normalized()
				var angle: float = (side+corner.x)*TAU/12.0
				st.set_uv(Vector2(float(side+corner.x)/12.0,float(i)/centers.size()))
				st.add_vertex(centers[i]+across*cos(angle)*widths[i].x+up*sin(angle)*widths[i].y)
