# GameSpice Camera

Shared camera rules: smoothing, field of view, orbit maths. Read the family [CLAUDE.md](../../CLAUDE.md) first. **The distributable is `addons/dot_camera/`**; it requires [GameSpice Core](../dot-core) only (`ln -s ../../dot-core/addons/dot_core addons/dot_core`, gitignored).

| Path | What |
| --- | --- |
| `core/dot_camera_config.gd` | `GSCameraConfig`: every tunable, `from_files()` |
| `core/dot_camera_smoothing.gd` | `GSCameraSmoothing`: half-life damping, frame-rate independent |
| `core/dot_camera_fov.gd` | `GSCameraFov`: speed widening, aim zoom, clamps, vertical/horizontal conversion |
| `core/dot_camera_free_look.gd`, `core/dot_camera_zoom_2d.gd` | `GSCameraFreeLook` (roam yaw, pitch, speed) and `GSCameraZoom2D` (follow, size zoom, arena clamp), both pure |
| `core/dot_camera_orbit.gd` | `GSCameraOrbit`: yaw, pitch, distance, shoulder, shake scaling |
| `examples/camera_selftest.tscn` | the headless suite |

- **Boundaries.** GameSpice Core already has `camera/` (`GSCameraBoom`, `GSCameraProbe`, `GSCameraFade`, `GSCameraCheck`, `GSCameraTool`): the collision-aware spring arm lives there, extend it, never rebuild it. Also owned elsewhere: look accumulation and the fp/tp rigs (`GSTpsCameraRig`, GameSpice Player Controller), shake values (`GSFxShake`, GameSpice FX), observer modes (GameSpice Spectate), seats (GameSpice Vehicle).
- **Name collisions.** Every `GSCamera*` name in Core is taken; this addon's are `GSCameraConfig`, `GSCameraSmoothing`, `GSCameraFov`, `GSCameraOrbit`. Check Core before adding another.
- **Pure functions.** Nothing here owns a `Camera3D`; a rig calls these each frame. The next slices (rig nodes for first person, third person and spectator, built on `GSCameraBoom`) go in `runtime/`.
- **No hard caps.** `fov_max` and `distance_max` 0 are unlimited; a bad config fails `validate()` loudly.
- **Validate**: `--import`, parse every `.gd`, run the suite.
