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
	_verify_placement_helpers()
	_verify_hud_constants()
	_verify_choice_constants()
	_verify_popup_size_table()
	await _verify_hud_callers_use_service(Vector2i(1920, 1080))
	await _verify_hud_callers_use_service(Vector2i(1152, 648))
	await _verify_choice_caller_uses_service(Vector2i(1920, 1080))
	if failures.is_empty():
		print("g3_layout_service_probe passed")
		get_tree().quit()
		return
	for failure in failures:
		push_error(str(failure))
	get_tree().quit(1)

func _verify_placement_helpers() -> void:
	var control = Control.new()
	HtmlLayoutMetrics.place_top_left(control, 12, 34, 100, 50)
	_expect_offsets("place_top_left", control, 0.0, 0.0, 0.0, 0.0, 12, 34, 112, 84)
	HtmlLayoutMetrics.place_top_right(control, 12, 34, 100, 50)
	_expect_offsets("place_top_right", control, 1.0, 1.0, 0.0, 0.0, -112, 34, -12, 84)
	HtmlLayoutMetrics.place_bottom_left(control, 12, 34, 100, 50)
	_expect_offsets("place_bottom_left", control, 0.0, 0.0, 1.0, 1.0, 12, -84, 112, -34)
	HtmlLayoutMetrics.place_bottom_right(control, 12, 34, 100, 50)
	_expect_offsets("place_bottom_right", control, 1.0, 1.0, 1.0, 1.0, -112, -84, -12, -34)
	HtmlLayoutMetrics.place_top_center(control, 34, 100, 50)
	_expect_offsets("place_top_center", control, 0.5, 0.5, 0.0, 0.0, -50, 34, 50, 84)
	HtmlLayoutMetrics.center_panel(control, 100, 50)
	_expect_offsets("center_panel", control, 0.5, 0.5, 0.5, 0.5, -50, -25, 50, 25)

func _verify_hud_constants() -> void:
	var desktop = Vector2(1920, 1080)
	_expect_rect("combat hud desktop", HtmlLayoutMetrics.combat_hud_rect(desktop), Rect2(Vector2(12, 12), Vector2(270, 360)))
	_expect_rect("economy hud desktop", HtmlLayoutMetrics.economy_hud_rect(desktop), Rect2(Vector2(1653, 12), Vector2(255, 517)))
	_expect_rect("difficulty hud desktop", HtmlLayoutMetrics.difficulty_hud_rect(desktop), Rect2(Vector2(790, 10), Vector2(340, 67)))
	_expect_rect("cleanup hud desktop", HtmlLayoutMetrics.cleanup_hud_rect(desktop), Rect2(Vector2(830, 64), Vector2(260, 67)))
	_expect_equal("debug desktop width", HtmlLayoutMetrics.debug_hud_rect(desktop).size.x, 250.0)
	_expect_equal("status desktop width", HtmlLayoutMetrics.status_hud_rect(desktop).size.x, 270.0)

func _verify_choice_constants() -> void:
	_expect_vector("choice panel desktop", HtmlLayoutMetrics.choice_panel_size(Vector2(1920, 1080)), Vector2(680, 365))
	_expect_vector("choice panel 960x540", HtmlLayoutMetrics.choice_panel_size(Vector2(960, 540)), Vector2(680, 365))
	_expect_vector("choice panel compact", HtmlLayoutMetrics.choice_panel_size(Vector2(640, 360)), Vector2(560, 346))
	_expect_equal("choice desktop gap", HtmlLayoutMetrics.choice_gap(Vector2(1920, 1080)), 12.0)
	_expect_equal("choice compact columns", HtmlLayoutMetrics.choice_columns_for_width(560, Vector2(640, 360)), 1)
	_expect_equal("choice desktop columns", HtmlLayoutMetrics.choice_columns_for_width(680, Vector2(1920, 1080)), 3)

func _verify_popup_size_table() -> void:
	var expected = {
		"terms": Vector2(318, 218),
		"timed_reward": Vector2(286, 168),
		"ad_buff": Vector2(300, 190),
		"sponsored_ad": Vector2(300, 190),
		"infection": Vector2(286, 168),
		"infected_popup": Vector2(292, 150),
		"first_purchase_package": Vector2(336, 236),
		"interest_offer": Vector2(350, 250),
		"recurring_investment": Vector2(342, 230),
		"loan_offer": Vector2(342, 230),
		"stock_market": Vector2(342, 230),
		"stock_broker_app": Vector2(300, 260),
		"clean_challenge": Vector2(320, 190),
		"volatile_popup": Vector2(310, 178),
		"popup_store": Vector2(326, 230),
		"boss_package_ad": Vector2(440, 430),
		"system_notice": Vector2(260, 120),
		"security_installer": Vector2(330, 220),
		"security_update_notice": Vector2(292, 150),
		"unknown": Vector2(252, 132),
	}
	for type in expected.keys():
		_expect_vector("service popup %s" % type, HtmlLayoutMetrics.popup_size_for_type(type), expected[type])
		_expect_vector("game popup %s" % type, game.popup_size_for({"type": type}), expected[type])

func _verify_hud_callers_use_service(viewport_size: Vector2i) -> void:
	get_window().size = viewport_size
	await get_tree().process_frame
	await get_tree().process_frame
	var viewport = Vector2(viewport_size.x, viewport_size.y)
	game.hud.update_from_state(game.state)
	_expect_control_rect("%s combat caller" % str(viewport_size), game.hud.ui.combatHud, HtmlLayoutMetrics.combat_hud_rect(viewport))
	_expect_control_rect("%s economy caller" % str(viewport_size), game.hud.ui.economyHud, HtmlLayoutMetrics.economy_hud_rect(viewport))
	_expect_control_rect("%s difficulty caller" % str(viewport_size), game.hud.ui.difficultyHud, HtmlLayoutMetrics.difficulty_hud_rect(viewport))
	_expect_control_rect("%s cleanup caller" % str(viewport_size), game.hud.ui.cleanupHud, HtmlLayoutMetrics.cleanup_hud_rect(viewport))
	_expect_control_rect("%s status caller" % str(viewport_size), game.hud.ui.statusPanel, HtmlLayoutMetrics.status_hud_rect(viewport, game.hud.status_minimized))
	_expect_control_rect("%s debug caller" % str(viewport_size), game.hud.ui.debugPanel, HtmlLayoutMetrics.debug_hud_rect(viewport, not game.hud.ui.debugBody.visible))

func _verify_choice_caller_uses_service(viewport_size: Vector2i) -> void:
	get_window().size = viewport_size
	await get_tree().process_frame
	await get_tree().process_frame
	var viewport = Vector2(viewport_size.x, viewport_size.y)
	game.hud.show_choices("G3", "layout service", [game.data.ITEMS[0], game.data.ITEMS[1], game.data.ITEMS[2]], func(_choice): pass, 3)
	await get_tree().process_frame
	_expect_control_rect("choice panel caller", game.hud.ui.choicePanel, _center_rect(HtmlLayoutMetrics.choice_panel_size(viewport), viewport))
	_expect_equal("choice grid caller columns", game.hud.ui.choiceGrid.columns, HtmlLayoutMetrics.choice_columns_for_width(HtmlLayoutMetrics.choice_panel_size(viewport).x, viewport))
	game.hud.hide_choices()

func _center_rect(size: Vector2, viewport_size: Vector2) -> Rect2:
	return Rect2((viewport_size - size) * 0.5, size)

func _expect_control_rect(label: String, control: Control, expected: Rect2) -> void:
	if control == null:
		failures.append("%s missing" % label)
		return
	_expect_rect(label, Rect2(control.position, control.size), expected)

func _expect_rect(label: String, actual: Rect2, expected: Rect2) -> void:
	if not _pixel_close(actual.position.x, expected.position.x) or not _pixel_close(actual.position.y, expected.position.y) or not _pixel_close(actual.size.x, expected.size.x) or not _pixel_close(actual.size.y, expected.size.y):
		failures.append("%s expected %s got %s" % [label, str(expected), str(actual)])

func _expect_offsets(label: String, control: Control, left_anchor: float, right_anchor: float, top_anchor: float, bottom_anchor: float, left: float, top: float, right: float, bottom: float) -> void:
	_expect_equal("%s anchor_left" % label, control.anchor_left, left_anchor)
	_expect_equal("%s anchor_right" % label, control.anchor_right, right_anchor)
	_expect_equal("%s anchor_top" % label, control.anchor_top, top_anchor)
	_expect_equal("%s anchor_bottom" % label, control.anchor_bottom, bottom_anchor)
	_expect_equal("%s offset_left" % label, control.offset_left, left)
	_expect_equal("%s offset_top" % label, control.offset_top, top)
	_expect_equal("%s offset_right" % label, control.offset_right, right)
	_expect_equal("%s offset_bottom" % label, control.offset_bottom, bottom)

func _expect_vector(label: String, actual: Vector2, expected: Vector2) -> void:
	if not _pixel_close(actual.x, expected.x) or not _pixel_close(actual.y, expected.y):
		failures.append("%s expected %s got %s" % [label, str(expected), str(actual)])

func _expect_equal(label: String, actual, expected) -> void:
	if actual != expected:
		failures.append("%s expected %s got %s" % [label, str(expected), str(actual)])

func _pixel_close(a: float, b: float) -> bool:
	return abs(a - b) <= 0.51
