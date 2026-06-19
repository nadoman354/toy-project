extends Node

const PrototypeGameScript = preload("res://scripts/v2/prototype_game.gd")

var game
var frames = 0
var result_path = "user://prototype_smoke_result.json"

func _ready() -> void:
	game = PrototypeGameScript.new()
	add_child(game)
	call_deferred("_start_scenario")

func _start_scenario() -> void:
	game.apply_attack_module_choice("primary", game.data.ATTACK_MODULES[0])
	game.debug_action("gold100")
	game.debug_action("xp10")
	var first_purchase_popup = game.create_popup(game.popup_def_by_id("first_purchase_package"))
	game.state.firstPurchaseOfferShown = true
	game.complete_first_purchase_payment(first_purchase_popup.id)
	game.apply_first_purchase_package_choice(game.data.FIRST_PURCHASE_PACKAGES[3])
	game.debug_action("gold100")
	var interest_popup = game.create_popup(game.popup_def_by_id("interest_offer"))
	game.accept_interest_offer(interest_popup.id, 0.25)
	game.debug_action("ad_buff")
	game.debug_action("popup_store")
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

func _process(_delta: float) -> void:
	frames += 1
	if frames < 180:
		return
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
	get_tree().quit()
