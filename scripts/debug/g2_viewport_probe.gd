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
	_verify_project_viewport_settings()
	_verify_no_fixed_board_container()
	for viewport_size in [Vector2i(960, 540), Vector2i(1152, 648), Vector2i(1920, 1080), Vector2i(2340, 1080)]:
		await _verify_viewport_fill(viewport_size)
	if failures.is_empty():
		print("g2_viewport_probe passed")
		get_tree().quit()
		return
	for failure in failures:
		push_error(str(failure))
	get_tree().quit(1)

func _verify_project_viewport_settings() -> void:
	_expect_equal("project viewport width", ProjectSettings.get_setting("display/window/size/viewport_width"), HtmlLayoutMetrics.PC_VIEWPORT_WIDTH)
	_expect_equal("project viewport height", ProjectSettings.get_setting("display/window/size/viewport_height"), HtmlLayoutMetrics.PC_VIEWPORT_HEIGHT)
	_expect_equal("project stretch mode", ProjectSettings.get_setting("display/window/stretch/mode"), "disabled")
	_expect_equal("project stretch aspect", ProjectSettings.get_setting("display/window/stretch/aspect"), "ignore")

func _verify_no_fixed_board_container() -> void:
	var fixed_container = _find_class_named(game, ["CenterContainer", "AspectRatioContainer", "SubViewportContainer"])
	if fixed_container != null:
		failures.append("main scene contains fixed board container %s" % fixed_container.get_path())

func _verify_viewport_fill(viewport_size: Vector2i) -> void:
	get_window().size = viewport_size
	await get_tree().process_frame
	await get_tree().process_frame
	game.hud.update_from_state(game.state)
	game.world.queue_redraw()
	await get_tree().process_frame
	var expected = Vector2(viewport_size.x, viewport_size.y)
	_expect_vector("%s visible viewport" % str(viewport_size), game.get_viewport().get_visible_rect().size, expected)
	_expect_vector("%s world viewport rect" % str(viewport_size), game.world.get_viewport_rect().size, expected)
	_expect_control_size("%s hud root" % str(viewport_size), game.hud.ui.root, expected)
	_expect_control_size("%s popup root" % str(viewport_size), game.popup_layer.root, expected)
	_expect_control_size("%s popup telegraph root" % str(viewport_size), game.popup_layer.telegraph_root, expected)
	_expect_control_size("%s popup overlay root" % str(viewport_size), game.popup_layer.overlay_root, expected)
	_expect_control_size("%s debug root" % str(viewport_size), game.debug_layer.root, expected)
	_expect_control_size("%s modal root" % str(viewport_size), game.modal_layer.root, expected)

func _expect_control_size(label: String, control: Control, expected: Vector2) -> void:
	if control == null:
		failures.append("%s missing" % label)
		return
	_expect_vector(label, control.size, expected)
	_expect_equal("%s scale" % label, control.scale, Vector2.ONE)

func _expect_vector(label: String, actual: Vector2, expected: Vector2) -> void:
	if not _pixel_close(actual.x, expected.x) or not _pixel_close(actual.y, expected.y):
		failures.append("%s expected %s got %s" % [label, str(expected), str(actual)])

func _expect_equal(label: String, actual, expected) -> void:
	if actual != expected:
		failures.append("%s expected %s got %s" % [label, str(expected), str(actual)])

func _pixel_close(a: float, b: float) -> bool:
	return abs(a - b) <= 0.51

func _find_class_named(node: Node, class_names: Array) -> Node:
	if class_names.has(node.get_class()):
		return node
	for child in node.get_children():
		var found = _find_class_named(child, class_names)
		if found != null:
			return found
	return null
