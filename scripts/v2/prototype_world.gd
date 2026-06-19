extends Node2D
class_name PrototypeWorld

var game = null

func setup(game_root) -> void:
	game = game_root
	z_index = 0

func _draw() -> void:
	if game == null or game.state.is_empty():
		return
	var viewport = get_viewport_rect().size
	var camera = game.camera_position()
	_draw_background(viewport, camera)
	_draw_fields(camera)
	_draw_pickups(camera)
	_draw_mines(camera)
	_draw_turrets(camera)
	_draw_projectiles(camera)
	_draw_charge_casts(camera)
	_draw_enemies(camera)
	_draw_resident_programs(camera)
	_draw_player(camera)
	_draw_attacks(camera)
	_draw_particles(camera)
	_draw_float_texts(camera)
	if game.state.paused and not game.state.gameOver:
		_draw_paused(viewport)

func world_to_screen(point: Vector2, camera: Vector2) -> Vector2:
	return point - camera

func _draw_background(size: Vector2, camera: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#101720"), true)
	var center = size * 0.5
	draw_circle(center, min(size.x, size.y) * 0.5, Color(0.08, 0.13, 0.18, 0.45))
	var step = 48.0
	var x = -fmod(camera.x, step)
	while x < size.x:
		var world_x = camera.x + x
		var color = Color(0.27, 0.38, 0.48, 0.18)
		if abs(fmod(world_x, step * 4.0)) < 1.0:
			color = Color(0.38, 0.58, 0.68, 0.26)
		draw_line(Vector2(x, 0), Vector2(x, size.y), color, 1.0)
		x += step
	var y = -fmod(camera.y, step)
	while y < size.y:
		var world_y = camera.y + y
		var color = Color(0.27, 0.38, 0.48, 0.18)
		if abs(fmod(world_y, step * 4.0)) < 1.0:
			color = Color(0.38, 0.58, 0.68, 0.26)
		draw_line(Vector2(0, y), Vector2(size.x, y), color, 1.0)
		y += step
	var origin = world_to_screen(Vector2.ZERO, camera)
	draw_circle(origin, 92, Color(0.16, 0.27, 0.34, 0.18))
	draw_arc(origin, 92, 0.0, TAU, 96, Color(0.46, 0.74, 0.86, 0.24), 2.0)

func _draw_player(camera: Vector2) -> void:
	var player = game.state.player
	var pos = world_to_screen(player.position, camera)
	var flash = clamp(float(player.hitFlash) * 3.0, 0.0, 1.0)
	draw_circle(pos, player.radius + 10.0, Color(0.28, 0.84, 0.59, 0.18 + flash * 0.18))
	draw_circle(pos, player.radius + 3.0, Color("#edf2f7"))
	draw_circle(pos, player.radius, Color("#48d597"))
	draw_line(pos, pos + game.state.lastMoveDir * 24.0, Color("#0b0f16"), 4.0)
	var hp_ratio = clamp(float(player.hp) / max(float(player.maxHP), 1.0), 0.0, 1.0)
	var bar = Rect2(pos + Vector2(-28, 22), Vector2(56, 5))
	draw_rect(bar, Color(0, 0, 0, 0.55), true)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * hp_ratio, bar.size.y)), Color("#48d597"), true)

func _draw_enemies(camera: Vector2) -> void:
	for enemy in game.state.enemies:
		var pos = world_to_screen(enemy.position, camera)
		var is_boss = enemy.get("type", "normal") == "boss"
		var color = Color("#d26bff") if is_boss else Color("#ff5964")
		var edge = Color(0.1, 0.02, 0.05, 0.9) if not is_boss else Color(0.18, 0.06, 0.24, 0.95)
		draw_circle(pos, enemy.radius + 3.0, edge)
		draw_circle(pos, enemy.radius, color)
		if is_boss:
			draw_arc(pos, enemy.radius + 8.0, 0.0, TAU, 72, Color("#f3c84b"), 3.0)
		var ratio = clamp(float(enemy.hp) / max(float(enemy.maxHP), 1.0), 0.0, 1.0)
		var bar = Rect2(pos + Vector2(-enemy.radius, -enemy.radius - 11.0), Vector2(enemy.radius * 2.0, 4.0))
		draw_rect(bar, Color(0, 0, 0, 0.55), true)
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), Color("#f3c84b") if is_boss else Color("#48d597"), true)

func _draw_pickups(camera: Vector2) -> void:
	for pickup in game.state.pickups:
		var pos = world_to_screen(pickup.position, camera)
		var color = Color("#f3c84b")
		if pickup.kind == "xp":
			color = Color("#4aa8ff")
		elif pickup.kind == "heal":
			color = Color("#48d597")
		elif pickup.kind == "magnet":
			color = Color("#d26bff")
		draw_circle(pos, 7.0, Color(color, 0.25))
		draw_circle(pos, 4.0, color)

func _draw_projectiles(camera: Vector2) -> void:
	for projectile in game.state.projectiles:
		if projectile.get("kind", "projectile") == "laser":
			var start = world_to_screen(projectile.position, camera)
			var end = world_to_screen(projectile.endPosition, camera)
			draw_line(start, end, Color(0.48, 0.86, 1.0, 0.22), projectile.width + 10.0)
			draw_line(start, end, Color("#9ee9ff"), projectile.width)
		else:
			var pos = world_to_screen(projectile.position, camera)
			var color = Color("#4aa8ff") if not projectile.get("swordWave", false) else Color("#b7fff0")
			draw_circle(pos, projectile.radius + 3.0, Color(color, 0.2))
			draw_circle(pos, projectile.radius, color)

func _draw_mines(camera: Vector2) -> void:
	for mine in game.state.mines:
		var pos = world_to_screen(mine.position, camera)
		var ratio = clamp(float(mine.life) / max(float(mine.maxLife), 0.1), 0.0, 1.0)
		var mine_color = Color("#b779ff") if mine.get("maturity", false) else Color("#ff9f43")
		draw_circle(pos, mine.triggerRadius, Color(mine_color, 0.10))
		draw_circle(pos, 8.0, mine_color)
		draw_arc(pos, 16.0, -PI * 0.5, -PI * 0.5 + TAU * ratio, 36, Color("#f3c84b"), 2.0)

func _draw_turrets(camera: Vector2) -> void:
	for turret in game.state.turrets:
		var pos = world_to_screen(turret.position, camera)
		draw_arc(pos, turret.range, 0, TAU, 64, Color(0.55, 0.82, 1.0, 0.12), 1.0)
		draw_circle(pos, 13.0, Color("#273244"))
		draw_circle(pos, 8.0, Color("#9ee9ff"))

func _draw_fields(camera: Vector2) -> void:
	for field in game.state.fields:
		var pos = world_to_screen(field.position, camera)
		var ratio = clamp(float(field.life) / max(float(field.maxLife), 0.1), 0.0, 1.0)
		draw_circle(pos, field.radius, Color(0.38, 0.86, 0.55, 0.12 * ratio))
		draw_arc(pos, field.radius, 0, TAU, 72, Color(0.38, 0.86, 0.55, 0.45 * ratio), 2.0)

func _draw_charge_casts(camera: Vector2) -> void:
	for cast in game.state.chargeCasts:
		var ratio = clamp(float(cast.elapsed) / max(float(cast.duration), 0.1), 0.0, 1.0)
		var pos = world_to_screen(cast.origin, camera)
		draw_circle(pos, lerp(20.0, cast.radius, ratio), Color(0.56, 0.78, 1.0, 0.13))
		draw_arc(pos, lerp(20.0, cast.radius, ratio), 0, TAU * ratio, 72, Color("#9ee9ff"), 3.0)

func _draw_resident_programs(camera: Vector2) -> void:
	var player_pos = world_to_screen(game.state.player.position, camera)
	for index in range(game.state.residentPrograms.size()):
		var program = game.state.residentPrograms[index]
		var angle = float(program.get("angle", float(Time.get_ticks_msec()) * 0.0012 + index * TAU / max(game.state.residentPrograms.size(), 1)))
		var radius = float(program.def.get("orbitRadius", 58))
		var pos = player_pos + Vector2(cos(angle), sin(angle)) * radius
		draw_circle(pos, 7.0, Color("#101720"))
		draw_circle(pos, 4.5, Color("#48d597") if not program.get("suspended", false) else Color("#9aa8ba"))

func _draw_attacks(camera: Vector2) -> void:
	for attack in game.state.attacks:
		var alpha = clamp(float(attack.life) / max(float(attack.maxLife), 0.1), 0.0, 1.0)
		var pos = world_to_screen(attack.position, camera)
		match attack.kind:
			"circle":
				var circle_color = attack.get("color", Color(0.28, 0.84, 0.59))
				draw_circle(pos, attack.radius, Color(circle_color, 0.12 * alpha))
				draw_arc(pos, attack.radius, 0, TAU, 72, Color(circle_color.lightened(0.55), 0.65 * alpha), 3.0)
			"slash":
				var end = world_to_screen(attack.endPosition, camera)
				draw_line(pos, end, Color(1.0, 1.0, 1.0, 0.6 * alpha), attack.width)
				draw_line(pos, end, Color(0.28, 0.84, 0.59, 0.85 * alpha), max(2.0, attack.width * 0.32))
			"arc":
				draw_arc(pos, attack.radius, attack.startAngle, attack.endAngle, 48, Color(0.88, 1.0, 0.82, 0.8 * alpha), attack.width)
			"explosion":
				draw_circle(pos, attack.radius, Color(1.0, 0.48, 0.18, 0.14 * alpha))
				var explosion_color = Color("#ff9f43")
				explosion_color.a = 0.9 * alpha
				draw_arc(pos, attack.radius, 0, TAU, 72, explosion_color, 4.0)

func _draw_particles(camera: Vector2) -> void:
	for particle in game.state.particles:
		var pos = world_to_screen(particle.position, camera)
		var particle_color = particle.color
		particle_color.a = clamp(particle.life / particle.maxLife, 0.0, 1.0)
		draw_circle(pos, particle.radius, particle_color)

func _draw_float_texts(camera: Vector2) -> void:
	var font = ThemeDB.fallback_font
	for text in game.state.floatTexts:
		var pos = world_to_screen(text.position, camera)
		var alpha = clamp(float(text.life) / max(float(text.maxLife), 0.1), 0.0, 1.0)
		draw_string(font, pos, text.text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, text.get("size", 14), Color(text.color, alpha))

func _draw_paused(size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.24), true)
	if game.is_selecting():
		return
	var font = ThemeDB.fallback_font
	draw_string(font, size * 0.5 + Vector2(-60, 0), "PAUSED", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#edf2f7"))
