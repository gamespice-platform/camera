class_name DotCameraFreeLook
extends RefCounted

## The controls of a roaming camera: yaw, pitch and a position, moved by a game's own input. Shared by a spectator's roam, a map flythrough and a debug camera.
##
## It reads no input and touches no camera: the game feeds it numbers, so every game's own input sampler works. What is shared is the arithmetic that is easy to get wrong: pitch clamped short of straight up so the basis never degenerates, movement along the way the camera faces so forward climbs when looking up, and speed scaling.
##
## [codeblock]
## var free := DotCameraFreeLook.new()
## free.seed_from(camera.global_transform)
## free.look(mouse_relative * sensitivity)
## camera.global_transform = free.step(cfg, Vector3(right, up, forward), fast, slow, delta)
## [/codeblock]

## Short of 90 degrees: at straight up the forward and up vectors are parallel and the basis is garbage.
const MAX_PITCH := deg_to_rad(89.0)

var position := Vector3.ZERO
## Radians.
var yaw: float = 0.0
var pitch: float = 0.0


## Starts from an existing camera so a roam begins where the view already was.
func seed_from(t: Transform3D) -> void:
	position = t.origin
	var euler := t.basis.orthonormalized().get_euler(EULER_ORDER_YXZ)
	yaw = euler.y
	pitch = clampf(euler.x, -MAX_PITCH, MAX_PITCH)


## Turns by [param delta_angles] radians: x is yaw, y is pitch (up positive).
func look(delta_angles: Vector2) -> void:
	yaw = wrapf(yaw + delta_angles.x, -PI, PI)
	pitch = clampf(pitch + delta_angles.y, -MAX_PITCH, MAX_PITCH)


func get_basis() -> Basis:
	return Basis.from_euler(Vector3(pitch, yaw, 0.0), EULER_ORDER_YXZ)


func get_transform() -> Transform3D:
	return Transform3D(get_basis(), position)


## Flies for [param delta] seconds. [param move] is x right, y up (world up, so looking down and pressing up does not dive), z forward along the view, each in -1..1.
func step(cfg: DotCameraConfig, move: Vector3, fast: bool, slow: bool, delta: float) -> Transform3D:
	var speed := cfg.free_speed
	if fast:
		speed *= cfg.free_fast_scale
	elif slow:
		speed *= cfg.free_slow_scale
	var b := get_basis()
	var wish := b.x * move.x + Vector3.UP * move.y + (-b.z) * move.z
	if wish.length_squared() > 1.0:
		wish = wish.normalized()
	position += wish * speed * delta
	return get_transform()
