extends SceneTree

const PrototypeGameScript = preload("res://scripts/v2/prototype_game.gd")

var game
var started = false
var frames = 0
var result_path = "user://prototype_smoke_result.json"
var ad_passive_paid = false
var popup_store_expired = false
var timed_reward_paid = false
var sponsored_completion_without_starter_stack = false
var terms_heat_on_risk_applied = false
var credit_cashout_has_no_debt = false
var combat_form_variants_exercised = false
var build_scaling_variants_exercised = false
var module_synergy_effects_exercised = false
var purchase_damage_burst_applied = false
var popup_drag_multiplier_applied = false
var all_popup_definitions_createable = false
var popup_definition_create_count = 0
var all_items_apply_without_error = false
var item_definition_apply_count = 0
var key_item_dynamics_exercised = false
var boss_package_two_pick_flow_exercised = false
var crit_feedback_exercised = false
var popup_close_damage_exercised = false
var trash_zone_centered = false
var popup_placement_rules_exercised = false
var locked_close_system_notice_exercised = false
var security_install_feedback_exercised = false
var popup_close_reward_gated = false
var cursed_item_heat_rule_exercised = false
var choice_card_information_exercised = false
var hud_original_layout_exercised = false
var inventory_card_grid_exercised = false
var stock_popup_detail_panel_exercised = false
var popup_detail_controls_exercised = false
var reward_terms_controls_exercised = false
var special_popup_detail_exercised = false
var special_popup_detail_breakdown = {}
var hud_card_layout_exercised = false
var popup_placement_breakdown = {}
var debug_panel_layout_exercised = false
var mobile_layout_controls_exercised = false
var mobile_layout_breakdown = {}
var popup_status_badges_exercised = false
var popup_status_badge_breakdown = {}
var popup_telegraph_style_exercised = false
var popup_telegraph_style_breakdown = {}

func _initialize() -> void:
	game = PrototypeGameScript.new()
	root.add_child(game)
	process_frame.connect(_on_process_frame)

func _on_process_frame() -> void:
	if not started:
		if game.state.is_empty():
			return
		_start_scenario()
		started = true
		return
	frames += 1
	if frames < 180:
		return
	_finish_scenario()

func _start_scenario() -> void:
	game.apply_attack_module_choice("primary", game.data.ATTACK_MODULES[0])
	game.apply_attack_module_choice("secondary", game.data.ATTACK_MODULES[1])
	game.debug_action("gold100")
	game.debug_action("xp10")
	var first_purchase_popup = game.create_popup(game.popup_def_by_id("first_purchase_package"))
	game.state.firstPurchaseOfferShown = true
	game.complete_first_purchase_payment(first_purchase_popup.id)
	game.apply_first_purchase_package_choice(game.data.FIRST_PURCHASE_PACKAGES[3])
	game.debug_action("gold100")
	var interest_popup = game.create_popup(game.popup_def_by_id("interest_offer"))
	game.accept_interest_offer(interest_popup.id, 0.25)
	game.state.stats.adGoldPerSecond = 20.0
	game.state.stats.adGoldMultiplier = 0.5
	var ad_passive_before = game.state.gold
	var passive_ad = game.create_popup(game.popup_def_by_id("ad_buff"))
	passive_ad.inputGrace = 0.0
	game.update_ad_passive_income(1.0)
	ad_passive_paid = game.state.gold > ad_passive_before and game.state.adOpenTime >= 1.0
	var sponsored_popup = game.create_popup(game.popup_def_by_id("ad_premium_sample"))
	sponsored_popup.inputGrace = 0.0
	sponsored_popup.elapsed = game.timed_reward_duration(sponsored_popup.def)
	var sponsored_stack_before = game.state.sponsoredAttackBoostStacks
	var sponsored_completion_before = game.state.sponsoredCompletions
	game.update_special_popups(0.1)
	sponsored_completion_without_starter_stack = game.state.sponsoredCompletions == sponsored_completion_before + 1 and game.state.sponsoredAttackBoostStacks == sponsored_stack_before
	var timed_popup = game.create_popup(game.popup_def_by_id("timed_reward"))
	timed_popup.inputGrace = 0.0
	timed_popup.elapsed = game.timed_reward_duration(timed_popup.def)
	var timed_reward_before = game.state.gold
	game.update_special_popups(0.1)
	timed_reward_paid = game.state.gold >= timed_reward_before + int(game.popup_def_by_id("timed_reward").rewardGold)
	var store_popup = game.create_popup(game.popup_def_by_id("popup_store"))
	store_popup.inputGrace = 0.0
	store_popup.elapsed = float(store_popup.def.duration)
	game.update_special_popups(0.1)
	popup_store_expired = game.popup_by_id(store_popup.id) == null
	var terms_popup = game.create_popup(game.popup_def_by_id("terms_emergency_waiver"))
	terms_popup.inputGrace = 0.0
	var terms_heat_before = game.state.heat
	game.accept_terms_popup(terms_popup.id, true)
	terms_heat_on_risk_applied = is_equal_approx(game.state.heat, terms_heat_before + float(terms_popup.def.heatOnRisk))
	var loan_popup = game.create_popup(game.popup_def_by_id("loan_offer"))
	loan_popup.inputGrace = 0.0
	var debt_before = game.state.debtGold
	var credit_before = game.state.creditScore
	var loan_option = game.credit_cashout_options()[0]
	game.accept_credit_cashout(loan_popup.id, loan_option)
	credit_cashout_has_no_debt = game.state.debtGold == debt_before and game.state.creditScore == credit_before - int(loan_option.creditCost)
	var projectiles_before = game.state.projectiles.size()
	game.execute_ranged_bounce("primary", 8.0, 220.0)
	var bounce_runtime = game.state.projectiles.size() > projectiles_before and game.state.projectiles.back().get("bounceLeft", 0) > 0
	var attacks_before = game.state.attacks.size()
	game.execute_melee_dash_slash("primary", 12.0, 160.0)
	var dash_runtime = game.state.attacks.size() > attacks_before
	var absorb_enemy = game.spawn_enemy(false)
	absorb_enemy.position = game.state.player.position + Vector2(20, 0)
	absorb_enemy.hp = 1.0
	absorb_enemy.maxHP = 1.0
	var absorb_gold_before = game.state.gold
	game.execute_aura_absorb("primary", 10.0, 90.0)
	var absorb_runtime = game.state.gold > absorb_gold_before
	var mines_before = game.state.mines.size()
	game.execute_deploy_maturity_bomb("primary", 10.0, 100.0)
	var maturity_runtime = game.state.mines.size() > mines_before and game.state.mines.back().get("maturity", false)
	combat_form_variants_exercised = bounce_runtime and dash_runtime and absorb_runtime and maturity_runtime
	game.state.moduleUpgrades.primary.scaling = "generic_expanded_ballistics"
	var generic_ballistics_runtime = game.projectile_extra_targets_bonus("primary") == 1 and game.beam_width_bonus("primary") >= 4.0
	game.state.moduleUpgrades.primary.scaling = "cleanup_combo_precision"
	game.state.cleanupComboValue = 3
	game.state.cleanupComboTimer = 4.0
	var cleanup_scaling_runtime = game.dynamic_cooldown_bonus("primary") < 0.0 and game.dynamic_range_bonus("primary") > 0.0
	game.state.moduleUpgrades.primary.scaling = "risk_liability_waiver"
	game.state.player.hp = game.state.player.maxHP * 0.3
	game.state.termsPenaltyCount = max(2, game.state.termsPenaltyCount)
	var risk_scaling_runtime = game.scaling_damage_bonus("primary") > 0.0 and game.dynamic_range_bonus("primary") > 0.0
	build_scaling_variants_exercised = generic_ballistics_runtime and cleanup_scaling_runtime and risk_scaling_runtime
	game.state.moduleSynergy = {"id": "secondary_haste", "name": "보조 적중 가속"}
	game.state.moduleTimers.primary = 1.0
	var haste_enemy = game.spawn_enemy(false)
	haste_enemy.position = game.state.player.position + Vector2(24, 0)
	haste_enemy.hp = 20.0
	haste_enemy.maxHP = 20.0
	game.damage_enemy_tracked(haste_enemy, 1.0, "secondary")
	var haste_runtime = game.state.moduleTimers.primary < 1.0
	game.state.moduleSynergy = {"id": "primary_charge", "name": "처치 충전"}
	game.state.moduleTimers.secondary = 5.0
	var charge_enemy = game.spawn_enemy(false)
	charge_enemy.position = game.state.player.position + Vector2(26, 0)
	charge_enemy.hp = 1.0
	charge_enemy.maxHP = 1.0
	game.damage_enemy_tracked(charge_enemy, 10.0, "primary")
	var charge_runtime = is_equal_approx(float(game.state.moduleTimers.secondary), 0.0)
	module_synergy_effects_exercised = haste_runtime and charge_runtime
	crit_feedback_exercised = _verify_crit_feedback()
	popup_close_damage_exercised = _verify_popup_close_damage()
	trash_zone_centered = _verify_trash_zone_centered()
	popup_placement_rules_exercised = _verify_popup_placement_rules()
	locked_close_system_notice_exercised = _verify_locked_close_system_notice()
	security_install_feedback_exercised = _verify_security_install_feedback()
	popup_close_reward_gated = _verify_popup_close_reward_gated()
	cursed_item_heat_rule_exercised = _verify_cursed_item_heat_rule()
	choice_card_information_exercised = _verify_choice_card_information()
	hud_original_layout_exercised = _verify_hud_original_layout()
	inventory_card_grid_exercised = _verify_inventory_card_grid()
	stock_popup_detail_panel_exercised = _verify_stock_popup_detail_panel()
	popup_detail_controls_exercised = _verify_popup_detail_controls()
	reward_terms_controls_exercised = _verify_reward_terms_controls()
	special_popup_detail_exercised = _verify_special_popup_detail()
	hud_card_layout_exercised = _verify_hud_card_layout()
	debug_panel_layout_exercised = _verify_debug_panel_layout()
	mobile_layout_controls_exercised = _verify_mobile_layout_controls()
	popup_status_badges_exercised = _verify_popup_status_badges()
	popup_telegraph_style_exercised = _verify_popup_telegraph_style()
	game.state.stats.purchaseDamageBurst = 0.15
	var timed_effects_before = game.state.timedEffects.size()
	game.apply_item_choice(game.data.ITEMS[0])
	purchase_damage_burst_applied = game.state.timedEffects.size() > timed_effects_before and game.state.timedEffects.any(func(effect): return effect.stat == "damageMultiplier" and is_equal_approx(float(effect.value), 0.15))
	var drag_multiplier_before = game.popup_drag_multiplier()
	game.apply_effect({"stat": "popupDragSpeedMultiplier", "value": -0.25})
	popup_drag_multiplier_applied = game.popup_drag_multiplier() < drag_multiplier_before and is_equal_approx(game.popup_drag_multiplier(), 0.75)
	all_popup_definitions_createable = _verify_all_popup_definitions_createable()
	game.debug_action("installKeyboardSecurity")
	game.debug_action("installPopupQuarantine")
	for program in game.state.residentPrograms:
		if program.type == "keyboard_security":
			program.angle = 0.0
			program.attackTimer = 0.05
		if program.type == "popup_quarantine":
			program.quarantineTimer = 10.0
	var security_enemy = game.spawn_enemy(false)
	security_enemy.position = game.state.player.position + Vector2(52, 0)
	security_enemy.hp = 3.0
	security_enemy.maxHP = 3.0
	var stock_popup = game.create_popup(game.popup_def_by_id("stock_momentum"))
	game.invest_stock_popup(stock_popup.id, 50)
	var infection_target = game.create_popup(game.popup_def_by_id("timed_reward"))
	infection_target.inputGrace = 0.0
	var infection_popup = game.create_popup(game.popup_def_by_id("infection"))
	infection_popup.inputGrace = 0.0
	infection_popup.infectionDuration = 0.05
	game.schedule_popup_spawn(game.popup_def_by_id("moving_close"))
	game.state.player.hp = 50.0
	game.apply_effect({"stat": "instantHeal", "value": 12})
	game.apply_effect({"stat": "gold", "value": 7})
	game.apply_effect({"stat": "heat", "value": 1})
	game.apply_effect({"stat": "delayedMaxHPLoss", "value": 4, "delay": 0.05})
	game.state.paused = false

func _finish_scenario() -> void:
	for popup in game.state.openPopups.duplicate():
		if popup.def.type == "stock_market" and popup.has("stock") and popup.stock.get("invested", false):
			game.sell_stock_popup(popup.id)
			break
	for popup in game.state.openPopups.duplicate():
		if popup.def.type == "interest_offer" and popup.get("interestAccepted", false):
			game.cancel_interest_offer(popup.id)
			break
	var quarantine_probe = game.create_popup(game.popup_def_by_id("moving_close"))
	quarantine_probe.inputGrace = 0.0
	game.start_security_quarantine(quarantine_probe)
	game.update_security_quarantines(1.3)
	var quarantine_removed = game.popup_by_id(quarantine_probe.id) == null
	boss_package_two_pick_flow_exercised = _verify_boss_package_two_pick_flow()
	all_items_apply_without_error = _verify_all_items_apply_without_error()
	key_item_dynamics_exercised = _verify_key_item_dynamics()
	var result = {
		"frames": frames,
		"has_primary_module": game.state.primaryModule != "",
		"active_playstyle": game.state.activePlaystyle,
		"first_purchase_paid": game.state.firstPurchasePaid,
		"enemy_count": game.state.enemies.size(),
		"popup_count": game.state.openPopups.size(),
		"pending_popup_count": game.state.pendingPopupSpawns.size(),
		"gold": game.state.gold,
		"heat": game.state.heat,
		"hp": game.state.player.hp,
		"max_hp": game.state.player.maxHP,
		"level": game.state.level,
		"security_count": game.state.residentPrograms.size(),
		"kill_count": game.state.killCount,
		"quarantine_removed": quarantine_removed,
		"stock_price": game.state.stockMarket.stock.price,
		"stock_broker_shares": game.state.stockMarket.stock.shares,
		"invested_gold": game.state.investedGold,
		"ad_passive_paid": ad_passive_paid,
		"ad_open_time": game.state.adOpenTime,
		"passive_gold_earned": game.state.metrics.passiveGoldEarned,
		"popup_store_expired": popup_store_expired,
		"timed_reward_paid": timed_reward_paid,
		"sponsored_completion_without_starter_stack": sponsored_completion_without_starter_stack,
		"sponsored_completions": game.state.sponsoredCompletions,
		"sponsored_stacks": game.state.sponsoredAttackBoostStacks,
		"terms_heat_on_risk_applied": terms_heat_on_risk_applied,
		"credit_cashout_has_no_debt": credit_cashout_has_no_debt,
		"debt_gold": game.state.debtGold,
		"combat_form_variants_exercised": combat_form_variants_exercised,
		"build_scaling_variants_exercised": build_scaling_variants_exercised,
		"module_synergy_effects_exercised": module_synergy_effects_exercised,
		"purchase_damage_burst_applied": purchase_damage_burst_applied,
		"popup_drag_multiplier_applied": popup_drag_multiplier_applied,
		"all_popup_definitions_createable": all_popup_definitions_createable,
		"popup_definition_create_count": popup_definition_create_count,
		"all_items_apply_without_error": all_items_apply_without_error,
		"item_definition_apply_count": item_definition_apply_count,
		"key_item_dynamics_exercised": key_item_dynamics_exercised,
		"boss_package_two_pick_flow_exercised": boss_package_two_pick_flow_exercised,
		"crit_feedback_exercised": crit_feedback_exercised,
		"popup_close_damage_exercised": popup_close_damage_exercised,
		"trash_zone_centered": trash_zone_centered,
		"popup_placement_rules_exercised": popup_placement_rules_exercised,
		"popup_placement_breakdown": popup_placement_breakdown,
		"locked_close_system_notice_exercised": locked_close_system_notice_exercised,
		"security_install_feedback_exercised": security_install_feedback_exercised,
		"popup_close_reward_gated": popup_close_reward_gated,
		"cursed_item_heat_rule_exercised": cursed_item_heat_rule_exercised,
		"choice_card_information_exercised": choice_card_information_exercised,
		"hud_original_layout_exercised": hud_original_layout_exercised,
		"inventory_card_grid_exercised": inventory_card_grid_exercised,
		"stock_popup_detail_panel_exercised": stock_popup_detail_panel_exercised,
		"popup_detail_controls_exercised": popup_detail_controls_exercised,
		"reward_terms_controls_exercised": reward_terms_controls_exercised,
		"special_popup_detail_exercised": special_popup_detail_exercised,
		"special_popup_detail_breakdown": special_popup_detail_breakdown,
		"hud_card_layout_exercised": hud_card_layout_exercised,
		"debug_panel_layout_exercised": debug_panel_layout_exercised,
		"mobile_layout_controls_exercised": mobile_layout_controls_exercised,
		"mobile_layout_breakdown": mobile_layout_breakdown,
		"popup_status_badges_exercised": popup_status_badges_exercised,
		"popup_status_badge_breakdown": popup_status_badge_breakdown,
		"popup_telegraph_style_exercised": popup_telegraph_style_exercised,
		"popup_telegraph_style_breakdown": popup_telegraph_style_breakdown,
		"interest_accepted": game.state.metrics.interestAccepted,
		"interest_lost": game.state.metrics.interestLost,
		"infected_popup_count": game.state.openPopups.filter(func(popup): return popup.def.type == "infected_popup").size(),
		"popup_types": game.state.openPopups.map(func(popup): return popup.def.type),
		"has_hud": game.hud != null,
		"has_popup_layer": game.popup_layer != null,
	}
	var file = FileAccess.open(result_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	quit()

func _verify_all_popup_definitions_createable() -> bool:
	var created = 0
	for def in game.data.POPUP_DEFINITIONS:
		var popup = game.create_popup(def)
		if popup.is_empty() or popup.def.get("id", "") != def.get("id", ""):
			return false
		created += 1
		game.remove_popup_without_reward(popup.id)
	popup_definition_create_count = created
	return created == game.data.POPUP_DEFINITIONS.size()

func _verify_boss_package_two_pick_flow() -> bool:
	var popup = game.create_popup(game.popup_def_by_id("boss_package_ad"))
	if popup == null or popup.get("packageItems", []).size() < 2:
		return false
	var item_a = popup.packageItems[0]
	var item_b = popup.packageItems[1]
	var before_a = game.owned_item_count(item_a.id)
	var before_b = game.owned_item_count(item_b.id)
	var before_metric = int(game.state.metrics.bossPackagesPurchased)
	var before_count = int(game.state.bossPackageCount)
	game.state.gold += int(popup.packageCost)
	game.purchase_boss_package(popup.id)
	var purchase_opened_selection = game.state.selectingPaidReward and game.state.selectingItem and int(game.state.metrics.bossPackagesPurchased) == before_metric and game.state.pendingBossPackage.get("selectedIds", []).is_empty()
	game.toggle_boss_package_selection(item_a)
	var one_pick_waits = game.state.selectingPaidReward and game.owned_item_count(item_a.id) == before_a and game.state.pendingBossPackage.get("selectedIds", []).size() == 1
	game.toggle_boss_package_selection(item_b)
	var completed = not game.state.selectingPaidReward and game.state.pendingBossPackage.is_empty()
	var items_applied = game.owned_item_count(item_a.id) == before_a + 1 and game.owned_item_count(item_b.id) == before_b + 1
	var metric_updated = int(game.state.metrics.bossPackagesPurchased) == before_metric + 1 and int(game.state.bossPackageCount) == before_count + 1
	return purchase_opened_selection and one_pick_waits and completed and items_applied and metric_updated

func _verify_crit_feedback() -> bool:
	var saved_chance = game.state.stats.critChance
	var saved_crit_damage = game.state.stats.critDamageMultiplier
	game.state.stats.critChance = 1.0
	game.state.stats.critDamageMultiplier = 0.5
	var text_ok = false
	var color_ok = false
	var damage_ok = false
	for attempt in range(12):
		var enemy = game.spawn_enemy(false)
		enemy.position = game.state.player.position + Vector2(30 + attempt, 0)
		enemy.hp = 1000.0
		enemy.maxHP = 1000.0
		var before_count = game.state.floatTexts.size()
		game.damage_enemy_tracked(enemy, 10.0, "primary")
		var text_added = game.state.floatTexts.size() > before_count
		var latest = game.state.floatTexts.back() if text_added else {}
		if text_added and str(latest.get("text", "")).ends_with("!"):
			text_ok = true
			color_ok = Color(latest.get("color", Color.WHITE)).is_equal_approx(Color("#ffe86e"))
			damage_ok = is_equal_approx(float(enemy.hp), 985.0)
			if game.state.enemies.has(enemy):
				game.state.enemies.erase(enemy)
			break
		if game.state.enemies.has(enemy):
			game.state.enemies.erase(enemy)
	game.state.stats.critChance = saved_chance
	game.state.stats.critDamageMultiplier = saved_crit_damage
	return text_ok and color_ok and damage_ok

func _verify_popup_close_damage() -> bool:
	var saved_damage = game.state.stats.popupCloseDamage
	var saved_crit = game.state.stats.critChance
	game.state.stats.popupCloseDamage = 15.0
	game.state.stats.critChance = 1.0
	var near_enemy = game.spawn_enemy(false)
	near_enemy.position = game.state.player.position + Vector2(140, 0)
	near_enemy.hp = 100.0
	near_enemy.maxHP = 100.0
	var far_enemy = game.spawn_enemy(false)
	far_enemy.position = game.state.player.position + Vector2(150, 0)
	far_enemy.hp = 100.0
	far_enemy.maxHP = 100.0
	var popup = game.create_popup(game.popup_def_by_id("moving_close"))
	popup.inputGrace = 0.0
	game.request_close_popup(popup.id, {"reason": "button"})
	var near_ok = is_equal_approx(float(near_enemy.hp), 85.0)
	var far_ok = is_equal_approx(float(far_enemy.hp), 100.0)
	game.state.stats.popupCloseDamage = saved_damage
	game.state.stats.critChance = saved_crit
	if game.state.enemies.has(near_enemy):
		game.state.enemies.erase(near_enemy)
	if game.state.enemies.has(far_enemy):
		game.state.enemies.erase(far_enemy)
	return near_ok and far_ok

func _verify_trash_zone_centered() -> bool:
	var viewport = game.get_viewport().get_visible_rect().size
	var rect = game.trash_zone_rect()
	return is_equal_approx(rect.size.x, 160.0) and is_equal_approx(rect.size.y, 58.0) and is_equal_approx(rect.position.x + rect.size.x * 0.5, viewport.x * 0.5) and is_equal_approx(rect.position.y + rect.size.y, viewport.y - 14.0)

func _verify_popup_placement_rules() -> bool:
	var saved_open = game.state.openPopups.duplicate(true)
	var saved_pending = game.state.pendingPopupSpawns.duplicate(true)
	game.state.openPopups = []
	game.state.pendingPopupSpawns = []
	var defs = [
		game.popup_def_by_id("timed_reward"),
		game.popup_def_by_id("ad_buff"),
		game.popup_def_by_id("moving_close"),
	]
	for def in defs:
		var popup = game.create_popup(def)
		popup.inputGrace = 0.0
	var viewport = game.get_viewport().get_visible_rect().size
	var avoid_rects = game.hud_avoid_rects(viewport)
	var ok = true
	var failures = []
	for popup in game.state.openPopups:
		var rect = Rect2(popup.position, popup.size)
		if rect.position.x < 4.0 or rect.position.y < 4.0 or rect.position.x + rect.size.x > viewport.x - 4.0 or rect.position.y + rect.size.y > viewport.y - 4.0:
			ok = false
			failures.append("%s bounds %s" % [popup.def.id, rect])
			break
		if avoid_rects.any(func(avoid): return rect.intersects(avoid)):
			ok = false
			failures.append("%s hud %s" % [popup.def.id, rect])
			break
		if game.popup_overlap_conflict(rect, int(popup.id)) != null:
			ok = false
			failures.append("%s overlap %s" % [popup.def.id, rect])
			break
	popup_placement_breakdown = {
		"ok": ok,
		"failures": failures,
		"positions": game.state.openPopups.map(func(popup): return "%s %s %s" % [popup.def.id, popup.position, popup.size]),
	}
	game.state.openPopups = saved_open
	game.state.pendingPopupSpawns = saved_pending
	return ok

func _verify_locked_close_system_notice() -> bool:
	var stock_popup = null
	for popup in game.state.openPopups:
		if popup.def.type == "stock_broker_app":
			stock_popup = popup
			break
	if stock_popup == null:
		stock_popup = game.create_popup(game.popup_def_by_id("stock_broker_app"))
	var before_notices = game.state.openPopups.filter(func(popup): return popup.def.type == "system_notice").size()
	game.request_close_popup(stock_popup.id, {"reason": "button"})
	var notices = game.state.openPopups.filter(func(popup): return popup.def.type == "system_notice")
	var created = notices.size() == before_notices + 1
	if not created:
		return false
	var notice = notices.back()
	var text_ok = notice.def.get("body", "").find("증권 앱은 닫을 수 없습니다") >= 0
	notice.elapsed = 3.5
	game.update_special_popups(0.1)
	var auto_closed = game.popup_by_id(notice.id) == null
	return text_ok and auto_closed

func _verify_security_install_feedback() -> bool:
	var saved_gold = game.state.gold
	var saved_programs = game.state.residentPrograms.duplicate(true)
	var saved_reserved = game.state.reservedMaxHP
	var saved_max_hp = game.state.player.maxHP
	var saved_hp = game.state.player.hp
	var saved_open = game.state.openPopups.duplicate(true)
	var saved_heat = game.state.heat
	var saved_playstyle = game.state.activePlaystyle

	game.state.gold = 0
	var fail_ok = not game.install_resident_program("realtime_guard", 0, false)
	var fail_notice = game.state.openPopups.any(func(popup): return popup.def.type == "system_notice" and popup.def.get("body", "").find("설치 비용이 부족") >= 0)
	game.state.gold = int(game.security_program_def("realtime_guard").installCost)
	var installed_ok = game.install_resident_program("realtime_guard", 0, false)
	var success_notice = game.state.openPopups.any(func(popup): return popup.def.type == "system_notice" and popup.def.get("body", "").find("상주 프로그램이 활성화") >= 0)
	var duplicate_ok = not game.install_resident_program("realtime_guard", 0, false)
	var duplicate_notice = game.state.openPopups.any(func(popup): return popup.def.type == "system_notice" and popup.def.get("body", "").find("이미 설치된 보안 프로그램") >= 0)
	game.state.activePlaystyle = "risky_terms_starter"
	game.state.gold = int(game.security_program_def("kernel_guard").installCost)
	var heat_before = game.state.heat
	var kernel_ok = game.install_resident_program("kernel_guard", 0, false)
	var kernel_program = game.installed_resident_program("kernel_guard")
	var kernel_boost_ok = kernel_ok and kernel_program != null and is_equal_approx(float(kernel_program.get("damageBoost", 1.0)), 1.25) and is_equal_approx(game.state.heat, heat_before + 1.0)

	game.state.gold = saved_gold
	game.state.residentPrograms = saved_programs
	game.state.reservedMaxHP = saved_reserved
	game.state.player.maxHP = saved_max_hp
	game.state.player.hp = saved_hp
	game.state.openPopups = saved_open
	game.state.heat = saved_heat
	game.state.activePlaystyle = saved_playstyle
	return fail_ok and fail_notice and installed_ok and success_notice and duplicate_ok and duplicate_notice and kernel_boost_ok

func _verify_popup_close_reward_gated() -> bool:
	var saved_gold = game.state.gold
	var saved_close_gold = game.state.stats.goldPerPopupClose
	var saved_close_damage = game.state.stats.popupCloseDamage
	var saved_combo_stacks = game.state.cleanupComboStacks
	var saved_combo_value = game.state.cleanupComboValue
	var saved_combo_timer = game.state.cleanupComboTimer
	game.state.gold = 0
	game.state.stats.goldPerPopupClose = 7
	game.state.stats.popupCloseDamage = 15.0
	var enemy = game.spawn_enemy(false)
	enemy.position = game.state.player.position + Vector2(80, 0)
	enemy.hp = 100.0
	enemy.maxHP = 100.0
	var popup = game.create_popup(game.popup_def_by_id("timed_reward"))
	popup.inputGrace = 0.0
	game.request_close_popup(popup.id, {"reason": "timed_complete"})
	var no_reward = game.state.gold == 0 and is_equal_approx(float(enemy.hp), 100.0) and game.state.cleanupComboValue == saved_combo_value
	var button_popup = game.create_popup(game.popup_def_by_id("timed_reward"))
	button_popup.inputGrace = 0.0
	game.request_close_popup(button_popup.id, {"reason": "button"})
	var manual_reward = game.state.gold == 7 and is_equal_approx(float(enemy.hp), 85.0) and game.state.cleanupComboValue > saved_combo_value
	game.state.gold = saved_gold
	game.state.stats.goldPerPopupClose = saved_close_gold
	game.state.stats.popupCloseDamage = saved_close_damage
	game.state.cleanupComboStacks = saved_combo_stacks
	game.state.cleanupComboValue = saved_combo_value
	game.state.cleanupComboTimer = saved_combo_timer
	if game.state.enemies.has(enemy):
		game.state.enemies.erase(enemy)
	return no_reward and manual_reward

func _verify_cursed_item_heat_rule() -> bool:
	var saved_heat = game.state.heat
	var saved_gold = game.state.gold
	var saved_hp = game.state.player.hp
	var saved_max_hp = game.state.player.maxHP
	var saved_counts = game.state.itemCounts.duplicate(true)
	var cursed_no_heat = game.data.ITEMS.filter(func(item): return item.id == "cursed_cache")[0]
	var cursed_with_heat = game.data.ITEMS.filter(func(item): return item.id == "cursed_transfusion")[0]
	game.state.heat = 0.0
	game.apply_item_reward(cursed_no_heat)
	var no_heat_rule_ok = is_equal_approx(game.state.heat, 1.0)
	game.state.heat = 0.0
	game.apply_item_reward(cursed_with_heat)
	var explicit_heat_ok = is_equal_approx(game.state.heat, 1.0)
	game.state.heat = saved_heat
	game.state.gold = saved_gold
	game.state.player.hp = saved_hp
	game.state.player.maxHP = saved_max_hp
	game.state.itemCounts = saved_counts
	return no_heat_rule_ok and explicit_heat_ok

func _verify_choice_card_information() -> bool:
	var item = game.data.ITEMS.filter(func(candidate): return candidate.id == "damage_up")[0]
	game.hud.show_choices("검증", "카드 정보 검증", [item], func(_choice): pass, 1)
	if game.hud.ui.choiceGrid.get_child_count() == 0:
		return false
	var item_card = game.hud.ui.choiceGrid.get_child(0)
	var text = _node_text_tree(item_card)
	var item_ok = item_card is Button and item_card.name == "itemChoice" and _find_node_named(item_card, "rarityBadge") != null and _find_node_named(item_card, "itemTags") != null and _find_node_named(item_card, "choiceMeta") != null and text.find("COMMON") >= 0 and text.find("현재:") >= 0 and text.find("선택 후:") >= 0
	var module = game.data.ATTACK_MODULES[0]
	game.hud.show_choices("검증", "모듈 카드 검증", [module], func(_choice): pass, 1)
	var module_card = game.hud.ui.choiceGrid.get_child(0)
	var module_text = _node_text_tree(module_card)
	var module_ok = module_card is Button and module_card.name == "moduleChoice" and _find_node_named(module_card, "choiceTitleText") != null and _find_node_named(module_card, "choiceMeta") != null and module_text.find("기본 피해") >= 0 and module_text.find("쿨타임") >= 0 and module_text.find("범위") >= 0
	game.hud.hide_choices()
	return item_ok and module_ok

func _verify_hud_original_layout() -> bool:
	var saved_playstyle = game.state.activePlaystyle
	var saved_playstyle_name = game.state.activePlaystyleName
	var saved_heat = game.state.heat
	var saved_elapsed = game.state.elapsed
	var saved_pulse = game.state.difficultyPulseTimer
	var saved_status_minimized = game.hud.status_minimized

	game.state.activePlaystyle = ""
	game.state.activePlaystyleName = "미선택"
	game.hud.update_from_state(game.state)
	var investor_hidden_ok = not game.hud.ui.investorDashboard.visible

	game.state.activePlaystyle = "investor_starter"
	game.state.activePlaystyleName = "투자자 스타터 계약"
	game.hud.update_from_state(game.state)
	var investor_visible_ok = game.hud.ui.investorDashboard.visible

	game.state.heat = 100.0
	game.state.elapsed = 0.0
	game.state.difficultyPulseTimer = 1.0
	game.hud.update_from_state(game.state)
	var fill = game.hud.ui.difficultyBar.get_theme_stylebox("fill") as StyleBoxFlat
	var difficulty_color_ok = fill != null and _color_close(fill.bg_color, Color("#ff4fd8")) and game.hud.ui.difficultyHud.scale.x > 1.0

	if game.hud.status_minimized:
		game.hud._toggle_status()
	game.hud._toggle_status()
	var minimized_ok = game.hud.status_minimized and not game.hud.ui.statusBody.visible and game.hud.ui.statusToggleButton.text == "+" and is_equal_approx(game.hud.ui.statusPanel.offset_top, -52.0)
	game.hud._toggle_status()
	var expanded_ok = not game.hud.status_minimized and game.hud.ui.statusBody.visible and game.hud.ui.statusToggleButton.text == "-" and is_equal_approx(game.hud.ui.statusPanel.offset_top, -148.0)

	if game.hud.status_minimized != saved_status_minimized:
		game.hud._toggle_status()
	game.state.activePlaystyle = saved_playstyle
	game.state.activePlaystyleName = saved_playstyle_name
	game.state.heat = saved_heat
	game.state.elapsed = saved_elapsed
	game.state.difficultyPulseTimer = saved_pulse
	game.hud.update_from_state(game.state)

	return investor_hidden_ok and investor_visible_ok and difficulty_color_ok and minimized_ok and expanded_ok

func _verify_hud_card_layout() -> bool:
	var saved_hp = game.state.player.hp
	var saved_max_hp = game.state.player.maxHP
	var saved_level = game.state.level
	var saved_xp = game.state.xp
	var saved_xp_need = game.state.xpNeed
	var saved_gold = game.state.gold
	var saved_primary_mastery = game.state.primaryMastery
	var saved_secondary_mastery = game.state.secondaryMastery
	var saved_playstyle = game.state.activePlaystyle
	var saved_playstyle_name = game.state.activePlaystyleName
	var saved_invested = game.state.investedGold
	var saved_credit = game.state.creditScore
	var saved_programs = game.state.residentPrograms.duplicate(true)
	var saved_reserved_hp = game.state.reservedMaxHP
	var saved_stock = game.state.stockMarket.stock.duplicate(true)
	game.state.player.hp = 88.0
	game.state.player.maxHP = 120.0
	game.state.level = 4
	game.state.xp = 17
	game.state.xpNeed = 80
	game.state.gold = 321
	game.state.primaryMastery = 3
	game.state.secondaryMastery = 2
	game.state.activePlaystyle = "investor_starter"
	game.state.activePlaystyleName = "투자자 스타터 계약"
	game.state.investedGold = 150
	game.state.creditScore = 82
	game.state.stockMarket.stock.price = 120.0
	game.state.stockMarket.stock.shares = 2
	game.state.stockMarket.stock.avgCost = 95.0
	game.state.stockMarket.lastBiasLabel = "검증 강세"
	var program_def = game.security_program_def("keyboard_security")
	game.state.residentPrograms = [game.make_resident_program(program_def)]
	game.state.residentPrograms[0].updateTimer = 12.0
	game.state.reservedMaxHP = 0
	game.hud.update_from_state(game.state)
	var hp_card_ok = ui_parent_chain_has_class(game.hud.ui.hpText, "PanelContainer") and game.hud.ui.hpText.text == "88 / 120"
	var xp_card_ok = ui_parent_chain_has_class(game.hud.ui.xpText, "PanelContainer") and game.hud.ui.levelText.text == "4" and game.hud.ui.xpText.text == "17 / 80"
	var module_meta_ok = game.hud.ui.moduleMeta is GridContainer and game.hud.ui.moduleMeta.get_child_count() == 4 and game.hud.ui.primaryMasteryText.text.find("1차 숙련 3") >= 0 and game.hud.ui.popupCountText.text.find("팝업") >= 0
	var gold_ok = game.hud.ui.goldText.text == "321G" and game.hud.ui.goldText.text.find("골드") < 0
	var investor_text = _node_text_tree(game.hud.ui.investorDashboard)
	var investor_ok = game.hud.ui.investorDashboard.visible and investor_text.find("투자자 터미널") >= 0 and investor_text.find("신용 82") >= 0 and investor_text.find("주식 평가") >= 0 and investor_text.find("검증 강세") >= 0
	var resident_text = _node_text_tree(game.hud.ui.residentProgramHud)
	var resident_ok = resident_text.find("보안 프로그램") >= 0 and resident_text.find("1") >= 0 and resident_text.find("활성") >= 0 and resident_text.find("업데이트") >= 0
	game.state.player.hp = saved_hp
	game.state.player.maxHP = saved_max_hp
	game.state.level = saved_level
	game.state.xp = saved_xp
	game.state.xpNeed = saved_xp_need
	game.state.gold = saved_gold
	game.state.primaryMastery = saved_primary_mastery
	game.state.secondaryMastery = saved_secondary_mastery
	game.state.activePlaystyle = saved_playstyle
	game.state.activePlaystyleName = saved_playstyle_name
	game.state.investedGold = saved_invested
	game.state.creditScore = saved_credit
	game.state.residentPrograms = saved_programs
	game.state.reservedMaxHP = saved_reserved_hp
	game.state.stockMarket.stock = saved_stock
	game.hud.update_from_state(game.state)
	return hp_card_ok and xp_card_ok and module_meta_ok and gold_ok and investor_ok and resident_ok

func _verify_debug_panel_layout() -> bool:
	if not game.hud.ui.debugBody.visible:
		game.hud._toggle_debug()
	game.hud.update_from_state(game.state)
	var expanded_text = str(game.hud.ui.debugStats.text)
	var text_ok = expanded_text.find("성능: FPS") >= 0 and expanded_text.find("현재 가격:") >= 0 and expanded_text.find("투자금·주식 평가") >= 0 and expanded_text.find("팝업 생성 배율") >= 0
	game.hud._toggle_debug()
	var collapsed_ok = not game.hud.ui.debugBody.visible and game.hud.ui.debugToggleButton.text == "+" and is_equal_approx(game.hud.ui.debugPanel.offset_left, -144.0) and is_equal_approx(game.hud.ui.debugPanel.offset_top, -54.0)
	game.hud._toggle_debug()
	var expanded_ok = game.hud.ui.debugBody.visible and game.hud.ui.debugToggleButton.text == "-" and is_equal_approx(game.hud.ui.debugPanel.offset_left, -262.0) and is_equal_approx(game.hud.ui.debugPanel.offset_top, -420.0)
	return text_ok and collapsed_ok and expanded_ok

func _verify_mobile_layout_controls() -> bool:
	var saved_mobile_input = game.state.mobileInput.duplicate(true)
	var saved_emergency_timer = game.state.emergencyTimer
	var saved_selecting_item = game.state.selectingItem
	var saved_selecting_perk = game.state.selectingPerk
	var saved_selecting_module = game.state.selectingModule
	var saved_game_over = game.state.gameOver

	game.state.selectingItem = false
	game.state.selectingPerk = false
	game.state.selectingModule = false
	game.state.gameOver = false
	game.state.emergencyTimer = 2.4
	game.hud._update_mobile_button_state(game.state)
	game.hud._apply_mobile_layout(Vector2(640, 900))
	var portrait_ok = game.hud.ui.mobileControls.visible and game.hud.ui.orientationPrompt.visible and game.hud.ui.mobileFullscreenButton.anchor_left == 0.5 and is_equal_approx(game.hud.ui.mobileFullscreenButton.offset_top, 8.0) and game.hud.ui.mobileEmergencyButton.disabled and game.hud.ui.mobileEmergencyButton.text.find("대기") >= 0
	var inactive_joystick_ok = game.hud.ui.mobileJoystick.visible and game.hud.ui.mobileJoystick.modulate.a < 0.05 and is_equal_approx(game.hud.ui.mobileJoystick.custom_minimum_size.x, 92.0)

	game.hud._start_floating_joystick(7, Vector2(24, 800), Vector2(640, 900))
	var active_rect = Rect2(Vector2(game.hud.ui.mobileJoystick.offset_left, game.hud.ui.mobileJoystick.offset_top), Vector2(game.hud.ui.mobileJoystick.offset_right - game.hud.ui.mobileJoystick.offset_left, game.hud.ui.mobileJoystick.offset_bottom - game.hud.ui.mobileJoystick.offset_top))
	var start_ok = game.state.mobileInput.get("active", false) and int(game.state.mobileInput.get("pointerId", -1)) == 7 and game.hud.ui.mobileJoystick.modulate.a > 0.95 and active_rect.position.x >= 4.0 and active_rect.position.y >= 4.0
	game.hud._update_floating_joystick(Vector2(120, 800))
	var drag_ok = float(game.state.mobileInput.get("x", 0.0)) > 0.25 and abs(float(game.state.mobileInput.get("y", 0.0))) < 0.1
	game.hud._finish_floating_joystick()
	var finish_ok = not game.state.mobileInput.get("active", false) and int(game.state.mobileInput.get("pointerId", -1)) == -1 and game.hud.ui.mobileJoystick.modulate.a < 0.05 and is_equal_approx(float(game.state.mobileInput.get("x", 1.0)), 0.0)

	game.state.emergencyTimer = 0.0
	game.hud._update_mobile_button_state(game.state)
	game.hud._apply_mobile_layout(Vector2(820, 480))
	var landscape_ok = game.hud.ui.mobileControls.visible and not game.hud.ui.orientationPrompt.visible and is_equal_approx(game.hud.ui.mobileJoystick.custom_minimum_size.x, 86.0) and game.hud.ui.mobileEmergencyButton.text == "긴급 닫기"
	game.hud._apply_mobile_layout(Vector2(1100, 700))
	var hidden_ok = not game.hud.ui.mobileControls.visible

	mobile_layout_breakdown = {
		"portrait_ok": portrait_ok,
		"inactive_joystick_ok": inactive_joystick_ok,
		"start_ok": start_ok,
		"drag_ok": drag_ok,
		"finish_ok": finish_ok,
		"landscape_ok": landscape_ok,
		"hidden_ok": hidden_ok,
	}

	game.state.mobileInput = saved_mobile_input
	game.state.emergencyTimer = saved_emergency_timer
	game.state.selectingItem = saved_selecting_item
	game.state.selectingPerk = saved_selecting_perk
	game.state.selectingModule = saved_selecting_module
	game.state.gameOver = saved_game_over
	game.hud.update_from_state(game.state)
	return portrait_ok and inactive_joystick_ok and start_ok and drag_ok and finish_ok and landscape_ok and hidden_ok

func _verify_popup_status_badges() -> bool:
	var target = game.create_popup(game.popup_def_by_id("timed_reward"))
	target.inputGrace = 1.2
	target.infectedByPopup = true
	var lock = game.create_popup(game.popup_def_by_id("stock_broker_app"))
	var quarantine = game.create_popup(game.popup_def_by_id("moving_close"))
	quarantine.securityQuarantineTimer = 2.5
	game.popup_layer.sync(game.state)

	var target_record = game.popup_layer.windows.get(int(target.id), null)
	var lock_record = game.popup_layer.windows.get(int(lock.id), null)
	var quarantine_record = game.popup_layer.windows.get(int(quarantine.id), null)
	var input_ok = false
	var infected_ok = false
	var lock_ok = false
	var quarantine_ok = false
	var disabled_ok = false
	if target_record != null:
		var badge_text = _node_text_tree(target_record.statusBadges)
		input_ok = badge_text.find("입력 유예 중") >= 0
		infected_ok = badge_text.find("감염 대상") >= 0
		var first_button = _first_button(target_record.controls)
		disabled_ok = first_button != null and first_button.disabled
	if lock_record != null:
		lock_ok = _node_text_tree(lock_record.statusBadges).find("잠김") >= 0
	if quarantine_record != null:
		quarantine_ok = _node_text_tree(quarantine_record.statusBadges).find("격리 중") >= 0

	popup_status_badge_breakdown = {
		"input_ok": input_ok,
		"infected_ok": infected_ok,
		"lock_ok": lock_ok,
		"quarantine_ok": quarantine_ok,
		"disabled_ok": disabled_ok,
	}

	game.remove_popup_without_reward(target.id)
	game.remove_popup_without_reward(lock.id)
	game.remove_popup_without_reward(quarantine.id)
	game.popup_layer.sync(game.state)
	return input_ok and infected_ok and lock_ok and quarantine_ok and disabled_ok

func _verify_popup_telegraph_style() -> bool:
	var saved_pending = game.state.pendingPopupSpawns.duplicate(true)
	var defs = [
		game.popup_def_by_id("ad_premium_sample"),
		game.popup_def_by_id("terms_emergency_waiver"),
		game.popup_def_by_id("interest_offer"),
		game.popup_def_by_id("moving_close"),
	]
	game.state.pendingPopupSpawns = []
	for index in range(defs.size()):
		game.state.pendingPopupSpawns.append({
			"def": defs[index],
			"timer": 1.2 + index,
			"duration": 2.0 + index,
			"position": Vector2(32 + index * 18, 42 + index * 16),
		})
	game.hud._update_telegraphs(game.state)
	var children = game.hud.ui.popupTelegraphLayer.get_children()
	var count_ok = children.size() == defs.size()
	var labels_ok = count_ok
	var colors_ok = count_ok
	var timer_ok = count_ok
	var expected_labels = ["스폰서 광고 예정", "약관 창 예정", "금융 창 예정", "팝업 예정"]
	var expected_borders = [Color(1.0, 0.85, 0.40, 0.72), Color(1.0, 0.35, 0.39, 0.72), Color(0.36, 0.84, 0.59, 0.72), Color(1, 1, 1, 0.58)]
	for index in range(children.size()):
		var panel = children[index]
		var label = _find_node_named(panel, "popupTelegraphLabel")
		var timer = _find_node_named(panel, "popupTelegraphTimer")
		var style = panel.get_theme_stylebox("panel") as StyleBoxFlat
		labels_ok = labels_ok and label != null and label is Label and label.text == expected_labels[index]
		timer_ok = timer_ok and timer != null and timer is Label and timer.text.find("초") >= 0
		colors_ok = colors_ok and style != null and _color_close(style.border_color, expected_borders[index])
	popup_telegraph_style_breakdown = {
		"count_ok": count_ok,
		"labels_ok": labels_ok,
		"colors_ok": colors_ok,
		"timer_ok": timer_ok,
	}
	game.state.pendingPopupSpawns = saved_pending
	game.hud._update_telegraphs(game.state)
	return count_ok and labels_ok and colors_ok and timer_ok

func ui_parent_chain_has_class(node: Node, expected_class: String) -> bool:
	var current = node.get_parent()
	while current != null:
		if current.get_class() == expected_class:
			return true
		current = current.get_parent()
	return false

func _verify_inventory_card_grid() -> bool:
	var saved_counts = game.state.itemCounts.duplicate(true)
	var saved_selecting = game.state.selectingItem
	var saved_paused = game.state.paused
	game.state.itemCounts = {
		"damage_up": 2,
		"popup_resonator": 1,
	}
	game.hud.show_inventory_overview(func(): pass)
	var child_count = game.hud.ui.choiceGrid.get_child_count()
	if child_count < 3:
		game.hud.hide_choices()
		game.state.itemCounts = saved_counts
		game.state.selectingItem = saved_selecting
		game.state.paused = saved_paused
		return false
	var first_card = game.hud.ui.choiceGrid.get_child(0)
	var first_text = _node_text_tree(first_card)
	var close_text = _node_text_tree(game.hud.ui.choiceGrid.get_child(child_count - 1))
	var card_ok = first_card is PanelContainer and first_text.find("[Common]") >= 0 and first_text.find("공격력 증가 x2") >= 0 and first_text.find("태그:") >= 0 and first_text.find("현재:") >= 0
	var close_ok = close_text.find("닫기") >= 0 and close_text.find("게임으로 돌아갑니다.") >= 0
	game.hud.hide_choices()
	game.state.itemCounts = saved_counts
	game.state.selectingItem = saved_selecting
	game.state.paused = saved_paused
	return card_ok and close_ok

func _verify_stock_popup_detail_panel() -> bool:
	var saved_stock = game.state.stockMarket.stock.duplicate(true)
	game.state.stockMarket.stock.price = 114.0
	game.state.stockMarket.stock.lastChange = 0.045
	game.state.stockMarket.stock.shares = 3
	game.state.stockMarket.stock.avgCost = 92.0
	game.state.stockMarket.stock.history = [90.0, 94.0, 91.0, 104.0, 114.0]
	game.state.stockMarket.lastBiasLabel = "검증 강세"
	var popup = game.create_popup(game.popup_def_by_id("stock_broker_app"))
	game.popup_layer.sync(game.state)
	var record = game.popup_layer.windows.get(int(popup.id), null)
	var ok = false
	if record != null:
		var detail_text = str(record.detail.text)
		ok = record.detail.visible and record.chart.visible and detail_text.find("보유: 3주") >= 0 and detail_text.find("평가손익:") >= 0
	game.remove_popup_without_reward(popup.id)
	game.popup_layer.sync(game.state)
	game.state.stockMarket.stock = saved_stock
	return ok

func _verify_popup_detail_controls() -> bool:
	var saved_gold = game.state.gold
	var saved_programs = game.state.residentPrograms.duplicate(true)
	var saved_reserved_hp = game.state.reservedMaxHP
	game.state.gold = 0

	var store_popup = game.create_popup(game.popup_def_by_id("popup_store"))
	game.popup_layer.sync(game.state)
	var store_record = game.popup_layer.windows.get(int(store_popup.id), null)
	var store_ok = false
	if store_record != null:
		var first_store_button = _first_button(store_record.controls)
		store_ok = store_popup.has("storeProducts") and store_popup.storeProducts.size() >= 3 and str(store_record.detail.text).find("난이도를 올리지 않습니다") >= 0 and first_store_button != null and first_store_button.disabled and first_store_button.text.find("미확인 아이템") >= 0
	game.remove_popup_without_reward(store_popup.id)
	game.popup_layer.sync(game.state)

	var boss_popup = game.create_popup(game.popup_def_by_id("boss_package_ad"))
	game.popup_layer.sync(game.state)
	var boss_record = game.popup_layer.windows.get(int(boss_popup.id), null)
	var boss_ok = false
	if boss_record != null:
		var boss_button = _first_button(boss_record.controls)
		boss_ok = str(boss_record.detail.text).find("후보:") >= 0 and str(boss_record.detail.text).find("패키지 가격") >= 0 and boss_button != null and boss_button.disabled and boss_button.text.find("아이템 6개 중 2개") >= 0
	game.remove_popup_without_reward(boss_popup.id)
	game.popup_layer.sync(game.state)

	var security_popup = game.create_popup(game.popup_def_by_id("keyboard_security_installer"))
	game.popup_layer.sync(game.state)
	var security_record = game.popup_layer.windows.get(int(security_popup.id), null)
	var security_ok = false
	if security_record != null:
		var security_button = _first_button(security_record.controls)
		security_ok = str(security_record.detail.text).find("설치 비용") >= 0 and str(security_record.detail.text).find("상주 부담") >= 0 and security_button != null and security_button.disabled and security_button.text.find("설치 -") >= 0
	game.remove_popup_without_reward(security_popup.id)
	game.popup_layer.sync(game.state)

	game.state.gold = saved_gold
	game.state.residentPrograms = saved_programs
	game.state.reservedMaxHP = saved_reserved_hp
	return store_ok and boss_ok and security_ok

func _verify_reward_terms_controls() -> bool:
	var terms_popup = game.create_popup(game.popup_def_by_id("terms_emergency_waiver"))
	terms_popup.inputGrace = 0.0
	game.popup_layer.sync(game.state)
	var terms_record = game.popup_layer.windows.get(int(terms_popup.id), null)
	var terms_ok = false
	if terms_record != null:
		var before_text = _node_text_tree(terms_record.controls)
		game.toggle_terms_risk(terms_popup.id)
		game.popup_layer.sync(game.state)
		var after_record = game.popup_layer.windows.get(int(terms_popup.id), null)
		var after_text = _node_text_tree(after_record.controls)
		terms_ok = str(after_record.detail.text).find("체크 해제") >= 0 and before_text.find("[x] 위험 조항 동의") >= 0 and after_text.find("[ ] 위험 조항 동의") >= 0 and after_text.find("선택 조건으로 수락") >= 0
	game.remove_popup_without_reward(terms_popup.id)
	game.popup_layer.sync(game.state)

	var sponsored_popup = game.create_popup(game.popup_def_by_id("ad_premium_sample"))
	sponsored_popup.inputGrace = 0.0
	sponsored_popup.elapsed = 3.0
	game.update_special_popups(0.0)
	game.popup_layer.sync(game.state)
	var sponsored_record = game.popup_layer.windows.get(int(sponsored_popup.id), null)
	var sponsored_ok = false
	if sponsored_record != null:
		var sponsored_text = _node_text_tree(sponsored_record.controls)
		sponsored_ok = sponsored_record.progress.visible and str(sponsored_record.detail.text).find("완료 보상") >= 0 and str(sponsored_record.detail.text).find("남은 시간") >= 0 and sponsored_text.find("중단하기") >= 0
	game.remove_popup_without_reward(sponsored_popup.id)
	game.popup_layer.sync(game.state)

	var timed_popup = game.create_popup(game.popup_def_by_id("timed_reward"))
	timed_popup.inputGrace = 0.0
	timed_popup.elapsed = 4.0
	game.update_special_popups(0.0)
	game.popup_layer.sync(game.state)
	var timed_record = game.popup_layer.windows.get(int(timed_popup.id), null)
	var timed_ok = false
	if timed_record != null:
		var timed_text = _node_text_tree(timed_record.controls)
		timed_ok = timed_record.progress.visible and str(timed_record.detail.text).find("완료 보상") >= 0 and str(timed_record.detail.text).find("중간에 닫으면") >= 0 and timed_text.find("취소") >= 0
	game.remove_popup_without_reward(timed_popup.id)
	game.popup_layer.sync(game.state)

	return terms_ok and sponsored_ok and timed_ok

func _verify_special_popup_detail() -> bool:
	var clean = game.create_popup(game.popup_def_by_id("clean_challenge_basic"))
	clean.inputGrace = 0.0
	clean.cleanProgress = 3.2
	clean.progress = 0.32
	game.popup_layer.sync(game.state)
	var clean_record = game.popup_layer.windows.get(int(clean.id), null)
	var clean_ok = false
	if clean_record != null:
		var clean_text = _node_text_tree(clean_record.controls)
		clean_ok = clean_record.progress.visible and str(clean_record.detail.text).find("목표:") >= 0 and str(clean_record.detail.text).find("보상:") >= 0 and clean_text.find("포기") >= 0
	game.remove_popup_without_reward(clean.id)
	game.popup_layer.sync(game.state)

	var volatile = game.create_popup(game.popup_def_by_id("volatile_bomb_popup"))
	volatile.inputGrace = 0.0
	volatile.elapsed = 6.4
	game.update_special_popups(0.0)
	game.popup_layer.sync(game.state)
	var volatile_record = game.popup_layer.windows.get(int(volatile.id), null)
	var volatile_ok = false
	if volatile_record != null:
		var volatile_text = _node_text_tree(volatile_record.controls)
		volatile_ok = volatile_record.progress.visible and str(volatile_record.detail.text).find("시간 안에 닫기") >= 0 and str(volatile_record.detail.text).find("시간 초과") >= 0 and volatile_text.find("지금 닫기") >= 0
	game.remove_popup_without_reward(volatile.id)
	game.popup_layer.sync(game.state)

	var target = game.create_popup(game.popup_def_by_id("timed_reward"))
	target.inputGrace = 0.0
	var infection = game.create_popup(game.popup_def_by_id("infection"))
	infection.inputGrace = 0.0
	game.choose_infection_target(infection)
	infection.infectionTimer = infection.infectionDuration * 0.5
	infection.progress = 0.5
	game.popup_layer.sync(game.state)
	var infection_record = game.popup_layer.windows.get(int(infection.id), null)
	var actual_target_id = int(infection.get("infectionTargetId", 0))
	var target_record = game.popup_layer.windows.get(actual_target_id, null)
	var infection_ok = false
	if infection_record != null and target_record != null:
		infection_ok = infection_record.progress.visible and str(infection_record.detail.text).find("감염 대상:") >= 0 and str(infection_record.detail.text).find("막대가 차기 전에") >= 0 and target_record.panel.modulate != Color.WHITE
	game.remove_popup_without_reward(infection.id)
	game.remove_popup_without_reward(target.id)
	game.popup_layer.sync(game.state)

	var infected = game.create_popup(game.infected_popup_definition("검증 팝업"))
	infected.inputGrace = 0.0
	game.popup_layer.sync(game.state)
	var infected_record = game.popup_layer.windows.get(int(infected.id), null)
	var infected_ok = false
	if infected_record != null:
		infected_ok = str(infected_record.detail.text).find("원래 보상은 지급되지 않습니다") >= 0 and _node_text_tree(infected_record.controls).find("감염 창 닫기") >= 0
	game.remove_popup_without_reward(infected.id)
	game.popup_layer.sync(game.state)

	special_popup_detail_breakdown = {
		"clean_ok": clean_ok,
		"volatile_ok": volatile_ok,
		"infection_ok": infection_ok,
		"infected_ok": infected_ok,
	}
	return clean_ok and volatile_ok and infection_ok and infected_ok

func _first_button(node: Node):
	for child in node.get_children():
		if child is Button:
			return child
		var nested = _first_button(child)
		if nested != null:
			return nested
	return null

func _node_text_tree(node: Node) -> String:
	var parts = []
	if node is Label:
		parts.append(node.text)
	elif node is RichTextLabel:
		parts.append(node.text)
	elif node is Button:
		parts.append(node.text)
	for child in node.get_children():
		parts.append(_node_text_tree(child))
	return "\n".join(parts)

func _find_node_named(node: Node, node_name: String):
	if node.name == node_name:
		return node
	for child in node.get_children():
		var found = _find_node_named(child, node_name)
		if found != null:
			return found
	return null

func _color_close(a: Color, b: Color) -> bool:
	return abs(a.r - b.r) < 0.01 and abs(a.g - b.g) < 0.01 and abs(a.b - b.b) < 0.01 and abs(a.a - b.a) < 0.01

func _verify_all_items_apply_without_error() -> bool:
	var applied = 0
	for item in game.data.ITEMS:
		game.apply_item_reward(item)
		if game.owned_item_count(item.id) <= 0:
			return false
		applied += 1
	item_definition_apply_count = applied
	return applied == game.data.ITEMS.size()

func _verify_key_item_dynamics() -> bool:
	var saved_open_popups = game.state.openPopups.duplicate(true)
	var saved_heat = game.state.heat
	var saved_credit = game.state.creditScore
	var saved_invested = game.state.investedGold
	var saved_gold = game.state.gold
	var saved_hp = game.state.player.hp
	var saved_max_hp = game.state.player.maxHP
	var saved_combo_value = game.state.cleanupComboValue
	var saved_combo_timer = game.state.cleanupComboTimer
	var saved_sponsored_stacks = game.state.sponsoredAttackBoostStacks

	game.state.heat = 4.0
	game.state.investedGold = 350
	game.state.gold = 250
	game.state.player.maxHP = 220.0
	game.state.player.hp = 66.0
	game.state.cleanupComboValue = 6
	game.state.cleanupComboTimer = 3.0
	game.state.sponsoredAttackBoostStacks = 5
	var damage_ok = game.dynamic_item_damage_multiplier() > 0.0 and game.global_damage_multiplier() > 0.0
	var regen_ok = game.effective_health_regen_per_second() > float(game.state.stats.healthRegenPerSecond)
	var cooldown_ok = game.dynamic_item_cooldown_multiplier() < 0.0

	game.state.creditScore = 85
	game.state.openPopups = [{}, {}, {}]
	var credit_range_ok = game.dynamic_item_range_multiplier() > 0.0
	game.state.creditScore = 50
	var popup_range_ok = game.dynamic_item_range_multiplier() > 0.0
	game.state.openPopups = []
	var low_popup_range_ok = game.dynamic_item_range_multiplier() > 0.0
	var quiet_cooldown_ok = game.dynamic_item_cooldown_multiplier() < 0.0

	game.state.openPopups = saved_open_popups
	game.state.heat = saved_heat
	game.state.creditScore = saved_credit
	game.state.investedGold = saved_invested
	game.state.gold = saved_gold
	game.state.player.hp = saved_hp
	game.state.player.maxHP = saved_max_hp
	game.state.cleanupComboValue = saved_combo_value
	game.state.cleanupComboTimer = saved_combo_timer
	game.state.sponsoredAttackBoostStacks = saved_sponsored_stacks

	return damage_ok and regen_ok and cooldown_ok and credit_range_ok and popup_range_ok and low_popup_range_ok and quiet_cooldown_ok
