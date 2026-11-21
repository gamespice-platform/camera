class_name DotCameraConfig
extends DotConfig

## Every tunable of the camera rules. A game binds it with DotGameConfigBinder (kind `camera`) for cvars and the workbench; `cfg/addon/dot_camera/*.yml`, `DOT_CAMERA_*` and `--camera-*` layer over these defaults.

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

@export_group("Shake")
## Scales the offsets GameSpice FX computes before they are applied; 0 turns shake off for comfort.
@export_range(0.0, 2.0, 0.05) var shake_scale: float = 1.0


func env_prefix() -> String:
	return "DOT_CAMERA_"


func cli_prefix() -> String:
	return "--camera-"


func validate() -> DotResult:
	if mode < MODE_FIRST or mode > MODE_SPECTATOR:
		return DotResult.fail(DotError.CODE_INVALID, "camera mode %d is not 0 to 3" % mode)
	if fov <= 0.0 or fov >= 180.0:
		return DotResult.fail(DotError.CODE_INVALID, "camera fov %.1f must be between 0 and 180" % fov)
	if fov_max > 0.0 and fov_max < fov_min:
		return DotResult.fail(DotError.CODE_INVALID, "camera fov_max %.1f is under fov_min %.1f (0 is no upper clamp)" % [fov_max, fov_min])
	if position_half_life < 0.0 or rotation_half_life < 0.0:
		return DotResult.fail(DotError.CODE_INVALID, "camera half lives cannot be negative (0 follows exactly)")
	if distance_max > 0.0 and distance_max < distance_min:
		return DotResult.fail(DotError.CODE_INVALID, "camera distance_max %.1f is under distance_min %.1f (0 is no limit)" % [distance_max, distance_min])
	if pitch_min >= pitch_max:
		return DotResult.fail(DotError.CODE_INVALID, "camera pitch_min %.0f must be under pitch_max %.0f" % [pitch_min, pitch_max])
	if shake_scale < 0.0:
		return DotResult.fail(DotError.CODE_INVALID, "camera shake_scale cannot be negative (0 is off)")
	return DotResult.success(self)


## Defaults, then `cfg/addon/dot_camera/*.yml` and the game tier, then environment and command line.
static func from_files() -> DotResult:
	var cfg := DotCameraConfig.new()
	var files := DotAddonConfig.load_dir(ADDON)
	if not files.ok:
		return files
	cfg.apply_dictionary(files.value as Dictionary, "yml")
	return cfg.load_layered()


func describe() -> String:
	return "camera %s mode %d fov %.0f (+%.0f at %.0f m/s, aim x%.2f) smoothing %.3f/%.3f orbit %.1f m shake x%.2f" % [
		"on" if enabled else "disabled", mode, fov, fov_speed_add, fov_speed_full, fov_aim_scale, position_half_life, rotation_half_life, distance, shake_scale]
