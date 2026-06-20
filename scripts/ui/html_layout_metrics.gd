extends RefCounted
class_name HtmlLayoutMetrics

const HUD_MARGIN := 12.0
const CENTER_TOP_MARGIN := 10.0
const CHOICE_MARGIN := 20.0
const CHOICE_MAX_WIDTH := 680.0
const CHOICE_DEFAULT_HEIGHT := 365.0
const CHOICE_GAP := 12.0
const CHOICE_PANEL_PADDING := 18.0
const CHOICE_MIN_CARD_WIDTH := 190.0
const PC_VIEWPORT_WIDTH := 1920
const PC_VIEWPORT_HEIGHT := 1080
const MOBILE_WIDTH_BREAKPOINT := 860.0
const MOBILE_HEIGHT_BREAKPOINT := 520.0
const MOBILE_PORTRAIT_MAX_WIDTH := 1440.0
const MOBILE_PORTRAIT_MIN_ASPECT := 1.20
const MOBILE_LANDSCAPE_MAX_HEIGHT := 1180.0
const MOBILE_LANDSCAPE_MIN_ASPECT := 1.95

const PROFILE_DESKTOP := "desktop"
const PROFILE_COMPACT := "compact"
const PROFILE_PORTRAIT := "portrait"

static func viewport_size(viewport: Viewport) -> Vector2:
	if viewport == null:
		return Vector2(960, 540)
	return viewport.get_visible_rect().size

static func html_choice_panel_size(viewport: Vector2, layout_scale := 1.0) -> Vector2:
	return choice_panel_size(viewport, layout_scale)

static func html_difficulty_width(viewport: Vector2) -> float:
	return difficulty_hud_rect(viewport).size.x

static func layout_profile(viewport_size: Vector2) -> String:
	if viewport_size == Vector2.ZERO:
		return PROFILE_DESKTOP
	if viewport_size.x < viewport_size.y and is_compact_viewport(viewport_size):
		return PROFILE_PORTRAIT
	if is_compact_viewport(viewport_size):
		return PROFILE_COMPACT
	return PROFILE_DESKTOP

static func is_compact_viewport(viewport_size: Vector2) -> bool:
	if viewport_size == Vector2.ZERO:
		return false
	return viewport_size.x <= MOBILE_WIDTH_BREAKPOINT or viewport_size.y < MOBILE_HEIGHT_BREAKPOINT or is_mobile_shaped_viewport(viewport_size)

static func is_mobile_shaped_viewport(viewport_size: Vector2) -> bool:
	if viewport_size == Vector2.ZERO:
		return false
	var short_side = max(1.0, min(viewport_size.x, viewport_size.y))
	var long_side = max(viewport_size.x, viewport_size.y)
	var aspect = long_side / short_side
	if viewport_size.x < viewport_size.y:
		return viewport_size.x <= MOBILE_PORTRAIT_MAX_WIDTH and aspect >= MOBILE_PORTRAIT_MIN_ASPECT
	return viewport_size.y <= MOBILE_LANDSCAPE_MAX_HEIGHT and aspect >= MOBILE_LANDSCAPE_MIN_ASPECT

static func mobile_controls_visible_for_viewport(viewport_size: Vector2) -> bool:
	return viewport_size.x < MOBILE_WIDTH_BREAKPOINT or viewport_size.y < MOBILE_HEIGHT_BREAKPOINT or is_mobile_shaped_viewport(viewport_size)

static func text_scale(viewport_size: Vector2) -> float:
	match layout_profile(viewport_size):
		PROFILE_PORTRAIT:
			return clamp(viewport_size.x / 540.0, 0.72, 1.0)
		PROFILE_COMPACT:
			return clamp(min(viewport_size.x, viewport_size.y) / 540.0, 0.78, 1.0)
	return 1.0

static func panel_padding(viewport_size: Vector2) -> int:
	return 2 if is_compact_viewport(viewport_size) else 12

static func panel_corner_radius(viewport_size: Vector2) -> int:
	return 6 if is_compact_viewport(viewport_size) else 8

static func debug_visible_for_viewport(viewport_size: Vector2) -> bool:
	return not is_compact_viewport(viewport_size)

static func fixed_panel_rule(key: String, viewport_size: Vector2, status_minimized := false, debug_minimized := false) -> Dictionary:
	var rect = Rect2(Vector2.ZERO, Vector2.ZERO)
	match key:
		"combatHud":
			rect = combat_hud_rect(viewport_size)
		"economyHud":
			rect = economy_hud_rect(viewport_size)
		"statusPanel":
			rect = status_hud_rect(viewport_size, status_minimized)
		"debugPanel":
			rect = debug_hud_rect(viewport_size, debug_minimized)
	return {
		"rect": rect,
		"padding": panel_padding(viewport_size),
		"radius": panel_corner_radius(viewport_size),
		"clip": true,
		"scroll_wrapper": fixed_panel_uses_scroll_wrapper(key),
		"mouse_filter": Control.MOUSE_FILTER_STOP if key == "debugPanel" and debug_visible_for_viewport(viewport_size) else Control.MOUSE_FILTER_IGNORE,
	}

static func fixed_panel_uses_scroll_wrapper(key: String) -> bool:
	return false

static func choice_panel_padding(viewport_size: Vector2) -> int:
	return 8 if is_compact_viewport(viewport_size) else 18

static func choice_panel_top_padding(viewport_size: Vector2) -> int:
	return 8 if is_compact_viewport(viewport_size) else 18

static func choice_panel_text_safe_inset(viewport_size: Vector2) -> int:
	return 4 if is_compact_viewport(viewport_size) else 6

static func choice_panel_header_height(viewport_size: Vector2) -> float:
	return 74.0 if is_compact_viewport(viewport_size) else 108.0

static func scrollbar_safe_inset(viewport_size: Vector2) -> int:
	return 10 if is_compact_viewport(viewport_size) else 14

static func debug_body_max_height(viewport_size: Vector2) -> float:
	if is_compact_viewport(viewport_size):
		return 0.0
	return max(120.0, viewport_size.y - 82.0)

static func debug_buttons_max_height(viewport_size: Vector2) -> float:
	return min(viewport_size.y * 0.34, 220.0)

static func place_top_left(control: Control, x: float, y: float, width: float, height := -1.0) -> void:
	_place_with_anchors(control, 0.0, 0.0, Vector2(x, y), Vector2(x + width, y + _resolved_height(control, height)))

static func place_top_right(control: Control, right_margin: float, y: float, width: float, height := -1.0) -> void:
	_place_with_anchors(control, 1.0, 0.0, Vector2(-right_margin - width, y), Vector2(-right_margin, y + _resolved_height(control, height)))

static func place_bottom_left(control: Control, x: float, bottom_margin: float, width: float, height := -1.0) -> void:
	var resolved_height = _resolved_height(control, height)
	_place_with_anchors(control, 0.0, 1.0, Vector2(x, -bottom_margin - resolved_height), Vector2(x + width, -bottom_margin))

static func place_bottom_right(control: Control, right_margin: float, bottom_margin: float, width: float, height := -1.0) -> void:
	var resolved_height = _resolved_height(control, height)
	_place_with_anchors(control, 1.0, 1.0, Vector2(-right_margin - width, -bottom_margin - resolved_height), Vector2(-right_margin, -bottom_margin))

static func place_top_center(control: Control, y: float, width: float, height := -1.0) -> void:
	var resolved_height = _resolved_height(control, height)
	_place_with_anchors(control, 0.5, 0.0, Vector2(-width * 0.5, y), Vector2(width * 0.5, y + resolved_height))

static func center_panel(control: Control, width: float, height_or_max_height: float) -> void:
	_apply_centered_rect(control, Vector2(width, height_or_max_height))

static func apply_popup_layout(popup_window: Control, popup_type: String) -> void:
	if popup_window == null:
		return
	popup_window.size = popup_size_for_type(popup_type)
	popup_window.custom_minimum_size = popup_window.size

static func combat_hud_rect(viewport_size: Vector2) -> Rect2:
	match layout_profile(viewport_size):
		PROFILE_PORTRAIT:
			var width = max(132.0, viewport_size.x * 0.5 - 12.0)
			var height = min(170.0, max(96.0, viewport_size.y * 0.22))
			return Rect2(Vector2(6.0, 6.0), Vector2(width, height))
		PROFILE_COMPACT:
			var width = min(156.0, max(132.0, viewport_size.x * 0.25))
			var height = min(170.0, max(96.0, viewport_size.y * 0.30))
			return Rect2(Vector2(6.0, 6.0), Vector2(width, height))
	return Rect2(Vector2(HUD_MARGIN, HUD_MARGIN), Vector2(270, min(360.0, max(218.0, viewport_size.y - HUD_MARGIN * 2.0))))

static func economy_hud_rect(viewport_size: Vector2) -> Rect2:
	match layout_profile(viewport_size):
		PROFILE_PORTRAIT:
			var width = max(132.0, viewport_size.x * 0.5 - 12.0)
			var height = min(170.0, max(96.0, viewport_size.y * 0.22))
			return Rect2(Vector2(viewport_size.x - 6.0 - width, 6.0), Vector2(width, height))
		PROFILE_COMPACT:
			var width = min(170.0, max(142.0, viewport_size.x * 0.26))
			var height = min(170.0, max(96.0, viewport_size.y * 0.30))
			return Rect2(Vector2(viewport_size.x - 6.0 - width, 6.0), Vector2(width, height))
	var height = min(517.0, max(250.0, viewport_size.y - HUD_MARGIN * 2.0))
	return Rect2(Vector2(viewport_size.x - HUD_MARGIN - 255.0, HUD_MARGIN), Vector2(255, height))

static func difficulty_hud_rect(viewport_size: Vector2) -> Rect2:
	if is_compact_viewport(viewport_size):
		var width = min(210.0, max(150.0, viewport_size.x * 0.38))
		return Rect2(Vector2((viewport_size.x - width) * 0.5, 5.0), Vector2(width, 60.0))
	var width = _clamped_css_width(viewport_size.x, 340.0, 520.0, 240.0)
	return Rect2(Vector2((viewport_size.x - width) * 0.5, CENTER_TOP_MARGIN), Vector2(width, 67))

static func cleanup_hud_rect(viewport_size: Vector2) -> Rect2:
	if is_compact_viewport(viewport_size):
		var width = min(170.0, max(132.0, viewport_size.x * 0.32))
		return Rect2(Vector2((viewport_size.x - width) * 0.5, 42.0), Vector2(width, 60.0))
	var width = _clamped_css_width(viewport_size.x, 260.0, 560.0, 190.0)
	return Rect2(Vector2((viewport_size.x - width) * 0.5, 64.0), Vector2(width, 67))

static func status_hud_rect(viewport_size: Vector2, minimized := false) -> Rect2:
	if is_compact_viewport(viewport_size):
		var minimized_size = Vector2(120, 36)
		if minimized:
			return Rect2(Vector2(8.0, viewport_size.y - 8.0 - minimized_size.y), minimized_size)
		if layout_profile(viewport_size) == PROFILE_PORTRAIT:
			var width = max(180.0, viewport_size.x - 16.0)
			var height = min(136.0, max(76.0, viewport_size.y * 0.18))
			return Rect2(Vector2(8.0, viewport_size.y - 118.0 - height), Vector2(width, height))
		var width = min(194.0, max(132.0, viewport_size.x * 0.30))
		return Rect2(Vector2(max(96.0, 90.0), viewport_size.y - 8.0 - 76.0), Vector2(width, 76.0))
	var size = Vector2(132, 42)
	if not minimized:
		size = Vector2(270, min(561.0, max(112.0, viewport_size.y - HUD_MARGIN * 2.0)))
	return Rect2(Vector2(HUD_MARGIN, viewport_size.y - HUD_MARGIN - size.y), size)

static func debug_hud_rect(viewport_size: Vector2, minimized := false) -> Rect2:
	if is_compact_viewport(viewport_size):
		var size = Vector2(132, 42) if minimized else Vector2(250, 260)
		return Rect2(Vector2(viewport_size.x - 6.0 - size.x, viewport_size.y - 6.0 - size.y), size)
	var size = Vector2(132, 42) if minimized else Vector2(250, min(616.0, max(300.0, viewport_size.y - HUD_MARGIN * 2.0)))
	return Rect2(Vector2(viewport_size.x - HUD_MARGIN - size.x, viewport_size.y - HUD_MARGIN - size.y), size)

static func choice_panel_size(viewport_size: Vector2, layout_scale := 1.0) -> Vector2:
	var safe_scale = max(1.0, layout_scale)
	if is_compact_viewport(viewport_size):
		var margin = 7.0
		var max_width = max(280.0, viewport_size.x - margin * 2.0)
		var max_height = max(260.0, viewport_size.y - margin * 2.0)
		var base_width = min(560.0, max_width)
		var base_height = min(CHOICE_DEFAULT_HEIGHT, max_height)
		return Vector2(min(max_width, base_width * safe_scale), min(max_height, base_height * safe_scale))
	var max_width = max(280.0, viewport_size.x - CHOICE_MARGIN * 2.0)
	var max_height = max(260.0, viewport_size.y - CHOICE_MARGIN * 2.0)
	var base_width = CHOICE_MAX_WIDTH
	var base_height = CHOICE_DEFAULT_HEIGHT
	var width = min(max_width, min(base_width, max_width) * safe_scale)
	var height = min(max_height, min(base_height, max_height) * safe_scale)
	return Vector2(width, height)

static func choice_columns_for_width(panel_width: float, viewport_size := Vector2.ZERO) -> int:
	if viewport_size != Vector2.ZERO:
		if layout_profile(viewport_size) == PROFILE_PORTRAIT or viewport_size.x <= 760.0:
			return 1
		if is_compact_viewport(viewport_size):
			return 3
	if panel_width >= 900.0:
		return 3
	if panel_width >= 620.0:
		return 3
	if panel_width >= 440.0:
		return 2
	return 1

static func choice_card_width(panel_width: float, columns: int, viewport_size := Vector2.ZERO) -> float:
	var safe_columns = max(1, columns)
	var min_width = choice_min_card_width(viewport_size)
	var padding = 18.0 if is_compact_viewport(viewport_size) else CHOICE_PANEL_PADDING
	var gap = choice_gap(viewport_size)
	var content_width = max(min_width, panel_width - padding * 2.0 - float(scrollbar_safe_inset(viewport_size)))
	var total_gap = gap * float(safe_columns - 1)
	return floor(max(min_width, (content_width - total_gap) / float(safe_columns)))

static func choice_card_padding(kind: String, viewport_size: Vector2) -> float:
	if is_compact_viewport(viewport_size):
		return 4.0
	if kind == "module":
		return 7.0
	return 6.0

static func choice_inner_gap(viewport_size: Vector2) -> float:
	return 3.0 if is_compact_viewport(viewport_size) else 4.0

static func choice_gap(viewport_size: Vector2) -> float:
	return 6.0 if is_compact_viewport(viewport_size) else CHOICE_GAP

static func choice_min_card_width(viewport_size: Vector2) -> float:
	if layout_profile(viewport_size) == PROFILE_PORTRAIT:
		return 220.0
	if is_compact_viewport(viewport_size):
		return 136.0
	return CHOICE_MIN_CARD_WIDTH

static func choice_card_min_height(kind: String, viewport_size: Vector2) -> float:
	var compact = is_compact_viewport(viewport_size)
	match kind:
		"item":
			return 74.0 if compact else 118.0
		"contract":
			return 76.0 if compact else 96.0
		"module":
			return 68.0 if compact else 96.0
		"inventory":
			return 86.0 if compact else 112.0
	return 50.0 if compact else 72.0

static func choice_description_height(kind: String, viewport_size: Vector2) -> float:
	var compact = is_compact_viewport(viewport_size)
	match kind:
		"item":
			return 18.0 if compact else 26.0
		"contract":
			return 22.0 if compact else 34.0
		"module":
			return 20.0 if compact else 24.0
	return 16.0 if compact else 22.0

static func apply_desktop_hud_layout(ui: Dictionary, viewport_size: Vector2, status_minimized := false, debug_minimized := false) -> void:
	_apply_rect(ui.get("combatHud", null), combat_hud_rect(viewport_size))
	_apply_rect(ui.get("economyHud", null), economy_hud_rect(viewport_size))
	_apply_rect(ui.get("difficultyHud", null), difficulty_hud_rect(viewport_size))
	_apply_rect(ui.get("cleanupHud", null), cleanup_hud_rect(viewport_size))
	_apply_rect(ui.get("statusPanel", null), status_hud_rect(viewport_size, status_minimized))
	_apply_rect(ui.get("debugPanel", null), debug_hud_rect(viewport_size, debug_minimized))
	if ui.has("debugPanel") and ui.debugPanel is Control:
		ui.debugPanel.visible = debug_visible_for_viewport(viewport_size)

static func apply_choice_overlay_layout(overlay: Control, panel: Control, scroll: Control, grid: GridContainer, viewport_size: Vector2, layout_scale := 1.0, requested_columns := 0) -> void:
	if overlay != null:
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.offset_left = 0.0
		overlay.offset_top = 0.0
		overlay.offset_right = 0.0
		overlay.offset_bottom = 0.0
	var panel_size = choice_panel_size(viewport_size, layout_scale)
	_apply_centered_rect(panel, panel_size)
	if panel != null:
		panel.clip_contents = true
	var columns = choice_columns_for_width(panel_size.x, viewport_size)
	if requested_columns > 0:
		columns = min(columns, requested_columns)
	var gap = choice_gap(viewport_size)
	if scroll != null:
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.custom_minimum_size = Vector2.ZERO
	if grid != null:
		grid.columns = columns
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", int(gap))
		grid.add_theme_constant_override("v_separation", int(gap))

static func game_over_panel_size(viewport_size: Vector2) -> Vector2:
	if is_compact_viewport(viewport_size):
		return Vector2(min(560.0, max(280.0, viewport_size.x - 14.0)), min(300.0, max(220.0, viewport_size.y - 14.0)))
	return Vector2(min(680.0, max(280.0, viewport_size.x - 40.0)), min(320.0, max(220.0, viewport_size.y - 40.0)))

static func popup_content_layout(viewport_size: Vector2, popup_type: String, popup_size: Vector2, body_text := "", detail_text := "", has_status_badges := false) -> Dictionary:
	var compact = is_compact_viewport(viewport_size)
	var layout_group = popup_layout_group(popup_type)
	var title_height = 18.0 if compact else 24.0
	var margin = 6.0 if compact else 10.0
	var gap = 4.0 if compact else 8.0
	var button_height = 28.0 if compact else 34.0
	var panel_size = _popup_resolved_size(viewport_size, popup_type, popup_size, compact)
	var has_chart = ["stock_broker_app", "stock_market"].has(popup_type)
	var chart_height = 48.0 if compact else 58.0
	if not has_chart:
		chart_height = 0.0
	var progress_height = 10.0 if _popup_progress_visible_by_type(popup_type) else 0.0
	var controls_hint = _popup_controls_height(popup_type, compact)
	if popup_type == "boss_package_ad":
		button_height = 38.0 if compact else 42.0
	elif popup_type == "sponsored_ad":
		button_height = 28.0 if compact else 30.0
	var body_scroll = false
	var detail_scroll = false
	var scroll_allowed = _popup_scroll_allowed(popup_type)
	var text_width = _popup_text_width(panel_size.x, margin, viewport_size)
	var body_floor = _popup_body_floor(popup_type, compact)
	var detail_floor = _popup_detail_floor(popup_type, compact)
	var body_height = body_floor
	if not body_scroll and body_text.strip_edges() != "":
		body_height = max(body_floor, _estimated_rich_text_height(body_text, 10 if compact else 13, text_width))
	var detail_visible = detail_text.strip_edges() != ""
	var detail_height = 0.0
	if detail_visible:
		detail_height = detail_floor
		if not detail_scroll:
			detail_height = max(detail_floor, _estimated_rich_text_height(detail_text, 10 if compact else 12, text_width))
	if popup_type == "boss_package_ad":
		body_height = max(body_height, 64.0 if compact else 76.0)
		if detail_visible:
			detail_height = max(detail_height, 92.0 if compact else 124.0)
	elif popup_type == "sponsored_ad":
		body_height = max(body_height, 38.0 if compact else 44.0)
		if detail_visible:
			detail_height = max(detail_height, 48.0 if compact else 58.0)
	var required_height = _popup_required_height(popup_type, compact, title_height, margin, gap, body_height, detail_height, chart_height, progress_height, controls_hint, detail_visible, has_status_badges)
	var max_panel_height = _popup_max_size(viewport_size).y
	if required_height > max_panel_height:
		var overflow = required_height - max_panel_height
		if detail_visible and not detail_scroll:
			var detail_cut = min(max(0.0, detail_height - detail_floor), overflow)
			if detail_cut > 0.0:
				detail_height -= detail_cut
				overflow -= detail_cut
				detail_scroll = scroll_allowed
		if not body_scroll:
			var body_cut = min(max(0.0, body_height - body_floor), overflow)
			if body_cut > 0.0:
				body_height -= body_cut
				overflow -= body_cut
				body_scroll = scroll_allowed
		required_height = _popup_required_height(popup_type, compact, title_height, margin, gap, body_height, detail_height, chart_height, progress_height, controls_hint, detail_visible, has_status_badges)
	panel_size.y = min(max_panel_height, max(title_height + margin * 2.0 + body_floor + controls_hint, required_height))
	return {
		"layout_group": layout_group,
		"panel_size": panel_size,
		"title_height": title_height,
		"content_margin": margin,
		"gap": gap,
		"body_height": body_height,
		"detail_height": detail_height,
		"chart_height": chart_height,
		"body_font": 10 if compact else 13,
		"detail_font": 10 if compact else 12,
		"title_font": 10 if compact else 13,
		"button_font": 10 if compact else 12,
		"button_height": button_height,
		"button_min_width": 82.0 if compact else 94.0,
		"button_max_width": max(90.0, panel_size.x - margin * 2.0 - scrollbar_safe_inset(viewport_size)),
		"control_label_width": 50.0 if compact else 56.0,
		"body_scroll": body_scroll,
		"detail_scroll": detail_scroll,
		"max_content_margin": margin,
	}

static func _popup_resolved_size(viewport_size: Vector2, popup_type: String, popup_size: Vector2, compact: bool) -> Vector2:
	var max_size = _popup_max_size(viewport_size)
	var size = popup_size
	size.x = min(max_size.x, max(size.x, _popup_min_width(popup_type, compact)))
	size.y = min(max_size.y, size.y)
	return size

static func _popup_min_width(popup_type: String, compact: bool) -> float:
	return 220.0

static func _popup_max_size(viewport_size: Vector2) -> Vector2:
	if viewport_size == Vector2.ZERO:
		return Vector2(920.0, 620.0)
	return Vector2(max(240.0, viewport_size.x - 24.0), max(160.0, viewport_size.y - 24.0))

static func _popup_progress_visible_by_type(popup_type: String) -> bool:
	return ["timed_reward", "sponsored_ad", "clean_challenge", "interest_offer", "recurring_investment", "stock_broker_app", "stock_market", "popup_store", "infection", "volatile_popup"].has(popup_type)

static func _popup_controls_height(popup_type: String, compact: bool) -> float:
	var button_height = 28.0 if compact else 34.0
	match popup_type:
		"boss_package_ad":
			return 44.0 if compact else 48.0
		"popup_store":
			return 148.0 if compact else 100.0
		"terms", "interest_offer", "loan_offer", "stock_broker_app", "stock_market":
			return button_height * 2.0 + (3.0 if compact else 4.0)
		"sponsored_ad":
			return 28.0 if compact else 30.0
	return button_height

static func _popup_required_height(popup_type: String, compact: bool, title_height: float, margin: float, gap: float, body_height: float, detail_height: float, chart_height: float, progress_height: float, controls_height: float, detail_visible: bool, has_status_badges: bool) -> float:
	var heights = [body_height]
	if detail_visible:
		heights.append(detail_height)
	if has_status_badges:
		heights.append(18.0 if compact else 20.0)
	if progress_height > 0.0:
		heights.append(progress_height)
	if chart_height > 0.0:
		heights.append(chart_height)
	if controls_height > 0.0:
		heights.append(controls_height)
	var content_height = 0.0
	for height in heights:
		content_height += float(height)
	content_height += gap * float(max(0, heights.size() - 1))
	return ceil(title_height + margin * 2.0 + content_height + 8.0)

static func _popup_body_floor(popup_type: String, compact: bool) -> float:
	match popup_type:
		"boss_package_ad":
			return 64.0 if compact else 76.0
		"sponsored_ad":
			return 38.0 if compact else 44.0
		"security_installer":
			return 72.0 if compact else 86.0
		"popup_store", "stock_broker_app", "stock_market":
			return 52.0 if compact else 68.0
	return 34.0

static func _popup_detail_floor(popup_type: String, compact: bool) -> float:
	match popup_type:
		"boss_package_ad":
			return 92.0 if compact else 124.0
		"terms", "security_installer", "interest_offer", "recurring_investment", "loan_offer":
			return 46.0 if compact else 58.0
		"sponsored_ad", "popup_store", "stock_broker_app":
			return 48.0 if compact else 58.0
	return 34.0 if compact else 44.0

static func _popup_text_width(panel_width: float, margin: float, viewport_size: Vector2) -> float:
	return max(24.0, panel_width - margin * 2.0 - scrollbar_safe_inset(viewport_size))

static func _estimated_rich_text_height(text: String, font_size: int, width: float) -> float:
	var clean_text = _strip_bbcode(text.strip_edges())
	if clean_text == "":
		return _line_box_height(font_size)
	return _line_box_height(font_size) * float(_estimated_wrapped_lines(clean_text, font_size, max(24.0, width)))

static func _line_box_height(font_size: int) -> float:
	return ceil(float(font_size) * 1.25)

static func _estimated_wrapped_lines(text: String, font_size: int, width: float) -> int:
	var total = 0
	for paragraph in text.split("\n"):
		total += _estimated_paragraph_lines(paragraph, font_size, width)
	return max(1, total)

static func _estimated_paragraph_lines(text: String, font_size: int, width: float) -> int:
	if text == "":
		return 1
	var lines = 1
	var used = 0.0
	for index in range(text.length()):
		var character = text.substr(index, 1)
		var char_width = _estimated_char_width(character, font_size)
		if used > 0.0 and used + char_width > width:
			lines += 1
			used = 0.0
		used += char_width
	return lines

static func _estimated_char_width(character: String, font_size: int) -> float:
	if character == " ":
		return max(3.0, float(font_size) * 0.32)
	var code = character.unicode_at(0)
	if code >= 0x1100:
		return float(font_size)
	return max(4.0, float(font_size) * 0.56)

static func _strip_bbcode(text: String) -> String:
	var result = ""
	var inside_tag = false
	for index in range(text.length()):
		var character = text.substr(index, 1)
		if character == "[":
			inside_tag = true
			continue
		if character == "]" and inside_tag:
			inside_tag = false
			continue
		if not inside_tag:
			result += character
	return result

static func popup_layout_group(popup_type: String) -> String:
	if ["boss_package_ad", "popup_store", "first_purchase_package"].has(popup_type):
		return "purchase"
	if ["stock_broker_app", "stock_market", "interest_offer", "recurring_investment", "loan_offer"].has(popup_type):
		return "finance"
	if ["terms", "security_installer", "security_update_notice"].has(popup_type):
		return "policy"
	if ["sponsored_ad", "timed_reward", "clean_challenge", "volatile_popup"].has(popup_type):
		return "timed"
	if ["infection", "infected_popup"].has(popup_type):
		return "security"
	if ["system_notice", "moving_close"].has(popup_type):
		return "notice"
	return "standard"

static func popup_detail_scroll_enabled(popup_type: String) -> bool:
	return false

static func popup_body_scroll_enabled(popup_type: String) -> bool:
	return false

static func _popup_scroll_allowed(popup_type: String) -> bool:
	return popup_type == "terms"

static func popup_size_for_type(type: String) -> Vector2:
	match type:
		"terms":
			return Vector2(318, 218)
		"timed_reward":
			return Vector2(286, 168)
		"ad_buff", "sponsored_ad":
			return Vector2(300, 190)
		"infection":
			return Vector2(286, 168)
		"infected_popup":
			return Vector2(292, 150)
		"first_purchase_package":
			return Vector2(336, 236)
		"interest_offer":
			return Vector2(350, 250)
		"recurring_investment", "loan_offer", "stock_market":
			return Vector2(342, 230)
		"stock_broker_app":
			return Vector2(300, 260)
		"clean_challenge":
			return Vector2(320, 190)
		"volatile_popup":
			return Vector2(310, 178)
		"popup_store":
			return Vector2(326, 230)
		"boss_package_ad":
			return Vector2(440, 430)
		"system_notice":
			return Vector2(260, 120)
		"security_installer":
			return Vector2(330, 220)
		"security_update_notice":
			return Vector2(292, 150)
	return Vector2(252, 132)

static func _clamped_css_width(viewport_width: float, max_width: float, reserved_width: float, min_width: float) -> float:
	var available_max = min(max_width, max(120.0, viewport_width - CHOICE_MARGIN * 2.0))
	if available_max < min_width:
		return available_max
	return clamp(min(max_width, viewport_width - reserved_width), min_width, available_max)

static func _apply_rect(control, rect: Rect2) -> void:
	if control == null or not control is Control:
		return
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = round(rect.position.x)
	control.offset_top = round(rect.position.y)
	control.offset_right = round(rect.position.x + rect.size.x)
	control.offset_bottom = round(rect.position.y + rect.size.y)
	control.custom_minimum_size = Vector2.ZERO
	control.size = rect.size

static func _place_with_anchors(control: Control, horizontal_anchor: float, vertical_anchor: float, top_left_offsets: Vector2, bottom_right_offsets: Vector2) -> void:
	if control == null:
		return
	control.anchor_left = horizontal_anchor
	control.anchor_right = horizontal_anchor
	control.anchor_top = vertical_anchor
	control.anchor_bottom = vertical_anchor
	control.offset_left = round(top_left_offsets.x)
	control.offset_top = round(top_left_offsets.y)
	control.offset_right = round(bottom_right_offsets.x)
	control.offset_bottom = round(bottom_right_offsets.y)
	control.custom_minimum_size = Vector2.ZERO
	control.size = Vector2(abs(bottom_right_offsets.x - top_left_offsets.x), abs(bottom_right_offsets.y - top_left_offsets.y))

static func _resolved_height(control: Control, height: float) -> float:
	if height > 0.0:
		return height
	if control != null and control.custom_minimum_size.y > 0.0:
		return control.custom_minimum_size.y
	if control != null and control.size.y > 0.0:
		return control.size.y
	return 0.0

static func _apply_centered_rect(control, size: Vector2) -> void:
	if control == null or not control is Control:
		return
	control.anchor_left = 0.5
	control.anchor_top = 0.5
	control.anchor_right = 0.5
	control.anchor_bottom = 0.5
	control.offset_left = round(-size.x * 0.5)
	control.offset_top = round(-size.y * 0.5)
	control.offset_right = round(size.x * 0.5)
	control.offset_bottom = round(size.y * 0.5)
	control.custom_minimum_size = Vector2.ZERO
	control.size = size
