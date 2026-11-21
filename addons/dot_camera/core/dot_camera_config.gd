class_name GSCameraConfig
extends GSConfig

## Every tunable of the camera rules. A game binds it with GSGameConfigBinder (kind `camera`) for cvars and the workbench; `cfg/addon/dot_camera/*.yml`, `DOT_CAMERA_*` and `--camera-*` layer over these defaults.

const ADDON := "dot-camera"
const MODE_FIRST := 0
const MODE_THIRD := 1
const MODE_ORBIT := 2
const MODE_SPECTATOR := 3

## Master switch: off, the rules return the base field of view and no smoothing.
@export var enabled: bool = true
## 0 first person, 1 third person, 2 orbit, 3 spectator.
@export_range(0, 3, 1) var mode: int = MODE_FIRST

@export_group("Field of view")
## Vertical field of view in degrees at rest.
@export_range(30.0, 140.0, 0.5) var fov: float = 75.0
## Degrees added at [member fov_speed_full] and over, scaled in between; 0 is a fixed field of view.
@export_range(0.0, 40.0, 0.5) var fov_speed_add: float = 8.0
## Speed in metres per second at which [member fov_speed_add] is fully applied.
@export_range(0.5, 100.0, 0.5) var fov_speed_full: float = 9.0
## Multiplier while aiming down sights or zooming; under 1 narrows.
@export_range(0.1, 2.0, 0.01) var fov_aim_scale: float = 0.7
## Lowest field of view the rules return.
@export_range(1.0, 120.0, 0.5) var fov_min: float = 30.0
## Highest field of view the rules return; 0 is no upper clamp.
@export_range(0.0, 179.0, 0.5) var fov_max: float = 120.0

@export_group("Smoothing")
## Seconds for the camera to cover half the distance to where it wants to be; 0 follows exactly.
@export_range(0.0, 2.0, 0.005) var position_half_life: float = 0.06
## The same for rotation; 0 follows exactly, which is what a mouse look wants.
@export_range(0.0, 2.0, 0.005) var rotation_half_life: float = 0.0

@export_group("Orbit")
## Metres behind the pivot.
@export_range(0.0, 50.0, 0.1) var distance: float = 3.5
## Closest the zoom may bring the camera.
@export_range(0.0, 50.0, 0.1) var distance_min: float = 0.8
## Furthest the zoom may take the camera; 0 is no limit.
@export_range(0.0, 100.0, 0.1) var distance_max: float = 8.0
## Lowest pitch in degrees (looking down is negative).
@export_range(-89.0, 0.0, 1.0) var pitch_min: float = -80.0
## Highest pitch in degrees.
@export_range(0.0, 89.0, 1.0) var pitch_max: float = 80.0
## Sideways offset of the camera in metres, positive to the right (a shoulder).
@export_range(-3.0, 3.0, 0.05) var shoulder: float = 0.0

@export_group("Free look")
## Metres per second of a roaming camera.
@export_range(0.1, 200.0, 0.1) var free_speed: float = 8.0
## Multiplier while the fast key is held.
@export_range(1.0, 20.0, 0.1) var free_fast_scale: float = 3.0
## Multiplier while the slow key is held; under 1 is slower.
@export_range(0.01, 1.0, 0.01) var free_slow_scale: float = 0.25

@export_group("Follow 2D")
## Seconds for a 2D camera to cover half the distance to its target; 0 snaps.
@export_range(0.0, 2.0, 0.01) var follow_2d_half_life: float = 0.08
## Radius at which the 2D zoom is exactly 1; 0 turns size-based zoom off.
@export_range(0.0, 1000.0, 1.0) var zoom_2d_reference: float = 32.0
## Zoom falls as radius to this power; 0.5 keeps the share of the screen the target fills about constant.
@export_range(0.0, 1.5, 0.05) var zoom_2d_exponent: float = 0.5
## Lowest 2D zoom.
@export_range(0.05, 8.0, 0.01) var zoom_2d_min: float = 0.18
## Highest 2D zoom; 0 is no upper clamp.
@export_range(0.0, 8.0, 0.01) var zoom_2d_max: float = 2.0

@export_group("Shake")
## Scales the offsets GameSpice FX computes before they are applied; 0 turns shake off for comfort.
@export_range(0.0, 2.0, 0.05) var shake_scale: float = 1.0


func env_prefix() -> String:
	return "DOT_CAMERA_"


func cli_prefix() -> String:
	return "--camera-"


func validate() -> GSResult:
	if mode < MODE_FIRST or mode > MODE_SPECTATOR:
		return GSResult.fail(GSError.CODE_INVALID, "camera mode %d is not 0 to 3" % mode)
	if fov <= 0.0 or fov >= 180.0:
		return GSResult.fail(GSError.CODE_INVALID, "camera fov %.1f must be between 0 and 180" % fov)
	if fov_max > 0.0 and fov_max < fov_min:
		return GSResult.fail(GSError.CODE_INVALID, "camera fov_max %.1f is under fov_min %.1f (0 is no upper clamp)" % [fov_max, fov_min])
	if position_half_life < 0.0 or rotation_half_life < 0.0:
		return GSResult.fail(GSError.CODE_INVALID, "camera half lives cannot be negative (0 follows exactly)")
	if distance_max > 0.0 and distance_max < distance_min:
		return GSResult.fail(GSError.CODE_INVALID, "camera distance_max %.1f is under distance_min %.1f (0 is no limit)" % [distance_max, distance_min])
	if pitch_min >= pitch_max:
		return GSResult.fail(GSError.CODE_INVALID, "camera pitch_min %.0f must be under pitch_max %.0f" % [pitch_min, pitch_max])
	if shake_scale < 0.0:
		return GSResult.fail(GSError.CODE_INVALID, "camera shake_scale cannot be negative (0 is off)")
	if free_speed <= 0.0 or free_fast_scale <= 0.0 or free_slow_scale <= 0.0:
		return GSResult.fail(GSError.CODE_INVALID, "camera free_speed and its fast and slow scales must be above 0")
	if follow_2d_half_life < 0.0 or zoom_2d_reference < 0.0 or zoom_2d_exponent < 0.0:
		return GSResult.fail(GSError.CODE_INVALID, "camera 2D half life, reference and exponent cannot be negative")
	if zoom_2d_min <= 0.0 or (zoom_2d_max > 0.0 and zoom_2d_max < zoom_2d_min):
		return GSResult.fail(GSError.CODE_INVALID, "camera zoom_2d_min must be above 0 and zoom_2d_max not under it (0 is no upper clamp)")
	return GSResult.success(self)


## Defaults, then `cfg/addon/dot_camera/*.yml` and the game tier, then environment and command line.
static func from_files() -> GSResult:
	var cfg := GSCameraConfig.new()
	var files := GSAddonConfig.load_dir(ADDON)
	if not files.ok:
		return files
	cfg.apply_dictionary(files.value as Dictionary, "yml")
	return cfg.load_layered()


func describe() -> String:
	return "camera %s mode %d fov %.0f (+%.0f at %.0f m/s, aim x%.2f) smoothing %.3f/%.3f orbit %.1f m shake x%.2f" % [
		"on" if enabled else "disabled", mode, fov, fov_speed_add, fov_speed_full, fov_aim_scale, position_half_life, rotation_half_life, distance, shake_scale]
