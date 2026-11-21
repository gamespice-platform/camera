# Rig maths

Everything here is pure: values in, values out, no nodes and no clock, so a game's own camera node applies the result.

- `DotCameraSmoothing`: frame-rate independent damping (a half life of 0 follows exactly).
- `DotCameraFov`: speed and aim field-of-view rules.
- `DotCameraOrbit`: yaw, pitch, distance, shoulder and shake scaling for third-person and orbit rigs.
- `DotCameraFreeLook`: a roaming camera for spectators, flythroughs and debug views. Pitch is held short of straight up, forward follows the view, up is world up, a diagonal is no faster.
- `DotCameraZoom2D`: follow, size-based zoom and arena clamp for a 2D camera. A view wider than the arena is centred.

## Where this came from

The roam and 2D maths are the generic part of the spectator free camera and the 2D camera rig in the game addons, which still carry their own copies; moving them onto these classes is tracked on the nightly board.
