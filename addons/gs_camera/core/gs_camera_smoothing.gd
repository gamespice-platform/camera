class_name GSCameraSmoothing
extends RefCounted

## Frame-rate independent smoothing as pure functions: the same half life gives the same motion at 30 and at 240 frames per second. A half life of 0 follows exactly, never divides by it.


## The fraction of the remaining distance covered in [param delta] seconds.
static func blend(half_life: float, delta: float) -> float:
	if half_life <= 0.0:
		return 1.0
	return 1.0 - pow(0.5, maxf(delta, 0.0) / half_life)


static func damp(current: float, target: float, half_life: float, delta: float) -> float:
	return lerpf(current, target, blend(half_life, delta))


static func damp_vec3(current: Vector3, target: Vector3, half_life: float, delta: float) -> Vector3:
	return current.lerp(target, blend(half_life, delta))


static func damp_vec2(current: Vector2, target: Vector2, half_life: float, delta: float) -> Vector2:
	return current.lerp(target, blend(half_life, delta))


## Radians, along the short way round.
static func damp_angle(current: float, target: float, half_life: float, delta: float) -> float:
	return lerp_angle(current, target, blend(half_life, delta))
