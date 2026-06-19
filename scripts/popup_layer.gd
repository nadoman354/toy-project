extends CanvasLayer
class_name PopupLayer

var game: Node = null
var root: Control = null
var windows = {}

func setup(game_root: Node) -> void:
	game = game_root
	root = Control.new()
	root.name = "PopupRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

func sync_from_state(state: Dictionary) -> void:
	if root == null:
		return
	var active = {}
	for popup in state.open_popups:
		var rid = popup.get("runtime_id", 0)
		active[rid] = true
		if not windows.has(rid):
			_create_window(popup)
		_update_window(popup)

	for rid in windows.keys():
		if not active.has(rid):
			windows[rid].panel.queue_free()
			windows.erase(rid)

func _create_window(popup: Dictionary) -> void:
	var panel = PanelContainer.new()
	panel.name = "Popup_%s" % popup.get("runtime_id", 0)
	panel.custom_minimum_size = popup.get("size", Vector2(300, 180))
	var style = StyleBoxFlat.new()
	style.bg_color = _popup_color(popup)
	style.border_color = Color(1, 1, 1, 0.22)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)

	var outer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	panel.add_child(outer)
	var title_bar = HBoxContainer.new()
	title_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	outer.add_child(title_bar)
	var title = Label.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color("#edf2f7"))
	title_bar.add_child(title)
	var close_button = Button.new()
	close_button.text = "X"
	close_button.custom_minimum_size = Vector2(30, 26)
	close_button.pressed.connect(func(): game.request_close_popup(popup.get("runtime_id", 0), {"reason": "button"}))
	title_bar.add_child(close_button)

	var body = RichTextLabel.new()
	body.bbcode_enabled = false
	body.fit_content = false
	body.custom_minimum_size = Vector2(0, 72)
	body.add_theme_font_size_override("normal_font_size", 11)
	outer.add_child(body)
	var controls = VBoxContainer.new()
	controls.add_theme_constant_override("separation", 5)
	outer.add_child(controls)

	title_bar.gui_input.connect(func(event): _handle_drag_event(event, popup.get("runtime_id", 0), panel))
	windows[popup.get("runtime_id", 0)] = {
		"panel": panel,
		"title": title,
		"body": body,
		"controls": controls,
		"dragging": false,
		"drag_offset": Vector2.ZERO,
	}

func _update_window(popup: Dictionary) -> void:
	var record = windows.get(popup.get("runtime_id", 0))
	if record == null:
		return
	var panel: PanelContainer = record.panel
	panel.position = popup.get("position", Vector2.ZERO)
	panel.size = popup.get("size", Vector2(300, 180))
	record.title.text = popup.get("def", {}).get("title", "팝업")
	record.body.text = _body_text(popup)
	_rebuild_controls(popup, record.controls)

func _body_text(popup: Dictionary) -> String:
	var def = popup.get("def", {})
	var lines = [def.get("body", "")]
	var type = def.get("type", "")
	if def.get("duration", 0.0) > 0.0:
		lines.append("남은 시간 %.1fs" % max(0.0, def.get("duration", 0.0) - popup.get("elapsed", 0.0)))
	if type == "sponsored_ad":
		lines.append("시청 진행 %.0f%%" % (100.0 * popup.get("progress", 0.0)))
	elif type == "timed_reward":
		lines.append("보상 진행 %.0f%%" % (100.0 * popup.get("progress", 0.0)))
	elif type == "clean_challenge":
		lines.append("정리 진행 %.1f / %.1fs" % [popup.get("clean_progress", 0.0), def.get("duration", 10.0)])
	elif type == "recurring_investment" and popup.has("investment"):
		var investment = popup.investment
		lines.append("적립 %dG / %.1fs" % [investment.get("accumulated", 0), max(0.0, investment.get("duration", 30.0) - investment.get("elapsed", 0.0))])
	elif type == "stock_broker_app":
		var stock = game.state.stock_market.stock
		lines.append("POP %.1fG / 보유 %d주 / 평균 %.1fG" % [stock.price, stock.shares, stock.avg_cost])
	elif type == "infection":
		lines.append("감염 진행 %.0f%%" % (100.0 * popup.get("progress", 0.0)))
	return "\n".join(lines)

func _rebuild_controls(popup: Dictionary, controls: VBoxContainer) -> void:
	for child in controls.get_children():
		child.queue_free()

	var def = popup.get("def", {})
	var type = def.get("type", "")
	if type == "first_purchase_package":
		for package in GameData.first_purchase_packages():
			_add_button(controls, "%s\n%s" % [package.name, package.description], func(p = package): game.apply_first_purchase_package(popup.get("runtime_id", 0), p))
		_add_button(controls, "나중에", func(): game.request_close_popup(popup.get("runtime_id", 0), {"reason": "reject"}))
	elif type == "boss_package_ad":
		_add_button(controls, "패키지 구매 %dG" % popup.get("package_cost", 60), func(): game.purchase_boss_package(popup.get("runtime_id", 0)))
		_add_button(controls, "닫기", func(): game.request_close_popup(popup.get("runtime_id", 0), {"reason": "reject"}))
	elif type == "security_installer":
		_add_button(controls, "설치", func(): game.install_resident_program(def.get("program", ""), popup.get("runtime_id", 0)))
		_add_button(controls, "나중에", func(): game.request_close_popup(popup.get("runtime_id", 0), {"reason": "security_later"}))
	elif type == "security_update_notice":
		_add_button(controls, "업데이트 적용 20G", func(): game.apply_security_update(popup.get("runtime_id", 0)))
		_add_button(controls, "닫기", func(): game.request_close_popup(popup.get("runtime_id", 0), {"reason": "security_ignore"}))
	elif type == "terms":
		_add_button(controls, "안전 보상", func(): game.accept_terms_popup(popup.get("runtime_id", 0), false))
		_add_button(controls, "위험 보상", func(): game.accept_terms_popup(popup.get("runtime_id", 0), true))
		_add_button(controls, "닫기", func(): game.request_close_popup(popup.get("runtime_id", 0), {"reason": "terms_reject"}))
	elif type == "interest_offer":
		_add_button(controls, "25% 예치", func(): game.accept_interest_offer(popup.get("runtime_id", 0), 0.25))
		_add_button(controls, "50% 예치", func(): game.accept_interest_offer(popup.get("runtime_id", 0), 0.50))
		_add_button(controls, "취소", func(): game.request_close_popup(popup.get("runtime_id", 0), {"reason": "interest_reject"}))
	elif type == "recurring_investment":
		if popup.has("investment") and popup.investment.get("accepted", false):
			_add_button(controls, "중도 해지", func(): game.cancel_recurring_investment(popup.get("runtime_id", 0)))
		else:
			_add_button(controls, "자동 적립 수락", func(): game.accept_recurring_investment(popup.get("runtime_id", 0)))
			_add_button(controls, "닫기", func(): game.request_close_popup(popup.get("runtime_id", 0), {"reason": "recurring_reject"}))
	elif type == "loan_offer":
		_add_button(controls, "소액 현금화: 신용 -6 / +50G", func(): game.accept_credit_cashout(popup.get("runtime_id", 0), 6, 50))
		_add_button(controls, "중간 현금화: 신용 -12 / +110G", func(): game.accept_credit_cashout(popup.get("runtime_id", 0), 12, 110))
		_add_button(controls, "대형 현금화: 신용 -20 / +210G", func(): game.accept_credit_cashout(popup.get("runtime_id", 0), 20, 210))
		_add_button(controls, "닫기", func(): game.request_close_popup(popup.get("runtime_id", 0), {"reason": "loan_reject"}))
	elif type == "stock_broker_app":
		_add_button(controls, "1주 매수", func(): game.buy_stock(1))
		_add_button(controls, "최대 매수", func(): game.buy_max_stock())
		_add_button(controls, "1주 매도", func(): game.sell_stock_shares(1))
		_add_button(controls, "전량 매도", func(): game.sell_all_stock())
	elif type == "stock_market":
		_add_button(controls, "증권 앱 열기", func(): game.ensure_stock_broker_app())
		_add_button(controls, "닫기", func(): game.request_close_popup(popup.get("runtime_id", 0), {"reason": "market_close"}))
	elif type == "popup_store":
		for product in GameData.popup_store_catalog():
			_add_button(controls, "%s %dG" % [product.label, game.popup_store_price(product)], func(p = product): game.purchase_popup_store_item(popup.get("runtime_id", 0), p))
		_add_button(controls, "닫기", func(): game.request_close_popup(popup.get("runtime_id", 0), {"reason": "store_close"}))
	elif type == "sponsored_ad" or type == "timed_reward" or type == "clean_challenge":
		_add_button(controls, "닫기", func(): game.request_close_popup(popup.get("runtime_id", 0), {"reason": "button"}))
	elif type == "volatile_popup":
		_add_button(controls, "지금 정리", func(): game.request_close_popup(popup.get("runtime_id", 0), {"reason": "volatile"}))
	elif type == "infection":
		_add_button(controls, "확장 차단", func(): game.request_close_popup(popup.get("runtime_id", 0), {"reason": "infection_blocked"}))
	else:
		_add_button(controls, "닫기", func(): game.request_close_popup(popup.get("runtime_id", 0), {"reason": "button"}))

func _add_button(parent: Node, text: String, callback: Callable) -> void:
	var button = Button.new()
	button.text = text
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size = Vector2(0, 30)
	button.pressed.connect(callback)
	parent.add_child(button)

func _handle_drag_event(event: InputEvent, runtime_id: int, panel: PanelContainer) -> void:
	var record = windows.get(runtime_id)
	if record == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		record.dragging = event.pressed
		record.drag_offset = panel.get_local_mouse_position()
		if event.pressed:
			panel.move_to_front()
			game.bring_popup_to_front(runtime_id)
	elif event is InputEventMouseMotion and record.dragging:
		var next_position = root.get_local_mouse_position() - record.drag_offset
		game.move_popup(runtime_id, next_position)

func _popup_color(popup: Dictionary) -> Color:
	var type = popup.get("def", {}).get("type", "")
	if type == "terms":
		return Color(0.18, 0.12, 0.08, 0.95)
	if type == "sponsored_ad":
		return Color(0.09, 0.13, 0.2, 0.95)
	if type == "security_installer":
		return Color(0.07, 0.15, 0.12, 0.95)
	if type == "volatile_popup" or type == "infection":
		return Color(0.19, 0.08, 0.1, 0.95)
	if type == "stock_broker_app" or type == "stock_market":
		return Color(0.07, 0.11, 0.18, 0.95)
	return Color(0.09, 0.11, 0.16, 0.95)

