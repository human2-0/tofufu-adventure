class_name DofufuMountainPaths
extends RefCounted
## Graded side trails and level destination clearings; shared by scenery and terrain.

const HUT := Vector2(-574, 120)
const LOOKOUT := Vector2(-774, -136)
var routes: Array[PackedVector3Array] = []
var _bounds: Array[Rect2] = []
var hut_height: float
var lookout_height: float

func _init(height: Callable) -> void:
	hut_height = height.call(HUT.x, HUT.y)
	lookout_height = height.call(LOOKOUT.x, LOOKOUT.y)
	for points: PackedVector2Array in [
		PackedVector2Array([Vector2(-480, 0), Vector2(-495, 34), Vector2(-510, 70), Vector2(-535, 101), Vector2(-558, 136), Vector2(-574, 131)]),
		PackedVector2Array([Vector2(-665, 0), Vector2(-678, -30), Vector2(-695, -60), Vector2(-720, -105), Vector2(-749, -132), LOOKOUT])]:
		var route := PackedVector3Array()
		var bounds := Rect2(points[0], Vector2.ZERO)
		for at in points:
			route.append(Vector3(at.x, height.call(at.x, at.y), at.y))
			bounds = bounds.expand(at)
		if routes.is_empty():
			route = _grade(route, hut_height)
			hut_height = route[-1].y
		else:
			route = _grade(route, lookout_height)
			lookout_height = route[-1].y
		routes.append(route)
		_bounds.append(bounds.grow(25))

func _grade(route: PackedVector3Array, destination: float) -> PackedVector3Array:
	# A bounded longitudinal grade, independent of the seed's individual rock peaks.
	var lengths := PackedFloat32Array([0])
	for index in range(1, route.size()):
		var a := Vector2(route[index - 1].x, route[index - 1].z)
		var b := Vector2(route[index].x, route[index].z)
		lengths.append(lengths[-1] + a.distance_to(b))
	var approach := lengths[-2] # The final segment is a level destination apron.
	var start := route[0].y
	destination = clampf(destination, start - approach * 0.25, start + approach * 0.25)
	for index in range(1, route.size()):
		route[index].y = lerpf(start, destination, minf(1, lengths[index] / approach))
	return route

func sample(at: Vector2) -> Vector2:
	var closest := Vector2(1000, 0) # Horizontal distance, interpolated path height.
	for index in routes.size():
		if not _bounds[index].has_point(at): continue
		var route := routes[index]
		for segment in route.size() - 1:
			var a := Vector2(route[segment].x, route[segment].z)
			var b := Vector2(route[segment + 1].x, route[segment + 1].z)
			var t := clampf((at - a).dot(b - a) / a.distance_squared_to(b), 0, 1)
			var distance := at.distance_to(a.lerp(b, t))
			if distance < closest.x:
				closest = Vector2(distance, lerpf(route[segment].y, route[segment + 1].y, t))
	return closest

func height_at(at: Vector2, base: float) -> float:
	var lane := sample(at)
	var result := lerpf(lane.y, base, smoothstep(8, 24, lane.x))
	result = lerpf(hut_height, result, smoothstep(10, 16, at.distance_to(HUT)))
	return lerpf(lookout_height, result, smoothstep(7, 13, at.distance_to(LOOKOUT)))

func distance_to(at: Vector2) -> float:
	return minf(sample(at).x, maxf(0, at.distance_to(HUT) - 8))

func path_mask(at: Vector2) -> float:
	return 1 - smoothstep(1.7, 3.2, distance_to(at))
