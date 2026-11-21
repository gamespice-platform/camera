class_name GSCameraFov
extends RefCounted

## The field-of-view rules as pure functions: widen with speed, narrow while aiming, clamp, and convert between the vertical and horizontal angle.


## The vertical field of view for a body moving at [param speed] metres per second. [param aiming] narrows it by `fov_aim_scale`.
static func target(cfg: GSCameraConfig, speed: float, aiming: bool = false) -> float:
	if not cfg.enabled:
		return cfg.fov
	var widen := 0.0
	if cfg.fov_speed_add > 0.0 and cfg.fov_speed_full > 0.0:
		widen = cfg.fov_speed_add * clampf(speed / cfg.fov_speed_full, 0.0, 1.0)
	var value := cfg.fov + widen
	if aiming:
		value *= cfg.fov_aim_scale
	return clamp_fov(cfg, value)


static func clamp_fov(cfg: GSCameraConfig, value: float) -> float:
	var out := maxf(value, cfg.fov_min)
	if cfg.fov_max > 0.0:
		out = minf(out, cfg.fov_max)
	return out


## Horizontal field of view in degrees for a vertical one at [param aspect] (width over height).
static func to_horizontal(vertical_deg: float, aspect: float) -> float:
	return rad_to_deg(2.0 * atan(tan(deg_to_rad(vertical_deg) * 0.5) * aspect))


static func to_vertical(horizontal_deg: float, aspect: float) -> float:
	return rad_to_deg(2.0 * atan(tan(deg_to_rad(horizontal_deg) * 0.5) / aspect))
