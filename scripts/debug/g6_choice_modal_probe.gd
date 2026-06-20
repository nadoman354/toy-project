extends Node

const MainScene = preload("res://scenes/main/Main.tscn")
const HtmlLayoutMetrics = preload("res://scripts/ui/html_layout_metrics.gd")

var game
var failures: Array = []

func _ready() -> void:
	game = MainScene.instantiate()
	add_child(game)
	for viewport_size in [Vector2i(960, 540), Vector2i(1152, 648), Vector2i(1920, 1080), Vector2i(390, 844)]:
		_verify_choice_cases(viewport_size)
	if failures.is_empty():
		print("g6_choice_modal_probe passed")
		get_tree().quit()
		return
	for failure in failures:
		push_error(str(failure))
	get_tree().quit(1)

func _verify_choice_cases(viewport_size: Vector2i) -> void:
	get_window().size = viewport_size
	game.hud._apply_html_layout(Vector2(viewport_size.x, viewport_size.y))
	game.hud.update_from_state(game.state)
	_verify_initial_module_case(viewport_size)
	_verify_item_case(viewport_size)
	_verify_boss_package_case(viewport_size)
	_verify_inventory_case(viewport_size)

func _verify_initial_module_case(viewport_size: Vector2i) -> void:
	_prepare_state()
	game.open_attack_module_selection("primary")
	game.hud._apply_html_layout(Vector2(viewport_size.x, viewport_size.y))
	_expect_choice_contract("%s initial module" % str(viewport_size), viewport_size)

func _verify_item_case(viewport_size: Vector2i) -> void:
	_prepare_state()
	game.open_item_selection([game.data.ITEMS[0], game.data.ITEMS[1], game.data.ITEMS[2]])
	game.hud._apply_html_layout(Vector2(viewport_size.x, viewport_size.y))
	_expect_choice_contract("%s item choices" % str(viewport_size), viewport_size)

func _verify_boss_package_case(viewport_size: Vector2i) -> void:
	_prepare_state()
	var choices = [game.data.ITEMS[0], game.data.ITEMS[1], game.data.ITEMS[2], game.data.ITEMS[3]]
	game.hud.show_boss_package_choices("보스 패키지", "2개를 선택합니다.", choices, [], func(_choice): pass, 3)
	game.hud._apply_html_layout(Vector2(viewport_size.x, viewport_size.y))
	_expect_choice_contract("%s boss package" % str(viewport_size), viewport_size)

func _verify_inventory_case(viewport_size: Vector2i) -> void:
	_prepare_state()
	game.state.itemCounts[str(game.data.ITEMS[0].get("id", ""))] = 1
	game.open_inventory_overview()
	game.hud._apply_html_layout(Vector2(viewport_size.x, viewport_size.y))
	_expect_choice_contract("%s inventory" % str(viewport_size), viewport_size)

func _prepare_state() -> void:
	game.state.gameOver = false
	game.state.paused = false
	game.state.selectingItem = false
	game.state.selectingPerk = false
	game.state.selectingModule = false
	game.state.selectingPaidReward = false
	game.state.openPopups.clear()
	game.hud.hide_choices()
	game.popup_layer.sync(game.state)
	game.hud.update_from_state(game.state)

func _expect_choice_contract(label: String, viewport_size: Vector2i) -> void:
	var viewport = Vector2(viewport_size.x, viewport_size.y)
	var expected_size = HtmlLayoutMetrics.choice_panel_size(viewport)
	_expect_equal("%s modal layer above popup" % label, int(game.modal_layer.layer) > int(game.popup_layer.layer), true)
	_expect_equal("%s modal layer above debug" % label, int(game.modal_layer.layer) > int(game.debug_layer.layer), true)
	_expect_equal("%s overlay parent" % label, game.hud.ui.choiceOverlay.get_parent(), game.modal_layer.root)
	_expect_equal("%s visible overlay stops mouse" % label, game.hud.ui.choiceOverlay.mouse_filter, Control.MOUSE_FILTER_STOP)
	_expect_centered_panel("%s choice panel" % label, game.hud.ui.choicePanel, expected_size)
	_expect_equal("%s choice columns" % label, game.hud.ui.choiceGrid.columns, HtmlLayoutMetrics.choice_columns_for_width(expected_size.x, viewport))
	_expect_equal("%s choice h gap" % label, game.hud.ui.choiceGrid.get_theme_constant("h_separation"), int(HtmlLayoutMetrics.choice_gap(viewport)))
	_expect_equal("%s choice v gap" % label, game.hud.ui.choiceGrid.get_theme_constant("v_separation"), int(HtmlLayoutMetrics.choice_gap(viewport)))
	_expect_equal("%s choice left padding" % label, int(game.hud.ui.choiceBox.offset_left), HtmlLayoutMetrics.choice_panel_padding(viewport))
	_expect_equal("%s choice top padding" % label, int(game.hud.ui.choiceBox.offset_top), HtmlLayoutMetrics.choice_panel_top_padding(viewport))
	for card in game.hud.ui.choiceGrid.get_children():
		if card is Control:
			if card is Button:
				_expect_equal("%s choice card button stops mouse" % label, card.mouse_filter, Control.MOUSE_FILTER_STOP)
			_expect_equal("%s choice card clips contents" % label, card.clip_contents, true)
			if float(card.custom_minimum_size.x) <= 0.0 or float(card.custom_minimum_size.y) <= 0.0:
				failures.append("%s choice card has no stable size" % label)
	game.hud.hide_choices()
	_expect_equal("%s hidden overlay ignores mouse" % label, game.hud.ui.choiceOverlay.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	_expect_equal("%s hidden overlay invisible" % label, game.hud.ui.choiceOverlay.visible, false)

func _expect_centered_panel(label: String, control: Control, expected_size: Vector2) -> void:
	if control == null:
		failures.append("%s missing" % label)
		return
	_expect_equal("%s anchor left" % label, control.anchor_left, 0.5)
	_expect_equal("%s anchor right" % label, control.anchor_right, 0.5)
	_expect_equal("%s anchor top" % label, control.anchor_top, 0.5)
	_expect_equal("%s anchor bottom" % label, control.anchor_bottom, 0.5)
	_expect_vector("%s size" % label, control.size, expected_size)
	_expect_close("%s offset left" % label, control.offset_left, -expected_size.x * 0.5)
	_expect_close("%s offset right" % label, control.offset_right, expected_size.x * 0.5)
	_expect_close("%s offset top" % label, control.offset_top, -expected_size.y * 0.5)
	_expect_close("%s offset bottom" % label, control.offset_bottom, expected_size.y * 0.5)

func _expect_vector(label: String, actual: Vector2, expected: Vector2) -> void:
	if not _pixel_close(actual.x, expected.x) or not _pixel_close(actual.y, expected.y):
		failures.append("%s expected %s got %s" % [label, str(expected), str(actual)])

func _expect_equal(label: String, actual, expected) -> void:
	if actual != expected:
		failures.append("%s expected %s got %s" % [label, str(expected), str(actual)])

func _expect_close(label: String, actual: float, expected: float) -> void:
	if not _pixel_close(actual, expected):
		failures.append("%s expected %.1f got %.1f" % [label, expected, actual])

func _pixel_close(a: float, b: float) -> bool:
	return abs(a - b) <= 0.51
