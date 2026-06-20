extends Node

const MainScene = preload("res://scenes/main/Main.tscn")
const HtmlLayoutMetrics = preload("res://scripts/ui/html_layout_metrics.gd")

var game
var failures: Array = []

func _ready() -> void:
	get_window().size = Vector2i(1920, 1080)
	game = MainScene.instantiate()
	add_child(game)
	while game.state.is_empty():
		await get_tree().process_frame
	await get_tree().process_frame
	_verify_popup_sizes()
	_verify_popup_clamp()
	_verify_click_brings_forward()
	_verify_drag_release_anywhere()
	_verify_stock_broker_minimize()
	_verify_forced_close_policies()
	if failures.is_empty():
		print("g7_popup_probe passed")
		get_tree().quit()
		return
	for failure in failures:
		push_error(str(failure))
	get_tree().quit(1)

func _verify_popup_sizes() -> void:
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
	}
	for type in expected.keys():
		_clear_popups()
		var popup = game.create_popup(_popup_def(type))
		popup.inputGrace = 0.0
		game.popup_layer.sync(game.state)
		var record = game.popup_layer.windows.get(int(popup.id), null)
		_expect_vector("popup state size %s" % type, popup.size, expected[type])
		if record == null:
			failures.append("popup record missing %s" % type)
		else:
			_expect_vector("popup panel size %s" % type, record.panel.size, expected[type])

func _verify_popup_clamp() -> void:
	_clear_popups()
	var popup = game.create_popup(_popup_def("boss_package_ad"))
	popup.inputGrace = 0.0
	popup.position = Vector2(5000, 5000)
	game.popup_layer.sync(game.state)
	var record = game.popup_layer.windows.get(int(popup.id), null)
	if record == null:
		failures.append("clamp popup record missing")
		return
	var viewport = game.get_viewport().get_visible_rect().size
	if record.panel.position.x + record.panel.size.x > viewport.x - 5.0 or record.panel.position.y + record.panel.size.y > viewport.y - 5.0:
		failures.append("popup did not clamp inside viewport: %s size %s viewport %s" % [str(record.panel.position), str(record.panel.size), str(viewport)])

func _verify_click_brings_forward() -> void:
	_clear_popups()
	var first = game.create_popup(_popup_def("timed_reward"))
	var second = game.create_popup(_popup_def("system_notice"))
	first.inputGrace = 0.0
	second.inputGrace = 0.0
	game.popup_layer.sync(game.state)
	var first_record = game.popup_layer.windows.get(int(first.id), null)
	if first_record == null:
		failures.append("bring-front popup record missing")
		return
	var before = int(first.get("z", 0))
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	game.popup_layer._panel_event(event, int(first.id), first_record.panel)
	if int(first.get("z", 0)) <= max(before, int(second.get("z", 0))):
		failures.append("popup content click did not bring popup forward")

func _verify_drag_release_anywhere() -> void:
	_clear_popups()
	var popup = game.create_popup(_popup_def("moving_close"))
	popup.inputGrace = 0.0
	game.popup_layer.sync(game.state)
	var record = game.popup_layer.windows.get(int(popup.id), null)
	if record == null:
		failures.append("drag popup record missing")
		return
	record.dragging = true
	record.dragStartMouse = Vector2.ZERO
	record.dragOriginPosition = popup.position
	game.start_dragging_popup(int(popup.id))
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = false
	game.popup_layer._input(event)
	_expect_equal("drag release clears record", record.dragging, false)
	_expect_equal("drag release clears game state", game.state.draggingPopup, null)

func _verify_stock_broker_minimize() -> void:
	_clear_popups()
	var popup = game.create_popup(_popup_def("stock_broker_app"))
	popup.inputGrace = 0.0
	game.popup_layer.sync(game.state)
	var record = game.popup_layer.windows.get(int(popup.id), null)
	if record == null:
		failures.append("stock broker record missing")
		return
	var title_buttons = _buttons_under(record.title_bar)
	if title_buttons.size() != 1 or title_buttons[0].text != "_":
		failures.append("stock broker should expose only minimize button")
		return
	title_buttons[0].emit_signal("pressed")
	game.popup_layer.sync(game.state)
	_expect_equal("stock broker minimized", popup.get("minimized", false), true)

func _verify_forced_close_policies() -> void:
	_clear_popups()
	var first_purchase = game.create_popup(_popup_def("first_purchase_package"))
	first_purchase.inputGrace = 0.0
	game.popup_layer.sync(game.state)
	var first_record = game.popup_layer.windows.get(int(first_purchase.id), null)
	if first_record != null:
		for button in _buttons_under(first_record.title_bar):
			if button.text == "X":
				failures.append("first purchase should not have title close button")
	game.request_close_popup(int(first_purchase.id), {"reason": "button"})
	if game.popup_by_id(int(first_purchase.id)) == null:
		failures.append("first purchase forced-choice popup closed through request_close_popup")
	_clear_popups()
	var broker = game.create_popup(_popup_def("stock_broker_app"))
	broker.inputGrace = 0.0
	game.popup_layer.sync(game.state)
	game.request_close_popup(int(broker.id), {"reason": "button"})
	if game.popup_by_id(int(broker.id)) == null:
		failures.append("stock broker closed through request_close_popup")

func _popup_def(type: String) -> Dictionary:
	return {
		"type": type,
		"title": type,
		"body": "검증 본문",
		"description": "검증 상세",
		"category": "test",
	}

func _clear_popups() -> void:
	game.state.openPopups.clear()
	game.popup_layer.sync(game.state)

func _buttons_under(node: Node) -> Array:
	var result = []
	if node is Button:
		result.append(node)
	for child in node.get_children():
		result.append_array(_buttons_under(child))
	return result

func _expect_vector(label: String, actual: Vector2, expected: Vector2) -> void:
	if not _pixel_close(actual.x, expected.x) or not _pixel_close(actual.y, expected.y):
		failures.append("%s expected %s got %s" % [label, str(expected), str(actual)])

func _expect_equal(label: String, actual, expected) -> void:
	if actual != expected:
		failures.append("%s expected %s got %s" % [label, str(expected), str(actual)])

func _pixel_close(a: float, b: float) -> bool:
	return abs(a - b) <= 0.51
