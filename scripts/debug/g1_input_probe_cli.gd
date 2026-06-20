extends Node

const PrototypeGameScript = preload("res://scripts/v2/prototype_game.gd")
const HtmlLayoutMetrics = preload("res://scripts/ui/html_layout_metrics.gd")

var game
var failures: Array = []

func _ready() -> void:
	_setup_game()
	while game.state.is_empty():
		await get_tree().process_frame
	await get_tree().process_frame
	_run_probe()

func _run_probe() -> void:
	_verify_layer_and_filter_contracts()
	_verify_choice_card_click()
	_verify_item_machine_click()
	_verify_inventory_click()
	_verify_popup_close_click()
	_verify_popup_content_click()
	_verify_popup_input_grace()
	_verify_debug_button_click()
	if failures.is_empty():
		print("g1_input_probe passed")
		get_tree().quit()
		return
	for failure in failures:
		push_error(str(failure))
	get_tree().quit(1)

func _setup_game() -> void:
	get_window().size = Vector2i(HtmlLayoutMetrics.PC_VIEWPORT_WIDTH, HtmlLayoutMetrics.PC_VIEWPORT_HEIGHT)
	game = PrototypeGameScript.new()
	add_child(game)

func _verify_layer_and_filter_contracts() -> void:
	_prepare_interaction_state()
	_expect_equal("hud layer", int(game.hud.layer), 10)
	_expect_equal("popup layer", int(game.popup_layer.layer), 20)
	_expect_equal("debug layer", int(game.debug_layer.layer), 40)
	_expect_equal("modal layer", int(game.modal_layer.layer), 50)
	_expect_equal("hud root ignores mouse", game.hud.ui.root.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	_expect_equal("popup root ignores mouse", game.popup_layer.root.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	_expect_equal("debug root ignores mouse", game.debug_layer.root.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	_expect_equal("modal root ignores mouse", game.modal_layer.root.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	_expect_equal("hidden choice overlay ignores mouse", game.hud.ui.choiceOverlay.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	_expect_equal("mobile controls root ignores mouse", game.hud.ui.mobileControls.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	_expect_equal("mobile fullscreen button stops mouse", game.hud.ui.mobileFullscreenButton.mouse_filter, Control.MOUSE_FILTER_STOP)
	_expect_equal("mobile emergency button stops mouse", game.hud.ui.mobileEmergencyButton.mouse_filter, Control.MOUSE_FILTER_STOP)

func _verify_choice_card_click() -> void:
	_prepare_interaction_state()
	var probe = {"called": false}
	game.hud.show_choices("G1", "choice card", [game.data.ITEMS[0]], func(_choice): probe["called"] = true, 1)
	_expect_equal("visible choice overlay blocks world input", game.hud.ui.choiceOverlay.mouse_filter, Control.MOUSE_FILTER_STOP)
	var choice_button = game.hud.ui.choiceGrid.get_child(0) if game.hud.ui.choiceGrid.get_child_count() > 0 else null
	if choice_button is Button:
		_expect_equal("choice card stops mouse", choice_button.mouse_filter, Control.MOUSE_FILTER_STOP)
		_expect_equal("choice card enabled", choice_button.disabled, false)
		_verify_control_tree_ignores_mouse(choice_button, "choice card child")
		choice_button.emit_signal("pressed")
		_expect_equal("choice card callback fired", bool(probe.called), true)
	else:
		failures.append("choice card button missing")
	game.hud.hide_choices()
	_expect_equal("hidden choice overlay ignores mouse after click test", game.hud.ui.choiceOverlay.mouse_filter, Control.MOUSE_FILTER_IGNORE)

func _verify_item_machine_click() -> void:
	_prepare_interaction_state()
	var item_cost = game.current_item_roll_cost()
	game.state.gold = item_cost + 100
	game.hud.update_from_state(game.state)
	var button = game.hud.ui.rollItemButton
	_expect_equal("item machine button stops mouse", button.mouse_filter, Control.MOUSE_FILTER_STOP)
	_expect_equal("item machine button enabled with enough gold", button.disabled, false)
	var gold_before = int(game.state.gold)
	button.emit_signal("pressed")
	_expect_equal("item machine opens selection", game.state.selectingItem and game.hud.ui.choiceOverlay.visible, true)
	if int(game.state.gold) >= gold_before:
		failures.append("item machine did not spend gold")

func _verify_inventory_click() -> void:
	_prepare_interaction_state()
	var item_id = str(game.data.ITEMS[0].get("id", ""))
	if item_id != "":
		game.state.itemCounts[item_id] = 1
	game.hud.update_from_state(game.state)
	var button = game.hud.ui.openInventoryButton
	_expect_equal("inventory button stops mouse", button.mouse_filter, Control.MOUSE_FILTER_STOP)
	_expect_equal("inventory button enabled when allowed", button.disabled, false)
	button.emit_signal("pressed")
	_expect_equal("inventory overlay opens", game.state.selectingItem and game.hud.ui.choiceOverlay.visible, true)
	var close_button = _first_button(game.hud.ui.choiceGrid)
	if close_button == null:
		failures.append("inventory close button missing")
	else:
		_expect_equal("inventory close button stops mouse", close_button.mouse_filter, Control.MOUSE_FILTER_STOP)
		_expect_equal("inventory close button enabled", close_button.disabled, false)
		close_button.emit_signal("pressed")
		_expect_equal("inventory close callback fired", game.state.selectingItem or game.hud.ui.choiceOverlay.visible, false)

func _verify_popup_close_click() -> void:
	_prepare_interaction_state()
	var popup = game.create_popup(game.popup_def_by_id("moving_close"))
	popup.inputGrace = 0.0
	game.popup_layer.sync(game.state)
	var record = game.popup_layer.windows.get(int(popup.id), null)
	if record == null:
		failures.append("popup close window missing")
		return
	var button = _first_button(record.title_bar)
	if button == null:
		failures.append("popup close button missing")
		return
	_expect_equal("popup close button stops mouse", button.mouse_filter, Control.MOUSE_FILTER_STOP)
	_expect_equal("popup close button enabled", button.disabled, false)
	button.emit_signal("pressed")
	_expect_equal("popup close button removed popup", game.popup_by_id(int(popup.id)) == null, true)

func _verify_popup_content_click() -> void:
	_prepare_interaction_state()
	var popup = game.create_popup(game.popup_def_by_id("moving_close"))
	popup.inputGrace = 0.0
	game.popup_layer.sync(game.state)
	var record = game.popup_layer.windows.get(int(popup.id), null)
	if record == null:
		failures.append("popup content window missing")
		return
	var button = _first_button(record.controls)
	if button == null:
		failures.append("popup content button missing")
		return
	_expect_equal("popup content button stops mouse", button.mouse_filter, Control.MOUSE_FILTER_STOP)
	_expect_equal("popup content button enabled", button.disabled, false)
	button.emit_signal("pressed")
	_expect_equal("popup content button removed popup", game.popup_by_id(int(popup.id)) == null, true)

func _verify_popup_input_grace() -> void:
	_prepare_interaction_state()
	var popup = game.create_popup(game.popup_def_by_id("timed_reward"))
	game.popup_layer.sync(game.state)
	var record = game.popup_layer.windows.get(int(popup.id), null)
	if record == null:
		failures.append("popup grace window missing")
		return
	var button = _first_button(record.controls)
	if button == null:
		failures.append("popup grace button missing")
		return
	_expect_equal("popup grace disables content button", button.disabled, true)
	popup.inputGrace = 0.0
	game.popup_layer.sync(game.state)
	button = _first_button(record.controls)
	_expect_equal("popup grace re-enables content button", button != null and not button.disabled, true)

func _verify_debug_button_click() -> void:
	_prepare_interaction_state()
	var button = game.hud.ui.debugButtons.get_child(0) if game.hud.ui.debugButtons.get_child_count() > 0 else null
	if button is Button:
		_expect_equal("debug button stops mouse", button.mouse_filter, Control.MOUSE_FILTER_STOP)
		_expect_equal("debug button enabled", button.disabled, false)
		var gold_before = int(game.state.gold)
		button.emit_signal("pressed")
		_expect_equal("debug button callback changed state", int(game.state.gold) > gold_before, true)
	else:
		failures.append("debug button missing")

func _prepare_interaction_state() -> void:
	game.state.gameOver = false
	game.state.paused = false
	game.state.selectingItem = false
	game.state.selectingPerk = false
	game.state.selectingModule = false
	game.state.selectingPaidReward = false
	game.state.emergencyTimer = 0.0
	game.state.gold = max(int(game.state.gold), 1000)
	if game.state.has("openPopups"):
		game.state.openPopups.clear()
	if game.state.has("pendingPopupSpawns"):
		game.state.pendingPopupSpawns.clear()
	game.hud.hide_choices()
	game.popup_layer.sync(game.state)
	game.hud.update_from_state(game.state)

func _verify_control_tree_ignores_mouse(node: Node, label: String) -> void:
	for child in node.get_children():
		if child is Control:
			if child is Button:
				failures.append("%s unexpectedly contains nested button %s" % [label, child.get_path()])
			elif child.mouse_filter != Control.MOUSE_FILTER_IGNORE:
				failures.append("%s expected mouse ignore for %s got %s" % [label, child.get_path(), child.mouse_filter])
		_verify_control_tree_ignores_mouse(child, label)

func _first_button(node: Node) -> Button:
	if node is Button:
		return node
	for child in node.get_children():
		var found = _first_button(child)
		if found != null:
			return found
	return null

func _expect_equal(label: String, actual, expected) -> void:
	if actual != expected:
		failures.append("%s expected %s got %s" % [label, str(expected), str(actual)])
