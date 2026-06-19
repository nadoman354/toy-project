extends Node2D
class_name GameWorld2D

var game: Node = null

func setup(game_root: Node) -> void:
	game = game_root
	set_process(false)

func _draw() -> void:
	if game == null or game.state.is_empty():
		return

	var size = get_viewport_rect().size
	var player = game.state.player
	var camera = Vector2(player.position.x - size.x * 0.5, player.position.y - size.y * 0.5)

	_draw_background(size, camera)
	_draw_fields(camera)
	_draw_pickups(camera)
	_draw_mines(camera)
	_draw_turrets(camera)
	_draw_projectiles(camera)
	_draw_enemies(camera)
	_draw_attacks(camera)
	_draw_player(camera)
	_draw_float_texts(camera)

	if game.state.paused and not game.state.game_over:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.26), true)

func _world_to_screen(point: Vector2, camera: Vector2) -> Vector2:
	return point - camera

func _draw_background(size: Vector2, camera: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#101720"), true)
	var grid_color = Color(0.24, 0.34, 0.44, 0.16)
	var major_color = Color(0.32, 0.48, 0.58, 0.22)
	var step = 48.0
	var start_x = -fmod(camera.x, step)
	var start_y = -fmod(camera.y, step)
	var x = start_x
	while x < size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), major_color if abs(fmod(camera.x + x, step * 4.0)) < 1.0 else grid_color, 1.0)
		x += step
	var y = start_y
	while y < size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), major_color if abs(fmod(camera.y + y, step * 4.0)) < 1.0 else grid_color, 1.0)
		y += step

	var origin = _world_to_screen(Vector2.ZERO, camera)
	draw_circle(origin, 80.0, Color(0.2, 0.32, 0.42, 0.12))
	draw_arc(origin, 80.0, 0.0, TAU, 96, Color(0.45, 0.72, 0.86, 0.25), 2.0)

func _draw_player(camera: Vector2) -> void:
	var player = game.state.player
	var pos = _world_to_screen(player.position, camera)
	var pulse = 0.0
	if player.hit_flash > 0.0:
		pulse = sin(Time.get_ticks_msec() * 0.04) * 0.18 + 0.2
	draw_circle(pos, player.radius + 8.0, Color(0.28, 0.84, 0.59, 0.18 + pulse))
	draw_circle(pos, player.radius, Color("#48d597"))
	draw_arc(pos, player.radius + 3.0, 0.0, TAU, 36, Color("#edf2f7"), 2.0)
	var dir = game.state.last_move_dir
	draw_line(pos, pos + dir * 22.0, Color("#edf2f7"), 3.0)

func _draw_enemies(camera: Vector2) -> void:
	for enemy in game.state.enemies:
		var pos = _world_to_screen(enemy.position, camera)
		var color = Color("#ff5964") if enemy.type != "boss" else Color("#d26bff")
		var outline = Color("#3a1219") if enemy.type != "boss" else Color("#2b1438")
		draw_circle(pos, enemy.radius + 3.0, outline)
		draw_circle(pos, enemy.radius, color)
		var ratio = clamp(enemy.hp / max(enemy.max_hp, 1.0), 0.0, 1.0)
		var bar = Rect2(pos + Vector2(-enemy.radius, -enemy.radius - 11.0), Vector2(enemy.radius * 2.0, 4.0))
		draw_rect(bar, Color(0, 0, 0, 0.55), true)
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), Color("#f3c84b") if enemy.type == "boss" else Color("#48d597"), true)

func _draw_projectiles(camera: Vector2) -> void:
	for projectile in game.state.projectiles:
		var pos = _world_to_screen(projectile.position, camera)
		if projectile.kind == "laser":
			var end_pos = _world_to_screen(projectile.end_position, camera)
			draw_line(pos, end_pos, Color(0.55, 0.8, 1.0, 0.28), projectile.width + 8.0)
			draw_line(pos, end_pos, Color("#9ee9ff"), projectile.width)
		else:
			draw_circle(pos, projectile.radius + 3.0, Color(0.4, 0.8, 1.0, 0.18))
			draw_circle(pos, projectile.radius, Color("#4aa8ff"))

func _draw_mines(camera: Vector2) -> void:
	for mine in game.state.mines:
		var pos = _world_to_screen(mine.position, camera)
		var ratio = clamp(mine.life / max(mine.max_life, 0.1), 0.0, 1.0)
		draw_circle(pos, 12.0, Color(0.95, 0.55, 0.1, 0.22))
		draw_circle(pos, 7.0, Color("#ff9f43"))
		draw_arc(pos, 16.0, -PI * 0.5, -PI * 0.5 + TAU * ratio, 28, Color("#f3c84b"), 2.0)

func _draw_turrets(camera: Vector2) -> void:
	for turret in game.state.turrets:
		var pos = _world_to_screen(turret.position, camera)
		draw_circle(pos, 12.0, Color("#273244"))
		draw_circle(pos, 8.0, Color("#9ee9ff"))
		draw_arc(pos, turret.range, 0.0, TAU, 48, Color(0.56, 0.82, 1.0, 0.12), 1.0)

func _draw_fields(camera: Vector2) -> void:
	for field in game.state.fields:
		var pos = _world_to_screen(field.position, camera)
		var ratio = clamp(field.life / max(field.max_life, 0.1), 0.0, 1.0)
		draw_circle(pos, field.radius, Color(0.42, 0.85, 0.55, 0.12 * ratio))
		draw_arc(pos, field.radius, 0.0, TAU, 64, Color(0.42, 0.85, 0.55, 0.32 * ratio), 2.0)

func _draw_pickups(camera: Vector2) -> void:
	for pickup in game.state.pickups:
		var pos = _world_to_screen(pickup.position, camera)
		var color = Color("#f3c84b")
		if pickup.kind == "xp":
			color = Color("#4aa8ff")
		elif pickup.kind == "heal":
			color = Color("#48d597")
		elif pickup.kind == "magnet":
			color = Color("#d26bff")
		draw_circle(pos, 6.0, Color(color, 0.22))
		draw_circle(pos, 3.5, color)

func _draw_attacks(camera: Vector2) -> void:
	for attack in game.state.attacks:
		var pos = _world_to_screen(attack.position, camera)
		var alpha = clamp(attack.life / max(attack.max_life, 0.1), 0.0, 1.0)
		if attack.kind == "circle":
			draw_circle(pos, attack.radius, Color(0.28, 0.84, 0.59, 0.12 * alpha))
			draw_arc(pos, attack.radius, 0.0, TAU, 64, Color(0.74, 1.0, 0.84, 0.6 * alpha), 3.0)
		elif attack.kind == "slash":
			var end_pos = _world_to_screen(attack.end_position, camera)
			draw_line(pos, end_pos, Color(1.0, 1.0, 1.0, 0.55 * alpha), attack.width)
			draw_line(pos, end_pos, Color(0.28, 0.84, 0.59, 0.72 * alpha), max(2.0, attack.width * 0.35))
		elif attack.kind == "explosion":
			draw_circle(pos, attack.radius, Color(1.0, 0.45, 0.25, 0.15 * alpha))
			draw_arc(pos, attack.radius, 0.0, TAU, 72, Color(1.0, 0.68, 0.2, 0.75 * alpha), 4.0)

func _draw_float_texts(camera: Vector2) -> void:
	var font = ThemeDB.fallback_font
	for text in game.state.float_texts:
		var pos = _world_to_screen(text.position, camera)
		var alpha = clamp(text.life / max(text.max_life, 0.1), 0.0, 1.0)
		draw_string(font, pos, text.text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, 14, Color(text.color, alpha))

