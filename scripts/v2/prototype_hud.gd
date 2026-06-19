extends CanvasLayer
class_name PrototypeHud

var game = null
var ui = {}
var status_minimized := false
var mobile_layout_visible := false

func setup(game_root) -> void:
	game = game_root
	_build()

func _unhandled_input(event: InputEvent) -> void:
	if game == null or game.state.is_empty() or not mobile_layout_visible:
		return
	if game.state.gameOver or game.is_selecting():
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_start_floating_joystick(event.index, event.position)
		elif int(game.state.mobileInput.get("pointerId", -1)) == event.index:
			_finish_floating_joystick()
	elif event is InputEventScreenDrag and int(game.state.mobileInput.get("pointerId", -1)) == event.index:
		_update_floating_joystick(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_floating_joystick(0, event.position)
		elif int(game.state.mobileInput.get("pointerId", -1)) == 0:
			_finish_floating_joystick()
	elif event is InputEventMouseMotion and game.state.mobileInput.get("active", false) and int(game.state.mobileInput.get("pointerId", -1)) == 0 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_update_floating_joystick(event.position)

func _build() -> void:
	var root = Control.new()
	root.name = "HudRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	ui.root = root

	ui.difficultyHud = _panel("difficultyHud", Vector2(-170, 10), Vector2(340, 68), 0.82, 8)
	ui.difficultyHud.anchor_left = 0.5
	ui.difficultyHud.anchor_right = 0.5
	root.add_child(ui.difficultyHud)
	var difficulty_box = _vbox(ui.difficultyHud, 6)
	var difficulty_row = HBoxContainer.new()
	difficulty_box.add_child(difficulty_row)
	ui.difficultyStage = _label("현재 난이도: 정상 작동", 12, Color("#edf2f7"), true)
	ui.difficultyStage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	difficulty_row.add_child(ui.difficultyStage)
	ui.difficultyScore = _label("0.0", 12, Color("#edf2f7"), true)
	difficulty_row.add_child(ui.difficultyScore)
	ui.difficultyBar = _bar(Color("#48d597"), 7)
	difficulty_box.add_child(ui.difficultyBar)
	ui.difficultyEffect = _label("선택 난이도 +0 / 팝업 압박 +0%", 10, Color("#9aa8ba"), true)
	difficulty_box.add_child(ui.difficultyEffect)

	ui.cleanupHud = _panel("cleanupComboHud", Vector2(-130, 64), Vector2(260, 58), 0.82, 7)
	ui.cleanupHud.anchor_left = 0.5
	ui.cleanupHud.anchor_right = 0.5
	root.add_child(ui.cleanupHud)
	var combo_box = _vbox(ui.cleanupHud, 5)
	ui.cleanupCount = _label("정리 콤보 x0", 12, Color("#edf2f7"), true)
	combo_box.add_child(ui.cleanupCount)
	ui.cleanupBar = _bar(Color("#5bd5ff"), 6)
	combo_box.add_child(ui.cleanupBar)
	ui.cleanupMeta = _label("대기 중", 10, Color("#9aa8ba"), true)
	combo_box.add_child(ui.cleanupMeta)

	ui.combatHud = _panel("combatHud", Vector2(12, 12), Vector2(270, 274), 0.92, 12)
	root.add_child(ui.combatHud)
	var combat_box = _vbox(ui.combatHud, 7)
	combat_box.add_child(_title("전투 HUD"))
	var hp_card = _hud_card(combat_box)
	var hp_header = _hud_card_header(hp_card, "HP")
	ui.hpText = _label("100 / 100", 12, Color("#edf2f7"), true)
	hp_header.add_child(ui.hpText)
	ui.healthBar = _bar(Color("#ff5964"), 10)
	hp_card.add_child(ui.healthBar)
	var xp_card = _hud_card(combat_box)
	var xp_header = _hud_card_header(xp_card, "Lv.")
	ui.levelText = _label("1", 12, Color("#edf2f7"), true)
	xp_header.get_child(0).add_child(ui.levelText)
	ui.xpText = _label("0 / 40", 12, Color("#edf2f7"), true)
	xp_header.add_child(ui.xpText)
	ui.xpBar = _bar(Color("#4aa8ff"), 10)
	xp_card.add_child(ui.xpBar)
	var modules = GridContainer.new()
	modules.columns = 2
	modules.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	combat_box.add_child(modules)
	ui.primaryModule = _module_card("1차 모듈", "미선택", "기본형")
	modules.add_child(ui.primaryModule)
	ui.secondaryModule = _module_card("보조 모듈", "없음", "대기 중")
	modules.add_child(ui.secondaryModule)
	ui.moduleMeta = GridContainer.new()
	ui.moduleMeta.columns = 2
	ui.moduleMeta.add_theme_constant_override("h_separation", 8)
	ui.moduleMeta.add_theme_constant_override("v_separation", 5)
	combat_box.add_child(ui.moduleMeta)
	ui.primaryMasteryText = _module_meta_cell(ui.moduleMeta, "1차 숙련", "0")
	ui.secondaryMasteryText = _module_meta_cell(ui.moduleMeta, "보조 숙련", "0")
	ui.nextChoiceText = _module_meta_cell(ui.moduleMeta, "다음 선택", "시작 선택", true)
	ui.popupCountText = _module_meta_cell(ui.moduleMeta, "팝업", "0 / 5", true)

	ui.economyHud = _panel("economyHud", Vector2(-267, 12), Vector2(255, 570), 0.92, 12)
	ui.economyHud.anchor_left = 1.0
	ui.economyHud.anchor_right = 1.0
	root.add_child(ui.economyHud)
	var economy_box = _vbox(ui.economyHud, 7)
	var gold_card = PanelContainer.new()
	gold_card.add_theme_stylebox_override("panel", _style_box(Color(0.27, 0.20, 0.05, 0.88), Color(0.95, 0.78, 0.29, 0.42), 8, 1, 9))
	economy_box.add_child(gold_card)
	var gold_row = HBoxContainer.new()
	gold_row.add_theme_constant_override("separation", 10)
	gold_card.add_child(gold_row)
	gold_row.add_child(_label("골드", 11, Color("#f6d477"), true))
	var gold_spacer = Control.new()
	gold_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gold_row.add_child(gold_spacer)
	ui.goldText = _label("0G", 22, Color("#ffe7a1"), true)
	gold_row.add_child(ui.goldText)
	_build_investor_dashboard(economy_box)
	var item_machine = _hud_card(economy_box)
	item_machine.add_child(_title("아이템 머신"))
	ui.itemCostText = _label("투입 비용 25G", 12, Color("#edf2f7"), true)
	item_machine.add_child(ui.itemCostText)
	ui.rollItemButton = Button.new()
	ui.rollItemButton.text = "아이템 머신 - 25G 투입"
	_style_button(ui.rollItemButton, "gold")
	ui.rollItemButton.pressed.connect(func(): game.roll_item())
	item_machine.add_child(ui.rollItemButton)
	var badge_row = HBoxContainer.new()
	item_machine.add_child(badge_row)
	ui.discountText = _badge("할인 0%")
	badge_row.add_child(ui.discountText)
	ui.extraChoiceText = _badge("선택지 +0")
	badge_row.add_child(ui.extraChoiceText)
	ui.openInventoryButton = Button.new()
	ui.openInventoryButton.text = "보유 아이템 보기"
	_style_button(ui.openInventoryButton, "blue")
	ui.openInventoryButton.pressed.connect(func(): game.open_inventory_overview())
	economy_box.add_child(ui.openInventoryButton)
	ui.lastItem = _rich("최근 아이템: 없음", 58)
	economy_box.add_child(ui.lastItem)
	_build_resident_program_hud(economy_box)
	economy_box.add_child(_title("아이템 목록"))
	ui.itemInventory = _rich("보유 아이템 없음", 122)
	economy_box.add_child(ui.itemInventory)
	economy_box.add_child(_title("최근 성장"))
	ui.recentPerk = _rich("아직 없음", 76)
	economy_box.add_child(ui.recentPerk)

	ui.statusPanel = _panel("statusPanel", Vector2(12, -148), Vector2(270, 136), 0.92, 12)
	ui.statusPanel.anchor_top = 1.0
	ui.statusPanel.anchor_bottom = 1.0
	root.add_child(ui.statusPanel)
	var status_box = _vbox(ui.statusPanel, 6)
	var status_header = HBoxContainer.new()
	status_box.add_child(status_header)
	status_header.add_child(_title("조작/상태"))
	var status_spacer = Control.new()
	status_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_header.add_child(status_spacer)
	ui.statusToggleButton = Button.new()
	ui.statusToggleButton.text = "-"
	ui.statusToggleButton.custom_minimum_size = Vector2(30, 26)
	ui.statusToggleButton.tooltip_text = "조작 패널 접기"
	_style_button(ui.statusToggleButton, "toggle")
	ui.statusToggleButton.pressed.connect(func(): _toggle_status())
	status_header.add_child(ui.statusToggleButton)
	ui.statusBody = VBoxContainer.new()
	ui.statusBody.add_theme_constant_override("separation", 6)
	status_box.add_child(ui.statusBody)
	var speed_row = HBoxContainer.new()
	speed_row.add_child(_label("배속", 11, Color("#9aa8ba"), true))
	var speed_spacer = Control.new()
	speed_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speed_row.add_child(speed_spacer)
	ui.speedSelect = OptionButton.new()
	for speed in ["0.5x", "1x", "1.5x", "2x"]:
		ui.speedSelect.add_item(speed)
	_style_button(ui.speedSelect, "compact")
	ui.speedSelect.select(1)
	ui.speedSelect.item_selected.connect(func(index): game.set_speed_index(index))
	speed_row.add_child(ui.speedSelect)
	ui.statusBody.add_child(speed_row)
	ui.runStats = _rich("WASD/모바일 조이스틱 이동, Space 긴급 닫기, P 일시정지.", 72)
	ui.statusBody.add_child(ui.runStats)

	ui.debugPanel = _panel("debugPanel", Vector2(-262, -420), Vector2(250, 408), 0.92, 12)
	ui.debugPanel.anchor_left = 1.0
	ui.debugPanel.anchor_right = 1.0
	ui.debugPanel.anchor_top = 1.0
	ui.debugPanel.anchor_bottom = 1.0
	root.add_child(ui.debugPanel)
	var debug_box = _vbox(ui.debugPanel, 6)
	var debug_header = HBoxContainer.new()
	debug_box.add_child(debug_header)
	debug_header.add_child(_title("디버그"))
	var debug_spacer = Control.new()
	debug_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	debug_header.add_child(debug_spacer)
	ui.debugToggleButton = Button.new()
	ui.debugToggleButton.text = "-"
	ui.debugToggleButton.custom_minimum_size = Vector2(30, 26)
	_style_button(ui.debugToggleButton, "toggle")
	ui.debugToggleButton.pressed.connect(func(): _toggle_debug())
	debug_header.add_child(ui.debugToggleButton)
	ui.debugBody = VBoxContainer.new()
	ui.debugBody.add_theme_constant_override("separation", 6)
	debug_box.add_child(ui.debugBody)
	ui.debugStats = _rich("", 78)
	ui.debugBody.add_child(ui.debugStats)
	ui.debugScroll = ScrollContainer.new()
	ui.debugScroll.custom_minimum_size = Vector2(0, 260)
	ui.debugBody.add_child(ui.debugScroll)
	ui.debugButtons = GridContainer.new()
	ui.debugButtons.columns = 2
	ui.debugScroll.add_child(ui.debugButtons)
	_add_debug_buttons()

	ui.popupTelegraphLayer = Control.new()
	ui.popupTelegraphLayer.name = "popupTelegraphLayer"
	ui.popupTelegraphLayer.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.popupTelegraphLayer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(ui.popupTelegraphLayer)

	ui.trashZone = _panel("trashZone", Vector2(-80, -72), Vector2(160, 58), 0.78, 0, true)
	ui.trashZone.anchor_left = 0.5
	ui.trashZone.anchor_right = 0.5
	ui.trashZone.anchor_top = 1.0
	ui.trashZone.anchor_bottom = 1.0
	ui.trashZone.visible = false
	root.add_child(ui.trashZone)
	var trash_box = _vbox(ui.trashZone, 0)
	var trash_label = _label("여기로 버리기", 12, Color("#edf2f7"), true)
	trash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	trash_box.add_child(trash_label)

	_build_mobile_controls(root)
	_build_choice_overlay(root)
	_build_game_over(root)

func _build_mobile_controls(root: Control) -> void:
	ui.mobileControls = Control.new()
	ui.mobileControls.name = "mobileControls"
	ui.mobileControls.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mobileControls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(ui.mobileControls)
	ui.mobileFullscreenButton = Button.new()
	ui.mobileFullscreenButton.text = "전체화면"
	_style_button(ui.mobileFullscreenButton, "compact")
	ui.mobileFullscreenButton.anchor_left = 0.5
	ui.mobileFullscreenButton.anchor_right = 0.5
	ui.mobileFullscreenButton.offset_left = -39
	ui.mobileFullscreenButton.offset_right = 39
	ui.mobileFullscreenButton.offset_top = 8
	ui.mobileFullscreenButton.offset_bottom = 40
	ui.mobileFullscreenButton.pressed.connect(func(): game.toggle_fullscreen())
	ui.mobileControls.add_child(ui.mobileFullscreenButton)
	ui.orientationPrompt = _panel("orientationPrompt", Vector2(-155, -45), Vector2(310, 90), 0.78, 14)
	ui.orientationPrompt.anchor_left = 0.5
	ui.orientationPrompt.anchor_right = 0.5
	ui.orientationPrompt.anchor_top = 0.5
	ui.orientationPrompt.anchor_bottom = 0.5
	ui.orientationPrompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.mobileControls.add_child(ui.orientationPrompt)
	var prompt_box = _vbox(ui.orientationPrompt, 4)
	prompt_box.alignment = BoxContainer.ALIGNMENT_CENTER
	var prompt_title = _label("가로 모드 권장", 16, Color("#8fd4ff"), true)
	prompt_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_box.add_child(prompt_title)
	var prompt_body = _label("휴대폰을 가로로 돌리거나 전체화면 버튼을 눌러 주세요.", 12, Color("#edf2f7"), false)
	prompt_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_box.add_child(prompt_body)
	ui.mobileJoystick = _panel("mobileJoystick", Vector2(0, 0), Vector2(86, 86), 0.58, 0)
	ui.mobileJoystick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.mobileJoystick.visible = false
	ui.mobileJoystick.modulate.a = 0.0
	ui.mobileJoystick.add_theme_stylebox_override("panel", _style_box(Color(0.05, 0.07, 0.11, 0.58), Color(1, 1, 1, 0.28), 43, 2, 0))
	ui.mobileControls.add_child(ui.mobileJoystick)
	ui.mobileJoystickKnob = PanelContainer.new()
	ui.mobileJoystickKnob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.mobileJoystickKnob.custom_minimum_size = Vector2(32, 32)
	ui.mobileJoystickKnob.add_theme_stylebox_override("panel", _style_box(Color(0.28, 0.84, 0.59, 0.88), Color(1, 1, 1, 0.68), 16, 2, 0))
	ui.mobileJoystick.add_child(ui.mobileJoystickKnob)
	ui.mobileEmergencyButton = Button.new()
	ui.mobileEmergencyButton.text = "긴급 닫기"
	_style_button(ui.mobileEmergencyButton, "danger")
	ui.mobileEmergencyButton.anchor_left = 1.0
	ui.mobileEmergencyButton.anchor_right = 1.0
	ui.mobileEmergencyButton.anchor_top = 1.0
	ui.mobileEmergencyButton.anchor_bottom = 1.0
	ui.mobileEmergencyButton.offset_left = -84
	ui.mobileEmergencyButton.offset_right = -12
	ui.mobileEmergencyButton.offset_top = -56
	ui.mobileEmergencyButton.offset_bottom = -18
	ui.mobileEmergencyButton.pressed.connect(func(): game.emergency_close_oldest_popup())
	ui.mobileControls.add_child(ui.mobileEmergencyButton)
	_apply_mobile_layout(get_viewport().get_visible_rect().size)

func _build_choice_overlay(root: Control) -> void:
	ui.choiceOverlay = ColorRect.new()
	ui.choiceOverlay.name = "itemOverlay"
	ui.choiceOverlay.color = Color(0, 0, 0, 0.72)
	ui.choiceOverlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.choiceOverlay.visible = false
	root.add_child(ui.choiceOverlay)
	var panel = _panel("itemPanel", Vector2(-340, -250), Vector2(680, 500), 0.98, 18)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	ui.choiceOverlay.add_child(panel)
	var box = _vbox(panel, 10)
	ui.choiceTitle = _title("아이템 선택")
	ui.choiceTitle.add_theme_font_size_override("font_size", 24)
	box.add_child(ui.choiceTitle)
	ui.choiceDescription = _rich("", 58)
	ui.choiceDescription.add_theme_stylebox_override("normal", _style_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0, 0))
	ui.choiceDescription.add_theme_color_override("default_color", Color("#9aa8ba"))
	box.add_child(ui.choiceDescription)
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	ui.choiceGrid = GridContainer.new()
	ui.choiceGrid.columns = 3
	ui.choiceGrid.add_theme_constant_override("h_separation", 12)
	ui.choiceGrid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(ui.choiceGrid)

func _build_game_over(root: Control) -> void:
	ui.gameOverOverlay = ColorRect.new()
	ui.gameOverOverlay.name = "gameOverOverlay"
	ui.gameOverOverlay.color = Color(0, 0, 0, 0.72)
	ui.gameOverOverlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.gameOverOverlay.visible = false
	root.add_child(ui.gameOverOverlay)
	var panel = _panel("gameOverPanel", Vector2(-230, -120), Vector2(460, 240), 0.96)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	ui.gameOverOverlay.add_child(panel)
	var box = _vbox(panel, 12)
	var title = _title("게임 오버")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	ui.gameOverSummary = _rich("", 80)
	box.add_child(ui.gameOverSummary)
	var restart = Button.new()
	restart.text = "재시작"
	_style_button(restart, "blue")
	restart.pressed.connect(func(): game.reset_game())
	box.add_child(restart)

func _panel(name: String, pos: Vector2, size: Vector2, alpha: float, margin := 12, dashed := false) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.name = name
	panel.offset_left = pos.x
	panel.offset_top = pos.y
	panel.offset_right = pos.x + size.x
	panel.offset_bottom = pos.y + size.y
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.10, 0.15, alpha)
	style.border_color = Color(1, 1, 1, 0.42 if dashed else 0.16)
	style.set_border_width_all(2 if dashed else 1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.set_content_margin_all(margin)
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _vbox(parent: Node, separation: int) -> VBoxContainer:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(box)
	return box

func _title(text: String) -> Label:
	return _label(text, 15, Color("#edf2f7"), true)

func _label(text: String, size: int, color: Color, bold: bool) -> Label:
	var label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	return label

func _rich(text: String, height: float) -> RichTextLabel:
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.text = text
	label.custom_minimum_size = Vector2(0, height)
	label.fit_content = false
	label.scroll_active = true
	label.add_theme_font_size_override("normal_font_size", 11)
	label.add_theme_color_override("default_color", Color("#c8d5e7"))
	var style = _style_box(Color(1, 1, 1, 0.08), Color(1, 1, 1, 0.0), 6, 0, 8)
	label.add_theme_stylebox_override("normal", style)
	return label

func _bar(fill_color: Color = Color("#4aa8ff"), height := 10) -> ProgressBar:
	var bar = ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, height)
	var background = _style_box(Color(1, 1, 1, 0.12), Color(1, 1, 1, 0.12), 99, 1)
	var fill = _style_box(fill_color, Color(fill_color, 0.0), 99, 0)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	return bar

func _set_bar_fill_color(bar: ProgressBar, fill_color: Color) -> void:
	bar.add_theme_stylebox_override("fill", _style_box(fill_color, Color(fill_color, 0.0), 99, 0))

func _difficulty_color(stage_id: String) -> Color:
	match stage_id:
		"warning":
			return Color("#f3c84b")
		"danger":
			return Color("#ff9f43")
		"overload":
			return Color("#ff5964")
		"collapse":
			return Color("#d26bff")
		"nightmare":
			return Color("#ff4fd8")
	return Color("#48d597")

func _badge(text: String) -> Label:
	var badge = _label(text, 10, Color("#edf2f7"), true)
	badge.custom_minimum_size = Vector2(86, 24)
	return badge

func _hud_card(parent: Node) -> VBoxContainer:
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _style_box(Color(1, 1, 1, 0.065), Color(1, 1, 1, 0.11), 7, 1, 8))
	parent.add_child(card)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)
	return box

func _hud_card_header(parent: Node, title: String) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var left = HBoxContainer.new()
	left.add_theme_constant_override("separation", 3)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	left.add_child(_label(title, 12, Color("#d8e3f3"), true))
	return row

func _build_investor_dashboard(parent: Node) -> void:
	ui.investorDashboard = PanelContainer.new()
	ui.investorDashboard.add_theme_stylebox_override("panel", _style_box(Color(0.08, 0.12, 0.15, 0.9), Color(0.95, 0.78, 0.29, 0.28), 7, 1, 8))
	parent.add_child(ui.investorDashboard)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	ui.investorDashboard.add_child(box)
	var header = _hud_card_header(box, "투자자 터미널")
	ui.investorCreditMini = _label("신용 50", 11, Color("#ffe4a3"), true)
	header.add_child(ui.investorCreditMini)
	ui.investorDashboardBody = VBoxContainer.new()
	ui.investorDashboardBody.add_theme_constant_override("separation", 4)
	box.add_child(ui.investorDashboardBody)

func _build_resident_program_hud(parent: Node) -> void:
	ui.residentProgramHud = PanelContainer.new()
	ui.residentProgramHud.add_theme_stylebox_override("panel", _style_box(Color(1, 1, 1, 0.065), Color(1, 1, 1, 0.11), 7, 1, 8))
	parent.add_child(ui.residentProgramHud)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	ui.residentProgramHud.add_child(box)
	var header = _hud_card_header(box, "보안 프로그램")
	ui.residentProgramCount = _label("0", 11, Color("#dceeff"), true)
	header.add_child(ui.residentProgramCount)
	ui.residentProgramList = VBoxContainer.new()
	ui.residentProgramList.add_theme_constant_override("separation", 4)
	box.add_child(ui.residentProgramList)

func _clear_container(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func _hud_line(parent: Node, left_text: String, right_text: String, accent := false) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.custom_minimum_size = Vector2(0, 22)
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style_box(Color(1, 1, 1, 0.06), Color(1, 1, 1, 0.0), 5, 0, 5))
	parent.add_child(panel)
	panel.add_child(row)
	var left = _label(left_text, 11, Color("#9aa8ba"), true)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	row.add_child(_label(right_text, 11, Color("#ffe4a3" if accent else "#edf2f7"), true))
	return row

func _hud_summary(parent: Node, text: String) -> Label:
	var label = _label(text, 10, Color("#bce8ff"), true)
	parent.add_child(label)
	return label

func _module_card(title: String, value: String, detail: String) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(134, 60)
	panel.add_theme_stylebox_override("panel", _style_box(Color(0.08, 0.14, 0.20, 0.72), Color(0.52, 0.82, 1.0, 0.22), 7, 1, 7))
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
	box.add_child(_label(title, 10, Color("#9aa8ba"), true))
	box.add_child(_label(value, 12, Color("#edf2f7"), true))
	box.add_child(_label(detail, 10, Color("#9aa8ba"), false))
	return panel

func _module_meta_cell(parent: Node, label_text: String, value_text: String, wide := false) -> Label:
	var label = _label("%s %s" % [label_text, value_text], 11, Color("#9aa8ba"), true)
	label.custom_minimum_size = Vector2(118 if not wide else 244, 22)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label

func _module_card_value(card: PanelContainer) -> Label:
	return card.get_child(0).get_child(1)

func _module_card_detail(card: PanelContainer) -> Label:
	return card.get_child(0).get_child(2)

func _add_debug_buttons() -> void:
	var actions = [
		["gold", "골드 +25"], ["gold100", "골드 +100"], ["xp10", "XP +10"], ["xp", "XP +레벨"], ["forceLevel", "강제 레벨업"],
		["formSelect", "Lv.9 방식 선택"], ["mechanicSelect", "Lv.13 기믹"], ["scalingSelect", "Lv.17 최적화"], ["executionWindow", "정리 콤보 +1"], ["cleanupCombo5", "정리 콤보 x5"],
		["waveNormal", "일반 웨이브"], ["waveSide", "한쪽 웨이브"], ["waveSurround", "포위 웨이브"], ["waveFast", "빠른 웨이브"], ["waveDense", "두꺼운 웨이브"],
		["dropMagnetPickup", "자석 드랍"], ["dropHealPickup", "회복 드랍"], ["installKeyboardSecurity", "키보드 보안"], ["installRealtimeGuard", "실시간 감시"], ["installPopupQuarantine", "팝업 격리"],
		["installKernelGuard", "커널 보안"], ["clearResidentPrograms", "보안 제거"], ["invested100", "투자금 +100"], ["sponsoredStacks", "후원탄 +5"], ["boss", "보스 소환"],
		["bossPackage", "보스 패키지"], ["boss_package_ad", "보스 광고창"], ["randomItem", "랜덤 아이템"], ["allItems", "아이템 전체"], ["rate", "팝업 x2"], ["heat", "난이도 +1"], ["creditPlus", "신용 +10"], ["creditMinus", "신용 -10"], ["clear", "팝업 제거"],
		["telegraphMoving", "예고 이동 팝업"], ["first_purchase_package", "첫 계약"], ["investorMode", "투자자 모드"], ["clearPlaystyle", "계약 해제"], ["interest_offer", "이자 상품"],
		["recurring_investment", "자동 투자"], ["loan_offer", "신용 현금화"], ["stock_broker_app", "증권 앱"], ["popup_store", "팝업 상점"], ["ad_buff", "광고 버프"],
		["stock_stable", "안정 배당주"], ["stock_momentum", "모멘텀 주식"], ["stock_cursed", "저주 조작주"], ["security_update_notice", "보안 알림"],
		["ad_coupon", "광고 할인"], ["ad_free_sample", "광고 샘플"], ["ad_premium_sample", "광고 선택지"], ["timed_reward", "시간 보상"], ["terms", "약관"],
		["keyboard_security_installer", "키보드 설치창"], ["realtime_guard_installer", "감시 설치창"], ["popup_quarantine_installer", "격리 설치창"], ["kernel_guard_installer", "커널 설치창"],
		["terms_ad_tracking", "추적 약관"], ["terms_emergency_waiver", "긴급 각서"], ["terms_malicious_optimization", "악성 약관"], ["clean_challenge_basic", "청소 의뢰"],
		["volatile_bomb_popup", "불안정 창"], ["moving_close", "떠다니는 광고"], ["infection", "감염"],
	]
	for action in actions:
		var button = Button.new()
		button.text = action[1]
		button.custom_minimum_size = Vector2(100, 28)
		_style_button(button, "compact")
		button.pressed.connect(func(id = action[0]): game.debug_action(id))
		ui.debugButtons.add_child(button)

func _toggle_debug() -> void:
	ui.debugBody.visible = not ui.debugBody.visible
	ui.debugToggleButton.text = "-" if ui.debugBody.visible else "+"
	ui.debugToggleButton.tooltip_text = "디버그 패널 접기" if ui.debugBody.visible else "디버그 패널 펼치기"
	ui.debugPanel.offset_left = -262 if ui.debugBody.visible else -144
	ui.debugPanel.offset_top = -420 if ui.debugBody.visible else -54

func _toggle_status() -> void:
	status_minimized = not status_minimized
	ui.statusBody.visible = not status_minimized
	ui.statusToggleButton.text = "+" if status_minimized else "-"
	ui.statusToggleButton.tooltip_text = "조작 패널 펼치기" if status_minimized else "조작 패널 접기"
	ui.statusPanel.offset_top = -52 if status_minimized else -148

func _update_investor_dashboard(state: Dictionary) -> void:
	var active = state.activePlaystyle == "investor_starter"
	ui.investorDashboard.visible = active
	ui.investorCreditMini.text = "신용 %d" % int(state.creditScore)
	_clear_container(ui.investorDashboardBody)
	if not active:
		_hud_summary(ui.investorDashboardBody, "투자자 계약 대기 중")
		return
	var values = game.investor_bonus_values()
	var recurring = 0
	var recurring_count = 0
	for popup in state.openPopups:
		if popup.def.type == "recurring_investment" and popup.has("investment") and popup.investment.get("accepted", false):
			recurring += int(popup.investment.get("accumulated", 0))
			recurring_count += 1
	var stock = state.stockMarket.stock
	var stock_value = int(floor(stock.price * stock.shares))
	var stock_principal = int(round(stock.avgCost * stock.shares))
	var stock_profit = stock_value - stock_principal
	_hud_line(ui.investorDashboardBody, "보유 골드", "%dG" % int(state.gold), true)
	_hud_line(ui.investorDashboardBody, "투자 중 골드", "%dG" % int(state.investedGold), true)
	_hud_line(ui.investorDashboardBody, "투자 피해", "%+d%%" % round(values.investedDamage * 100.0))
	_hud_line(ui.investorDashboardBody, "신용 템포", "%+d%%" % round(values.creditCooldown * 100.0))
	_hud_line(ui.investorDashboardBody, "보유 골드 사거리", "%+d%%" % round(values.heldGoldRange * 100.0))
	_hud_line(ui.investorDashboardBody, "자동 적립", "%d건 · %dG" % [recurring_count, recurring])
	_hud_line(ui.investorDashboardBody, "주식 평가", "%dG / %+dG" % [stock_value, stock_profit], true)
	_hud_line(ui.investorDashboardBody, "시장 심리", str(state.stockMarket.lastBiasLabel))

func _update_resident_program_hud(state: Dictionary) -> void:
	ui.residentProgramCount.text = "%d" % state.residentPrograms.size()
	_clear_container(ui.residentProgramList)
	if state.residentPrograms.is_empty():
		_hud_summary(ui.residentProgramList, "설치 없음")
		return
	for program in state.residentPrograms:
		var status = "정지" if program.get("suspended", false) else "활성"
		_hud_line(ui.residentProgramList, program.name, status, not program.get("suspended", false))
		if program.def.get("upkeepGold", 0) > 0:
			_hud_summary(ui.residentProgramList, "%.0f초 후 %dG" % [float(program.get("upkeepTimer", 0.0)), int(program.def.upkeepGold)])
		else:
			_hud_summary(ui.residentProgramList, "%.0f초 후 업데이트" % float(program.get("updateTimer", 0.0)))
	if state.reservedMaxHP > 0:
		_hud_summary(ui.residentProgramList, "점유 HP: %d" % int(state.reservedMaxHP))
	var item_burden = game.total_resident_item_cost_multiplier()
	if item_burden > 0.0:
		_hud_summary(ui.residentProgramList, "아이템 비용 부담 +%d%%" % round(item_burden * 100.0))

func update_from_state(state: Dictionary) -> void:
	var hp_ratio = clamp(float(state.player.hp) / max(float(state.player.maxHP), 1.0), 0.0, 1.0)
	ui.hpText.text = "%d / %d" % [ceil(state.player.hp), ceil(state.player.maxHP)]
	ui.healthBar.value = hp_ratio * 100.0
	ui.levelText.text = "%d" % state.level
	ui.xpText.text = "%d / %d" % [state.xp, state.xpNeed]
	ui.xpBar.value = 100.0 * float(state.xp) / max(float(state.xpNeed), 1.0)
	ui.goldText.text = "%dG" % state.gold
	ui.itemCostText.text = "투입 비용 %dG" % game.current_item_roll_cost()
	ui.rollItemButton.text = "아이템 머신 - %dG 투입" % game.current_item_roll_cost()
	ui.rollItemButton.disabled = state.paused or game.is_selecting() or state.gold < game.current_item_roll_cost()
	ui.discountText.text = "할인 %d%%" % round(game.current_item_discount() * 100.0)
	ui.extraChoiceText.text = "선택지 +%d" % state.nextItemExtraChoices
	_module_card_value(ui.primaryModule).text = game.module_name(state.primaryModule, "미선택")
	_module_card_detail(ui.primaryModule).text = game.module_detail("primary")
	_module_card_value(ui.secondaryModule).text = game.module_name(state.secondaryModule, "없음")
	_module_card_detail(ui.secondaryModule).text = game.module_detail("secondary")
	ui.primaryMasteryText.text = "1차 숙련 %d" % state.primaryMastery
	ui.secondaryMasteryText.text = "보조 숙련 %d" % state.secondaryMastery
	ui.nextChoiceText.text = "다음 선택 %s" % game.next_growth_choice_label()
	ui.popupCountText.text = "팝업 %d / %d" % [state.openPopups.size(), game.max_open_popups()]
	var info = game.difficulty_stage_info()
	ui.difficultyStage.text = "현재 난이도: %s" % info.current.label
	ui.difficultyScore.text = "%.1f" % game.current_difficulty_score()
	ui.difficultyBar.value = info.progress * 100.0
	_set_bar_fill_color(ui.difficultyBar, _difficulty_color(info.current.id))
	var pulse = clamp(float(state.difficultyPulseTimer), 0.0, 1.0)
	ui.difficultyHud.pivot_offset = ui.difficultyHud.size * 0.5
	ui.difficultyHud.scale = Vector2.ONE * (1.0 + pulse * 0.025)
	ui.difficultyEffect.text = game.difficulty_effect_summary()
	ui.cleanupCount.text = "정리 콤보 x%d" % state.cleanupComboValue
	ui.cleanupBar.value = 100.0 * clamp(float(state.cleanupComboTimer) / max(game.effective_cleanup_combo_grace(), 0.1), 0.0, 1.0)
	ui.cleanupMeta.text = game.cleanup_combo_meta()
	_update_investor_dashboard(state)
	ui.lastItem.text = state.lastItemText
	_update_resident_program_hud(state)
	ui.itemInventory.text = game.inventory_text()
	ui.recentPerk.text = state.recentPerkText
	ui.runStats.text = game.run_stats_text()
	ui.debugStats.text = game.debug_stats_text()
	ui.gameOverOverlay.visible = state.gameOver
	if state.gameOver:
		ui.gameOverSummary.text = "생존 시간 %s, 도달 레벨 %d, 보유 골드 %dG.\nR을 눌러 재시작하세요." % [game.format_time(state.elapsed), state.level, state.gold]
	ui.cleanupHud.visible = state.cleanupComboValue > 0
	var viewport_size = get_viewport().get_visible_rect().size
	_update_mobile_button_state(state)
	_apply_mobile_layout(viewport_size)
	_update_mobile_knob(state)
	_update_telegraphs(state)
	_update_trash_zone(state)

func show_choices(title: String, description: String, choices: Array, callback: Callable, columns := 3) -> void:
	ui.choiceTitle.text = title
	ui.choiceDescription.text = description
	ui.choiceGrid.columns = columns
	_clear_choice_grid()
	for choice in choices:
		ui.choiceGrid.add_child(_choice_card_button(choice, false, false, callback))
	ui.choiceOverlay.visible = true

func show_boss_package_choices(title: String, description: String, choices: Array, selected_ids: Array, callback: Callable, columns := 3) -> void:
	ui.choiceTitle.text = title
	ui.choiceDescription.text = "%s\n%d / 2 선택" % [description, selected_ids.size()]
	ui.choiceGrid.columns = columns
	_clear_choice_grid()
	for choice in choices:
		var selected = selected_ids.has(choice.get("id", ""))
		ui.choiceGrid.add_child(_choice_card_button(choice, selected, not selected and selected_ids.size() >= 2, callback))
	ui.choiceOverlay.visible = true

func show_inventory_overview(callback: Callable) -> void:
	ui.choiceTitle.text = "보유 아이템"
	ui.choiceDescription.text = "현재 보유 중인 아이템과 태그, 적용 중인 효과를 한눈에 확인합니다.\n\n%s" % game.resident_program_hud_text()
	ui.choiceGrid.columns = 3
	_clear_choice_grid()
	var owned_count = 0
	for item in game.data.ITEMS:
		var count = int(game.state.itemCounts.get(item.get("id", ""), 0))
		if count <= 0:
			continue
		owned_count += 1
		ui.choiceGrid.add_child(_inventory_card(item, count))
	if owned_count == 0:
		var empty = _rich("아직 보유한 아이템이 없습니다.", 64)
		empty.custom_minimum_size = Vector2(220, 64)
		ui.choiceGrid.add_child(empty)
	var close = Button.new()
	close.text = "닫기\n게임으로 돌아갑니다."
	close.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	close.custom_minimum_size = Vector2(220, 54)
	_style_button(close, "choice")
	close.pressed.connect(callback)
	ui.choiceGrid.add_child(close)
	ui.choiceOverlay.visible = true

func hide_choices() -> void:
	ui.choiceOverlay.visible = false

func _clear_choice_grid() -> void:
	for child in ui.choiceGrid.get_children():
		ui.choiceGrid.remove_child(child)
		child.queue_free()

func _choice_card_button(choice: Dictionary, selected: bool, disabled: bool, callback: Callable) -> Button:
	var button = Button.new()
	button.name = "itemChoice" if choice.has("rarity") else "moduleChoice"
	button.text = ""
	button.tooltip_text = _choice_button_text(choice, selected)
	button.custom_minimum_size = _choice_button_size(choice)
	button.disabled = disabled
	_style_button(button, _choice_button_variant(choice, selected))
	button.pressed.connect(func(c = choice): callback.call(c))
	var box = VBoxContainer.new()
	box.name = "choiceCardBody"
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 10
	box.offset_top = 10
	box.offset_right = -10
	box.offset_bottom = -10
	box.add_theme_constant_override("separation", 6)
	button.add_child(box)
	if selected:
		box.add_child(_choice_badge("선택됨", Color(0.28, 0.84, 0.59, 0.16), Color(0.28, 0.84, 0.59, 0.52), Color("#dfffee"), "selectedBadge"))
	if choice.has("rarity"):
		_build_item_choice_card(box, choice)
	else:
		_build_module_choice_card(box, choice)
	_make_mouse_transparent(box)
	return button

func _build_item_choice_card(box: VBoxContainer, choice: Dictionary) -> void:
	var rarity = choice.get("rarity", "Common")
	box.add_child(_choice_badge(str(rarity).to_upper(), Color(1, 1, 1, 0.14), Color(1, 1, 1, 0.0), _rarity_accent(rarity), "rarityBadge"))
	var title = _label(choice.get("name", choice.get("id", "아이템")), 16, Color("#ffe29a"), true)
	title.name = "choiceTitleText"
	box.add_child(title)
	var tag_row = _choice_tag_row(choice)
	if tag_row.get_child_count() > 0:
		box.add_child(tag_row)
	else:
		tag_row.free()
	var desc = _label(str(choice.get("description", "")), 13, Color("#c8d5e7"), false)
	desc.name = "choiceDescriptionText"
	desc.custom_minimum_size = Vector2(0, 44)
	box.add_child(desc)
	box.add_child(_choice_meta("현재: %s\n선택 후: %s" % [game.describe_item_current(choice, 0), game.describe_item_current(choice, 1)]))

func _build_module_choice_card(box: VBoxContainer, choice: Dictionary) -> void:
	var title = _label(choice.get("name", choice.get("label", choice.get("title", choice.get("id", "선택")))), 15, Color("#f4f7fb"), true)
	title.name = "choiceTitleText"
	box.add_child(title)
	var desc = _label(str(choice.get("description", choice.get("body", ""))), 12, Color("#c7d2e1"), false)
	desc.name = "choiceDescriptionText"
	desc.custom_minimum_size = Vector2(0, 42)
	box.add_child(desc)
	var tag_row = _choice_tag_row(choice)
	if tag_row.get_child_count() > 0:
		box.add_child(tag_row)
	else:
		tag_row.free()
	var meta_lines = []
	if choice.has("baseDamage"):
		meta_lines.append("기본 피해 %s / 쿨타임 %.2f초 / 범위 %s" % [choice.get("baseDamage", "-"), float(choice.get("baseCooldown", 0.0)), choice.get("baseRange", "-")])
	if choice.has("compatibleTags"):
		var compatible = []
		for tag in choice.get("compatibleTags", []):
			compatible.append(str(tag))
		meta_lines.append("호환: %s" % ", ".join(compatible))
	if choice.has("playstyle"):
		meta_lines.append("판정 빌드: %s" % choice.get("playstyle", "generic"))
	if not meta_lines.is_empty():
		box.add_child(_choice_meta("\n".join(meta_lines)))

func _choice_tag_row(choice: Dictionary) -> HFlowContainer:
	var row = HFlowContainer.new()
	row.name = "itemTags"
	row.add_theme_constant_override("h_separation", 4)
	row.add_theme_constant_override("v_separation", 4)
	for tag in _choice_tag_keys(choice).slice(0, 5):
		var build_tag = _tag_matches_active_build(tag)
		row.add_child(_choice_badge(_tag_label(tag), Color(1.0, 0.89, 0.60, 0.14) if build_tag else Color(1, 1, 1, 0.08), Color(1.0, 0.89, 0.60, 0.55) if build_tag else Color(1, 1, 1, 0.16), Color("#ffe29a") if build_tag else Color("#dce8f8"), "itemTagBuild" if build_tag else "itemTag"))
	return row

func _choice_meta(text: String) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.name = "choiceMeta"
	panel.add_theme_stylebox_override("panel", _style_box(Color(1, 1, 1, 0.06), Color(1, 1, 1, 0.12), 5, 1, 7))
	var label = _label(text, 12, Color("#f6d477"), true)
	label.name = "choiceMetaText"
	panel.add_child(label)
	return panel

func _choice_badge(text: String, bg: Color, border: Color, font: Color, node_name: String) -> Label:
	var label = _label(text, 10, font, true)
	label.name = node_name
	label.add_theme_stylebox_override("normal", _style_box(bg, border, 99, 1, 6))
	return label

func _rarity_accent(rarity: String) -> Color:
	return _inventory_rarity_colors(rarity).accent

func _make_mouse_transparent(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_make_mouse_transparent(child)

func _inventory_card(item: Dictionary, count: int) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(220, 154)
	var rarity = item.get("rarity", "Common")
	var colors = _inventory_rarity_colors(rarity)
	card.add_theme_stylebox_override("panel", _style_box(colors.bg, colors.border, 6, 1, 10))
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	card.add_child(box)
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 5)
	box.add_child(header)
	var badge = _label("[%s]" % rarity, 10, colors.accent, true)
	header.add_child(badge)
	var title = _label("%s x%d" % [item.get("name", item.get("id", "아이템")), count], 12, Color("#edf2f7"), true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var tags = _choice_tag_text(item)
	if tags != "":
		box.add_child(_label("태그: %s" % tags, 10, Color("#aebdd0"), true))
	var desc = _label(str(item.get("description", "")), 11, Color("#d5e1ef"), false)
	desc.custom_minimum_size = Vector2(0, 40)
	box.add_child(desc)
	box.add_child(_label("현재: %s" % game.describe_item_current(item, 0), 10, Color("#f3c84b"), true))
	return card

func _inventory_rarity_colors(rarity: String) -> Dictionary:
	match rarity:
		"Rare":
			return {"bg": Color("#1c2d42"), "border": Color(0.45, 0.75, 1.0, 0.66), "accent": Color("#8fd0ff")}
		"Epic":
			return {"bg": Color("#2d2240"), "border": Color(0.82, 0.64, 1.0, 0.7), "accent": Color("#d8b6ff")}
		"Cursed":
			return {"bg": Color("#3c1f2b"), "border": Color(1.0, 0.56, 0.63, 0.78), "accent": Color("#ff9cab")}
	return {"bg": Color("#1f2a3b"), "border": Color(0.86, 0.91, 0.97, 0.34), "accent": Color("#dce8f8")}

func _choice_button_text(choice: Dictionary, selected := false) -> String:
	var name = choice.get("name", choice.get("label", choice.get("title", choice.get("id", "선택"))))
	var desc = choice.get("description", choice.get("body", ""))
	var lines = []
	if selected:
		lines.append("[선택됨]")
	if choice.has("rarity"):
		lines.append("[%s] %s" % [choice.get("rarity", "Common"), name])
		var tags = _choice_tag_text(choice)
		if tags != "":
			lines.append("태그: %s" % tags)
		lines.append(desc)
		lines.append("현재: %s" % game.describe_item_current(choice, 0))
		lines.append("선택 후: %s" % game.describe_item_current(choice, 1))
	else:
		lines.append(str(name))
		if choice.has("baseDamage"):
			lines.append("기본 피해 %s / 쿨타임 %.2fs / 범위 %s" % [choice.get("baseDamage", "-"), float(choice.get("baseCooldown", 0.0)), choice.get("baseRange", "-")])
		var tags = _choice_tag_text(choice)
		if tags != "":
			lines.append("태그: %s" % tags)
		if desc != "":
			lines.append(desc)
	return "\n".join(lines)

func _choice_button_size(choice: Dictionary) -> Vector2:
	if choice.has("rarity"):
		return Vector2(204, 160)
	if choice.has("baseDamage") or choice.has("tags"):
		return Vector2(204, 128)
	return Vector2(204, 112)

func _choice_button_variant(choice: Dictionary, selected := false) -> String:
	if selected:
		return "selected_choice"
	match choice.get("rarity", ""):
		"Rare":
			return "choice_rare"
		"Epic":
			return "choice_epic"
		"Cursed":
			return "choice_cursed"
		"Common":
			return "choice_common"
	return "choice"

func _choice_tag_text(choice: Dictionary) -> String:
	var ordered = _choice_tag_keys(choice)
	var labels = []
	for index in range(min(4, ordered.size())):
		labels.append(_tag_label(ordered[index]))
	return " · ".join(labels)

func _choice_tag_keys(choice: Dictionary) -> Array:
	var tags = choice.get("tags", choice.get("compatibleTags", []))
	if tags.is_empty():
		return []
	var priority = ["investor", "sponsored", "clutter", "clean", "vitality", "curse", "gold", "invested_gold", "credit", "ad_open", "ad_completion", "popup_count", "low_popup", "popup_close", "cleanup_combo", "pickup", "crit", "health", "regen", "lifesteal", "low_hp", "healing", "heat", "damage", "cooldown", "range", "economy", "utility"]
	var ordered = []
	for tag in priority:
		if tags.has(tag):
			ordered.append(tag)
	for tag in tags:
		if not ordered.has(tag):
			ordered.append(tag)
	return ordered

func _tag_label(tag: String) -> String:
	return game.data.get("ITEM_TAG_LABELS", {}).get(tag, tag)

func _tag_matches_active_build(tag: String) -> bool:
	if game == null or game.state.is_empty():
		return false
	var playstyle = game.active_playstyle_key()
	var groups = {
		"investor": ["investor", "gold", "credit", "invested_gold"],
		"sponsored": ["sponsored", "ad_open", "ad_completion"],
		"clean": ["clean", "cleanup_combo", "low_popup"],
		"clutter": ["clutter", "popup_count", "crowded"],
		"curse": ["curse", "heat", "risk"],
	}
	return groups.get(playstyle, []).has(tag)

func _update_telegraphs(state: Dictionary) -> void:
	for child in ui.popupTelegraphLayer.get_children():
		child.queue_free()
	for pending in state.pendingPopupSpawns:
		var panel = PanelContainer.new()
		panel.name = "popupTelegraph_%s" % pending.def.get("id", "pending")
		panel.position = pending.position
		panel.size = game.popup_size_for(pending.def)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var colors = _telegraph_colors(pending.def)
		panel.add_theme_stylebox_override("panel", _style_box(colors.bg, colors.border, 8, 2, 0))
		var pulse = 0.58 + 0.37 * abs(sin(float(Time.get_ticks_msec()) / 500.0))
		panel.modulate.a = pulse
		panel.pivot_offset = panel.size * 0.5
		panel.scale = Vector2.ONE * (0.992 + 0.008 * pulse)
		ui.popupTelegraphLayer.add_child(panel)
		var box = VBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_theme_constant_override("separation", 4)
		panel.add_child(box)
		var label = _label(game.popup_telegraph_label(pending.def), 12, Color("#f6fbff"), true)
		label.name = "popupTelegraphLabel"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_stylebox_override("normal", _style_box(Color(0, 0, 0, 0.38), Color(0, 0, 0, 0), 99, 0, 6))
		box.add_child(label)
		var timer = _label("%.1f초" % max(0.0, pending.timer), 18, Color("#ffe29a"), true)
		timer.name = "popupTelegraphTimer"
		timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(timer)

func _telegraph_colors(def: Dictionary) -> Dictionary:
	match def.get("copyTone", def.get("type", "product_ad")):
		"sponsored_reward":
			return {"bg": Color(0.28, 0.20, 0.05, 0.36), "border": Color(1.0, 0.85, 0.40, 0.72)}
		"legal_contract":
			return {"bg": Color(0.28, 0.05, 0.09, 0.36), "border": Color(1.0, 0.35, 0.39, 0.72)}
		"finance", "broker_app":
			return {"bg": Color(0.04, 0.24, 0.15, 0.32), "border": Color(0.36, 0.84, 0.59, 0.72)}
		"game_package":
			return {"bg": Color(0.31, 0.22, 0.05, 0.34), "border": Color(0.95, 0.78, 0.29, 0.70)}
		"cleanup_utility":
			return {"bg": Color(0.04, 0.21, 0.27, 0.34), "border": Color(0.30, 0.72, 0.86, 0.70)}
		"security_installer":
			return {"bg": Color(0.04, 0.18, 0.27, 0.34), "border": Color(0.31, 0.66, 0.88, 0.70)}
	return {"bg": Color(0.04, 0.07, 0.10, 0.34), "border": Color(1, 1, 1, 0.58)}

func _update_trash_zone(state: Dictionary) -> void:
	var active = state.draggingPopup != null
	ui.trashZone.visible = active
	ui.trashZone.modulate = Color(1.0, 0.74, 0.28, 1.0) if active else Color.WHITE

func _update_mobile_button_state(state: Dictionary) -> void:
	if not ui.has("mobileEmergencyButton"):
		return
	var blocked = state.gameOver or state.selectingItem or state.selectingPerk or state.selectingModule or state.openPopups.is_empty() or state.emergencyTimer > 0.0 or state.stats.emergencyCloseDisabled > 0
	ui.mobileEmergencyButton.disabled = blocked
	ui.mobileEmergencyButton.text = "대기 %.1f" % state.emergencyTimer if state.emergencyTimer > 0.0 else "긴급 닫기"

func _apply_mobile_layout(viewport_size: Vector2) -> void:
	if not ui.has("mobileControls"):
		return
	var mobile_visible = _mobile_visible_for_size(viewport_size)
	var portrait = viewport_size.x < viewport_size.y
	mobile_layout_visible = mobile_visible
	ui.mobileControls.visible = mobile_visible
	ui.orientationPrompt.visible = mobile_visible and portrait
	ui.mobileFullscreenButton.text = "창 모드" if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else "전체화면"
	var fullscreen_width = 84.0 if portrait else 78.0
	var fullscreen_height = 32.0 if portrait else 28.0
	ui.mobileFullscreenButton.anchor_left = 0.5
	ui.mobileFullscreenButton.anchor_right = 0.5
	ui.mobileFullscreenButton.anchor_top = 0.0
	ui.mobileFullscreenButton.anchor_bottom = 0.0
	ui.mobileFullscreenButton.offset_left = -fullscreen_width * 0.5
	ui.mobileFullscreenButton.offset_right = fullscreen_width * 0.5
	ui.mobileFullscreenButton.offset_top = 8.0
	ui.mobileFullscreenButton.offset_bottom = 8.0 + fullscreen_height

	var prompt_width = min(310.0, max(220.0, viewport_size.x - 40.0))
	var prompt_height = 92.0 if portrait else 76.0
	ui.orientationPrompt.offset_left = -prompt_width * 0.5
	ui.orientationPrompt.offset_right = prompt_width * 0.5
	ui.orientationPrompt.offset_top = -prompt_height * 0.5
	ui.orientationPrompt.offset_bottom = prompt_height * 0.5

	var emergency_width = 78.0 if portrait else 72.0
	var emergency_height = 42.0 if portrait else 38.0
	ui.mobileEmergencyButton.anchor_left = 1.0
	ui.mobileEmergencyButton.anchor_right = 1.0
	ui.mobileEmergencyButton.anchor_top = 1.0
	ui.mobileEmergencyButton.anchor_bottom = 1.0
	ui.mobileEmergencyButton.offset_left = -12.0 - emergency_width
	ui.mobileEmergencyButton.offset_right = -12.0
	ui.mobileEmergencyButton.offset_top = -18.0 - emergency_height
	ui.mobileEmergencyButton.offset_bottom = -18.0

	var joystick_size = _mobile_joystick_size(viewport_size)
	ui.mobileJoystick.offset_right = ui.mobileJoystick.offset_left + joystick_size
	ui.mobileJoystick.offset_bottom = ui.mobileJoystick.offset_top + joystick_size
	ui.mobileJoystick.custom_minimum_size = Vector2(joystick_size, joystick_size)
	ui.mobileJoystick.add_theme_stylebox_override("panel", _style_box(Color(0.05, 0.07, 0.11, 0.58), Color(1, 1, 1, 0.28), int(round(joystick_size * 0.5)), 2, 0))
	var knob_size = 34.0 if portrait else 32.0
	ui.mobileJoystickKnob.custom_minimum_size = Vector2(knob_size, knob_size)
	ui.mobileJoystickKnob.add_theme_stylebox_override("panel", _style_box(Color(0.28, 0.84, 0.59, 0.88), Color(1, 1, 1, 0.68), int(round(knob_size * 0.5)), 2, 0))
	var center = _current_mobile_joystick_center(viewport_size)
	_position_mobile_joystick(center, viewport_size)
	var active = mobile_visible and game != null and not game.state.is_empty() and game.state.mobileInput.get("active", false)
	ui.mobileJoystick.visible = mobile_visible
	ui.mobileJoystick.modulate.a = 1.0 if active else 0.0

func _mobile_visible_for_size(viewport_size: Vector2) -> bool:
	return viewport_size.x < 860.0 or viewport_size.y < 520.0

func _mobile_joystick_size(viewport_size: Vector2) -> float:
	return 92.0 if viewport_size.x < viewport_size.y else 86.0

func _mobile_joystick_radius() -> float:
	var diameter = max(max(ui.mobileJoystick.size.x, ui.mobileJoystick.size.y), ui.mobileJoystick.custom_minimum_size.x)
	return max(28.0, diameter * 0.36)

func _current_mobile_joystick_center(viewport_size: Vector2) -> Vector2:
	if game != null and not game.state.is_empty() and game.state.mobileInput.get("active", false):
		return _clamp_mobile_joystick_center(Vector2(game.state.mobileInput.get("baseX", 0.0), game.state.mobileInput.get("baseY", 0.0)), viewport_size)
	var size = _mobile_joystick_size(viewport_size)
	return Vector2(18.0 + size * 0.5, viewport_size.y - 18.0 - size * 0.5)

func _clamp_mobile_joystick_center(screen_position: Vector2, viewport_size: Vector2) -> Vector2:
	var half = max(36.0, _mobile_joystick_size(viewport_size) * 0.5)
	return Vector2(
		clamp(screen_position.x, half + 4.0, max(half + 4.0, viewport_size.x - half - 4.0)),
		clamp(screen_position.y, half + 4.0, max(half + 4.0, viewport_size.y - half - 4.0))
	)

func _position_mobile_joystick(center: Vector2, viewport_size: Vector2) -> void:
	var size = _mobile_joystick_size(viewport_size)
	var top_left = center - Vector2(size, size) * 0.5
	ui.mobileJoystick.anchor_left = 0.0
	ui.mobileJoystick.anchor_right = 0.0
	ui.mobileJoystick.anchor_top = 0.0
	ui.mobileJoystick.anchor_bottom = 0.0
	ui.mobileJoystick.offset_left = top_left.x
	ui.mobileJoystick.offset_top = top_left.y
	ui.mobileJoystick.offset_right = top_left.x + size
	ui.mobileJoystick.offset_bottom = top_left.y + size

func _start_floating_joystick(pointer_id: int, screen_position: Vector2, viewport_size := Vector2.ZERO) -> void:
	if game == null or game.state.is_empty():
		return
	var size = viewport_size if viewport_size != Vector2.ZERO else get_viewport().get_visible_rect().size
	var center = _clamp_mobile_joystick_center(screen_position, size)
	game.input_controller.start_mobile_joystick(game.state, center)
	game.state.mobileInput.pointerId = pointer_id
	_position_mobile_joystick(center, size)
	game.input_controller.update_mobile_joystick(game.state, screen_position, _mobile_joystick_radius())
	_apply_mobile_layout(size)
	_update_mobile_knob(game.state)
	get_viewport().set_input_as_handled()

func _update_floating_joystick(screen_position: Vector2) -> void:
	if game == null or game.state.is_empty() or not game.state.mobileInput.get("active", false):
		return
	game.input_controller.update_mobile_joystick(game.state, screen_position, _mobile_joystick_radius())
	_update_mobile_knob(game.state)
	get_viewport().set_input_as_handled()

func _finish_floating_joystick() -> void:
	if game == null or game.state.is_empty():
		return
	game.input_controller.finish_mobile_joystick(game.state)
	game.state.mobileInput.pointerId = -1
	_apply_mobile_layout(get_viewport().get_visible_rect().size)
	_update_mobile_knob(game.state)
	get_viewport().set_input_as_handled()

func _mobile_joystick_input(event: InputEvent) -> void:
	var radius = _mobile_joystick_radius()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var global_pos = ui.mobileJoystick.get_global_mouse_position()
		if event.pressed:
			game.input_controller.start_mobile_joystick(game.state, global_pos)
			game.input_controller.update_mobile_joystick(game.state, global_pos, radius)
		else:
			game.input_controller.finish_mobile_joystick(game.state)
	elif event is InputEventMouseMotion and game.state.mobileInput.get("active", false):
		game.input_controller.update_mobile_joystick(game.state, ui.mobileJoystick.get_global_mouse_position(), radius)

func _update_mobile_knob(state: Dictionary) -> void:
	if not ui.has("mobileJoystickKnob"):
		return
	var base = ui.mobileJoystick.size * 0.5 - ui.mobileJoystickKnob.custom_minimum_size * 0.5
	var offset = Vector2(state.mobileInput.get("x", 0.0), state.mobileInput.get("y", 0.0)) * 32.0
	ui.mobileJoystickKnob.position = base + offset

func _style_box(bg: Color, border: Color, radius := 6, border_width := 1, margin := 0) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.set_content_margin_all(margin)
	return style

func _style_button(button: Button, variant := "default") -> void:
	var normal_bg = Color("#273244")
	var hover_bg = Color("#34435c")
	var pressed_bg = Color("#1f2a3b")
	var border = Color(1, 1, 1, 0.18)
	var font = Color("#edf2f7")
	var font_size = 12
	var margin = 8
	match variant:
		"gold":
			normal_bg = Color("#3c2f13")
			hover_bg = Color("#51401a")
			pressed_bg = Color("#2d230e")
			border = Color(0.95, 0.78, 0.29, 0.55)
			font = Color("#ffe7a1")
		"blue":
			normal_bg = Color("#233247")
			hover_bg = Color("#2f4260")
			pressed_bg = Color("#1c293d")
			border = Color(0.45, 0.75, 1.0, 0.45)
			font = Color("#dceeff")
		"danger":
			normal_bg = Color("#572532")
			hover_bg = Color("#723041")
			pressed_bg = Color("#421b26")
			border = Color(1.0, 0.35, 0.39, 0.52)
			font = Color("#ffe4e8")
		"compact", "toggle":
			font_size = 11
			margin = 6
		"choice":
			normal_bg = Color("#1f2a3b")
			hover_bg = Color("#263752")
			pressed_bg = Color("#182234")
			border = Color(0.95, 0.78, 0.29, 0.5)
			font = Color("#edf2f7")
			font_size = 12
			margin = 10
		"choice_common":
			normal_bg = Color("#1f2a3b")
			hover_bg = Color("#263752")
			pressed_bg = Color("#182234")
			border = Color(0.86, 0.91, 0.97, 0.34)
			font = Color("#dce8f8")
			font_size = 12
			margin = 10
		"choice_rare":
			normal_bg = Color("#1c2d42")
			hover_bg = Color("#233b59")
			pressed_bg = Color("#172537")
			border = Color(0.45, 0.75, 1.0, 0.66)
			font = Color("#e4f3ff")
			font_size = 12
			margin = 10
		"choice_epic":
			normal_bg = Color("#2d2240")
			hover_bg = Color("#3b2d58")
			pressed_bg = Color("#241b34")
			border = Color(0.82, 0.64, 1.0, 0.7)
			font = Color("#f3e8ff")
			font_size = 12
			margin = 10
		"choice_cursed":
			normal_bg = Color("#3c1f2b")
			hover_bg = Color("#532839")
			pressed_bg = Color("#2d1721")
			border = Color(1.0, 0.56, 0.63, 0.78)
			font = Color("#ffe5ea")
			font_size = 12
			margin = 10
		"selected_choice":
			normal_bg = Color("#263d32")
			hover_bg = Color("#30513f")
			pressed_bg = Color("#1d2f27")
			border = Color(0.28, 0.84, 0.59, 0.72)
			font = Color("#dfffee")
			font_size = 12
			margin = 10
	button.add_theme_stylebox_override("normal", _style_box(normal_bg, border, 6, 1, margin))
	button.add_theme_stylebox_override("hover", _style_box(hover_bg, border.lightened(0.16), 6, 1, margin))
	button.add_theme_stylebox_override("pressed", _style_box(pressed_bg, border, 6, 1, margin))
	button.add_theme_stylebox_override("disabled", _style_box(Color(normal_bg, 0.42), Color(border, 0.4), 6, 1, margin))
	button.add_theme_color_override("font_color", font)
	button.add_theme_color_override("font_hover_color", font)
	button.add_theme_color_override("font_pressed_color", font)
	button.add_theme_color_override("font_disabled_color", Color(font, 0.5))
	button.add_theme_font_size_override("font_size", font_size)
