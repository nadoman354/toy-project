extends CanvasLayer
class_name HudLayer

var game: Node = null
var ui = {}

func setup(game_root: Node) -> void:
	game = game_root
	_build_ui()

func _build_ui() -> void:
	var root = Control.new()
	root.name = "HudRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	ui.root = root

	var combat = _make_panel("combat", Vector2(12, 12), Vector2(310, 254))
	root.add_child(combat)
	var combat_box = _panel_box(combat)
	_add_title(combat_box, "전투 HUD")
	ui.hp = _add_label(combat_box, "HP 100 / 100")
	ui.hp_bar = _add_bar(combat_box, 100.0)
	ui.xp = _add_label(combat_box, "Lv. 1  XP 0 / 40")
	ui.xp_bar = _add_bar(combat_box, 100.0)
	ui.module_primary = _add_label(combat_box, "1차 모듈: 미선택")
	ui.module_secondary = _add_label(combat_box, "보조 모듈: 없음")
	ui.module_meta = _add_label(combat_box, "숙련 0 / 0")
	ui.popup_count = _add_label(combat_box, "팝업 0 / 5")
	ui.combo = _add_label(combat_box, "정리 콤보 x0")
	ui.difficulty = _add_label(combat_box, "난이도: 정상 작동 0.0")

	var economy = _make_panel("economy", Vector2(-332, 12), Vector2(320, 430))
	economy.anchor_left = 1.0
	economy.anchor_right = 1.0
	root.add_child(economy)
	var economy_box = _panel_box(economy)
	_add_title(economy_box, "경제 / 아이템")
	ui.gold = _add_label(economy_box, "골드 0G")
	ui.credit = _add_label(economy_box, "신용 50 / 투자 0G / 부채 0G")
	ui.item_cost = _add_label(economy_box, "아이템 머신 25G")
	var roll_button = Button.new()
	roll_button.text = "아이템 머신"
	roll_button.pressed.connect(func(): game.roll_item())
	economy_box.add_child(roll_button)
	ui.roll_button = roll_button
	var inventory_button = Button.new()
	inventory_button.text = "보유 아이템 보기"
	inventory_button.pressed.connect(func(): game.open_inventory_overview())
	economy_box.add_child(inventory_button)
	ui.inventory_button = inventory_button
	ui.last_item = _add_label(economy_box, "최근 아이템: 없음")
	ui.resident = _add_label(economy_box, "보안 프로그램: 설치 없음")
	ui.inventory = _add_rich_label(economy_box, "보유 아이템 없음", 126)
	ui.recent = _add_rich_label(economy_box, "공격 모듈을 선택하세요.", 72)

	var status = _make_panel("status", Vector2(12, -158), Vector2(420, 146))
	status.anchor_top = 1.0
	status.anchor_bottom = 1.0
	root.add_child(status)
	var status_box = _panel_box(status)
	_add_title(status_box, "조작 / 상태")
	ui.run_stats = _add_rich_label(status_box, "WASD 이동, Space 긴급 닫기, P 일시정지, R 재시작.", 76)

	var debug = _make_panel("debug", Vector2(-372, -300), Vector2(360, 288))
	debug.anchor_left = 1.0
	debug.anchor_right = 1.0
	debug.anchor_top = 1.0
	debug.anchor_bottom = 1.0
	root.add_child(debug)
	var debug_box = _panel_box(debug)
	var header = HBoxContainer.new()
	debug_box.add_child(header)
	var debug_title = Label.new()
	debug_title.text = "디버그"
	debug_title.add_theme_font_size_override("font_size", 15)
	header.add_child(debug_title)
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var debug_toggle = Button.new()
	debug_toggle.text = "-"
	debug_toggle.custom_minimum_size = Vector2(32, 26)
	debug_toggle.pressed.connect(func(): _toggle_debug_body())
	header.add_child(debug_toggle)
	ui.debug_toggle = debug_toggle
	ui.debug_stats = _add_rich_label(debug_box, "", 80)
	var debug_scroll = ScrollContainer.new()
	debug_scroll.custom_minimum_size = Vector2(0, 154)
	debug_box.add_child(debug_scroll)
	var debug_grid = GridContainer.new()
	debug_grid.columns = 3
	debug_scroll.add_child(debug_grid)
	ui.debug_grid = debug_grid
	_add_debug_buttons(debug_grid)

	var overlay = ColorRect.new()
	overlay.name = "ChoiceOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.68)
	overlay.visible = false
	root.add_child(overlay)
	ui.overlay = overlay
	var choice_panel = PanelContainer.new()
	choice_panel.custom_minimum_size = Vector2(620, 360)
	choice_panel.anchor_left = 0.5
	choice_panel.anchor_top = 0.5
	choice_panel.anchor_right = 0.5
	choice_panel.anchor_bottom = 0.5
	choice_panel.offset_left = -310
	choice_panel.offset_top = -190
	choice_panel.offset_right = 310
	choice_panel.offset_bottom = 190
	overlay.add_child(choice_panel)
	var choice_box = VBoxContainer.new()
	choice_box.add_theme_constant_override("separation", 8)
	choice_panel.add_child(choice_box)
	ui.choice_title = _add_title(choice_box, "선택")
	ui.choice_description = _add_rich_label(choice_box, "", 56)
	var choice_scroll = ScrollContainer.new()
	choice_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	choice_box.add_child(choice_scroll)
	var choice_grid = GridContainer.new()
	choice_grid.columns = 2
	choice_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_scroll.add_child(choice_grid)
	ui.choice_grid = choice_grid

	var game_over = ColorRect.new()
	game_over.name = "GameOverOverlay"
	game_over.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_over.color = Color(0, 0, 0, 0.72)
	game_over.visible = false
	root.add_child(game_over)
	ui.game_over = game_over
	var over_panel = PanelContainer.new()
	over_panel.custom_minimum_size = Vector2(430, 210)
	over_panel.anchor_left = 0.5
	over_panel.anchor_top = 0.5
	over_panel.anchor_right = 0.5
	over_panel.anchor_bottom = 0.5
	over_panel.offset_left = -215
	over_panel.offset_top = -105
	over_panel.offset_right = 215
	over_panel.offset_bottom = 105
	game_over.add_child(over_panel)
	var over_box = VBoxContainer.new()
	over_box.alignment = BoxContainer.ALIGNMENT_CENTER
	over_box.add_theme_constant_override("separation", 10)
	over_panel.add_child(over_box)
	_add_title(over_box, "게임 오버")
	ui.game_over_summary = _add_rich_label(over_box, "", 72)
	var restart = Button.new()
	restart.text = "재시작"
	restart.pressed.connect(func(): game.reset_game())
	over_box.add_child(restart)

func _make_panel(name: String, position: Vector2, size: Vector2) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.name = name
	panel.offset_left = position.x
	panel.offset_top = position.y
	panel.offset_right = position.x + size.x
	panel.offset_bottom = position.y + size.y
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.1, 0.15, 0.88)
	style.border_color = Color(1, 1, 1, 0.16)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _panel_box(panel: PanelContainer) -> VBoxContainer:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(box)
	return box

func _add_title(parent: Node, text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color("#edf2f7"))
	parent.add_child(label)
	return label

func _add_label(parent: Node, text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color("#edf2f7"))
	parent.add_child(label)
	return label

func _add_rich_label(parent: Node, text: String, height: float) -> RichTextLabel:
	var label = RichTextLabel.new()
	label.bbcode_enabled = false
	label.text = text
	label.fit_content = false
	label.scroll_active = true
	label.custom_minimum_size = Vector2(0, height)
	label.add_theme_font_size_override("normal_font_size", 11)
	parent.add_child(label)
	return label

func _add_bar(parent: Node, max_value: float) -> ProgressBar:
	var bar = ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = max_value
	bar.value = max_value
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 10)
	parent.add_child(bar)
	return bar

func _add_debug_buttons(parent: Node) -> void:
	var buttons = [
		["gold", "골드 +25"],
		["gold100", "골드 +100"],
		["xp10", "XP +10"],
		["xp", "XP +레벨"],
		["force_level", "강제 레벨업"],
		["form_select", "방식 선택"],
		["mechanic_select", "기믹 선택"],
		["scaling_select", "최적화"],
		["combo", "콤보 +1"],
		["combo5", "콤보 x5"],
		["wave_normal", "일반 웨이브"],
		["wave_side", "한쪽 웨이브"],
		["wave_surround", "포위 웨이브"],
		["wave_fast", "빠른 웨이브"],
		["wave_dense", "두꺼운 웨이브"],
		["drop_magnet", "자석 드랍"],
		["drop_heal", "회복 드랍"],
		["install_keyboard", "키보드 보안"],
		["install_realtime", "실시간 감시"],
		["install_quarantine", "팝업 격리"],
		["install_kernel", "커널 보안"],
		["clear_security", "보안 제거"],
		["invested100", "투자금 +100"],
		["sponsored5", "후원탄 +5"],
		["boss", "보스 소환"],
		["boss_package", "보스 패키지"],
		["rate", "팝업 x2"],
		["heat", "난이도 +1"],
		["credit_plus", "신용 +10"],
		["credit_minus", "신용 -10"],
		["clear_popups", "팝업 제거"],
		["telegraph_moving", "이동 팝업"],
		["first_purchase_package", "첫 계약"],
		["investor_mode", "투자자 모드"],
		["clear_playstyle", "계약 해제"],
		["interest_offer", "이자 상품"],
		["recurring_investment", "자동 투자"],
		["loan_offer", "신용 현금화"],
		["stock_broker_app", "증권 앱"],
		["popup_store", "팝업 상점"],
		["ad_buff", "광고 버프"],
		["ad_coupon", "광고 할인"],
		["ad_free_sample", "광고 샘플"],
		["ad_premium_sample", "광고 선택지"],
		["timed_reward", "시간 보상"],
		["terms", "약관"],
		["terms_ad_tracking", "추적 약관"],
		["terms_emergency_waiver", "긴급 각서"],
		["terms_malicious_optimization", "악성 약관"],
		["clean_challenge_basic", "청소 의뢰"],
		["volatile_bomb_popup", "불안정 창"],
		["moving_close", "떠다니는 광고"],
		["infection", "감염"],
	]
	for data in buttons:
		var button = Button.new()
		button.text = data[1]
		button.custom_minimum_size = Vector2(92, 28)
		button.pressed.connect(func(action = data[0]): game.debug_action(action))
		parent.add_child(button)

func _toggle_debug_body() -> void:
	ui.debug_grid.visible = not ui.debug_grid.visible
	ui.debug_stats.visible = ui.debug_grid.visible
	ui.debug_toggle.text = "-" if ui.debug_grid.visible else "+"

func update_from_state(state: Dictionary) -> void:
	if state.is_empty():
		return
	var player = state.player
	ui.hp.text = "HP %d / %d" % [ceil(player.hp), ceil(player.max_hp)]
	ui.hp_bar.max_value = player.max_hp
	ui.hp_bar.value = clamp(player.hp, 0.0, player.max_hp)
	ui.xp.text = "Lv. %d  XP %d / %d" % [state.level, state.xp, state.xp_need]
	ui.xp_bar.max_value = max(state.xp_need, 1)
	ui.xp_bar.value = clamp(state.xp, 0, state.xp_need)
	ui.gold.text = "골드 %dG" % state.gold
	ui.credit.text = "신용 %d / 투자 %dG / 부채 %dG" % [state.credit_score, state.invested_gold, state.debt_gold]
	ui.item_cost.text = "아이템 머신 %dG  할인 %d%%  선택지 +%d" % [game.current_item_roll_cost(), round(game.current_item_discount() * 100.0), state.next_item_extra_choices]
	ui.roll_button.disabled = state.paused or state.game_over or state.gold < game.current_item_roll_cost()
	ui.module_primary.text = "1차 모듈: %s" % game.module_summary("primary")
	ui.module_secondary.text = "보조 모듈: %s" % game.module_summary("secondary")
	ui.module_meta.text = "숙련 %d / %d  다음 선택: %s" % [state.primary_mastery, state.secondary_mastery, game.next_growth_choice_label()]
	ui.popup_count.text = "팝업 %d / %d" % [state.open_popups.size(), game.max_open_popups()]
	ui.combo.text = "정리 콤보 x%d  %.1fs" % [state.cleanup_combo_stacks, state.cleanup_combo_timer]
	var diff = game.difficulty_stage_info()
	ui.difficulty.text = "난이도: %s %.1f / 웨이브 %s" % [diff.current.label, game.current_difficulty_score(), game.current_wave_mode().label]
	ui.last_item.text = state.last_item_text
	ui.resident.text = game.resident_program_summary()
	ui.inventory.text = game.inventory_summary()
	ui.recent.text = state.recent_perk_text
	ui.run_stats.text = game.run_stats_text()
	ui.debug_stats.text = game.debug_stats_text()
	ui.game_over.visible = state.game_over
	if state.game_over:
		ui.game_over_summary.text = "생존 시간 %s, 도달 레벨 %d, 보유 골드 %dG." % [game.format_time(state.elapsed), state.level, state.gold]

func show_choices(title: String, description: String, choices: Array, callback: Callable, force_pause = true) -> void:
	if force_pause:
		game.state.paused = true
	ui.choice_title.text = title
	ui.choice_description.text = description
	for child in ui.choice_grid.get_children():
		child.queue_free()
	for choice in choices:
		var selected = choice
		var button = Button.new()
		button.text = "%s\n%s" % [selected.get("name", selected.get("label", selected.get("title", selected.get("id", "선택")))), selected.get("description", "")]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(280, 86)
		button.pressed.connect(func():
			hide_choices()
			callback.call(selected)
		)
		ui.choice_grid.add_child(button)
	ui.overlay.visible = true

func hide_choices() -> void:
	ui.overlay.visible = false

func show_inventory_panel(title: String, body: String) -> void:
	show_choices(title, body, [{"id": "close", "name": "닫기", "description": ""}], func(_choice): game.resume_after_overlay(), false)

