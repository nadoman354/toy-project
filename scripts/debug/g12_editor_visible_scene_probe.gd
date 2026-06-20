extends Node

const MAIN_SCENE := "res://scenes/main/Main.tscn"

const TEMPLATE_NODES := {
	"res://scenes/layers/HudLayer.tscn": [
		"HudRoot/difficultyHud",
		"HudRoot/cleanupComboHud",
		"HudRoot/combatHud",
		"HudRoot/economyHud",
		"HudRoot/statusPanel",
		"HudRoot/debugPanel",
	],
	"res://scenes/layers/ModalLayer.tscn": [
		"ModalRoot/itemOverlay",
		"ModalRoot/gameOverOverlay/gameOverPanel/GameOverBox/gameOverTitle",
		"ModalRoot/gameOverOverlay/gameOverPanel/GameOverBox/gameOverSummary",
		"ModalRoot/gameOverOverlay/gameOverPanel/GameOverBox/restartButton",
	],
	"res://scenes/ui/modal/ChoiceOverlay.tscn": [
		"itemPanel",
		"itemPanel/ChoiceBox",
		"itemPanel/ChoiceBox/choiceTitle",
		"itemPanel/ChoiceBox/choiceDescription",
		"itemPanel/ChoiceBox/ChoiceScroll",
		"itemPanel/ChoiceBox/ChoiceScroll/choiceGrid",
	],
	"res://scenes/ui/cards/ChoiceCard.tscn": [
		"choiceCardBody",
		"choiceCardBody/selectedBadge",
		"choiceCardBody/itemTags",
		"choiceCardBody/choiceTitleText",
		"choiceCardBody/choiceDescriptionText",
		"choiceCardBody/choiceMeta",
		"choiceCardBody/choiceMeta/choiceMetaText",
	],
	"res://scenes/ui/popup/PopupWindow.tscn": [
		"PopupBox",
		"PopupBox/TitleFrame",
		"PopupBox/TitleFrame/TitleBar",
		"PopupBox/TitleFrame/TitleBar/TitleLabel",
		"PopupBox/TitleFrame/TitleBar/MinimizeButton",
		"PopupBox/TitleFrame/TitleBar/CloseButton",
		"PopupBox/ContentFrame",
		"PopupBox/ContentFrame/ContentBox",
		"PopupBox/ContentFrame/ContentBox/BodyText",
		"PopupBox/ContentFrame/ContentBox/DetailText",
		"PopupBox/ContentFrame/ContentBox/StatusBadgeRow",
		"PopupBox/ContentFrame/ContentBox/ProgressBar",
		"PopupBox/ContentFrame/ContentBox/ChartArea",
		"PopupBox/ContentFrame/ContentBox/ButtonRow",
	],
}

const HUD_PANEL_BINDINGS := {
	"difficultyHud": "difficultyHud",
	"cleanupComboHud": "cleanupHud",
	"combatHud": "combatHud",
	"economyHud": "economyHud",
	"statusPanel": "statusPanel",
	"debugPanel": "debugPanel",
}

var failures: Array = []

func _ready() -> void:
	get_window().size = Vector2i(1152, 648)
	_verify_template_scenes()
	await _verify_runtime_bindings()
	if failures.is_empty():
		print("g12_editor_visible_scene_probe passed")
		get_tree().quit()
		return
	for failure in failures:
		push_error(str(failure))
	get_tree().quit(1)

func _verify_template_scenes() -> void:
	for scene_path in TEMPLATE_NODES.keys():
		_expect_true("%s exists" % scene_path, ResourceLoader.exists(scene_path))
		var packed = load(scene_path)
		if packed == null or not (packed is PackedScene):
			failures.append("%s could not load as PackedScene" % scene_path)
			continue
		var instance = packed.instantiate()
		for node_path in TEMPLATE_NODES[scene_path]:
			_expect_true("%s has %s" % [scene_path, node_path], instance.get_node_or_null(node_path) != null)
		instance.free()
	for scene_path in [
		"res://scenes/ui/hud/CombatHud.tscn",
		"res://scenes/ui/hud/EconomyHud.tscn",
		"res://scenes/ui/hud/DifficultyHud.tscn",
		"res://scenes/ui/hud/CleanupComboHud.tscn",
		"res://scenes/ui/hud/StatusPanel.tscn",
		"res://scenes/ui/hud/DebugPanel.tscn",
	]:
		_expect_true("%s exists" % scene_path, ResourceLoader.exists(scene_path))
		var packed = load(scene_path)
		if packed == null or not (packed is PackedScene):
			failures.append("%s could not load as PackedScene" % scene_path)
			continue
		var instance = packed.instantiate()
		_expect_true("%s has editor preview" % scene_path, instance.get_node_or_null("EditorPreview") != null)
		instance.free()

func _verify_runtime_bindings() -> void:
	var packed = load(MAIN_SCENE)
	if packed == null or not (packed is PackedScene):
		failures.append("%s could not load as PackedScene" % MAIN_SCENE)
		return
	var game = packed.instantiate()
	add_child(game)
	for _i in range(30):
		if game.get("state") != null and not game.state.is_empty():
			break
		await get_tree().process_frame
	await get_tree().process_frame
	if game.get("state") == null or game.state.is_empty():
		failures.append("game state did not initialize")
		game.queue_free()
		return
	_verify_hud_runtime_bindings(game)
	_verify_modal_runtime_bindings(game)
	await _verify_choice_card_runtime_binding(game)
	await _verify_popup_runtime_binding(game)
	game.queue_free()
	await get_tree().process_frame

func _verify_hud_runtime_bindings(game) -> void:
	for node_name in HUD_PANEL_BINDINGS.keys():
		_expect_equal("runtime has one %s" % node_name, _nodes_named(game, node_name).size(), 1)
		var ui_key = HUD_PANEL_BINDINGS[node_name]
		var bound_node = game.hud.ui.get(ui_key)
		var scene_node = _first_node_named(game, node_name)
		_expect_equal("%s binds to scene node" % node_name, bound_node, scene_node)
		if bound_node is Node:
			_expect_equal("%s editor preview cleared at runtime" % node_name, _nodes_named(bound_node, "EditorPreview").size(), 0)

func _verify_modal_runtime_bindings(game) -> void:
	_expect_equal("runtime has one itemOverlay", _nodes_named(game, "itemOverlay").size(), 1)
	_expect_equal("runtime has one gameOverOverlay", _nodes_named(game, "gameOverOverlay").size(), 1)
	_expect_equal("choice overlay binds to scene node", game.hud.ui.choiceOverlay, _first_node_named(game, "itemOverlay"))
	_expect_equal("game over overlay binds to scene node", game.hud.ui.gameOverOverlay, _first_node_named(game, "gameOverOverlay"))

func _verify_choice_card_runtime_binding(game) -> void:
	var choice = {
		"id": "g13_probe_module",
		"name": "G13 Probe Module",
		"description": "Editor-visible ChoiceCard binding probe.",
		"baseDamage": 4,
		"baseCooldown": 1.0,
		"baseRange": 120,
		"compatibleTags": ["probe"],
	}
	game.hud.show_choices("G13 Probe", "ChoiceCard template binding", [choice], Callable(self, "_choice_probe_callback"))
	await get_tree().process_frame
	_expect_equal("choice grid has one runtime card", game.hud.ui.choiceGrid.get_child_count(), 1)
	var card = game.hud.ui.choiceGrid.get_child(0) if game.hud.ui.choiceGrid.get_child_count() > 0 else null
	_expect_true("choice card is Button", card is Button)
	if card is Button:
		_expect_equal("choice card has one body", _nodes_named(card, "choiceCardBody").size(), 1)
		_expect_true("choice card has title label", _first_node_named(card, "choiceTitleText") is Label)
		_expect_true("choice card has description label", _first_node_named(card, "choiceDescriptionText") is Label)
		_expect_true("choice card has meta panel", _first_node_named(card, "choiceMeta") is PanelContainer)
	game.hud.hide_choices()

func _verify_popup_runtime_binding(game) -> void:
	var popup = game.create_popup({
		"id": "g13_probe_popup",
		"type": "normal",
		"title": "G13 Popup",
		"body": "PopupWindow template binding probe.",
		"duration": 1.0,
	})
	game.popup_layer.sync(game.state)
	await get_tree().process_frame
	var record = game.popup_layer.windows.get(int(popup.id), null)
	_expect_true("popup record exists", record != null)
	if record == null:
		return
	_expect_equal("popup has one PopupBox", _nodes_named(record.panel, "PopupBox").size(), 1)
	_expect_equal("popup title binds to template node", record.title, record.panel.get_node_or_null("PopupBox/TitleFrame/TitleBar/TitleLabel"))
	_expect_equal("popup body binds to template node", record.body, record.panel.get_node_or_null("PopupBox/ContentFrame/ContentBox/BodyText"))
	_expect_equal("popup controls bind to template node", record.controls, record.panel.get_node_or_null("PopupBox/ContentFrame/ContentBox/ButtonRow"))
	_expect_equal("normal popup title button count", _buttons_under(record.title_bar).size(), 1)
	_expect_true("normal popup keeps close button", record.panel.get_node_or_null("PopupBox/TitleFrame/TitleBar/CloseButton") is Button)
	_expect_true("popup title text updated", str(record.title.text).begins_with("G13 Popup"))

func _choice_probe_callback(_choice: Dictionary) -> void:
	pass

func _nodes_named(root: Node, node_name: String) -> Array:
	var result = []
	if root.name == node_name:
		result.append(root)
	for child in root.get_children():
		result.append_array(_nodes_named(child, node_name))
	return result

func _first_node_named(root: Node, node_name: String) -> Node:
	if root.name == node_name:
		return root
	for child in root.get_children():
		var found = _first_node_named(child, node_name)
		if found != null:
			return found
	return null

func _buttons_under(root: Node) -> Array:
	var result = []
	if root is Button:
		result.append(root)
	for child in root.get_children():
		result.append_array(_buttons_under(child))
	return result

func _expect_true(label: String, condition: bool) -> void:
	if not condition:
		failures.append(label)

func _expect_equal(label: String, actual, expected) -> void:
	if actual != expected:
		failures.append("%s expected %s got %s" % [label, str(expected), str(actual)])
