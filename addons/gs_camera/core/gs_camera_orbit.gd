class_name GSCameraOrbit
extends RefCounted

## The state and maths of an orbit or third-person camera around a pivot: yaw, pitch, distance and a shoulder offset, with the clamps from [GSCameraConfig]. It places nothing and casts no ray; GameSpice Core's `GSCameraBoom` pulls the result in front of walls.

var yaw: float = 0.0
var pitch: float = 0.0
var distance: float = 3.5


static func from_config(cfg: GSCameraConfig) -> GSCameraOrbit:
	var o := GSCameraOrbit.new()
	o.distance = cfg.distance
	return o


## Turns by [param d_yaw] and [param d_pitch] radians; pitch stays inside the configured degrees.
func look(cfg: GSCameraConfig, d_yaw: float, d_pitch: float) -> void:
	yaw = wrapf(yaw + d_yaw, -PI, PI)
	pitch = clampf(pitch + d_pitch, deg_to_rad(cfg.pitch_min), deg_to_rad(cfg.pitch_max))


## Moves closer (negative) or further (positive); `distance_max` 0 is no upper limit.
func zoom(cfg: GSCameraConfig, delta: float) -> void:
	distance = maxf(distance + delta, cfg.distance_min)
	if cfg.distance_max > 0.0:
		distance = minf(distance, cfg.distance_max)


## Where the camera wants to be relative to the pivot: behind the look direction by [member distance], shifted sideways by the shoulder.
func offset(cfg: GSCameraConfig) -> Vector3:
	var basis := Basis.from_euler(Vector3(pitch, yaw, 0.0))
	return basis * Vector3(cfg.shoulder, 0.0, distance)


## The camera transform for [param pivot], looking at it from [method offset].
func transform_at(cfg: GSCameraConfig, pivot: Vector3) -> Transform3D:
	var basis := Basis.from_euler(Vector3(pitch, yaw, 0.0))
	return Transform3D(basis, pivot + offset(cfg))


## The offset a shake of [param raw] (from GameSpice FX) adds, scaled by `shake_scale`.
static func shake_offset(cfg: GSCameraConfig, raw: Vector3) -> Vector3:
	return raw * cfg.shake_scale
