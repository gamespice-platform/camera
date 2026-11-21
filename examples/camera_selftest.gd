extends Node

## dot-camera's headless suite (res://examples/camera_selftest.tscn).
## Counts sections run to their last line as well as checks, because a script error
## aborts a section and not the run.

const EXPECTED_SECTIONS := 6
const EXPECTED_CHECKS := 65

var _passed := 0
var _failed := 0
var _sections := 0


func _ready() -> void:
	print("dot-camera")
	_config()
	_smoothing()
	_fov()
	_orbit()
	_free_look()
	_zoom_2d()
	print("")
	_check(_sections == EXPECTED_SECTIONS, "every section ran to its last line (%d of %d)" % [_sections, EXPECTED_SECTIONS])
	_check(_passed + _failed == EXPECTED_CHECKS, "and the suite ran all %d of its checks (%d)" % [EXPECTED_CHECKS, _passed + _failed])
	print("%d passed, %d failed" % [_passed, _failed])
	get_tree().quit(1 if _failed > 0 else 0)


func _config() -> void:
	var c := GSCameraConfig.new()
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
	_check(GSCameraSmoothing.blend(0.0, 0.016) == 1.0, "a half life of 0 follows exactly")
	_check(is_equal_approx(GSCameraSmoothing.blend(0.1, 0.1), 0.5), "one half life covers half")
	var one := GSCameraSmoothing.damp(0.0, 1.0, 0.1, 0.2)
	var two := GSCameraSmoothing.damp(GSCameraSmoothing.damp(0.0, 1.0, 0.1, 0.1), 1.0, 0.1, 0.1)
	_check(is_equal_approx(one, two), "two small steps equal one big one, so the frame rate does not matter")
	_check(GSCameraSmoothing.damp_vec3(Vector3.ZERO, Vector3(2, 0, 0), 0.1, 0.1).is_equal_approx(Vector3(1, 0, 0)), "vectors damp the same way")
	var a := GSCameraSmoothing.damp_angle(deg_to_rad(170.0), deg_to_rad(-170.0), 0.1, 0.1)
	_check(absf(absf(rad_to_deg(a)) - 180.0) < 0.01, "angles take the short way round")
	_check(GSCameraSmoothing.blend(0.1, -1.0) == 0.0, "a negative delta moves nothing")
	_sections += 1


func _fov() -> void:
	var c := GSCameraConfig.new()
	_check(is_equal_approx(GSCameraFov.target(c, 0.0), 75.0), "at rest the base fov")
	_check(is_equal_approx(GSCameraFov.target(c, 9.0), 83.0), "at full speed the add")
	_check(is_equal_approx(GSCameraFov.target(c, 4.5), 79.0), "half speed adds half")
	_check(is_equal_approx(GSCameraFov.target(c, 90.0), 83.0), "more speed adds no more")
	_check(is_equal_approx(GSCameraFov.target(c, 0.0, true), 52.5), "aiming narrows")
	c.fov_aim_scale = 0.2
	_check(is_equal_approx(GSCameraFov.target(c, 0.0, true), 30.0), "the lower clamp holds")
	c.fov_max = 0.0
	c.fov_speed_add = 200.0
	_check(GSCameraFov.target(c, 9.0) > 200.0, "fov_max 0 leaves the top open")
	c.enabled = false
	_check(is_equal_approx(GSCameraFov.target(c, 9.0), c.fov), "disabled returns the base")
	var h := GSCameraFov.to_horizontal(60.0, 16.0 / 9.0)
	_check(absf(h - 91.49) < 0.05, "60 vertical at 16:9 is about 91.5 horizontal", str(h))
	_check(absf(GSCameraFov.to_vertical(h, 16.0 / 9.0) - 60.0) < 0.001, "and back")
	_sections += 1


func _orbit() -> void:
	var c := GSCameraConfig.new()
	var o := GSCameraOrbit.from_config(c)
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
	var p := GSCameraOrbit.from_config(c)
	p.distance = 4.0
	c.shoulder = 1.0
	_check(p.offset(c).is_equal_approx(Vector3(1, 0, 4)), "the shoulder shifts it sideways")
	_check(p.transform_at(c, Vector3(0, 2, 0)).origin.is_equal_approx(Vector3(1, 2, 4)), "the transform sits at pivot plus offset")
	c.shake_scale = 0.0
	_check(GSCameraOrbit.shake_offset(c, Vector3.ONE) == Vector3.ZERO, "shake scale 0 silences it")
	_sections += 1



func _check(ok: bool, what: String, extra: String = "") -> void:
	if ok:
		_passed += 1
		print("  ok    ", what)
	else:
		_failed += 1
		print("  FAIL  ", what, "  ", extra)


func _free_look() -> void:
	var c := GSCameraConfig.new()
	var f := GSCameraFreeLook.new()
	f.look(Vector2(0.0, 10.0))
	_check(is_equal_approx(f.pitch, GSCameraFreeLook.MAX_PITCH), "pitch stops short of straight up")
	f.look(Vector2(0.0, -20.0))
	_check(is_equal_approx(f.pitch, -GSCameraFreeLook.MAX_PITCH), "and short of straight down")
	f.look(Vector2(7.0, 0.0))
	_check(absf(f.yaw) <= PI, "yaw wraps instead of growing without bound")
	f = GSCameraFreeLook.new()
	var t := f.step(c, Vector3(0, 0, 1), false, false, 1.0)
	_check(t.origin.is_equal_approx(Vector3(0, 0, -c.free_speed)), "forward is along the view, which is -Z at rest")
	f = GSCameraFreeLook.new()
	f.step(c, Vector3(0, 1, 0), false, false, 1.0)
	_check(is_equal_approx(f.position.y, c.free_speed), "up is world up")
	f = GSCameraFreeLook.new()
	f.step(c, Vector3(1, 0, 1), false, false, 1.0)
	_check(is_equal_approx(f.position.length(), c.free_speed), "a diagonal is no faster than a straight line")
	f = GSCameraFreeLook.new()
	f.step(c, Vector3(1, 0, 0), true, false, 1.0)
	var fast := f.position.length()
	f = GSCameraFreeLook.new()
	f.step(c, Vector3(1, 0, 0), false, true, 1.0)
	_check(fast > f.position.length() * 10.0, "fast outruns slow")
	f = GSCameraFreeLook.new()
	f.seed_from(Transform3D(Basis.from_euler(Vector3(0.3, 1.0, 0.0), EULER_ORDER_YXZ), Vector3(1, 2, 3)))
	_check(is_equal_approx(f.yaw, 1.0) and is_equal_approx(f.pitch, 0.3) and f.position == Vector3(1, 2, 3), "seed_from reads back an existing camera")
	c.free_speed = 0.0
	_check(not c.validate().ok, "a free speed of 0 is refused")
	_sections += 1


func _zoom_2d() -> void:
	var c := GSCameraConfig.new()
	_check(is_equal_approx(GSCameraZoom2D.zoom_for(c, c.zoom_2d_reference), 1.0), "the reference radius is zoom 1")
	_check(GSCameraZoom2D.zoom_for(c, 4.0 * c.zoom_2d_reference) < 1.0, "a bigger target zooms out")
	_check(GSCameraZoom2D.zoom_for(c, 1.0e9) == c.zoom_2d_min, "zoom floors at zoom_2d_min")
	_check(GSCameraZoom2D.zoom_for(c, 0.01) == c.zoom_2d_max, "and caps at zoom_2d_max")
	c.zoom_2d_max = 0.0
	_check(GSCameraZoom2D.zoom_for(c, 0.01) > 2.0, "zoom_2d_max 0 is no cap")
	c.zoom_2d_reference = 0.0
	_check(GSCameraZoom2D.zoom_for(c, 50.0, 1.5) == 1.5, "a reference of 0 leaves the base zoom alone")
	c = GSCameraConfig.new()
	_check(GSCameraZoom2D.follow(c, Vector2.ZERO, Vector2(10, 0), 1.0).x > 9.9, "follow converges")
	c.follow_2d_half_life = 0.0
	_check(GSCameraZoom2D.follow(c, Vector2.ZERO, Vector2(10, 0), 0.016) == Vector2(10, 0), "a half life of 0 snaps")
	var half := GSCameraZoom2D.half_extent(Vector2(800, 600), 2.0)
	_check(half == Vector2(200, 150), "half extent is half the viewport over the zoom")
	_check(GSCameraZoom2D.half_extent(Vector2(800, 600), 0.0).is_finite(), "a zero zoom does not divide by zero")
	var bounds := Rect2(0, 0, 1000, 1000)
	_check(GSCameraZoom2D.clamp_centre(Vector2(-50, 1200), half, bounds) == Vector2(200, 850), "the view stays inside the arena")
	_check(GSCameraZoom2D.clamp_centre(Vector2(5, 5), Vector2(800, 800), bounds) == Vector2(500, 500), "a view wider than the arena is centred")
	_check(GSCameraZoom2D.clamp_centre(Vector2(-50, 7), half, Rect2()) == Vector2(-50, 7), "empty bounds do not clamp")
	_sections += 1
