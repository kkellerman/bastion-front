class_name MeshWorkshop
extends RefCounted
## Authoring helpers shared by offline asset builders, never gameplay logic.

static func tube(st: SurfaceTool, start: Vector3, end: Vector3, radius: float, tip: float, sides: int = 8) -> void:
	var axis: Vector3 = (end - start).normalized()
	var u: Vector3 = axis.cross(Vector3.RIGHT if absf(axis.x) < 0.9 else Vector3.UP).normalized()
	var v: Vector3 = axis.cross(u)
	for i: int in range(sides):
		var a: Vector3 = u * cos(TAU * i / sides) + v * sin(TAU * i / sides)
		var b: Vector3 = u * cos(TAU * (i + 1) / sides) + v * sin(TAU * (i + 1) / sides)
		for p: Vector3 in [start + a * radius, end + a * tip, end + b * tip, start + a * radius, end + b * tip, start + b * radius]:
			st.set_normal(a if p.distance_to(start + a * radius) < 0.001 or p.distance_to(end + a * tip) < 0.001 else b)
			st.set_uv(Vector2(p.x + p.z, p.y))
			st.add_vertex(p)

static func leaf(st: SurfaceTool, base: Vector3, tip: Vector3, width: float, color: Color) -> void:
	var side: Vector3 = (tip - base).cross(Vector3.UP).normalized() * width
	if side.length_squared() < 0.00001:
		side = Vector3.RIGHT * width
	var mid: Vector3 = base.lerp(tip, 0.42) + Vector3.UP * width * 0.2
	st.set_color(color)
	for p: Vector3 in [base, mid + side, tip, base, tip, mid - side]:
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2.ZERO)
		st.add_vertex(p)

static func surface() -> SurfaceTool:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st
