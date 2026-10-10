class_name CastleDecorationBatch
extends RefCounted
## Collision-free carvings and metalwork share spatially culled instanced meshes.

var _poses: Dictionary[String, Array] = {}

func box(kind: String, at: Vector3, size: Vector3, yaw: float = 0.0) -> void:
	oriented(kind, at, size, Basis(Vector3.UP, yaw))

func oriented(kind: String, at: Vector3, size: Vector3, orientation: Basis) -> void:
	if not _poses.has(kind): _poses[kind] = []
	_poses[kind].append(Transform3D(orientation.scaled_local(size), at))

func build(parent: Node3D, title: String) -> Node3D:
	var root := Node3D.new()
	root.name = title
	parent.add_child(root)
	for kind: String in _poses:
		var mesh := BoxMesh.new()
		mesh.size = Vector3.ONE
		mesh.material = CastleMaterials.ornament(kind)
		var poses: Array[Transform3D] = []
		poses.assign(_poses[kind])
		SceneryInstances.build(root, kind, mesh, poses, 170.0)
	return root

func crest(at: Vector3, yaw: float = 0.0, scale_factor: float = 1.0) -> void:
	# A crowned square tofu seal, with inset eyes and a moustache flourish.
	var parts: Array[Array] = [
		["bronze", Vector3.ZERO, Vector3(1.45, 1.15, 0.12)],
		["iron", Vector3(-0.3, 0.12, 0.08), Vector3(0.14, 0.16, 0.05)],
		["iron", Vector3(0.3, 0.12, 0.08), Vector3(0.14, 0.16, 0.05)],
		["iron", Vector3(0, -0.25, 0.08), Vector3(0.75, 0.12, 0.05)],
		["bronze", Vector3(0, 0.85, 0), Vector3(1.65, 0.18, 0.14)]]
	for x in [-0.6, 0.0, 0.6]:
		parts.append(["bronze", Vector3(x, 1.08, 0), Vector3(0.22, 0.4, 0.14)])
	for part in parts:
		var offset: Vector3 = part[1]
		box(part[0], at + offset.rotated(Vector3.UP, yaw) * scale_factor, part[2] * scale_factor, yaw)
