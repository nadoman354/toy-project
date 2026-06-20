extends SceneTree

const PrototypeGameScript = preload("res://scripts/v2/prototype_game.gd")
const HtmlLayoutMetrics = preload("res://scripts/ui/html_layout_metrics.gd")

const PC_VIEWPORT := Vector2i(1920, 1080)
const MOBILE_PORTRAIT_VIEWPORT := Vector2i(390, 844)
const MOBILE_LANDSCAPE_VIEWPORT := Vector2i(915, 412)

var game
var test_viewport: SubViewport
var ran := false
var captures := {}

func _init() -> void:
	test_viewport = SubViewport.new()
	test_viewport.size = PC_VIEWPORT
	test_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(test_viewport)
	game = PrototypeGameScript.new()
	test_viewport.add_child(game)
	process_frame.connect(_on_process_frame)

func _on_process_frame() -> void:
	if ran or game.state.is_empty():
		return
	ran = true
	_prepare_output_dir()
	await _capture_initial_module("pc_initial_module", PC_VIEWPORT, "godot_initial_module_1920x1080.png")
	await _capture_initial_module("mobile_portrait_initial_module", MOBILE_PORTRAIT_VIEWPORT, "godot_initial_module_390x844.png")
	await _capture_initial_module("mobile_landscape_initial_module", MOBILE_LANDSCAPE_VIEWPORT, "godot_initial_module_915x412.png")
	await _capture_popup_cluster("pc_popup_cluster", PC_VIEWPORT, "godot_popup_cluster_1920x1080.png")
	_save_metrics()
	print("visual_compare_godot saved %d captures" % captures.size())
	quit()

func _capture_initial_module(key: String, viewport_size: Vector2i, file_name: String) -> void:
	test_viewport.size = viewport_size
	game.hud._apply_html_layout(Vector2(viewport_size.x, viewport_size.y))
	await _settle_frames(4)
	captures[key] = {
		"image": _save_viewport_png(file_name),
		"ui": _ui_metrics(),
		"choices": _choice_metrics(),
	}

func _capture_popup_cluster(key: String, viewport_size: Vector2i, file_name: String) -> void:
	test_viewport.size = viewport_size
	game.hud._apply_html_layout(Vector2(viewport_size.x, viewport_size.y))
	if game.state.get("primaryModule", "") == "":
		game.apply_attack_module_choice("primary", game.data.ATTACK_MODULES[0])
	game.state.gold = 1000
	for id in ["ad_buff", "popup_store", "stock_broker_app", "boss_package_ad", "infection"]:
		var def = game.popup_def_by_id(id)
		if not def.is_empty():
			var popup = game.create_popup(def)
			popup.inputGrace = 0.0
	game.popup_layer.sync(game.state)
	game.hud.update_from_state(game.state)
	await _settle_frames(6)
	captures[key] = {
		"image": _save_viewport_png(file_name),
		"ui": _ui_metrics(),
		"popups": _popup_metrics(),
	}

func _settle_frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _prepare_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp/visual_compare"))

func _save_viewport_png(file_name: String) -> String:
	if DisplayServer.get_name() == "headless":
		return ""
	var path = "res://tmp/visual_compare/%s" % file_name
	var texture = test_viewport.get_texture()
	if texture == null:
		return ""
	var image = texture.get_image()
	if image == null:
		return ""
	image.save_png(path)
	return ProjectSettings.globalize_path(path)

func _save_metrics() -> void:
	var path = "res://tmp/visual_compare/godot_metrics.json"
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(captures, "\t"))
	file.close()

func _ui_metrics() -> Dictionary:
	var ui = game.hud.ui
	return {
		"viewport": {"w": test_viewport.size.x, "h": test_viewport.size.y},
		"combatHud": _control_record(ui.get("combatHud", null)),
		"economyHud": _control_record(ui.get("economyHud", null)),
		"difficultyHud": _control_record(ui.get("difficultyHud", null)),
		"statusPanel": _control_record(ui.get("statusPanel", null)),
		"debugPanel": _control_record(ui.get("debugPanel", null)),
		"choiceOverlay": _control_record(ui.get("choiceOverlay", null)),
		"choicePanel": _control_record(ui.get("choicePanel", null)),
		"choiceTitle": _control_record(ui.get("choiceTitle", null)),
		"choiceDescription": _control_record(ui.get("choiceDescription", null)),
		"choiceScroll": _control_record(ui.get("choiceScroll", null)),
		"choiceGrid": _control_record(ui.get("choiceGrid", null)),
		"choiceColumns": int(ui.choiceGrid.columns) if ui.has("choiceGrid") else 0,
	}

func _choice_metrics() -> Array:
	var result = []
	if not game.hud.ui.has("choiceGrid"):
		return result
	for child in game.hud.ui.choiceGrid.get_children():
		if child is Control:
			result.append({
				"card": _control_record(child),
				"title": _control_record(_find_node_named(child, "choiceTitleText")),
				"description": _control_record(_find_node_named(child, "choiceDescriptionText")),
				"meta": _control_record(_find_node_named(child, "choiceMetaText")),
			})
	return result

func _popup_metrics() -> Array:
	var result = []
	for id in game.popup_layer.windows.keys():
		var record = game.popup_layer.windows[id]
		result.append({
			"id": id,
			"panel": _control_record(record.panel),
			"title": _control_record(record.title),
			"body": _control_record(record.body),
			"detail": _control_record(record.detail),
			"controls": _control_record(record.controls),
			"buttons": _button_metrics(record.controls),
		})
	return result

func _button_metrics(node: Node) -> Array:
	var result = []
	for child in node.get_children():
		if child is Button or child is Label:
			result.append(_control_record(child))
		result.append_array(_button_metrics(child))
	return result

func _control_record(control) -> Dictionary:
	if control == null or not control is Control:
		return {"missing": true}
	var rect = control.get_global_rect()
	var record = {
		"name": control.name,
		"type": control.get_class(),
		"visible": control.visible,
		"rect": _rect_dict(rect),
		"custom_min": _vec_dict(control.custom_minimum_size),
	}
	if control is Label:
		record.text = control.text
	elif control is RichTextLabel:
		record.text = control.text
	elif control is Button:
		record.text = control.text
	return record

func _rect_dict(rect: Rect2) -> Dictionary:
	return {
		"x": round(rect.position.x),
		"y": round(rect.position.y),
		"w": round(rect.size.x),
		"h": round(rect.size.y),
	}

func _vec_dict(vec: Vector2) -> Dictionary:
	return {"x": round(vec.x), "y": round(vec.y)}

func _find_node_named(root_node: Node, node_name: String):
	if root_node == null:
		return null
	if root_node.name == node_name:
		return root_node
	for child in root_node.get_children():
		var found = _find_node_named(child, node_name)
		if found != null:
			return found
	return null
