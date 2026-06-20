extends CanvasLayer
class_name PrototypePopupLayer

const PopupWindowScene = preload("res://scenes/ui/popup/PopupWindow.tscn")
const HtmlLayoutMetrics = preload("res://scripts/ui/html_layout_metrics.gd")

var game = null
var root: Control
var telegraph_root: Control
var overlay_root: Control
var windows = {}

func setup(game_root) -> void:
	game = game_root
	layer = 20
	telegraph_root = _ensure_root("PopupTelegraphRoot", 0)
	root = _ensure_root("PopupRoot", 100)
	overlay_root = _ensure_root("PopupOverlayRoot", 200)

func telegraph_parent() -> Control:
	return telegraph_root

func overlay_parent() -> Control:
	return overlay_root

func _ensure_root(node_name: String, z := 0) -> Control:
	var existing = get_node_or_null(node_name)
	var control: Control = existing if existing is Control else null
	if control == null:
		control = Control.new()
		control.name = node_name
		control.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(control)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.z_index = z
	return control

func sync(state: Dictionary) -> void:
	var active = {}
	for popup in state.openPopups:
		var id = int(popup.id)
		active[id] = true
		if not windows.has(id):
			_create_popup_window(popup)
		_update_popup_window(popup)
	for id in windows.keys():
		if not active.has(id):
			windows[id].panel.queue_free()
			windows.erase(id)

func _create_popup_window(popup: Dictionary) -> void:
	var panel = PopupWindowScene.instantiate() as PanelContainer
	panel.name = "popupWindow_%d" % popup.id
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.z_index = 100 + int(popup.get("z", 0))
	panel.clip_contents = true
	panel.custom_minimum_size = popup.size
	var style = StyleBoxFlat.new()
	style.bg_color = _popup_bg_color(popup.def.type)
	style.border_color = _popup_border_color(popup.def.type)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)
	panel.gui_input.connect(func(event, id = popup.id, p = panel): _panel_event(event, id, p))
	var box = VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.clip_contents = true
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 0)
	panel.add_child(box)
	var title_frame = PanelContainer.new()
	title_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	title_frame.clip_contents = true
	title_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title_style = StyleBoxFlat.new()
	title_style.bg_color = _popup_title_color(popup.def.type)
	title_style.corner_radius_top_left = 6
	title_style.corner_radius_top_right = 6
	title_style.set_content_margin_all(2)
	title_frame.add_theme_stylebox_override("panel", title_style)
	box.add_child(title_frame)
	var title_bar = HBoxContainer.new()
	title_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	title_bar.clip_contents = true
	title_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_bar.add_theme_constant_override("separation", 4)
	title_frame.add_child(title_bar)
	var title = Label.new()
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color.WHITE)
	title_bar.add_child(title)
	if popup.def.type == "stock_broker_app":
		var min_button = Button.new()
		min_button.text = "_"
		min_button.custom_minimum_size = Vector2(22, 20)
		_style_title_button(min_button)
		min_button.pressed.connect(func(id = popup.id): game.toggle_popup_minimized(id))
		title_bar.add_child(min_button)
	if not ["first_purchase_package", "stock_broker_app"].has(popup.def.type):
		var close = Button.new()
		close.text = "X"
		close.custom_minimum_size = Vector2(22, 20)
		_style_title_button(close)
		close.pressed.connect(func(id = popup.id): game.request_close_popup(id, {"reason": "button"}))
		title_bar.add_child(close)
	var content_frame = PanelContainer.new()
	content_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_frame.clip_contents = true
	content_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var content_style = StyleBoxFlat.new()
	content_style.bg_color = Color(0, 0, 0, 0)
	content_style.set_content_margin_all(3)
	content_frame.add_theme_stylebox_override("panel", content_style)
	box.add_child(content_frame)
	var content_box = VBoxContainer.new()
	content_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_box.clip_contents = true
	content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_box.add_theme_constant_override("separation", 4)
	content_frame.add_child(content_box)
	var body = RichTextLabel.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.clip_contents = true
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.bbcode_enabled = true
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(0, 60)
	body.fit_content = false
	body.scroll_active = true
	body.add_theme_font_size_override("normal_font_size", 13)
	body.add_theme_color_override("default_color", _popup_text_color(popup.def.type))
	content_box.add_child(body)
	var detail = RichTextLabel.new()
	detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail.clip_contents = true
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.bbcode_enabled = true
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size = Vector2(0, 44)
	detail.fit_content = false
	detail.scroll_active = false
	detail.visible = false
	detail.add_theme_font_size_override("normal_font_size", 12)
	detail.add_theme_color_override("default_color", _popup_text_color(popup.def.type))
	detail.add_theme_stylebox_override("normal", _style_box(Color(1, 1, 1, 0.48), Color(0, 0, 0, 0.10), 6, 1, 2))
	content_box.add_child(detail)
	var status_badges = HFlowContainer.new()
	status_badges.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_badges.clip_contents = true
	status_badges.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_badges.add_theme_constant_override("h_separation", 4)
	status_badges.add_theme_constant_override("v_separation", 3)
	status_badges.visible = false
	content_box.add_child(status_badges)
	var progress = ProgressBar.new()
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress.clip_contents = true
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(0, 8)
	var progress_bg = StyleBoxFlat.new()
	progress_bg.bg_color = Color(0, 0, 0, 0.12)
	progress.add_theme_stylebox_override("background", progress_bg)
	var progress_fill = StyleBoxFlat.new()
	progress_fill.bg_color = _popup_title_color(popup.def.type)
	progress.add_theme_stylebox_override("fill", progress_fill)
	content_box.add_child(progress)
	var chart = Control.new()
	chart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chart.clip_contents = true
	chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chart.custom_minimum_size = Vector2(0, 54)
	chart.visible = false
	content_box.add_child(chart)
	chart.draw.connect(func(): _draw_stock_chart(chart, popup.id))
	var controls = HFlowContainer.new()
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	controls.clip_contents = true
	controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_theme_constant_override("h_separation", 4)
	controls.add_theme_constant_override("v_separation", 4)
	content_box.add_child(controls)
	title_bar.gui_input.connect(func(event, id = popup.id, p = panel): _drag_event(event, id, p))
	windows[popup.id] = {
		"panel": panel,
		"title_bar": title_bar,
		"content_frame": content_frame,
		"content_box": content_box,
		"title_frame": title_frame,
		"title": title,
		"body": body,
		"detail": detail,
		"statusBadges": status_badges,
		"progress": progress,
		"chart": chart,
		"controls": controls,
		"dragging": false,
		"dragOffset": Vector2.ZERO,
		"dragStartMouse": Vector2.ZERO,
		"dragOriginPosition": popup.position,
		"controlsSignature": "",
	}

func _update_popup_window(popup: Dictionary) -> void:
	var record = windows.get(int(popup.id), null)
	if record == null:
		return
	record.panel.position = popup.position
	record.panel.size = popup.size
	record.panel.z_index = 100 + int(popup.get("z", 0))
	record.title.text = _popup_title(popup)
	record.body.text = _popup_body(popup)
	var detail_text = _popup_detail(popup)
	record.detail.text = detail_text
	record.detail.visible = detail_text != ""
	_apply_popup_content_layout(popup, record)
	_update_status_badges(popup, record.statusBadges)
	record.progress.visible = popup.def.get("duration", 0.0) > 0.0 or popup.def.type in ["clean_challenge", "interest_offer", "recurring_investment", "stock_broker_app", "stock_market"]
	record.progress.value = clamp(float(popup.get("progress", 0.0)) * 100.0, 0.0, 100.0)
	_set_progress_color(record.progress, _progress_color(popup))
	record.chart.visible = popup.def.type in ["stock_broker_app", "stock_market"]
	if record.chart.visible:
		record.chart.queue_redraw()
	record.panel.modulate = Color(1, 1, 1, 0.62) if popup.get("minimized", false) else Color.WHITE
	if popup.get("infectedByPopup", false):
		var pulse = 0.72 + 0.28 * abs(sin(float(Time.get_ticks_msec()) / 145.0))
		record.panel.modulate = Color(0.62, 1.0, 0.68, pulse)
	if popup.get("securityQuarantineTimer", 0.0) > 0.0:
		record.panel.modulate = Color(0.55, 0.85, 1.0, 0.78)
	record.body.visible = not popup.get("minimized", false)
	record.detail.visible = record.detail.visible and not popup.get("minimized", false)
	record.statusBadges.visible = record.statusBadges.get_child_count() > 0 and not popup.get("minimized", false)
	record.progress.visible = record.progress.visible and not popup.get("minimized", false)
	record.chart.visible = record.chart.visible and not popup.get("minimized", false)
	record.controls.visible = not popup.get("minimized", false)
	var controls_signature = _controls_signature(popup)
	if record.get("controlsSignature", "") != controls_signature:
		_rebuild_controls(popup, record.controls)
		record.controlsSignature = controls_signature
		_apply_popup_content_layout(popup, record)

func _apply_popup_content_layout(popup: Dictionary, record: Dictionary) -> void:
	var viewport_size = HtmlLayoutMetrics.viewport_size(get_viewport())
	var popup_size = popup.size
	var minimized_stock_app = popup.get("minimized", false) and popup.def.type == "stock_broker_app"
	if minimized_stock_app:
		popup_size = Vector2(min(300.0, popup.size.x), 34.0 if HtmlLayoutMetrics.is_compact_viewport(viewport_size) else 38.0)
	var layout = HtmlLayoutMetrics.popup_content_layout(
		viewport_size,
		str(popup.def.get("type", "")),
		popup_size,
		"" if minimized_stock_app else str(record.body.text),
		"" if minimized_stock_app else str(record.detail.text),
		_popup_has_layout_badge(popup)
	)
	if not minimized_stock_app:
		var resolved_size = layout.get("panel_size", popup_size)
		if resolved_size != popup_size:
			layout = HtmlLayoutMetrics.popup_content_layout(
				viewport_size,
				str(popup.def.get("type", "")),
				resolved_size,
				str(record.body.text),
				str(record.detail.text),
				_popup_has_layout_badge(popup)
			)
			resolved_size = layout.get("panel_size", resolved_size)
		popup_size = resolved_size
		popup.size = popup_size
		_clamp_popup_to_viewport(popup, viewport_size)
	record.panel.position = popup.position
	record.panel.size = popup_size
	record.panel.custom_minimum_size = popup_size
	record.title.add_theme_font_size_override("font_size", int(layout.title_font))
	if record.has("content_frame") and record.content_frame is PanelContainer:
		var content_style = StyleBoxFlat.new()
		content_style.bg_color = Color(0, 0, 0, 0)
		content_style.set_content_margin_all(int(layout.content_margin))
		record.content_frame.add_theme_stylebox_override("panel", content_style)
	if record.has("title_frame") and record.title_frame is PanelContainer:
		var title_style = StyleBoxFlat.new()
		title_style.bg_color = _popup_title_color(popup.def.type)
		title_style.corner_radius_top_left = 6
		title_style.corner_radius_top_right = 6
		title_style.set_content_margin_all(max(1, int(layout.content_margin * 0.5)))
		record.title_frame.add_theme_stylebox_override("panel", title_style)
		record.title_frame.custom_minimum_size = Vector2(0, float(layout.title_height))
	if record.has("content_box") and record.content_box is VBoxContainer:
		record.content_box.add_theme_constant_override("separation", int(layout.gap))
	var body_height = float(layout.body_height)
	record.body.custom_minimum_size = Vector2(0, body_height)
	_apply_popup_text_contract(record.body, popup, layout, "body")
	record.detail.custom_minimum_size = Vector2(0, float(layout.detail_height))
	_apply_popup_text_contract(record.detail, popup, layout, "detail")
	record.chart.custom_minimum_size = Vector2(0, float(layout.chart_height))
	record.controls.add_theme_constant_override("h_separation", int(layout.gap))
	record.controls.add_theme_constant_override("v_separation", int(layout.gap))
	_apply_popup_button_layout(record.controls, int(layout.button_font), float(layout.button_height), float(layout.button_min_width), float(layout.button_max_width), float(layout.control_label_width))

func _popup_has_layout_badge(popup: Dictionary) -> bool:
	return popup.get("inputGrace", 0.0) > 0.0 or popup.get("securityQuarantineTimer", 0.0) > 0.0 or popup.get("infectedByPopup", false) or _popup_has_lock_badge(popup)

func _clamp_popup_to_viewport(popup: Dictionary, viewport_size: Vector2) -> void:
	var margin = 6.0
	popup.position.x = clamp(float(popup.position.x), margin, max(margin, viewport_size.x - float(popup.size.x) - margin))
	popup.position.y = clamp(float(popup.position.y), margin, max(margin, viewport_size.y - float(popup.size.y) - margin))

func _apply_popup_text_contract(label: RichTextLabel, popup: Dictionary, layout: Dictionary, role: String) -> void:
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.clip_contents = true
	label.bbcode_enabled = true
	label.fit_content = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.scroll_active = bool(layout.body_scroll) if role == "body" else bool(layout.detail_scroll)
	var font_size = int(layout.body_font) if role == "body" else int(layout.detail_font)
	label.add_theme_font_size_override("normal_font_size", font_size)
	label.add_theme_color_override("default_color", _popup_text_color(popup.def.type))

func _apply_popup_button_layout(node: Node, font_size: int, min_height: float, min_width: float, max_width: float, control_label_width: float) -> void:
	for child in node.get_children():
		if child is Button:
			child.add_theme_font_size_override("font_size", font_size)
			child.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			child.clip_contents = true
			child.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			var width = clamp(float(child.custom_minimum_size.x), min_width, max_width)
			child.custom_minimum_size = Vector2(width, max(float(child.custom_minimum_size.y), min_height))
		elif child is Label:
			child.add_theme_font_size_override("font_size", font_size)
			child.clip_text = true
			child.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			child.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			child.custom_minimum_size = Vector2(control_label_width, min_height)
		_apply_popup_button_layout(child, font_size, min_height, min_width, max_width, control_label_width)

func _popup_title(popup: Dictionary) -> String:
	var title = popup.def.get("title", "팝업")
	if popup.get("locked", false):
		title += " [잠김]"
	if popup.get("securityQuarantineTimer", 0.0) > 0.0:
		title += " [격리]"
	if popup.get("inputGrace", 0.0) > 0.0:
		title += " [입력 대기]"
	return title

func _popup_body(popup: Dictionary) -> String:
	var def = popup.def
	var lines = [def.get("body", "")]
	if popup.get("securityQuarantineTimer", 0.0) > 0.0:
		lines.append("보안 격리 중 %.1fs" % popup.securityQuarantineTimer)
	match def.type:
		"first_purchase_package":
			lines.append("10G를 지불하면 스타터 계약 선택 화면으로 넘어갑니다.")
			lines.append("현재 상태: %s" % game.first_purchase_status_text())
		"sponsored_ad":
			lines.append("광고 유지 %.0f%% / 완료 시 보상 지급" % (popup.get("progress", 0.0) * 100.0))
			lines.append("열려 있는 동안 전투 버프가 적용됩니다.")
		"timed_reward":
			lines.append("보상까지 %.1f초" % max(0.0, game.timed_reward_duration(def) - float(popup.elapsed)))
		"terms":
			lines.append("체크 상태로 수락하면 높은 보상과 위험 패널티가 함께 적용됩니다.")
		"interest_offer":
			lines.append(game.interest_popup_text(popup))
		"recurring_investment":
			lines.append(game.recurring_investment_text(popup))
		"loan_offer":
			lines.append("현재 신용도: %d" % game.state.creditScore)
		"stock_broker_app":
			lines.append(_stock_broker_header_text())
		"stock_market":
			lines.append(_stock_market_header_text(popup))
		"popup_store":
			lines.append("상점 할인: %d%%" % round(game.state.stats.popupStoreDiscountMultiplier * 100.0))
			lines.append("만료까지 %.1f초" % max(0.0, float(def.get("duration", 18.0)) - float(popup.elapsed)))
		"clean_challenge":
			lines.append("진행 %.1f / %.1f초" % [popup.get("cleanProgress", 0.0), def.get("duration", 10.0)])
		"volatile_popup":
			lines.append("지금 닫으면 주변 프로세스가 함께 정리됩니다.")
		"infection":
			lines.append(game.infection_popup_text(popup))
		"security_installer":
			lines.append(game.security_installer_text(def.get("installProgram", "")))
		"security_update_notice":
			lines.append("보안 프로그램 업데이트 또는 유지 비용을 처리하세요.")
	return "\n".join(lines)

func _popup_detail(popup: Dictionary) -> String:
	match popup.def.type:
		"stock_broker_app":
			return _stock_broker_portfolio_text()
		"stock_market":
			return _stock_market_detail_text(popup)
		"popup_store":
			return _popup_store_detail_text(popup)
		"boss_package_ad":
			return _boss_package_detail_text(popup)
		"security_installer":
			return _security_installer_detail_text(popup)
		"sponsored_ad":
			return _sponsored_ad_detail_text(popup)
		"timed_reward":
			return _timed_reward_detail_text(popup)
		"terms":
			return _terms_detail_text(popup)
		"clean_challenge":
			return _clean_challenge_detail_text(popup)
		"volatile_popup":
			return _volatile_detail_text(popup)
		"infection":
			return _infection_detail_text(popup)
		"infected_popup":
			return _infected_detail_text(popup)
		"moving_close":
			return _moving_close_detail_text(popup)
	return ""

func _stock_broker_header_text() -> String:
	var stock = game.state.stockMarket.stock
	var arrow = "▲" if float(stock.lastChange) >= 0.0 else "▼"
	return "[b]%s (%s)[/b]\n현재가: %dG %s %+.1f%%\n시장 심리: [b]%s[/b]" % [stock.name, stock.symbol, int(ceil(float(stock.price))), arrow, float(stock.lastChange) * 100.0, game.state.stockMarket.lastBiasLabel]

func _stock_broker_portfolio_text() -> String:
	var stock = game.state.stockMarket.stock
	var value = int(floor(stock.price * stock.shares))
	var principal = int(round(stock.avgCost * stock.shares))
	var profit = value - principal
	var rate = 0.0 if principal <= 0 else float(profit) / float(principal)
	return "보유: %d주 / 평단: %dG\n평가액: %dG\n평가손익: %+dG (%+.1f%%)" % [stock.shares, int(round(float(stock.avgCost))), value, profit, rate * 100.0]

func _stock_market_header_text(popup: Dictionary) -> String:
	if not popup.has("stock"):
		return "주식 데이터를 초기화하는 중입니다."
	var stock = popup.stock
	if not stock.get("invested", false):
		return "단기 투자 제안\n투자 후 매도 전까지 창이 잠깁니다."
	return "[b]단기 포지션 보유 중[/b]\n흐름: %s / 경과 %.1fs" % [stock.lastTrend, float(stock.elapsed)]

func _stock_market_detail_text(popup: Dictionary) -> String:
	if not popup.has("stock"):
		return ""
	var stock = popup.stock
	if not stock.get("invested", false):
		var options = []
		for value in popup.def.get("principalOptions", [50, 100, 150]):
			options.append("%dG" % int(value))
		return "변동성: %d%% / 기대 흐름: %+d%%\n원금 옵션: %s" % [round(float(stock.volatility) * 100.0), round(float(stock.drift) * 100.0), ", ".join(options)]
	var payout = int(floor(float(stock.currentValue)))
	var principal = int(stock.principal)
	var profit = payout - principal
	var rate = 0.0 if principal <= 0 else float(profit) / float(principal)
	return "원금: %dG\n현재 평가액: %dG\n평가손익: %+dG (%+.1f%%)" % [principal, payout, profit, rate * 100.0]

func _popup_store_detail_text(popup: Dictionary) -> String:
	var lines = []
	if popup.def.has("efficiencyLabel"):
		lines.append("[b]%s[/b]" % popup.def.efficiencyLabel)
	lines.append("구매하면 미확인 아이템 1개를 즉시 얻습니다.")
	lines.append("팝업 스토어는 난이도를 올리지 않습니다.")
	var product_lines = []
	for product in popup.get("storeProducts", game.data.POPUP_STORE_CATALOG):
		product_lines.append("[%s] %s %dG" % [product.get("rarity", "Common"), product.get("label", "상품"), game.popup_store_price(product)])
	if not product_lines.is_empty():
		lines.append("상품: %s" % " / ".join(product_lines))
	return "\n".join(lines)

func _boss_package_detail_text(popup: Dictionary) -> String:
	var lines = []
	if popup.def.has("efficiencyLabel"):
		lines.append("[b]%s[/b]" % popup.def.efficiencyLabel)
	lines.append("패키지 가격: [b]%dG[/b]" % int(popup.get("packageCost", 0)))
	lines.append("선결제 후 아이템 6개 중 2개를 선택합니다.")
	var preview = []
	for item in popup.get("packageItems", []):
		preview.append("[%s] %s" % [item.get("rarity", "Common"), item.get("name", item.get("id", "아이템"))])
	lines.append("후보: %s" % " / ".join(preview.slice(0, 6)))
	return "\n".join(lines)

func _security_installer_detail_text(popup: Dictionary) -> String:
	var def = game.security_program_def(popup.def.get("installProgram", ""))
	if def.is_empty():
		return ""
	var status = "이미 설치됨" if game.installed_resident_program(def.type) != null else "설치 가능"
	return "[b]%s[/b]\n%s\n설치 비용: %dG / 상태: %s\n상주 부담: %s" % [def.name, def.summary, int(def.installCost), status, game.security_program_burden_text(def)]

func _sponsored_ad_detail_text(popup: Dictionary) -> String:
	var def = popup.def
	var lines = []
	var buffs = []
	for effect in def.get("ongoingBuffs", []):
		buffs.append(_effect_summary(effect))
	var rewards = []
	for reward in def.get("completionRewards", []):
		rewards.append(_sponsored_reward_text(reward))
	if not buffs.is_empty():
		lines.append("열려 있는 동안: [b]%s[/b]" % ", ".join(buffs))
	if not rewards.is_empty():
		lines.append("완료 보상: [b]%s[/b]" % ", ".join(rewards))
	lines.append("남은 시간: %.1f초" % max(0.0, game.timed_reward_duration(def) - float(popup.elapsed)))
	lines.append("난이도 상승 없음. 중간에 닫으면 완료 보상은 취소됩니다.")
	return "\n".join(lines)

func _timed_reward_detail_text(popup: Dictionary) -> String:
	var reward = int(round(float(popup.def.get("rewardGold", 0)) * max(0.1, 1.0 + game.state.stats.rewardGoldMultiplier)))
	return "남은 시간: %.1f초\n완료 보상: [b]%dG[/b]\n중간에 닫으면 혜택은 소멸됩니다." % [max(0.0, game.timed_reward_duration(popup.def) - float(popup.elapsed)), reward]

func _terms_detail_text(popup: Dictionary) -> String:
	var checked = popup.get("termsRiskChecked", true)
	var status = "체크됨" if checked else "체크 해제"
	return "%s\n상태: [b]%s[/b]\n체크 상태로 수락: 높은 보상 + 위험 패널티 + 난이도 증가\n체크 해제 후 수락: 낮은 보상, 패널티 없음" % [popup.def.get("dangerClauseText", "위험 조항에 동의합니다."), status]

func _effect_summary(effect: Dictionary) -> String:
	var type = effect.get("type", "")
	if type == "gold":
		return "%dG" % int(effect.get("value", 0))
	if type == "itemDiscount":
		return "다음 아이템 비용 -%d%%" % round(float(effect.get("value", 0.0)) * 100.0)
	if type == "extraItemChoice":
		return "다음 아이템 선택지 +%d" % int(effect.get("value", 1))
	if type == "freeSampleItem":
		return "%s 샘플 x%d" % [effect.get("rarity", "Common"), int(effect.get("count", 1))]
	if effect.has("stat"):
		var value = float(effect.get("value", 0.0))
		var sign = "+" if value >= 0.0 else ""
		return "%s %s%.0f%%" % [_stat_label(effect.stat), sign, value * 100.0]
	return str(type if type != "" else effect.get("stat", "효과"))

func _sponsored_reward_text(reward: Dictionary) -> String:
	return _effect_summary(reward)

func _stat_label(stat: String) -> String:
	var labels = {
		"damageMultiplier": "피해",
		"attackIntervalMultiplier": "공격 간격",
		"rewardGoldMultiplier": "보상 골드",
		"sponsoredRewardMultiplier": "스폰서 보상",
		"sponsoredPopupWeightMultiplier": "스폰서 압박",
		"termsPopupWeightMultiplier": "약관 압박",
		"emergencyCooldownMultiplier": "긴급 쿨타임",
		"popupSpawnRateMultiplier": "팝업 생성률",
	}
	return labels.get(stat, stat)

func _clean_challenge_detail_text(popup: Dictionary) -> String:
	var duration = float(popup.def.get("duration", 10.0))
	var target = int(popup.def.get("targetOpenPopups", 2))
	var reward = popup.def.get("reward", {"type": "itemDiscount", "value": 0.2})
	return "목표: 열린 팝업 %d개 이하를 %.0f초 유지\n진행: %.1f / %.0f초\n보상: %s" % [target, duration, float(popup.get("cleanProgress", 0.0)), duration, _effect_summary(reward)]

func _volatile_detail_text(popup: Dictionary) -> String:
	var duration = float(popup.def.get("duration", 8.0))
	var remaining = max(0.0, duration - float(popup.elapsed))
	return "시간 안에 닫기: 주변 %dpx 적에게 %d 피해\n남은 시간: %.1f초\n시간 초과: 다음 팝업 압박이 앞당겨질 수 있습니다." % [int(popup.def.get("closeRadius", 150)), int(popup.def.get("closeDamage", 25)), remaining]

func _infection_detail_text(popup: Dictionary) -> String:
	var target = game.popup_by_id(int(popup.get("infectionTargetId", 0)))
	var target_text = "감염할 대상 검색 중" if target == null else "감염 대상: %s" % target.def.get("title", "팝업")
	return "%s\n감염 진행 %.0f%%\n막대가 차기 전에 이 창을 닫으면 감염을 막을 수 있습니다." % [target_text, float(popup.get("progress", 0.0)) * 100.0]

func _infected_detail_text(popup: Dictionary) -> String:
	return "감염된 창입니다.\n원래 보상은 지급되지 않습니다.\n직접 닫아야 정리 콤보에 반영됩니다."

func _moving_close_detail_text(popup: Dictionary) -> String:
	return "이 창은 자동으로 이동합니다.\n속도: %.0f, %.0f\n직접 따라가서 닫거나 쓰레기존으로 끌어야 합니다." % [popup.velocity.x, popup.velocity.y]

func _controls_signature(popup: Dictionary) -> String:
	var type = str(popup.def.get("type", ""))
	var parts = [
		type,
		"grace:%s" % str(float(popup.get("inputGrace", 0.0)) > 0.0),
		"min:%s" % str(popup.get("minimized", false)),
	]
	match type:
		"first_purchase_package":
			var cost = game.first_purchase_cost()
			parts.append("afford:%s" % str(game.state.gold >= cost))
		"boss_package_ad":
			var package_cost = int(popup.get("packageCost", 0))
			parts.append("cost:%d" % package_cost)
			parts.append("afford:%s" % str(game.state.gold >= package_cost))
		"security_installer":
			var program_def = game.security_program_def(popup.def.get("installProgram", ""))
			var installed = false if program_def.is_empty() else game.installed_resident_program(program_def.type) != null
			var install_cost = 0 if program_def.is_empty() else int(program_def.installCost)
			parts.append("installed:%s" % str(installed))
			parts.append("afford:%s" % str(game.state.gold >= install_cost))
		"terms":
			parts.append("checked:%s" % str(popup.get("termsRiskChecked", true)))
		"interest_offer":
			parts.append("accepted:%s" % str(popup.get("interestAccepted", false)))
			parts.append("matured:%s" % str(popup.get("interestMatured", false)))
		"recurring_investment":
			parts.append("accepted:%s" % str(popup.has("investment") and popup.investment.get("accepted", false)))
			parts.append("matured:%s" % str(popup.has("investment") and popup.investment.get("matured", false)))
		"loan_offer":
			parts.append("credit:%d" % int(game.state.creditScore))
		"stock_broker_app":
			var stock = game.state.stockMarket.stock
			var price = int(ceil(float(stock.price)))
			parts.append("buy:%s" % str(game.state.gold >= price))
			parts.append("shares:%d" % int(stock.shares))
		"stock_market":
			parts.append("invested:%s" % str(popup.has("stock") and popup.stock.get("invested", false)))
			for principal in popup.def.get("principalOptions", [50, 100, 150]):
				parts.append("p%d:%s" % [int(principal), str(game.state.gold >= int(principal))])
		"popup_store":
			for product in popup.get("storeProducts", game.data.POPUP_STORE_CATALOG):
				var price = game.popup_store_price(product)
				parts.append("%s:%d:%s" % [product.get("id", product.get("label", "product")), price, str(game.state.gold >= price)])
	return "|".join(parts)

func _rebuild_controls(popup: Dictionary, controls: Node) -> void:
	for child in controls.get_children():
		controls.remove_child(child)
		child.queue_free()
	var type = popup.def.type
	match type:
		"first_purchase_package":
			_button(controls, "인게임 결제 - %dG" % game.first_purchase_cost(), func(id = popup.id): game.complete_first_purchase_payment(id), game.state.gold < game.first_purchase_cost())
			_button(controls, "거절", func(id = popup.id): game.reject_first_purchase_package(id))
		"boss_package_ad":
			var cost = int(popup.get("packageCost", 0))
			_button(controls, "패키지 구매 - %dG\n아이템 6개 중 2개 선택" % cost, func(id = popup.id): game.purchase_boss_package(id), game.state.gold < cost, Vector2(184, 44))
			_button(controls, "닫기", func(id = popup.id): game.request_close_popup(id, {"reason": "reject"}))
		"security_installer":
			var program_def = game.security_program_def(popup.def.get("installProgram", ""))
			var installed = false if program_def.is_empty() else game.installed_resident_program(program_def.type) != null
			var install_cost = 0 if program_def.is_empty() else int(program_def.installCost)
			var label = "이미 설치됨" if installed else "설치 - %dG" % install_cost
			_button(controls, label, func(id = popup.id): game.install_resident_program(popup.def.get("installProgram", ""), id), installed or game.state.gold < install_cost)
			_button(controls, "나중에", func(id = popup.id): game.request_close_popup(id, {"reason": "security_later"}))
		"security_update_notice":
			_button(controls, "확인", func(id = popup.id): game.request_close_popup(id, {"reason": "security_notice_ack"}))
		"terms":
			var checked = popup.get("termsRiskChecked", true)
			_button(controls, "[x] 위험 조항 동의" if checked else "[ ] 위험 조항 동의", func(id = popup.id): game.toggle_terms_risk(id), false, Vector2(154, 34))
			_button(controls, "선택 조건으로 수락", func(id = popup.id): game.accept_terms_popup(id, game.popup_by_id(id).get("termsRiskChecked", true)), false, Vector2(142, 34))
			_button(controls, "거절", func(id = popup.id): game.request_close_popup(id, {"reason": "terms_reject"}))
		"interest_offer":
			if popup.get("interestAccepted", false):
				_button(controls, "중도 해지", func(id = popup.id): game.cancel_interest_offer(id))
			else:
				for option in popup.get("depositOptions", []):
					var principal = int(floor(game.state.gold * float(option.get("ratio", 0.25))))
					var payout = int(round(principal * (1.0 + float(option.get("bonus", 0.2)))))
					_button(controls, "%s - %dG -> %dG" % [option.get("label", "예치"), principal, payout], func(ratio = float(option.get("ratio", 0.25)), id = popup.id): game.accept_interest_offer(id, ratio))
				_button(controls, "닫기", func(id = popup.id): game.request_close_popup(id, {"reason": "interest_reject"}))
		"recurring_investment":
			if popup.has("investment") and popup.investment.get("accepted", false):
				_button(controls, "중도 해지", func(id = popup.id): game.cancel_recurring_investment(id))
			else:
				_button(controls, "자동 적립 수락", func(id = popup.id): game.accept_recurring_investment(id))
				_button(controls, "닫기", func(id = popup.id): game.request_close_popup(id, {"reason": "recurring_reject"}))
		"loan_offer":
			for option in game.credit_cashout_options():
				_button(controls, "%s: 신용 -%d / +%dG" % [option.label, option.creditCost, option.gold], func(opt = option, id = popup.id): game.accept_credit_cashout(id, opt))
			_button(controls, "닫기", func(id = popup.id): game.request_close_popup(id, {"reason": "loan_reject"}))
		"stock_broker_app":
			var stock = game.state.stockMarket.stock
			var price = int(ceil(float(stock.price)))
			_button(controls, "1주 매수", func(): game.buy_stock(1), game.state.gold < price)
			_button(controls, "최대 매수", func(): game.buy_max_stock(), game.state.gold < price)
			_button(controls, "1주 매도", func(): game.sell_stock_shares(1), int(stock.shares) <= 0)
			_button(controls, "전량 매도", func(): game.sell_all_stock(), int(stock.shares) <= 0)
		"stock_market":
			if popup.has("stock") and popup.stock.get("invested", false):
				_button(controls, "매도", func(id = popup.id): game.sell_stock_popup(id))
			else:
				for principal in popup.def.get("principalOptions", [50, 100, 150]):
					_button(controls, "%dG 투자" % int(principal), func(value = int(principal), id = popup.id): game.invest_stock_popup(id, value), game.state.gold < int(principal))
				_button(controls, "증권 앱 열기", func(): game.ensure_stock_broker_app())
				_button(controls, "닫기", func(id = popup.id): game.request_close_popup(id, {"reason": "stock_notice_close"}))
		"popup_store":
			for product in popup.get("storeProducts", game.data.POPUP_STORE_CATALOG):
				var price = game.popup_store_price(product)
				_button(controls, "[%s] %s - %dG\n미확인 아이템 즉시 획득" % [product.get("rarity", "Common"), product.get("label", "상품"), price], func(p = product, id = popup.id): game.purchase_popup_store_item(id, p), game.state.gold < price, Vector2(178, 48))
			_button(controls, "닫기", func(id = popup.id): game.request_close_popup(id, {"reason": "store_close"}))
		"volatile_popup":
			_control_label(controls, "%.1f초" % max(0.0, float(popup.def.get("duration", 8.0)) - float(popup.elapsed)))
			_button(controls, "지금 닫기", func(id = popup.id): game.trigger_volatile_popup_close(id))
		"infection":
			_button(controls, "확장 차단", func(id = popup.id): game.request_close_popup(id, {"reason": "infection_blocked"}))
		"sponsored_ad":
			_control_label(controls, "%.1f초" % max(0.0, game.timed_reward_duration(popup.def) - float(popup.elapsed)))
			_button(controls, "중단하기", func(id = popup.id): game.request_close_popup(id, {"reason": "sponsored_cancel"}))
		"timed_reward":
			_control_label(controls, "%.1f초" % max(0.0, game.timed_reward_duration(popup.def) - float(popup.elapsed)))
			_button(controls, "취소", func(id = popup.id): game.request_close_popup(id, {"reason": "timed_cancel"}))
		"clean_challenge":
			_control_label(controls, "%.1f / %.0f초" % [float(popup.get("cleanProgress", 0.0)), float(popup.def.get("duration", 10.0))])
			_button(controls, "포기", func(id = popup.id): game.request_close_popup(id, {"reason": "clean_give_up"}))
		"infected_popup":
			_button(controls, "감염 창 닫기", func(id = popup.id): game.request_close_popup(id, {"reason": "button"}), false, Vector2(124, 34))
		"moving_close":
			_button(controls, "닫기", func(id = popup.id): game.request_close_popup(id, {"reason": "button"}))
		_:
			_button(controls, "닫기", func(id = popup.id): game.request_close_popup(id, {"reason": "button"}))
	if popup.get("inputGrace", 0.0) > 0.0:
		_set_buttons_disabled(controls, true)

func _button(parent: Node, text: String, callback: Callable, disabled := false, min_size := Vector2(96, 34)) -> Button:
	var button = Button.new()
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.clip_contents = true
	button.text = text
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.custom_minimum_size = min_size
	button.disabled = disabled
	_style_popup_button(button)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _control_label(parent: Node, text: String) -> Label:
	var label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.text = text
	label.custom_minimum_size = Vector2(56, 28)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color("#182235"))
	parent.add_child(label)
	return label

func _set_buttons_disabled(node: Node, disabled: bool) -> void:
	for child in node.get_children():
		if child is Button:
			child.disabled = disabled
		_set_buttons_disabled(child, disabled)

func _update_status_badges(popup: Dictionary, container: HFlowContainer) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
	if popup.get("inputGrace", 0.0) > 0.0:
		_status_badge(container, "입력 유예 중", Color(0.06, 0.08, 0.11, 0.68), Color(1, 1, 1, 0.22), Color.WHITE)
	if _popup_has_lock_badge(popup):
		_status_badge(container, "잠김", Color("#4b2a33"), Color(1.0, 0.35, 0.45, 0.45), Color("#ffe5ea"))
	if popup.get("securityQuarantineTimer", 0.0) > 0.0:
		_status_badge(container, "격리 중 %.1fs" % float(popup.securityQuarantineTimer), Color("#8be9ff"), Color(0.02, 0.30, 0.42, 0.42), Color("#073044"))
	if popup.get("infectedByPopup", false):
		_status_badge(container, "감염 대상", Color(0.22, 0.64, 0.35, 0.26), Color(0.20, 0.80, 0.40, 0.56), Color("#0d3c22"))
	container.visible = container.get_child_count() > 0

func _popup_has_lock_badge(popup: Dictionary) -> bool:
	if popup.get("locked", false) or popup.def.type == "stock_broker_app":
		return true
	if popup.def.type == "interest_offer" and popup.get("interestAccepted", false) and not popup.get("interestMatured", false):
		return true
	if popup.def.type == "recurring_investment" and popup.has("investment") and popup.investment.get("accepted", false) and not popup.investment.get("matured", false):
		return true
	if popup.def.type == "stock_market" and popup.has("stock") and popup.stock.get("invested", false):
		return true
	return false

func _status_badge(parent: Node, text: String, bg: Color, border: Color, font: Color) -> Label:
	var label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", font)
	label.add_theme_stylebox_override("normal", _style_box(bg, border, 99, 1, 6))
	parent.add_child(label)
	return label

func _set_progress_color(bar: ProgressBar, fill_color: Color) -> void:
	bar.add_theme_stylebox_override("fill", _style_box(fill_color, Color(fill_color, 0.0), 99, 0))

func _progress_color(popup: Dictionary) -> Color:
	match popup.def.type:
		"clean_challenge":
			return Color("#49a7c7")
		"volatile_popup":
			return Color("#d84e4e") if float(popup.get("progress", 0.0)) > 0.72 else Color("#df6c36")
		"infection":
			return Color("#3caa5f")
		"timed_reward":
			return Color("#4c91d8")
		"sponsored_ad":
			return Color("#d8aa27")
	return _popup_title_color(popup.def.type)

func _input(event: InputEvent) -> void:
	for popup_id in windows.keys():
		var record = windows.get(popup_id, null)
		if record == null or not record.get("dragging", false):
			continue
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			record.dragging = false
			game.settle_dragged_popup(int(popup_id))
		elif event is InputEventMouseMotion:
			var panel = record.panel
			var delta = root.get_local_mouse_position() - record.dragStartMouse
			game.move_popup(int(popup_id), record.dragOriginPosition + delta * game.popup_drag_multiplier())
			if panel is Control:
				panel.position = game.popup_by_id(int(popup_id)).position if game.popup_by_id(int(popup_id)) != null else panel.position

func _panel_event(event: InputEvent, popup_id: int, panel: PanelContainer) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		panel.move_to_front()
		game.bring_popup_to_front(popup_id)

func _drag_event(event: InputEvent, popup_id: int, panel: PanelContainer) -> void:
	var record = windows.get(popup_id, null)
	if record == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			record.dragging = true
			record.dragOffset = panel.get_local_mouse_position()
			record.dragStartMouse = root.get_local_mouse_position()
			record.dragOriginPosition = panel.position
			panel.move_to_front()
			game.bring_popup_to_front(popup_id)
			game.start_dragging_popup(popup_id)
		else:
			record.dragging = false
			game.settle_dragged_popup(popup_id)
	elif event is InputEventMouseMotion and record.dragging:
		var delta = root.get_local_mouse_position() - record.dragStartMouse
		game.move_popup(popup_id, record.dragOriginPosition + delta * game.popup_drag_multiplier())

func _draw_stock_chart(chart: Control, popup_id: int) -> void:
	var popup = game.popup_by_id(popup_id)
	var stock = game.state.stockMarket.stock
	var history = stock.history
	var last_change = stock.lastChange
	if popup != null and popup.def.type == "stock_market" and popup.has("stock"):
		history = popup.stock.get("history", [])
		if history.size() >= 2:
			var previous_value = float(history[history.size() - 2])
			last_change = (float(history[history.size() - 1]) - previous_value) / max(previous_value, 1.0)
	var rect = Rect2(Vector2.ZERO, chart.size)
	chart.draw_rect(rect, Color(0, 0, 0, 0.25), true)
	chart.draw_rect(rect, Color(0, 0, 0, 0.22), false, 1.0)
	for i in range(1, 4):
		var y = rect.position.y + rect.size.y * float(i) / 4.0
		chart.draw_line(Vector2(rect.position.x, y), Vector2(rect.position.x + rect.size.x, y), Color(1, 1, 1, 0.08), 1.0)
	for i in range(1, 5):
		var x = rect.position.x + rect.size.x * float(i) / 5.0
		chart.draw_line(Vector2(x, rect.position.y), Vector2(x, rect.position.y + rect.size.y), Color(1, 1, 1, 0.06), 1.0)
	if history.size() < 2:
		return
	var min_value = history.min()
	var max_value = history.max()
	var span = max(max_value - min_value, 1.0)
	var baseline = history[0]
	var baseline_y = rect.position.y + rect.size.y - rect.size.y * ((baseline - min_value) / span)
	chart.draw_line(Vector2(rect.position.x, baseline_y), Vector2(rect.position.x + rect.size.x, baseline_y), Color(0.95, 0.78, 0.29, 0.28), 1.0)
	var previous = Vector2.ZERO
	for i in range(history.size()):
		var x = rect.position.x + rect.size.x * float(i) / float(max(history.size() - 1, 1))
		var y = rect.position.y + rect.size.y - rect.size.y * ((history[i] - min_value) / span)
		var point = Vector2(x, y)
		if i > 0:
			chart.draw_line(previous, point, Color("#48d597") if last_change >= 0.0 else Color("#ff5964"), 2.0)
		previous = point

func _popup_bg_color(type: String) -> Color:
	match type:
		"terms":
			return Color("#ffe2ea")
		"sponsored_ad", "ad_buff":
			return Color("#fff6cf")
		"timed_reward":
			return Color("#dfeeff")
		"moving_close":
			return Color("#f2f2f2")
		"infection":
			return Color("#e4ffe6")
		"infected_popup":
			return Color("#19281e")
		"volatile_popup":
			return Color("#ffe8dd")
		"first_purchase_package":
			return Color("#fff7d7")
		"system_notice":
			return Color("#eaf6ff")
		"boss_package_ad":
			return Color("#fff0f0")
		"popup_store":
			return Color("#f4edff")
		"stock_market", "stock_broker_app", "recurring_investment", "loan_offer":
			return Color("#eaf7ef")
		"interest_offer":
			return Color("#e8fbff")
		"clean_challenge":
			return Color("#eefcff")
		"security_installer", "security_update_notice":
			return Color("#eaf6ff")
	return Color("#f6fbff")

func _popup_border_color(type: String) -> Color:
	match type:
		"terms":
			return Color("#d84e74")
		"sponsored_ad", "ad_buff":
			return Color("#d8aa27")
		"timed_reward":
			return Color("#4c91d8")
		"moving_close":
			return Color("#7f8a99")
		"infection", "infected_popup":
			return Color("#3caa5f")
		"volatile_popup":
			return Color("#df6c36")
		"first_purchase_package":
			return Color("#d7a72f")
		"system_notice":
			return Color("#67a9d8")
		"boss_package_ad":
			return Color("#c63b52")
		"popup_store":
			return Color("#8154c7")
		"stock_market", "stock_broker_app", "recurring_investment", "loan_offer":
			return Color("#35a866")
		"interest_offer":
			return Color("#2d9bb8")
		"clean_challenge":
			return Color("#49a7c7")
		"security_installer", "security_update_notice":
			return Color("#67a9d8")
	return Color("#7f8a99")

func _popup_title_color(type: String) -> Color:
	match type:
		"terms":
			return Color("#a92f55")
		"sponsored_ad", "ad_buff":
			return Color("#9d7308")
		"timed_reward":
			return Color("#235d99")
		"infection":
			return Color("#207a3e")
		"infected_popup":
			return Color("#105a2d")
		"first_purchase_package":
			return Color("#8c6410")
		"system_notice":
			return Color("#2a6f9a")
		"boss_package_ad":
			return Color("#8e2637")
		"stock_market", "stock_broker_app", "recurring_investment", "loan_offer":
			return Color("#217748")
		"interest_offer":
			return Color("#126d82")
		"clean_challenge":
			return Color("#257d97")
		"volatile_popup":
			return Color("#a84d20")
		"popup_store":
			return Color("#56339a")
		"security_installer", "security_update_notice":
			return Color("#15577b")
	return Color("#394354")

func _popup_text_color(type: String) -> Color:
	if type == "infected_popup":
		return Color("#dfffea")
	return Color("#182235")

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

func _style_popup_button(button: Button) -> void:
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	var normal_bg = Color(1, 1, 1, 0.75)
	var hover_bg = Color(1, 1, 1, 0.92)
	var pressed_bg = Color(0.88, 0.92, 0.96, 0.96)
	var border = Color(0, 0, 0, 0.22)
	button.add_theme_stylebox_override("normal", _style_box(normal_bg, border, 5, 1, 3))
	button.add_theme_stylebox_override("hover", _style_box(hover_bg, border, 5, 1, 3))
	button.add_theme_stylebox_override("pressed", _style_box(pressed_bg, border, 5, 1, 3))
	button.add_theme_stylebox_override("disabled", _style_box(Color(1, 1, 1, 0.36), Color(0, 0, 0, 0.12), 5, 1, 3))
	button.add_theme_color_override("font_color", Color("#15202b"))
	button.add_theme_color_override("font_hover_color", Color("#15202b"))
	button.add_theme_color_override("font_pressed_color", Color("#15202b"))
	button.add_theme_color_override("font_disabled_color", Color(0.08, 0.12, 0.16, 0.5))
	button.add_theme_font_size_override("font_size", 12)

func _style_title_button(button: Button) -> void:
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg = Color(0, 0, 0, 0.22)
	var hover = Color(0, 0, 0, 0.34)
	var border = Color(1, 1, 1, 0.22)
	button.add_theme_stylebox_override("normal", _style_box(bg, border, 4, 1, 0))
	button.add_theme_stylebox_override("hover", _style_box(hover, border, 4, 1, 0))
	button.add_theme_stylebox_override("pressed", _style_box(Color(0, 0, 0, 0.42), border, 4, 1, 0))
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", 12)
