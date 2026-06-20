extends Node

const ACTIVE_MAIN_SCENE := "res://scenes/main/Main.tscn"
const LEGACY_MAIN_SCENE := "res://scenes/main.tscn"

const LAYER_NAMES := [
	"WorldLayer",
	"EntityLayer",
	"VfxLayer",
	"HudLayer",
	"PopupLayer",
	"ModalLayer",
	"DebugLayer",
]

const SCRIPT_PATHS := {
	"WorldLayer": "res://scripts/v2/prototype_world.gd",
	"HudLayer": "res://scripts/v2/prototype_hud.gd",
	"PopupLayer": "res://scripts/v2/prototype_popup_layer.gd",
	"ModalLayer": "res://scripts/ui/modal/prototype_modal_layer.gd",
	"DebugLayer": "res://scripts/debug/prototype_debug_layer.gd",
}

var failures: Array = []

func _ready() -> void:
	get_window().size = Vector2i(1152, 648)
	_verify_project_main_scene()
	_verify_legacy_scene_delegates()
	await _verify_scene_runtime(ACTIVE_MAIN_SCENE, "active main")
	await _verify_scene_runtime(LEGACY_MAIN_SCENE, "legacy delegate")
	_verify_layout_metrics_activation()
	if failures.is_empty():
		print("g12_runtime_path_probe passed")
		get_tree().quit()
		return
	for failure in failures:
		push_error(str(failure))
	get_tree().quit(1)

func _verify_project_main_scene() -> void:
	_expect_equal("project.godot active main scene", _project_main_scene(), ACTIVE_MAIN_SCENE)

func _verify_legacy_scene_delegates() -> void:
	var legacy_text = FileAccess.get_file_as_string(LEGACY_MAIN_SCENE)
	_expect_contains("legacy main delegates to structured scene", legacy_text, "path=\"%s\"" % ACTIVE_MAIN_SCENE)
	_expect_contains("legacy main uses packed scene instance", legacy_text, "instance=ExtResource")

func _verify_scene_runtime(scene_path: String, label: String) -> void:
	var packed = load(scene_path)
	if packed == null or not packed is PackedScene:
		failures.append("%s could not load %s" % [label, scene_path])
		return
	var game = packed.instantiate()
	game.name = "%s_probe_root" % label.replace(" ", "_")
	add_child(game)
	while game.get("state") == null or game.state.is_empty():
		await get_tree().process_frame
	await get_tree().process_frame
	for layer_name in LAYER_NAMES:
		_expect_equal("%s has one %s" % [label, layer_name], _nodes_named(game, layer_name).size(), 1)
	for layer_name in SCRIPT_PATHS.keys():
		var node = game.get_node_or_null(layer_name)
		if node == null:
			failures.append("%s missing %s" % [label, layer_name])
			continue
		_expect_script("%s %s script" % [label, layer_name], node, SCRIPT_PATHS[layer_name])
	_expect_equal("%s world binding" % label, game.world, game.get_node_or_null("WorldLayer"))
	_expect_equal("%s popup binding" % label, game.popup_layer, game.get_node_or_null("PopupLayer"))
	_expect_equal("%s modal binding" % label, game.modal_layer, game.get_node_or_null("ModalLayer"))
	_expect_equal("%s debug binding" % label, game.debug_layer, game.get_node_or_null("DebugLayer"))
	_expect_equal("%s hud binding" % label, game.hud, game.get_node_or_null("HudLayer"))
	_verify_canvas_layers(game, label)
	_verify_input_roots(game, label)
	game.queue_free()
	await get_tree().process_frame

func _verify_canvas_layers(game, label: String) -> void:
	var hud = game.get_node_or_null("HudLayer")
	var popup = game.get_node_or_null("PopupLayer")
	var debug = game.get_node_or_null("DebugLayer")
	var modal = game.get_node_or_null("ModalLayer")
	if hud == null or popup == null or debug == null or modal == null:
		return
	_expect_true("%s HUD below Popup" % label, int(hud.layer) < int(popup.layer))
	_expect_true("%s Popup below Debug" % label, int(popup.layer) < int(debug.layer))
	_expect_true("%s Debug below Modal" % label, int(debug.layer) < int(modal.layer))
	_expect_equal("%s HUD layer" % label, int(hud.layer), 10)
	_expect_equal("%s Popup layer" % label, int(popup.layer), 20)
	_expect_equal("%s Debug layer" % label, int(debug.layer), 40)
	_expect_equal("%s Modal layer" % label, int(modal.layer), 50)

func _verify_input_roots(game, label: String) -> void:
	game.hud.hide_choices()
	_expect_equal("%s HUD root ignores empty input" % label, int(game.hud.ui.root.mouse_filter), Control.MOUSE_FILTER_IGNORE)
	_expect_equal("%s hidden choice overlay ignores input" % label, int(game.hud.ui.choiceOverlay.mouse_filter), Control.MOUSE_FILTER_IGNORE)
	_expect_equal("%s Popup root ignores empty input" % label, int(game.popup_layer.root.mouse_filter), Control.MOUSE_FILTER_IGNORE)
	_expect_equal("%s Popup telegraph root ignores input" % label, int(game.popup_layer.telegraph_root.mouse_filter), Control.MOUSE_FILTER_IGNORE)
	_expect_equal("%s Popup overlay root ignores input" % label, int(game.popup_layer.overlay_root.mouse_filter), Control.MOUSE_FILTER_IGNORE)
	_expect_equal("%s Modal root ignores empty input" % label, int(game.modal_layer.root.mouse_filter), Control.MOUSE_FILTER_IGNORE)
	_expect_equal("%s Debug root ignores empty input" % label, int(game.debug_layer.root.mouse_filter), Control.MOUSE_FILTER_IGNORE)

func _verify_layout_metrics_activation() -> void:
	var metrics = FileAccess.get_file_as_string("res://scripts/ui/html_layout_metrics.gd")
	var hud = FileAccess.get_file_as_string("res://scripts/v2/prototype_hud.gd")
	var popup = FileAccess.get_file_as_string("res://scripts/v2/prototype_popup_layer.gd")
	var game = FileAccess.get_file_as_string("res://scripts/v2/prototype_game.gd")
	_expect_contains("HtmlLayoutMetrics has HTML choice width", metrics, "const CHOICE_MAX_WIDTH := 680.0")
	_expect_contains("HtmlLayoutMetrics has popup size table", metrics, "static func popup_size_for_type")
	_expect_contains("HtmlLayoutMetrics has boss package size", metrics, "return Vector2(440, 430)")
	_expect_contains("HUD preloads HtmlLayoutMetrics", hud, "const HtmlLayoutMetrics")
	_expect_contains("HUD applies desktop layout helper", hud, "HtmlLayoutMetrics.apply_desktop_hud_layout")
	_expect_contains("HUD applies choice layout helper", hud, "HtmlLayoutMetrics.apply_choice_overlay_layout")
	_expect_contains("HUD uses choice card metrics", hud, "HtmlLayoutMetrics.choice_card_min_height")
	_expect_contains("Popup layer preloads HtmlLayoutMetrics", popup, "const HtmlLayoutMetrics")
	_expect_contains("Popup layer uses popup content layout", popup, "HtmlLayoutMetrics.popup_content_layout")
	_expect_contains("Game popup sizes use HtmlLayoutMetrics", game, "HtmlLayoutMetrics.popup_size_for_type")
	_expect_contains("Game popup avoidance uses HUD metrics", game, "HtmlLayoutMetrics.combat_hud_rect")

func _project_main_scene() -> String:
	var text = FileAccess.get_file_as_string("res://project.godot")
	var marker = "run/main_scene=\""
	var start = text.find(marker)
	if start < 0:
		return ""
	start += marker.length()
	var end = text.find("\"", start)
	if end < 0:
		return ""
	return text.substr(start, end - start)

func _nodes_named(root: Node, node_name: String) -> Array:
	var result = []
	if root.name == node_name:
		result.append(root)
	for child in root.get_children():
		result.append_array(_nodes_named(child, node_name))
	return result

func _expect_script(label: String, node: Node, expected_path: String) -> void:
	var script = node.get_script()
	if script == null:
		failures.append("%s expected script %s got <none>" % [label, expected_path])
		return
	_expect_equal(label, script.resource_path, expected_path)

func _expect_contains(label: String, haystack: String, needle: String) -> void:
	if haystack.find(needle) < 0:
		failures.append("%s missing %s" % [label, needle])

func _expect_true(label: String, condition: bool) -> void:
	if not condition:
		failures.append(label)

func _expect_equal(label: String, actual, expected) -> void:
	if actual != expected:
		failures.append("%s expected %s got %s" % [label, str(expected), str(actual)])
