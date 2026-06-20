extends SceneTree

const PrototypeGameScript = preload("res://scripts/v2/prototype_game.gd")
const HtmlLayoutMetrics = preload("res://scripts/ui/html_layout_metrics.gd")

var game
var test_viewport: SubViewport
var initialized := false
var ran := false
var runtime_choice_cases_checked := 0
var runtime_popup_cases_checked := 0
var text_capacity_cases_checked := 0

func _init() -> void:
	_initialize()

func _initialize() -> void:
	if initialized:
		return
	initialized = true
	test_viewport = SubViewport.new()
	test_viewport.size = Vector2i(HtmlLayoutMetrics.PC_VIEWPORT_WIDTH, HtmlLayoutMetrics.PC_VIEWPORT_HEIGHT)
	test_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(test_viewport)
	game = PrototypeGameScript.new()
	test_viewport.add_child(game)
	process_frame.connect(_on_process_frame)

func _on_process_frame() -> void:
	if ran or game.state.is_empty():
		return
	ran = true
	var failures: Array = []
	_verify_viewport_fill_config(failures)
	_verify_layer_priority(failures)
	await _verify_layout_for_viewport(Vector2(1920, 1080), failures)
	await _verify_layout_for_viewport(Vector2(1080, 2340), failures)
	await _verify_layout_for_viewport(Vector2(2340, 1080), failures)
	await _verify_layout_for_viewport(Vector2(412, 915), failures)
	await _verify_layout_for_viewport(Vector2(915, 412), failures)
	await _verify_layout_for_viewport(Vector2(768, 1024), failures)
	await _verify_layout_for_viewport(Vector2(1152, 648), failures)
	await _verify_layout_for_viewport(Vector2(960, 540), failures)
	await _verify_layout_for_viewport(Vector2(1440, 810), failures)
	await _verify_layout_for_viewport(Vector2(860, 520), failures)
	await _verify_layout_for_viewport(Vector2(760, 520), failures)
	await _verify_layout_for_viewport(Vector2(640, 360), failures)
	await _verify_layout_for_viewport(Vector2(390, 844), failures)
	_verify_progression_gates(failures)
	_verify_popup_sizes(failures)
	await _verify_input_policy(failures)
	await _verify_g1_button_acceptance(failures)
	await _verify_runtime_generated_ui(failures)
	if failures.is_empty():
		print("layout_probe passed; runtime_choice_cases=%d runtime_popup_cases=%d text_capacity_cases=%d" % [runtime_choice_cases_checked, runtime_popup_cases_checked, text_capacity_cases_checked])
		quit()
		return
	for failure in failures:
		push_error(str(failure))
	quit(1)

func _verify_layout_for_viewport(viewport_size: Vector2, failures: Array) -> void:
	test_viewport.size = Vector2i(int(round(viewport_size.x)), int(round(viewport_size.y)))
	await _settle_layout(viewport_size)
	_expect_rect("combat %s" % viewport_size, game.hud.ui.combatHud, HtmlLayoutMetrics.combat_hud_rect(viewport_size), viewport_size, failures)
	_expect_rect("economy %s" % viewport_size, game.hud.ui.economyHud, HtmlLayoutMetrics.economy_hud_rect(viewport_size), viewport_size, failures)
	_expect_rect("difficulty %s" % viewport_size, game.hud.ui.difficultyHud, HtmlLayoutMetrics.difficulty_hud_rect(viewport_size), viewport_size, failures)
	_expect_rect("cleanup %s" % viewport_size, game.hud.ui.cleanupHud, HtmlLayoutMetrics.cleanup_hud_rect(viewport_size), viewport_size, failures)
	_expect_rect("status %s" % viewport_size, game.hud.ui.statusPanel, HtmlLayoutMetrics.status_hud_rect(viewport_size), viewport_size, failures)
	_expect_rect("debug %s" % viewport_size, game.hud.ui.debugPanel, HtmlLayoutMetrics.debug_hud_rect(viewport_size), viewport_size, failures)
	_expect_equal("debug visibility %s" % viewport_size, game.hud.ui.debugPanel.visible, HtmlLayoutMetrics.debug_visible_for_viewport(viewport_size), failures)
	for key in ["combatHud", "economyHud", "difficultyHud", "cleanupHud", "statusPanel"]:
		_expect_inside("%s inside %s" % [key, viewport_size], game.hud.ui[key], viewport_size, failures)
	for key in ["combatHud", "economyHud", "statusPanel", "debugPanel"]:
		_expect_equal("%s clip contents %s" % [key, viewport_size], game.hud.ui[key].clip_contents, true, failures)
	_verify_combat_hud_text(viewport_size, failures)
	_verify_content_margin_density(viewport_size, failures)

	if game.hud.status_minimized:
		game.hud._toggle_status()
	game.hud._toggle_status()
	await _settle_layout(viewport_size)
	_expect_rect("status minimized %s" % viewport_size, game.hud.ui.statusPanel, HtmlLayoutMetrics.status_hud_rect(viewport_size, true), viewport_size, failures)
	_expect_visible_text_label("status minimized title %s" % viewport_size, game.hud.ui.statusTitle, failures)
	_expect_control_inside_control("status minimized title safe %s" % viewport_size, game.hud.ui.statusTitle, game.hud.ui.statusPanel, 1.0, failures)
	game.hud._toggle_status()

	if not game.hud.ui.debugBody.visible:
		game.hud._toggle_debug()
	game.hud._toggle_debug()
	await _settle_layout(viewport_size)
	_expect_rect("debug minimized %s" % viewport_size, game.hud.ui.debugPanel, HtmlLayoutMetrics.debug_hud_rect(viewport_size, true), viewport_size, failures)
	_expect_visible_text_label("debug minimized title %s" % viewport_size, game.hud.ui.debugTitle, failures)
	_expect_control_inside_control("debug minimized title safe %s" % viewport_size, game.hud.ui.debugTitle, game.hud.ui.debugPanel, 1.0, failures)
	game.hud._toggle_debug()

	var long_item = game.data.ITEMS[0].duplicate(true)
	long_item.description = "긴 설명 검증: 패시브 아이템 1개를 선택해 현재 런 성능을 누적 성장시키고, 태그와 현재/선택 후 수치가 카드 안에서 줄바꿈되어야 합니다."
	var long_module = game.data.ATTACK_MODULES[0].duplicate(true)
	long_module.description = "긴 모듈 설명 검증: 기본 공격 방식, 쿨타임, 범위, 호환 태그 문장이 카드 안에서 겹치지 않아야 합니다."
	var long_contract = game.data.FIRST_PURCHASE_PACKAGES[0].duplicate(true)
	long_contract.description = "긴 계약 설명 검증: 초반 성장 효율, 계약 효과, 아이템 풀 설명이 선택 카드 내부에서 자연스럽게 줄바꿈되어야 합니다."
	var choices = [long_item, long_module, long_contract]
	game.hud.show_choices("검증", "HTML choice layout", choices, func(_choice): pass, 3)
	await _settle_layout(viewport_size)
	var panel_size = HtmlLayoutMetrics.choice_panel_size(viewport_size)
	var expected_panel = Rect2(Vector2((viewport_size.x - panel_size.x) * 0.5, (viewport_size.y - panel_size.y) * 0.5), panel_size)
	_expect_rect("choice panel %s" % viewport_size, game.hud.ui.choicePanel, expected_panel, viewport_size, failures)
	_expect_equal("choice columns %s" % viewport_size, game.hud.ui.choiceGrid.columns, HtmlLayoutMetrics.choice_columns_for_width(panel_size.x, viewport_size), failures)
	_expect_control_vertical_inside_control("choice panel title vertical safe %s" % viewport_size, game.hud.ui.choiceTitle, game.hud.ui.choicePanel, HtmlLayoutMetrics.choice_panel_text_safe_inset(viewport_size), failures)
	var choice_scroll_inset = game.hud.ui.get("choiceScrollInset", null)
	if choice_scroll_inset is MarginContainer:
		_expect_equal("choice scrollbar inset %s" % viewport_size, choice_scroll_inset.get_theme_constant("margin_right"), HtmlLayoutMetrics.scrollbar_safe_inset(viewport_size), failures)
	else:
		failures.append("choice scrollbar inset missing %s" % viewport_size)
	var expected_card_width = HtmlLayoutMetrics.choice_card_width(panel_size.x, game.hud.ui.choiceGrid.columns, viewport_size)
	for child in game.hud.ui.choiceGrid.get_children():
		var kind = str(child.get_meta("choiceKind", "generic")) if child is Control else "generic"
		if child is Control and float(child.custom_minimum_size.x) < expected_card_width:
			failures.append("card width %s expected >= %.1f got %.1f" % [viewport_size, expected_card_width, child.custom_minimum_size.x])
		if child is Control and float(child.custom_minimum_size.y) < HtmlLayoutMetrics.choice_card_min_height(kind, viewport_size):
			failures.append("card height %s expected >= %.1f got %.1f" % [viewport_size, HtmlLayoutMetrics.choice_card_min_height(kind, viewport_size), child.custom_minimum_size.y])
		if child is Control:
			var required_height = game.hud._choice_card_required_height(child, expected_card_width, viewport_size)
			if float(child.custom_minimum_size.y) < required_height:
				failures.append("card content height %s expected >= %.1f got %.1f" % [viewport_size, required_height, child.custom_minimum_size.y])
		var title = _find_node_named(child, "choiceTitleText")
		if title is Label:
			_expect_equal("choice title wrap %s" % viewport_size, title.autowrap_mode, TextServer.AUTOWRAP_OFF, failures)
			_expect_equal("choice title ellipsis %s" % viewport_size, title.text_overrun_behavior, TextServer.OVERRUN_TRIM_ELLIPSIS, failures)
			_expect_control_inside_control("choice card title safe %s" % viewport_size, title, child, 1.0, failures)
		var desc = _find_node_named(child, "choiceDescriptionText")
		if desc is Label:
			_expect_equal("choice desc wrap %s" % viewport_size, desc.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART, failures)
			_expect_equal("choice desc no ellipsis %s" % viewport_size, desc.text_overrun_behavior, TextServer.OVERRUN_NO_TRIMMING, failures)
			if float(desc.custom_minimum_size.y) < HtmlLayoutMetrics.choice_description_height(kind, viewport_size):
				failures.append("choice desc height %s expected >= %.1f got %.1f" % [viewport_size, HtmlLayoutMetrics.choice_description_height(kind, viewport_size), desc.custom_minimum_size.y])
			_expect_control_inside_control("choice card desc safe %s" % viewport_size, desc, child, 1.0, failures)
		var meta = _find_node_named(child, "choiceMetaText")
		if meta is Label:
			_expect_equal("choice meta wrap %s" % viewport_size, meta.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART, failures)
			_expect_control_inside_control("choice card meta safe %s" % viewport_size, meta, child, 1.0, failures)
	game.hud.hide_choices()
	_expect_equal("choice layout scale reset %s" % viewport_size, game.hud.choice_layout_scale, 1.0, failures)

	var starter_choices = []
	for package in game.data.FIRST_PURCHASE_PACKAGES:
		starter_choices.append(package.duplicate(true))
	game.hud.show_choices("스타터 계약 패키지 선택", "결제 완료. 한정 스타터 계약 1개를 선택해 이번 런의 성장 효율을 확정하세요.", starter_choices, func(_choice): pass, 2, 1.7)
	await _settle_layout(viewport_size)
	var starter_panel_size = HtmlLayoutMetrics.choice_panel_size(viewport_size, 1.7)
	var expected_starter_panel = Rect2(Vector2((viewport_size.x - starter_panel_size.x) * 0.5, (viewport_size.y - starter_panel_size.y) * 0.5), starter_panel_size)
	_expect_rect("starter choice panel scaled %s" % viewport_size, game.hud.ui.choicePanel, expected_starter_panel, viewport_size, failures)
	_expect_control_vertical_inside_control("starter choice title vertical safe %s" % viewport_size, game.hud.ui.choiceTitle, game.hud.ui.choicePanel, HtmlLayoutMetrics.choice_panel_text_safe_inset(viewport_size), failures)
	_expect_control_inside_control("starter choice scroll inside panel %s" % viewport_size, game.hud.ui.choiceScroll, game.hud.ui.choicePanel, 1.0, failures)
	game.hud.hide_choices()

func _settle_layout(viewport_size: Vector2) -> void:
	game.hud._apply_html_layout(viewport_size)
	await process_frame
	game.hud._apply_html_layout(viewport_size)
	await process_frame

func _verify_progression_gates(failures: Array) -> void:
	game.state.primaryModule = game.data.ATTACK_MODULES[0].id
	game.state.secondaryModule = ""
	game.state.moduleSynergy = {}
	_expect_equal("advanced master flag disabled", game.progression_choice_enabled("enableAdvancedBuildChoices"), false, failures)
	_expect_equal("build optimization flag disabled", game.progression_choice_enabled("enableBuildOptimizationChoices"), false, failures)
	game.state.level = 5
	_expect_equal("secondary module enabled", game.next_growth_choice_label(), "보조 모듈", failures)
	game.state.secondaryModule = game.data.ATTACK_MODULES[1].id
	game.state.level = 8
	_expect_equal("attack form gated before 9", game.next_growth_choice_label(), "패시브 보상", failures)
	game.state.level = 9
	_expect_equal("attack form enabled", game.next_growth_choice_label(), "공격 방식", failures)
	game.state.level = 13
	_expect_equal("attack mechanic enabled", game.next_growth_choice_label(), "공격 기믹", failures)
	game.state.level = 11
	_expect_equal("build optimization gated", game.next_growth_choice_label(), "패시브 보상", failures)
	game.state.level = 15
	_expect_equal("synergy gated", game.next_growth_choice_label(), "패시브 보상", failures)
	game.state.level = 4
	_expect_equal("deepening gated", game.next_growth_choice_label(), "패시브 보상", failures)

func _verify_popup_sizes(failures: Array) -> void:
	var expected = {
		"system_notice": Vector2(260, 120),
		"first_purchase_package": Vector2(336, 236),
		"boss_package_ad": Vector2(440, 430),
		"popup_store": Vector2(326, 230),
		"stock_broker_app": Vector2(300, 260),
		"interest_offer": Vector2(350, 250),
		"recurring_investment": Vector2(342, 230),
		"sponsored_ad": Vector2(300, 190),
		"security_update_notice": Vector2(292, 150),
		"terms": Vector2(318, 218),
	}
	for type in expected.keys():
		_expect_vector("popup %s" % type, game.popup_size_for({"type": type}), expected[type], failures)
		if HtmlLayoutMetrics.popup_layout_group(type) == "":
			failures.append("popup %s has no layout group" % type)

func _verify_viewport_fill_config(failures: Array) -> void:
	_expect_equal("viewport width", ProjectSettings.get_setting("display/window/size/viewport_width"), HtmlLayoutMetrics.PC_VIEWPORT_WIDTH, failures)
	_expect_equal("viewport height", ProjectSettings.get_setting("display/window/size/viewport_height"), HtmlLayoutMetrics.PC_VIEWPORT_HEIGHT, failures)
	_expect_equal("stretch mode", ProjectSettings.get_setting("display/window/stretch/mode"), "disabled", failures)
	_expect_equal("stretch aspect", ProjectSettings.get_setting("display/window/stretch/aspect"), "ignore", failures)
	var fixed_container = _find_class_named(game, ["CenterContainer", "AspectRatioContainer", "SubViewportContainer"])
	if fixed_container != null:
		failures.append("active scene contains fixed viewport container %s" % fixed_container.get_path())

func _verify_layer_priority(failures: Array) -> void:
	if game.modal_layer != null and game.debug_layer != null:
		if int(game.modal_layer.layer) <= int(game.debug_layer.layer):
			failures.append("modal layer should render above debug layer: modal %d debug %d" % [int(game.modal_layer.layer), int(game.debug_layer.layer)])

func _verify_input_policy(failures: Array) -> void:
	var desktop_size = Vector2(HtmlLayoutMetrics.PC_VIEWPORT_WIDTH, HtmlLayoutMetrics.PC_VIEWPORT_HEIGHT)
	test_viewport.size = Vector2i(HtmlLayoutMetrics.PC_VIEWPORT_WIDTH, HtmlLayoutMetrics.PC_VIEWPORT_HEIGHT)
	game.hud._apply_html_layout(desktop_size)
	_expect_equal("hud root ignores mouse", game.hud.ui.root.mouse_filter, Control.MOUSE_FILTER_IGNORE, failures)
	_expect_equal("debug body is scroll container", game.hud.ui.debugBody is ScrollContainer, true, failures)
	for key in ["combatHud", "economyHud", "statusPanel"]:
		_expect_equal("%s ignores mouse" % key, game.hud.ui[key].mouse_filter, Control.MOUSE_FILTER_IGNORE, failures)
	_expect_equal("debugPanel blocks mouse on desktop", game.hud.ui.debugPanel.mouse_filter, Control.MOUSE_FILTER_STOP, failures)
	for key in ["rollItemButton", "openInventoryButton", "statusToggleButton", "debugToggleButton"]:
		_expect_equal("%s stops mouse" % key, game.hud.ui[key].mouse_filter, Control.MOUSE_FILTER_STOP, failures)
	_expect_equal("hidden choice overlay ignores mouse", game.hud.ui.choiceOverlay.mouse_filter, Control.MOUSE_FILTER_IGNORE, failures)

	game.hud.show_choices("검증", "input policy", [game.data.ITEMS[0], game.data.ITEMS[1], game.data.ITEMS[2]], func(_choice): pass, 3)
	_expect_equal("visible choice overlay stops mouse", game.hud.ui.choiceOverlay.mouse_filter, Control.MOUSE_FILTER_STOP, failures)
	for card in game.hud.ui.choiceGrid.get_children():
		_expect_equal("choice card stops mouse", card.mouse_filter, Control.MOUSE_FILTER_STOP, failures)
		for child in card.get_children():
			_verify_control_tree_ignores_mouse(child, "choice child", failures)
	game.hud.hide_choices()
	_expect_equal("hidden choice overlay ignores mouse after hide", game.hud.ui.choiceOverlay.mouse_filter, Control.MOUSE_FILTER_IGNORE, failures)

	var popup = game.create_popup(game.popup_def_by_id("moving_close"))
	popup.inputGrace = 0.0
	game.popup_layer.sync(game.state)
	await process_frame
	game.popup_layer.sync(game.state)
	var record = game.popup_layer.windows.get(int(popup.id), null)
	if record == null:
		failures.append("popup window was not created")
	else:
		var popup_layout = HtmlLayoutMetrics.popup_content_layout(HtmlLayoutMetrics.viewport_size(game.get_viewport()), popup.def.type, popup.size, str(record.body.text), str(record.detail.text), record.statusBadges.get_child_count() > 0)
		_expect_equal("popup panel stops mouse", record.panel.mouse_filter, Control.MOUSE_FILTER_STOP, failures)
		_expect_equal("popup title frame stops mouse", record.title_frame.mouse_filter, Control.MOUSE_FILTER_STOP, failures)
		_expect_equal("popup body ignores mouse", record.body.mouse_filter, Control.MOUSE_FILTER_IGNORE, failures)
		_expect_equal("popup detail ignores mouse", record.detail.mouse_filter, Control.MOUSE_FILTER_IGNORE, failures)
		_expect_equal("popup progress ignores mouse", record.progress.mouse_filter, Control.MOUSE_FILTER_IGNORE, failures)
		if float(record.body.custom_minimum_size.y) + 4.0 < float(popup_layout.body_height):
			failures.append("popup body height expected >= %.1f got %.1f" % [float(popup_layout.body_height), record.body.custom_minimum_size.y])
		_expect_popup_regions_inside("moving popup regions", record, failures)
		_expect_popup_layout_contract("moving popup layout contract", popup, record, failures)
		var first_button = _first_button(record.controls)
		if first_button == null:
			failures.append("popup controls did not create a button")
		else:
			_expect_equal("popup control button stops mouse", first_button.mouse_filter, Control.MOUSE_FILTER_STOP, failures)
			var instance_id = first_button.get_instance_id()
			game.popup_layer.sync(game.state)
			await process_frame
			game.popup_layer.sync(game.state)
			var next_button = _first_button(record.controls)
			if next_button == null or next_button.get_instance_id() != instance_id:
				failures.append("popup controls rebuilt without state change")
	game.remove_popup_without_reward(popup.id)
	game.popup_layer.sync(game.state)

	var terms_popup = game.create_popup(game.popup_def_by_id("terms_ad_tracking"))
	terms_popup.inputGrace = 0.0
	game.popup_layer.sync(game.state)
	await process_frame
	game.popup_layer.sync(game.state)
	var terms_record = game.popup_layer.windows.get(int(terms_popup.id), null)
	if terms_record == null:
		failures.append("terms popup window was not created")
	else:
		if not terms_record.body.scroll_active:
			failures.append("terms popup body should be scrollable for long text")
		if not terms_record.detail.visible:
			failures.append("terms popup detail should be visible")
		if float(terms_record.detail.custom_minimum_size.y) <= 0.0:
			failures.append("terms popup detail height should be positive")
		_expect_popup_layout_contract("terms popup layout contract", terms_popup, terms_record, failures)
	game.remove_popup_without_reward(terms_popup.id)
	game.popup_layer.sync(game.state)

	var grace_popup = game.create_popup(game.popup_def_by_id("timed_reward"))
	game.popup_layer.sync(game.state)
	await process_frame
	game.popup_layer.sync(game.state)
	var grace_record = game.popup_layer.windows.get(int(grace_popup.id), null)
	if grace_record != null:
		_expect_popup_layout_contract("grace popup layout contract", grace_popup, grace_record, failures)
		var disabled_button = _first_button(grace_record.controls)
		if disabled_button == null or not disabled_button.disabled:
			failures.append("popup input grace did not temporarily disable buttons")
		grace_popup.inputGrace = 0.0
		game.popup_layer.sync(game.state)
		await process_frame
		game.popup_layer.sync(game.state)
		var enabled_button = _first_button(grace_record.controls)
		if enabled_button == null or enabled_button.disabled:
			failures.append("popup buttons did not re-enable after input grace")
	game.remove_popup_without_reward(grace_popup.id)
	game.popup_layer.sync(game.state)

	var boss_popup = game.create_popup(game.popup_def_by_id("boss_package_ad"))
	boss_popup.inputGrace = 0.0
	game.popup_layer.sync(game.state)
	await process_frame
	game.popup_layer.sync(game.state)
	var boss_record = game.popup_layer.windows.get(int(boss_popup.id), null)
	if boss_record == null:
		failures.append("boss popup window was not created")
	else:
		var boss_layout = HtmlLayoutMetrics.popup_content_layout(HtmlLayoutMetrics.viewport_size(game.get_viewport()), boss_popup.def.type, boss_popup.size)
		if float(boss_record.body.custom_minimum_size.y) > 92.0:
			failures.append("boss popup body is too tall: %.1f" % boss_record.body.custom_minimum_size.y)
		if float(boss_record.detail.custom_minimum_size.y) < float(boss_layout.detail_height):
			failures.append("boss popup detail height expected >= %.1f got %.1f" % [float(boss_layout.detail_height), boss_record.detail.custom_minimum_size.y])
		_expect_popup_regions_inside("boss popup regions", boss_record, failures)
		_expect_popup_layout_contract("boss popup layout contract", boss_popup, boss_record, failures)
	game.remove_popup_without_reward(boss_popup.id)
	game.popup_layer.sync(game.state)

	var sponsored_popup = game.create_popup(game.popup_def_by_id("ad_buff"))
	sponsored_popup.inputGrace = 0.0
	game.popup_layer.sync(game.state)
	await process_frame
	game.popup_layer.sync(game.state)
	var sponsored_record = game.popup_layer.windows.get(int(sponsored_popup.id), null)
	if sponsored_record == null:
		failures.append("sponsored popup window was not created")
	else:
		_expect_popup_regions_inside("sponsored popup regions", sponsored_record, failures)
		if float(sponsored_record.detail.custom_minimum_size.y) < 48.0:
			failures.append("sponsored popup detail too short: %.1f" % sponsored_record.detail.custom_minimum_size.y)
		_expect_popup_layout_contract("sponsored popup layout contract", sponsored_popup, sponsored_record, failures)
	game.remove_popup_without_reward(sponsored_popup.id)
	game.popup_layer.sync(game.state)

func _verify_g1_button_acceptance(failures: Array) -> void:
	var desktop_size = Vector2(HtmlLayoutMetrics.PC_VIEWPORT_WIDTH, HtmlLayoutMetrics.PC_VIEWPORT_HEIGHT)
	test_viewport.size = Vector2i(int(desktop_size.x), int(desktop_size.y))
	_prepare_g1_interaction_state()
	game.hud._apply_html_layout(desktop_size)
	await process_frame

	var choice_probe = {"called": false}
	game.hud.show_choices("검증", "G1 choice card", [game.data.ITEMS[0]], func(_choice): choice_probe["called"] = true, 1)
	await process_frame
	var choice_button = null
	if game.hud.ui.choiceGrid.get_child_count() > 0:
		choice_button = game.hud.ui.choiceGrid.get_child(0)
	if choice_button is Button:
		_expect_equal("g1 choice overlay blocks world input", game.hud.ui.choiceOverlay.mouse_filter, Control.MOUSE_FILTER_STOP, failures)
		_expect_equal("g1 choice card button stops mouse", choice_button.mouse_filter, Control.MOUSE_FILTER_STOP, failures)
		_expect_equal("g1 choice card enabled", choice_button.disabled, false, failures)
		choice_button.emit_signal("pressed")
		_expect_equal("g1 choice card callback fired", choice_probe.called, true, failures)
	else:
		failures.append("g1 choice card button missing")
	game.hud.hide_choices()
	_expect_equal("g1 hidden choice overlay ignores mouse", game.hud.ui.choiceOverlay.mouse_filter, Control.MOUSE_FILTER_IGNORE, failures)

	_prepare_g1_interaction_state()
	var item_cost = game.current_item_roll_cost()
	game.state.gold = max(int(game.state.gold), item_cost + 100)
	game.hud.update_from_state(game.state)
	var item_machine_button = game.hud.ui.rollItemButton
	_expect_equal("g1 item machine stops mouse", item_machine_button.mouse_filter, Control.MOUSE_FILTER_STOP, failures)
	_expect_equal("g1 item machine enabled with enough gold", item_machine_button.disabled, false, failures)
	var gold_before_roll = int(game.state.gold)
	item_machine_button.emit_signal("pressed")
	await process_frame
	_expect_equal("g1 item machine opens item selection", game.state.selectingItem and game.hud.ui.choiceOverlay.visible, true, failures)
	if int(game.state.gold) >= gold_before_roll:
		failures.append("g1 item machine did not spend gold")

	_prepare_g1_interaction_state()
	var inventory_item_id = str(game.data.ITEMS[0].get("id", ""))
	if inventory_item_id != "":
		game.state.itemCounts[inventory_item_id] = max(1, int(game.state.itemCounts.get(inventory_item_id, 0)))
	game.hud.update_from_state(game.state)
	var inventory_button = game.hud.ui.openInventoryButton
	_expect_equal("g1 inventory button stops mouse", inventory_button.mouse_filter, Control.MOUSE_FILTER_STOP, failures)
	_expect_equal("g1 inventory button enabled when allowed", inventory_button.disabled, false, failures)
	inventory_button.emit_signal("pressed")
	await process_frame
	_expect_equal("g1 inventory overlay opens", game.state.selectingItem and game.hud.ui.choiceOverlay.visible, true, failures)
	var inventory_close_button = _first_button(game.hud.ui.choiceGrid)
	if inventory_close_button == null:
		failures.append("g1 inventory close button missing")
	else:
		_expect_equal("g1 inventory close button stops mouse", inventory_close_button.mouse_filter, Control.MOUSE_FILTER_STOP, failures)
		_expect_equal("g1 inventory close button enabled", inventory_close_button.disabled, false, failures)
		inventory_close_button.emit_signal("pressed")
		await process_frame
		_expect_equal("g1 inventory close callback fired", game.state.selectingItem or game.hud.ui.choiceOverlay.visible, false, failures)

	_prepare_g1_interaction_state()
	var title_popup = game.create_popup(game.popup_def_by_id("moving_close"))
	title_popup.inputGrace = 0.0
	game.popup_layer.sync(game.state)
	await process_frame
	game.popup_layer.sync(game.state)
	var title_record = game.popup_layer.windows.get(int(title_popup.id), null)
	if title_record == null:
		failures.append("g1 popup title close window missing")
	else:
		var title_close_button = _first_button(title_record.title_bar)
		if title_close_button == null:
			failures.append("g1 popup close button missing")
		else:
			_expect_equal("g1 popup close button stops mouse", title_close_button.mouse_filter, Control.MOUSE_FILTER_STOP, failures)
			_expect_equal("g1 popup close button enabled", title_close_button.disabled, false, failures)
			title_close_button.emit_signal("pressed")
			game.popup_layer.sync(game.state)
			await process_frame
			_expect_equal("g1 popup close callback removed popup", game.popup_by_id(int(title_popup.id)) == null, true, failures)

	_prepare_g1_interaction_state()
	var content_popup = game.create_popup(game.popup_def_by_id("moving_close"))
	content_popup.inputGrace = 0.0
	game.popup_layer.sync(game.state)
	await process_frame
	game.popup_layer.sync(game.state)
	var content_record = game.popup_layer.windows.get(int(content_popup.id), null)
	if content_record == null:
		failures.append("g1 popup content window missing")
	else:
		var content_button = _first_button(content_record.controls)
		if content_button == null:
			failures.append("g1 popup content button missing")
		else:
			_expect_equal("g1 popup content button stops mouse", content_button.mouse_filter, Control.MOUSE_FILTER_STOP, failures)
			_expect_equal("g1 popup content button enabled", content_button.disabled, false, failures)
			content_button.emit_signal("pressed")
			game.popup_layer.sync(game.state)
			await process_frame
			_expect_equal("g1 popup content callback removed popup", game.popup_by_id(int(content_popup.id)) == null, true, failures)

	_prepare_g1_interaction_state()
	var debug_button = game.hud.ui.debugButtons.get_child(0) if game.hud.ui.debugButtons.get_child_count() > 0 else null
	if debug_button is Button:
		_expect_equal("g1 debug button stops mouse", debug_button.mouse_filter, Control.MOUSE_FILTER_STOP, failures)
		_expect_equal("g1 debug button enabled", debug_button.disabled, false, failures)
		var debug_gold_before = int(game.state.gold)
		debug_button.emit_signal("pressed")
		_expect_equal("g1 debug button callback changed state", int(game.state.gold) > debug_gold_before, true, failures)
	else:
		failures.append("g1 debug button missing")

	_prepare_g1_interaction_state()

func _prepare_g1_interaction_state() -> void:
	game.state.gameOver = false
	game.state.paused = false
	game.state.selectingItem = false
	game.state.selectingPerk = false
	game.state.selectingModule = false
	game.state.selectingPaidReward = false
	game.state.emergencyTimer = 0.0
	if game.state.has("openPopups"):
		game.state.openPopups.clear()
	if game.state.has("pendingPopupSpawns"):
		game.state.pendingPopupSpawns.clear()
	game.hud.hide_choices()
	game.popup_layer.sync(game.state)
	game.hud.update_from_state(game.state)

func _verify_runtime_generated_ui(failures: Array) -> void:
	var desktop = Vector2(HtmlLayoutMetrics.PC_VIEWPORT_WIDTH, HtmlLayoutMetrics.PC_VIEWPORT_HEIGHT)
	var compact = Vector2(640, 360)
	var mobile_portrait = Vector2(1080, 2340)
	await _verify_runtime_choice_cases(desktop, failures)
	await _verify_runtime_choice_cases(compact, failures)
	await _verify_runtime_choice_cases(mobile_portrait, failures)
	await _verify_runtime_popup_cases(desktop, failures)
	await _verify_game_over_overlay_case(desktop, failures)
	await _verify_mobile_runtime_controls(compact, failures)
	await _verify_mobile_runtime_controls(mobile_portrait, failures)
	_clear_runtime_popups()
	game.hud.hide_choices()
	game.state.gameOver = false
	game.hud._apply_html_layout(desktop)

func _verify_runtime_choice_cases(viewport_size: Vector2, failures: Array) -> void:
	test_viewport.size = Vector2i(int(viewport_size.x), int(viewport_size.y))
	await _settle_layout(viewport_size)
	await _verify_choice_case("attack module choices", viewport_size, "시작 1차 공격 모듈 선택", "선택 전까지 게임은 멈춥니다. 이번 런의 기본 공격 방식을 고르세요.", game.data.ATTACK_MODULES, 3, 1.0, failures)
	await _verify_choice_case("attack form choices", viewport_size, "공격 방식 선택", "현재 모듈의 실제 판정과 렌더링이 바뀝니다.", game.data.ATTACK_FORMS, 2, 1.0, failures)
	await _verify_choice_case("attack mechanic choices", viewport_size, "공격 기믹 선택", "공격에 반사, 관통, 처치 연쇄 같은 규칙을 추가합니다.", game.data.ATTACK_MECHANICS, 2, 1.0, failures)
	await _verify_choice_case("build scaling choices", viewport_size, "빌드 최적화 선택", "현재 계약과 아이템 태그에 맞춘 스케일링을 적용합니다.", game.data.BUILD_SCALINGS, 2, 1.0, failures)
	var synergy_choices = game.data.SYNERGY_OPTIONS.filter(func(option): return not option.get("hidden", false))
	await _verify_choice_case("synergy choices", viewport_size, "공격 연계 선택", "1차와 보조 공격이 서로 영향을 주는 임시 연계 규칙을 고릅니다.", synergy_choices, 2, 1.0, failures)
	await _verify_choice_case("deepening choices", viewport_size, "심화 선택", "피해, 빈도, 범위 중 하나를 강화합니다.", game.data.DEEPENING_OPTIONS, 3, 1.0, failures)
	await _verify_choice_case("item choices all", viewport_size, "아이템 선택", "골드를 지불했습니다. 패시브 아이템 1개를 선택해 현재 런 성능을 누적 성장시키세요.", game.data.ITEMS, 3, 1.0, failures)
	await _verify_choice_case("perk choices all", viewport_size, "성장 보상", "레벨 성장은 공격 모듈과 팝업 관리 능력을 강화합니다.", game.data.PERKS, 3, 1.0, failures)
	await _verify_choice_case("starter package choices", viewport_size, "스타터 계약 패키지 선택", "결제 완료. 한정 스타터 계약 1개를 선택해 이번 런의 성장 효율을 확정하세요.", _starter_package_choices(), 2, 1.7, failures)
	await _verify_boss_package_choice_case(viewport_size, failures)
	await _verify_inventory_choice_case(viewport_size, failures)

func _verify_choice_case(label: String, viewport_size: Vector2, title: String, description: String, choices: Array, columns: int, layout_scale: float, failures: Array) -> void:
	if choices.is_empty():
		failures.append("%s has no choices" % label)
		return
	game.hud.show_choices(title, description, choices, func(_choice): pass, columns, layout_scale)
	await _settle_layout(viewport_size)
	_expect_choice_overlay_contract(label, viewport_size, columns, layout_scale, failures)
	game.hud.hide_choices()
	runtime_choice_cases_checked += 1

func _verify_boss_package_choice_case(viewport_size: Vector2, failures: Array) -> void:
	var items = game.data.ITEMS.slice(0, min(6, game.data.ITEMS.size()))
	if items.size() < 2:
		failures.append("boss package choice needs at least 2 items")
		return
	var selected = [items[0].id, items[1].id]
	game.hud.show_boss_package_choices("보스 패키지 보상 선택", "결제 완료. 아이템 6개 중 2개를 선택하면 즉시 적용됩니다.", items, selected, func(_choice): pass, 3)
	await _settle_layout(viewport_size)
	_expect_choice_overlay_contract("boss package choices", viewport_size, 3, 1.0, failures)
	var disabled_count = 0
	for child in game.hud.ui.choiceGrid.get_children():
		if child is Button and child.disabled:
			disabled_count += 1
	if disabled_count == 0:
		failures.append("boss package choices should disable unselected cards when two items are selected")
	game.hud.hide_choices()
	runtime_choice_cases_checked += 1

func _verify_inventory_choice_case(viewport_size: Vector2, failures: Array) -> void:
	var previous_counts = game.state.itemCounts.duplicate(true)
	game.state.itemCounts.clear()
	for item in game.data.ITEMS:
		game.state.itemCounts[item.id] = 1
	game.hud.show_inventory_overview(func(): pass)
	await _settle_layout(viewport_size)
	_expect_choice_overlay_contract("inventory overview all items", viewport_size, 3, 1.0, failures)
	game.hud.hide_choices()
	game.state.itemCounts = previous_counts
	runtime_choice_cases_checked += 1

func _expect_choice_overlay_contract(label: String, viewport_size: Vector2, requested_columns: int, layout_scale: float, failures: Array) -> void:
	_expect_equal("%s overlay visible %s" % [label, viewport_size], game.hud.ui.choiceOverlay.visible, true, failures)
	_expect_equal("%s overlay blocks input %s" % [label, viewport_size], game.hud.ui.choiceOverlay.mouse_filter, Control.MOUSE_FILTER_STOP, failures)
	var panel_size = HtmlLayoutMetrics.choice_panel_size(viewport_size, layout_scale)
	var expected_panel = Rect2(Vector2((viewport_size.x - panel_size.x) * 0.5, (viewport_size.y - panel_size.y) * 0.5), panel_size)
	_expect_rect("%s panel %s" % [label, viewport_size], game.hud.ui.choicePanel, expected_panel, viewport_size, failures)
	var expected_columns = HtmlLayoutMetrics.choice_columns_for_width(panel_size.x, viewport_size)
	if requested_columns > 0:
		expected_columns = min(expected_columns, requested_columns)
	_expect_equal("%s columns %s" % [label, viewport_size], game.hud.ui.choiceGrid.columns, expected_columns, failures)
	_expect_control_vertical_inside_control("%s title safe %s" % [label, viewport_size], game.hud.ui.choiceTitle, game.hud.ui.choicePanel, HtmlLayoutMetrics.choice_panel_text_safe_inset(viewport_size), failures)
	_expect_control_inside_control("%s scroll inside panel %s" % [label, viewport_size], game.hud.ui.choiceScroll, game.hud.ui.choicePanel, 1.0, failures)
	var expected_card_width = HtmlLayoutMetrics.choice_card_width(panel_size.x, expected_columns, viewport_size)
	for child in game.hud.ui.choiceGrid.get_children():
		if child is Control:
			_expect_choice_child_contract("%s child %s" % [label, child.name], child, expected_card_width, viewport_size, failures)

func _expect_choice_child_contract(label: String, child: Control, expected_card_width: float, viewport_size: Vector2, failures: Array) -> void:
	var kind = str(child.get_meta("choiceKind", ""))
	if kind == "":
		if child is Button:
			if child.custom_minimum_size.x <= 0.0 or child.custom_minimum_size.y <= 0.0:
				failures.append("%s simple button has invalid minimum size %s" % [label, child.custom_minimum_size])
		elif child is RichTextLabel:
			if child.custom_minimum_size.y <= 0.0:
				failures.append("%s simple rich label has invalid minimum height %.1f" % [label, child.custom_minimum_size.y])
		return
	if float(child.custom_minimum_size.x) < expected_card_width:
		failures.append("%s width expected >= %.1f got %.1f" % [label, expected_card_width, child.custom_minimum_size.x])
	if float(child.custom_minimum_size.y) < HtmlLayoutMetrics.choice_card_min_height(kind, viewport_size):
		failures.append("%s height expected >= %.1f got %.1f" % [label, HtmlLayoutMetrics.choice_card_min_height(kind, viewport_size), child.custom_minimum_size.y])
	var required_height = game.hud._choice_card_required_height(child, expected_card_width, viewport_size)
	if float(child.custom_minimum_size.y) < required_height:
		failures.append("%s content height expected >= %.1f got %.1f" % [label, required_height, child.custom_minimum_size.y])
	var body = _find_node_named(child, "choiceCardBody")
	if not body is Control:
		failures.append("%s missing choiceCardBody" % label)
	else:
		_expect_equal("%s body clip" % label, body.clip_contents, true, failures)
	var title = _find_node_named(child, "choiceTitleText")
	if title is Label:
		_expect_equal("%s title single-line" % label, title.autowrap_mode, TextServer.AUTOWRAP_OFF, failures)
		_expect_equal("%s title ellipsis" % label, title.text_overrun_behavior, TextServer.OVERRUN_TRIM_ELLIPSIS, failures)
		_expect_label_text_capacity("%s title text capacity" % label, title, true, failures)
	else:
		failures.append("%s missing title label" % label)
	var desc = _find_node_named(child, "choiceDescriptionText")
	if desc is Label:
		_expect_equal("%s desc wraps" % label, desc.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART, failures)
		_expect_equal("%s desc no ellipsis" % label, desc.text_overrun_behavior, TextServer.OVERRUN_NO_TRIMMING, failures)
		if float(desc.custom_minimum_size.y) < HtmlLayoutMetrics.choice_description_height(kind, viewport_size):
			failures.append("%s desc height expected >= %.1f got %.1f" % [label, HtmlLayoutMetrics.choice_description_height(kind, viewport_size), desc.custom_minimum_size.y])
		_expect_label_text_capacity("%s desc text capacity" % label, desc, false, failures)
	var meta = _find_node_named(child, "choiceMetaText")
	if meta is Label:
		_expect_equal("%s meta wraps" % label, meta.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART, failures)
		_expect_label_text_capacity("%s meta text capacity" % label, meta, false, failures)

func _verify_runtime_popup_cases(viewport_size: Vector2, failures: Array) -> void:
	test_viewport.size = Vector2i(int(viewport_size.x), int(viewport_size.y))
	await _settle_layout(viewport_size)
	var popup_defs = game.data.POPUP_DEFINITIONS.duplicate(true)
	popup_defs.append(game.infected_popup_definition("검증 원본"))
	popup_defs.append({"id": "system_notice_probe", "title": "시스템 알림", "body": "런타임 생성 시스템 알림입니다.", "type": "system_notice", "category": "system", "families": ["system"], "copyTone": "system_warning", "autoClose": 3.4, "weight": 0.0})
	for def in popup_defs:
		await _verify_single_popup_definition(viewport_size, def, failures)

func _verify_single_popup_definition(viewport_size: Vector2, def: Dictionary, failures: Array) -> void:
	_clear_runtime_popups()
	var previous_gold = game.state.gold
	game.state.gold = max(previous_gold, 1000)
	var popup = game.create_popup(def)
	popup.inputGrace = 0.0
	popup.elapsed = min(1.0, float(popup.def.get("duration", 2.0)))
	game.popup_layer.sync(game.state)
	await process_frame
	game.popup_layer.sync(game.state)
	var record = game.popup_layer.windows.get(int(popup.id), null)
	var popup_label = "runtime popup %s/%s" % [popup.def.get("id", ""), popup.def.get("type", "")]
	if record == null:
		failures.append("%s did not create a window" % popup_label)
	else:
		_expect_popup_regions_inside("%s regions" % popup_label, record, failures)
		_expect_popup_layout_contract("%s layout contract" % popup_label, popup, record, failures)
		var layout = HtmlLayoutMetrics.popup_content_layout(viewport_size, str(popup.def.get("type", "")), record.panel.size, str(record.body.text), str(record.detail.text), record.statusBadges.get_child_count() > 0)
		if popup.def.get("type", "") == "terms":
			_expect_equal("%s terms body scroll" % popup_label, record.body.scroll_active, bool(layout.body_scroll), failures)
		if record.controls.visible and _first_button(record.controls) == null:
			failures.append("%s visible controls missing button" % popup_label)
	runtime_popup_cases_checked += 1
	game.state.gold = previous_gold
	_clear_runtime_popups()

func _verify_game_over_overlay_case(viewport_size: Vector2, failures: Array) -> void:
	test_viewport.size = Vector2i(int(viewport_size.x), int(viewport_size.y))
	game.state.gameOver = true
	game.hud.update_from_state(game.state)
	await _settle_layout(viewport_size)
	_expect_equal("game over overlay visible", game.hud.ui.gameOverOverlay.visible, true, failures)
	_expect_equal("game over overlay blocks input", game.hud.ui.gameOverOverlay.mouse_filter, Control.MOUSE_FILTER_STOP, failures)
	_expect_control_inside_control("game over panel inside overlay", game.hud.ui.gameOverPanel, game.hud.ui.gameOverOverlay, 1.0, failures)
	game.state.gameOver = false
	game.hud.update_from_state(game.state)

func _verify_mobile_runtime_controls(viewport_size: Vector2, failures: Array) -> void:
	test_viewport.size = Vector2i(int(viewport_size.x), int(viewport_size.y))
	game.state.mobileInput.active = true
	game.state.mobileInput.baseX = viewport_size.x * 0.32
	game.state.mobileInput.baseY = viewport_size.y * 0.72
	game.hud._apply_mobile_layout(viewport_size)
	await process_frame
	_expect_equal("mobile controls visible %s" % viewport_size, game.hud.ui.mobileControls.visible, true, failures)
	_expect_control_inside_control("mobile fullscreen inside root %s" % viewport_size, game.hud.ui.mobileFullscreenButton, game.hud.ui.mobileControls, 0.0, failures)
	_expect_control_inside_control("mobile emergency inside root %s" % viewport_size, game.hud.ui.mobileEmergencyButton, game.hud.ui.mobileControls, 0.0, failures)
	_expect_control_inside_control("mobile joystick inside root %s" % viewport_size, game.hud.ui.mobileJoystick, game.hud.ui.mobileControls, 0.0, failures)
	game.state.mobileInput.active = false
	game.hud._apply_mobile_layout(Vector2(HtmlLayoutMetrics.PC_VIEWPORT_WIDTH, HtmlLayoutMetrics.PC_VIEWPORT_HEIGHT))

func _starter_package_choices() -> Array:
	var choices = []
	for package in game.data.FIRST_PURCHASE_PACKAGES:
		var benefits = "\n".join(package.get("benefits", []))
		var copy = package.duplicate(true)
		copy.description = "%s\n%s\n%s\n%s" % [package.get("efficiencyLabel", ""), package.get("theme", ""), package.get("description", ""), benefits]
		choices.append(copy)
	return choices

func _clear_runtime_popups() -> void:
	if game == null or game.state.is_empty():
		return
	game.state.openPopups.clear()
	game.popup_layer.sync(game.state)

func _verify_combat_hud_text(viewport_size: Vector2, failures: Array) -> void:
	for key in ["hpText", "levelText", "xpText"]:
		_expect_visible_text_label("combat %s visible %s" % [key, viewport_size], game.hud.ui[key], failures)
		var card = _ancestor_panel_container(game.hud.ui[key])
		if card is PanelContainer:
			_expect_control_inside_control("combat %s card safe %s" % [key, viewport_size], game.hud.ui[key], card, 1.0, failures)
		else:
			failures.append("combat %s does not have a card parent" % key)
	_expect_visible_control("combat health bar visible %s" % viewport_size, game.hud.ui.healthBar, failures)
	_expect_visible_control("combat xp bar visible %s" % viewport_size, game.hud.ui.xpBar, failures)
	_expect_no_vertical_overlap("hp text above health bar %s" % viewport_size, game.hud.ui.hpText, game.hud.ui.healthBar, failures)
	_expect_no_vertical_overlap("level text above xp bar %s" % viewport_size, game.hud.ui.levelText, game.hud.ui.xpBar, failures)
	_expect_no_vertical_overlap("xp text above xp bar %s" % viewport_size, game.hud.ui.xpText, game.hud.ui.xpBar, failures)

func _verify_content_margin_density(viewport_size: Vector2, failures: Array) -> void:
	var panel_margin_limit = float(HtmlLayoutMetrics.panel_padding(viewport_size))
	for key in ["combatHud", "economyHud", "statusPanel", "debugPanel"]:
		var panel = game.hud.ui.get(key, null)
		if not panel is Control:
			failures.append("%s missing for content margin check" % key)
			continue
		_expect_stylebox_margin_at_most("%s style margin %s" % [key, viewport_size], panel, panel_margin_limit, failures)
		var clip = panel.get_node_or_null("%sClip" % panel.name)
		if clip is Control:
			_expect_panel_inset_at_most("%s clip inset %s" % [key, viewport_size], panel, clip, max(1.0, panel_margin_limit), failures)
	for key in ["difficultyHud", "cleanupHud"]:
		var small_panel = game.hud.ui.get(key, null)
		if small_panel is Control:
			_expect_stylebox_margin_at_most("%s style margin %s" % [key, viewport_size], small_panel, 4.0, failures)
	if game.hud.ui.has("choicePanel") and game.hud.ui.choicePanel is Control:
		_expect_stylebox_margin_at_most("choice panel style margin %s" % viewport_size, game.hud.ui.choicePanel, 0.0, failures)
	if game.hud.ui.has("choiceBox") and game.hud.ui.choiceBox is Control:
		var expected_padding = HtmlLayoutMetrics.choice_panel_padding(viewport_size)
		if float(game.hud.ui.choiceBox.offset_left) > expected_padding + 0.51:
			failures.append("choice box left inset too large %s expected <= %.1f got %.1f" % [viewport_size, expected_padding, game.hud.ui.choiceBox.offset_left])
		if abs(float(game.hud.ui.choiceBox.offset_right)) > expected_padding + 0.51:
			failures.append("choice box right inset too large %s expected <= %.1f got %.1f" % [viewport_size, expected_padding, abs(float(game.hud.ui.choiceBox.offset_right))])
		var expected_top = HtmlLayoutMetrics.choice_panel_top_padding(viewport_size)
		if float(game.hud.ui.choiceBox.offset_top) > expected_top + 0.51:
			failures.append("choice box top inset too large %s expected <= %.1f got %.1f" % [viewport_size, expected_top, game.hud.ui.choiceBox.offset_top])
		if abs(float(game.hud.ui.choiceBox.offset_bottom)) > expected_padding + 0.51:
			failures.append("choice box bottom inset too large %s expected <= %.1f got %.1f" % [viewport_size, expected_padding, abs(float(game.hud.ui.choiceBox.offset_bottom))])

func _expect_popup_regions_inside(label: String, record: Dictionary, failures: Array) -> void:
	var panel = record.get("panel", null)
	if not panel is Control:
		failures.append("%s missing panel" % label)
		return
	for key in ["title_frame", "content_frame", "body", "detail", "controls"]:
		var control = record.get(key, null)
		if control is Control and control.visible:
			_expect_control_inside_control("%s %s" % [label, key], control, panel, 0.0, failures)
	if record.has("controls") and record.controls is Control and record.controls.visible:
		var first_button = _first_button(record.controls)
		if first_button == null:
			failures.append("%s controls missing button" % label)
		else:
			_expect_control_inside_control("%s first action button" % label, first_button, panel, 0.0, failures)
		_expect_visible_descendants_inside("%s controls descendants" % label, record.controls, panel, failures)

func _expect_popup_layout_contract(label: String, popup: Dictionary, record: Dictionary, failures: Array) -> void:
	var layout = HtmlLayoutMetrics.popup_content_layout(HtmlLayoutMetrics.viewport_size(game.get_viewport()), str(popup.def.get("type", "")), record.panel.size, str(record.body.text), str(record.detail.text), record.statusBadges.get_child_count() > 0)
	_expect_equal("%s panel clip" % label, record.panel.clip_contents, true, failures)
	_expect_equal("%s content clip" % label, record.content_frame.clip_contents, true, failures)
	_expect_equal("%s content box clip" % label, record.content_box.clip_contents, true, failures)
	_expect_equal("%s body wrap" % label, record.body.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART, failures)
	_expect_equal("%s body scroll" % label, record.body.scroll_active, bool(layout.body_scroll), failures)
	_expect_equal("%s body fit" % label, record.body.fit_content, false, failures)
	_expect_equal("%s body font" % label, record.body.get_theme_font_size("normal_font_size"), int(layout.body_font), failures)
	_expect_rich_text_capacity("%s body text capacity" % label, record.body, failures)
	_expect_equal("%s detail wrap" % label, record.detail.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART, failures)
	_expect_equal("%s detail scroll" % label, record.detail.scroll_active, bool(layout.detail_scroll), failures)
	_expect_equal("%s detail fit" % label, record.detail.fit_content, false, failures)
	_expect_equal("%s detail font" % label, record.detail.get_theme_font_size("normal_font_size"), int(layout.detail_font), failures)
	if record.detail.visible:
		_expect_rich_text_capacity("%s detail text capacity" % label, record.detail, failures)
	_expect_equal("%s content gap" % label, record.content_box.get_theme_constant("separation"), int(layout.gap), failures)
	_expect_stylebox_margin_at_most("%s content margin" % label, record.content_frame, float(layout.max_content_margin), failures)
	_expect_popup_buttons_follow_contract(label, record.controls, layout, failures)

func _expect_popup_buttons_follow_contract(label: String, node: Node, layout: Dictionary, failures: Array) -> void:
	for child in node.get_children():
		if child is Button:
			if float(child.custom_minimum_size.y) < float(layout.button_height):
				failures.append("%s button height expected >= %.1f got %.1f" % [label, float(layout.button_height), child.custom_minimum_size.y])
			if float(child.custom_minimum_size.x) > float(layout.button_max_width) + 0.51:
				failures.append("%s button width expected <= %.1f got %.1f" % [label, float(layout.button_max_width), child.custom_minimum_size.x])
			_expect_equal("%s button wrap" % label, child.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART, failures)
			_expect_equal("%s button clip" % label, child.clip_contents, true, failures)
			_expect_button_text_capacity("%s button text capacity" % label, child, failures)
		elif child is Label:
			if float(child.custom_minimum_size.x) != float(layout.control_label_width):
				failures.append("%s control label width expected %.1f got %.1f" % [label, float(layout.control_label_width), child.custom_minimum_size.x])
			if float(child.custom_minimum_size.y) < float(layout.button_height):
				failures.append("%s control label height expected >= %.1f got %.1f" % [label, float(layout.button_height), child.custom_minimum_size.y])
			_expect_label_text_capacity("%s control label text capacity" % label, child, true, failures)
			_expect_popup_buttons_follow_contract(label, child, layout, failures)

func _expect_visible_descendants_inside(label: String, node: Node, parent: Control, failures: Array) -> void:
	for child in node.get_children():
		if child is Control and child.visible:
			_expect_control_inside_control("%s %s" % [label, child.name], child, parent, 0.0, failures)
		_expect_visible_descendants_inside(label, child, parent, failures)

func _expect_label_text_capacity(label: String, control: Label, allow_horizontal_ellipsis: bool, failures: Array) -> void:
	text_capacity_cases_checked += 1
	if control == null or not control.visible:
		return
	var text = control.text.strip_edges()
	if text == "":
		return
	var rect = control.get_global_rect()
	var font_size = max(1, int(control.get_theme_font_size("font_size")))
	var line_height = _line_box_height(font_size)
	if rect.size.y + 0.51 < line_height:
		failures.append("%s height expected >= %.1f got %.1f" % [label, line_height, rect.size.y])
		return
	if control.autowrap_mode == TextServer.AUTOWRAP_OFF:
		if allow_horizontal_ellipsis:
			if control.text_overrun_behavior != TextServer.OVERRUN_TRIM_ELLIPSIS:
				failures.append("%s should use ellipsis for single-line overflow" % label)
			return
		var expected_width = _estimated_text_width(text, font_size)
		if rect.size.x + 0.51 < expected_width:
			failures.append("%s width expected >= %.1f got %.1f" % [label, expected_width, rect.size.x])
		return
	var expected_height = _estimated_text_height(text, font_size, rect.size.x)
	if rect.size.y + line_height * 0.35 < expected_height:
		failures.append("%s wrapped height expected >= %.1f got %.1f for width %.1f" % [label, expected_height, rect.size.y, rect.size.x])

func _expect_button_text_capacity(label: String, button: Button, failures: Array) -> void:
	text_capacity_cases_checked += 1
	if button == null or not button.visible or button.text.strip_edges() == "":
		return
	var rect = button.get_global_rect()
	var font_size = max(1, int(button.get_theme_font_size("font_size")))
	var text = button.text.strip_edges()
	var line_height = _line_box_height(font_size)
	if button.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART:
		var expected_height = _estimated_text_height(text, font_size, rect.size.x)
		if rect.size.y + line_height * 0.45 < expected_height:
			failures.append("%s wrapped height expected >= %.1f got %.1f for width %.1f" % [label, expected_height, rect.size.y, rect.size.x])
	else:
		if rect.size.y + 0.51 < line_height:
			failures.append("%s height expected >= %.1f got %.1f" % [label, line_height, rect.size.y])

func _expect_rich_text_capacity(label: String, control: RichTextLabel, failures: Array) -> void:
	text_capacity_cases_checked += 1
	if control == null or not control.visible or control.text.strip_edges() == "":
		return
	if control.scroll_active:
		return
	var rect = control.get_global_rect()
	var font_size = max(1, int(control.get_theme_font_size("normal_font_size")))
	var text = _strip_bbcode(control.text.strip_edges())
	var expected_height = _estimated_text_height(text, font_size, rect.size.x)
	var line_height = _line_box_height(font_size)
	if rect.size.y + line_height * 0.45 < expected_height:
		failures.append("%s rich text height expected >= %.1f got %.1f for width %.1f" % [label, expected_height, rect.size.y, rect.size.x])

func _line_box_height(font_size: int) -> float:
	return ceil(float(font_size) * 1.25)

func _estimated_text_height(text: String, font_size: int, width: float) -> float:
	return _line_box_height(font_size) * float(_estimated_wrapped_lines(text, font_size, max(24.0, width)))

func _estimated_wrapped_lines(text: String, font_size: int, width: float) -> int:
	if text.strip_edges() == "":
		return 1
	var total = 0
	for paragraph in text.split("\n"):
		total += _estimated_paragraph_lines(paragraph, font_size, width)
	return max(1, total)

func _estimated_paragraph_lines(text: String, font_size: int, width: float) -> int:
	if text == "":
		return 1
	var lines = 1
	var used = 0.0
	for index in range(text.length()):
		var ch = text.substr(index, 1)
		var ch_width = _estimated_char_width(ch, font_size)
		if used > 0.0 and used + ch_width > width:
			lines += 1
			used = ch_width
		else:
			used += ch_width
	return lines

func _estimated_text_width(text: String, font_size: int) -> float:
	var width = 0.0
	for index in range(text.length()):
		width += _estimated_char_width(text.substr(index, 1), font_size)
	return width

func _estimated_char_width(ch: String, font_size: int) -> float:
	var code = ch.unicode_at(0)
	if code <= 32:
		return float(font_size) * 0.34
	if code < 128:
		return float(font_size) * 0.56
	return float(font_size) * 0.92

func _strip_bbcode(text: String) -> String:
	var output = ""
	var in_tag = false
	for index in range(text.length()):
		var ch = text.substr(index, 1)
		if ch == "[":
			in_tag = true
			continue
		if ch == "]" and in_tag:
			in_tag = false
			continue
		if not in_tag:
			output += ch
	return output

func _expect_rect(label: String, control: Control, expected: Rect2, viewport_size: Vector2, failures: Array) -> void:
	var actual = _control_rect(control, viewport_size)
	if not _rect_close(actual, expected):
		failures.append("%s expected %s got %s" % [label, expected, actual])

func _expect_equal(label: String, actual, expected, failures: Array) -> void:
	if actual != expected:
		failures.append("%s expected %s got %s" % [label, expected, actual])

func _expect_vector(label: String, actual: Vector2, expected: Vector2, failures: Array) -> void:
	if not actual.is_equal_approx(expected):
		failures.append("%s expected %s got %s" % [label, expected, actual])

func _expect_inside(label: String, control: Control, viewport_size: Vector2, failures: Array) -> void:
	var rect = _control_rect(control, viewport_size)
	if rect.position.x < -0.1 or rect.position.y < -0.1 or rect.position.x + rect.size.x > viewport_size.x + 0.1 or rect.position.y + rect.size.y > viewport_size.y + 0.1:
		failures.append("%s outside viewport: %s in %s" % [label, rect, viewport_size])

func _expect_visible_text_label(label: String, control: Control, failures: Array) -> void:
	if not control is Label:
		failures.append("%s is not a Label" % label)
		return
	if not control.visible or control.text.strip_edges() == "":
		failures.append("%s missing visible text" % label)
	var rect = control.get_global_rect()
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		failures.append("%s has collapsed rect %s" % [label, rect])

func _expect_visible_control(label: String, control: Control, failures: Array) -> void:
	if not control is Control:
		failures.append("%s is not a Control" % label)
		return
	if not control.visible:
		failures.append("%s is hidden" % label)
	var rect = control.get_global_rect()
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		failures.append("%s has collapsed rect %s" % [label, rect])

func _expect_stylebox_margin_at_most(label: String, control: Control, max_margin: float, failures: Array) -> void:
	if control == null:
		failures.append("%s missing control" % label)
		return
	var style = control.get_theme_stylebox("panel")
	if style == null:
		failures.append("%s missing panel stylebox" % label)
		return
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		var margin = float(style.get_content_margin(side))
		if margin > max_margin + 0.51:
			failures.append("%s side %d margin too large: expected <= %.1f got %.1f" % [label, side, max_margin, margin])

func _expect_panel_inset_at_most(label: String, panel: Control, content: Control, max_inset: float, failures: Array) -> void:
	var panel_rect = panel.get_global_rect()
	var content_rect = content.get_global_rect()
	var left = content_rect.position.x - panel_rect.position.x
	var top = content_rect.position.y - panel_rect.position.y
	var right = panel_rect.position.x + panel_rect.size.x - content_rect.position.x - content_rect.size.x
	var bottom = panel_rect.position.y + panel_rect.size.y - content_rect.position.y - content_rect.size.y
	for value in [left, top, right, bottom]:
		if value > max_inset + 0.51:
			failures.append("%s inset too large: expected <= %.1f got %.1f" % [label, max_inset, value])

func _expect_no_vertical_overlap(label: String, a: Control, b: Control, failures: Array) -> void:
	if not a is Control or not b is Control:
		failures.append("%s missing controls" % label)
		return
	var ar = a.get_global_rect()
	var br = b.get_global_rect()
	if ar.position.y + ar.size.y > br.position.y + 0.51 and br.position.y + br.size.y > ar.position.y + 0.51:
		failures.append("%s vertical overlap: %s with %s" % [label, ar, br])

func _expect_control_inside_control(label: String, control: Control, parent: Control, safe_inset: float, failures: Array) -> void:
	if control == null or parent == null:
		failures.append("%s missing control or parent" % label)
		return
	var rect = control.get_global_rect()
	var parent_rect = parent.get_global_rect()
	var safe_rect = Rect2(parent_rect.position + Vector2(safe_inset, safe_inset), parent_rect.size - Vector2(safe_inset * 2.0, safe_inset * 2.0))
	if rect.position.x < safe_rect.position.x - 0.51 or rect.position.y < safe_rect.position.y - 0.51 or rect.position.x + rect.size.x > safe_rect.position.x + safe_rect.size.x + 0.51 or rect.position.y + rect.size.y > safe_rect.position.y + safe_rect.size.y + 0.51:
		failures.append("%s outside safe rect: %s not in %s" % [label, rect, safe_rect])

func _expect_control_vertical_inside_control(label: String, control: Control, parent: Control, safe_inset: float, failures: Array) -> void:
	if control == null or parent == null:
		failures.append("%s missing control or parent" % label)
		return
	var rect = control.get_global_rect()
	var parent_rect = parent.get_global_rect()
	var safe_top = parent_rect.position.y + safe_inset
	var safe_bottom = parent_rect.position.y + parent_rect.size.y - safe_inset
	if rect.position.y < safe_top - 0.51 or rect.position.y + rect.size.y > safe_bottom + 0.51:
		failures.append("%s outside vertical safe range: %s not in %.1f..%.1f" % [label, rect, safe_top, safe_bottom])

func _control_rect(control: Control, viewport_size: Vector2) -> Rect2:
	return control.get_global_rect()

func _rect_close(a: Rect2, b: Rect2) -> bool:
	return _pixel_close(a.position.x, b.position.x) and _pixel_close(a.position.y, b.position.y) and _pixel_close(a.size.x, b.size.x) and _pixel_close(a.size.y, b.size.y)

func _pixel_close(a: float, b: float) -> bool:
	return abs(a - b) <= 0.51

func _find_node_named(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var found = _find_node_named(child, node_name)
		if found != null:
			return found
	return null

func _find_class_named(node: Node, class_names: Array) -> Node:
	if class_names.has(node.get_class()):
		return node
	for child in node.get_children():
		var found = _find_class_named(child, class_names)
		if found != null:
			return found
	return null

func _ancestor_panel_container(node: Node) -> PanelContainer:
	var current = node.get_parent()
	while current != null:
		if current is PanelContainer:
			return current
		current = current.get_parent()
	return null

func _verify_control_tree_ignores_mouse(node: Node, label: String, failures: Array) -> void:
	if node is Control:
		if node is Button:
			failures.append("%s unexpectedly contains nested Button %s" % [label, node.get_path()])
		elif node.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			failures.append("%s %s expected mouse ignore got %s" % [label, node.get_path(), node.mouse_filter])
	for child in node.get_children():
		_verify_control_tree_ignores_mouse(child, label, failures)

func _first_button(node: Node) -> Button:
	if node is Button:
		return node
	for child in node.get_children():
		var found = _first_button(child)
		if found != null:
			return found
	return null
