class_name DotCameraZoom2D
extends RefCounted

## The three things a 2D follow camera must do and that interact: follow a target, zoom with its size, and stay inside the arena. Pure functions over values, so one implementation serves a Camera2D rig and a headless suite.
##
## Zooming out shows more world, which changes what "inside the arena" means, which changes how far the camera may follow.


## The zoom for a target of [param radius]: falls as radius to `zoom_2d_exponent`, clamped. A radius of 0 or a reference of 0 returns [param base_zoom].
static func zoom_for(cfg: DotCameraConfig, radius: float, base_zoom: float = 1.0) -> float:
	if cfg.zoom_2d_reference <= 0.0 or radius <= 0.0:
		return base_zoom
	var z := base_zoom * pow(cfg.zoom_2d_reference / maxf(0.001, radius), cfg.zoom_2d_exponent)
	z = maxf(z, cfg.zoom_2d_min)
	if cfg.zoom_2d_max > 0.0:
		z = minf(z, cfg.zoom_2d_max)
	return z


## Where a camera at [param current] ends up after [param delta] seconds chasing [param target].
static func follow(cfg: DotCameraConfig, current: Vector2, target: Vector2, delta: float) -> Vector2:
	return DotCameraSmoothing.damp_vec2(current, target, cfg.follow_2d_half_life, delta)


## Half the world area a view of [param viewport] pixels shows at [param zoom]. A zero zoom is clamped: the division otherwise gives an infinite rectangle.
static func half_extent(viewport: Vector2, zoom: float) -> Vector2:
	return viewport * 0.5 / maxf(absf(zoom), 0.001)


## [param centre] moved inside [param bounds]. A view wider than the world is centred on it instead of clamped to a negative range. Bounds of zero size leave the centre alone.
static func clamp_centre(centre: Vector2, half: Vector2, bounds: Rect2) -> Vector2:
	if bounds.size == Vector2.ZERO:
		return centre
	var lo := bounds.position + half
	var hi := bounds.end - half
	var mid := bounds.get_center()
	return Vector2(
		mid.x if lo.x > hi.x else clampf(centre.x, lo.x, hi.x),
		mid.y if lo.y > hi.y else clampf(centre.y, lo.y, hi.y))
