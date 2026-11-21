extends Node

## dot-camera's headless suite (res://examples/camera_selftest.tscn).
## Counts sections run to their last line as well as checks, because a script error
## aborts a section and not the run.

const EXPECTED_SECTIONS := 4
const EXPECTED_CHECKS := 43

var _passed := 0
var _failed := 0
var _sections := 0


func _ready() -> void:
	print("dot-camera")
	_config()
	_smoothing()
	_fov()
	_orbit()
	print("")
	_check(_sections == EXPECTED_SECTIONS, "every section ran to its last line (%d of %d)" % [_sections, EXPECTED_SECTIONS])
	_check(_passed + _failed == EXPECTED_CHECKS, "and the suite ran all %d of its checks (%d)" % [EXPECTED_CHECKS, _passed + _failed])
	print("%d passed, %d failed" % [_passed, _failed])
	get_tree().quit(1 if _failed > 0 else 0)


func _config() -> void:
	var c := DotCameraConfig.new()
	_check(c.validate().ok, "defaults validate")
	_check(c.config_keys().size() >= 14, "every tunable is a config key", str(c.config_keys().size()))
	for k in ["fov", "fov_speed_add", "fov_aim_scale", "position_half_life", "distance_max", "pitch_min", "shoulder", "shake_scale", "mode"]:
		_check(c.has_key(k), "key %s exists" % k)
	c.fov = 180.0
	_check(not c.validate().ok, "a fov of 180 is refused")
	c.fov = 75.0
	c.fov_max = 10.0
	_check(not c.validate().ok, "a fov_max under fov_min is refused")
	c.fov_max = 0.0
	_check(c.validate().ok, "fov_max 0 is no clamp, not an error")
	c.pitch_min = 85.0
	_check(not c.validate().ok, "inverted pitch limits are refused")
	_sections += 1


func _smoothing() -> void:
	_check(DotCameraSmoothing.blend(0.0, 0.016) == 1.0, "a half life of 0 follows exactly")
	_check(is_equal_approx(DotCameraSmoothing.blend(0.1, 0.1), 0.5), "one half life covers half")
	var one := DotCameraSmoothing.damp(0.0, 1.0, 0.1, 0.2)
	var two := DotCameraSmoothing.damp(DotCameraSmoothing.damp(0.0, 1.0, 0.1, 0.1), 1.0, 0.1, 0.1)
	_check(is_equal_approx(one, two), "two small steps equal one big one, so the frame rate does not matter")
	_check(DotCameraSmoothing.damp_vec3(Vector3.ZERO, Vector3(2, 0, 0), 0.1, 0.1).is_equal_approx(Vector3(1, 0, 0)), "vectors damp the same way")
	var a := DotCameraSmoothing.damp_angle(deg_to_rad(170.0), deg_to_rad(-170.0), 0.1, 0.1)
	_check(absf(absf(rad_to_deg(a)) - 180.0) < 0.01, "angles take the short way round")
	_check(DotCameraSmoothing.blend(0.1, -1.0) == 0.0, "a negative delta moves nothing")
	_sections += 1


func _fov() -> void:
	var c := DotCameraConfig.new()
	_check(is_equal_approx(DotCameraFov.target(c, 0.0), 75.0), "at rest the base fov")
	_check(is_equal_approx(DotCameraFov.target(c, 9.0), 83.0), "at full speed the add")
	_check(is_equal_approx(DotCameraFov.target(c, 4.5), 79.0), "half speed adds half")
	_check(is_equal_approx(DotCameraFov.target(c, 90.0), 83.0), "more speed adds no more")
	_check(is_equal_approx(DotCameraFov.target(c, 0.0, true), 52.5), "aiming narrows")
	c.fov_aim_scale = 0.2
	_check(is_equal_approx(DotCameraFov.target(c, 0.0, true), 30.0), "the lower clamp holds")
	c.fov_max = 0.0
	c.fov_speed_add = 200.0
	_check(DotCameraFov.target(c, 9.0) > 200.0, "fov_max 0 leaves the top open")
	c.enabled = false
	_check(is_equal_approx(DotCameraFov.target(c, 9.0), c.fov), "disabled returns the base")
	var h := DotCameraFov.to_horizontal(60.0, 16.0 / 9.0)
	_check(absf(h - 91.49) < 0.05, "60 vertical at 16:9 is about 91.5 horizontal", str(h))
	_check(absf(DotCameraFov.to_vertical(h, 16.0 / 9.0) - 60.0) < 0.001, "and back")
	_sections += 1


func _orbit() -> void:
	var c := DotCameraConfig.new()
	var o := DotCameraOrbit.from_config(c)
	_check(is_equal_approx(o.distance, 3.5), "starts at the configured distance")
	_check(o.offset(c).is_equal_approx(Vector3(0, 0, 3.5)), "unturned it sits behind the pivot (+Z)")
	o.look(c, 0.0, 10.0)
	_check(is_equal_approx(o.pitch, deg_to_rad(80.0)), "pitch clamps at the top")
	o.look(c, 0.0, -20.0)
	_check(is_equal_approx(o.pitch, deg_to_rad(-80.0)), "and at the bottom")
	o.look(c, 4.0, 0.0)
	o.look(c, 4.0, 0.0)
	_check(absf(o.yaw) <= PI, "yaw wraps", str(o.yaw))
	o.zoom(c, 100.0)
	_check(is_equal_approx(o.distance, 8.0), "zoom stops at distance_max")
	o.zoom(c, -100.0)
	_check(is_equal_approx(o.distance, 0.8), "and at distance_min")
	c.distance_max = 0.0
	o.zoom(c, 500.0)
	_check(o.distance > 400.0, "distance_max 0 is unlimited")
	var p := DotCameraOrbit.from_config(c)
	p.distance = 4.0
	c.shoulder = 1.0
	_check(p.offset(c).is_equal_approx(Vector3(1, 0, 4)), "the shoulder shifts it sideways")
	_check(p.transform_at(c, Vector3(0, 2, 0)).origin.is_equal_approx(Vector3(1, 2, 4)), "the transform sits at pivot plus offset")
	c.shake_scale = 0.0
	_check(DotCameraOrbit.shake_offset(c, Vector3.ONE) == Vector3.ZERO, "shake scale 0 silences it")
	_sections += 1



func _check(ok: bool, what: String, extra: String = "") -> void:
	if ok:
		_passed += 1
		print("  ok    ", what)
	else:
		_failed += 1
		print("  FAIL  ", what, "  ", extra)
