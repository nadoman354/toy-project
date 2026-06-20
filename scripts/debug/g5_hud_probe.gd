extends Node

const MainScene = preload("res://scenes/main/Main.tscn")
const HtmlLayoutMetrics = preload("res://scripts/ui/html_layout_metrics.gd")

var game
var failures: Array = []

func _ready() -> void:
	game = MainScene.instantiate()
	add_child(game)
	while game.state.is_empty():
		await get_tree().process_frame
	await get_tree().process_frame
	for viewport_size in [Vector2i(960, 540), Vector2i(1152, 648)]:
		await _verify_desktop_hud(viewport_size)
	if failures.is_empty():
		print("g5_hud_probe passed")
		get_tree().quit()
		return
	for failure in failures:
		push_error(str(failure))
	get_tree().quit(1)

func _verify_desktop_hud(viewport_size: Vector2i) -> void:
	get_window().size = viewport_size
	await get_tree().process_frame
	await get_tree().process_frame
	var viewport = Vector2(viewport_size.x, viewport_size.y)
	game.hud.update_from_state(game.state)
	_expect_control_rect("%s combatHud" % str(viewport_size), game.hud.ui.combatHud, HtmlLayoutMetrics.combat_hud_rect(viewport))
	_expect_control_rect("%s economyHud" % str(viewport_size), game.hud.ui.economyHud, HtmlLayoutMetrics.economy_hud_rect(viewport))
	_expect_control_rect("%s difficultyHud" % str(viewport_size), game.hud.ui.difficultyHud, HtmlLayoutMetrics.difficulty_hud_rect(viewport))
	_expect_control_rect("%s cleanupHud" % str(viewport_size), game.hud.ui.cleanupHud, HtmlLayoutMetrics.cleanup_hud_rect(viewport))
	_expect_control_rect("%s statusPanel" % str(viewport_size), game.hud.ui.statusPanel, HtmlLayoutMetrics.status_hud_rect(viewport))
	_expect_control_rect("%s debugPanel" % str(viewport_size), game.hud.ui.debugPanel, HtmlLayoutMetrics.debug_hud_rect(viewport))
	_expect_equal("%s combat top-left" % str(viewport_size), game.hud.ui.combatHud.position, Vector2(12, 12))
	_expect_equal("%s economy right margin" % str(viewport_size), round(viewport.x - game.hud.ui.economyHud.position.x - game.hud.ui.economyHud.size.x), 12.0)
	_expect_equal("%s status left margin" % str(viewport_size), game.hud.ui.statusPanel.position.x, 12.0)
	_expect_equal("%s debug right margin" % str(viewport_size), round(viewport.x - game.hud.ui.debugPanel.position.x - game.hud.ui.debugPanel.size.x), 12.0)
	_expect_equal("%s difficulty centered" % str(viewport_size), round(game.hud.ui.difficultyHud.position.x + game.hud.ui.difficultyHud.size.x * 0.5), round(viewport.x * 0.5))
	_expect_equal("%s hud root ignores mouse" % str(viewport_size), game.hud.ui.root.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	_expect_equal("%s combat pass-through" % str(viewport_size), game.hud.ui.combatHud.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	_expect_equal("%s economy pass-through" % str(viewport_size), game.hud.ui.economyHud.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	_expect_equal("%s status pass-through" % str(viewport_size), game.hud.ui.statusPanel.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	_expect_equal("%s debug panel receives controls" % str(viewport_size), game.hud.ui.debugPanel.mouse_filter, Control.MOUSE_FILTER_STOP)
	for key in ["combatHud", "economyHud", "statusPanel", "debugPanel"]:
		_expect_panel_style("%s %s style" % [str(viewport_size), key], game.hud.ui[key], 12, 8)

func _expect_panel_style(label: String, panel: Control, expected_margin: int, expected_radius: int) -> void:
	var style = panel.get_theme_stylebox("panel")
	if not style is StyleBoxFlat:
		failures.append("%s missing StyleBoxFlat" % label)
		return
	_expect_equal("%s margin left" % label, int(style.content_margin_left), expected_margin)
	_expect_equal("%s margin top" % label, int(style.content_margin_top), expected_margin)
	_expect_equal("%s margin right" % label, int(style.content_margin_right), expected_margin)
	_expect_equal("%s margin bottom" % label, int(style.content_margin_bottom), expected_margin)
	_expect_equal("%s radius" % label, style.corner_radius_top_left, expected_radius)

func _expect_control_rect(label: String, control: Control, expected: Rect2) -> void:
	if control == null:
		failures.append("%s missing" % label)
		return
	_expect_rect(label, Rect2(control.position, control.size), expected)

func _expect_rect(label: String, actual: Rect2, expected: Rect2) -> void:
	if not _pixel_close(actual.position.x, expected.position.x) or not _pixel_close(actual.position.y, expected.position.y) or not _pixel_close(actual.size.x, expected.size.x) or not _pixel_close(actual.size.y, expected.size.y):
		failures.append("%s expected %s got %s" % [label, str(expected), str(actual)])

func _expect_equal(label: String, actual, expected) -> void:
	if actual != expected:
		failures.append("%s expected %s got %s" % [label, str(expected), str(actual)])

func _pixel_close(a: float, b: float) -> bool:
	return abs(a - b) <= 0.51
