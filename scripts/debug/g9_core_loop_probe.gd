extends Node

const MainScene = preload("res://scenes/main/Main.tscn")

var game
var failures: Array = []

func _ready() -> void:
	get_window().size = Vector2i(1152, 648)
	game = MainScene.instantiate()
	add_child(game)
	while game.state.is_empty():
		await get_tree().process_frame
	await get_tree().process_frame
	_prepare_open_run()
	_verify_player()
	_verify_enemy_spawn_and_chase()
	_verify_auto_attack_kill_and_drop()
	_verify_pickup_attraction_and_collect()
	_verify_hud_update()
	_verify_item_machine()
	_verify_popup_spawn()
	_verify_boss_reward_flow()
	if failures.is_empty():
		print("g9_core_loop_probe passed")
		get_tree().quit()
		return
	for failure in failures:
		push_error(str(failure))
	get_tree().quit(1)

func _prepare_open_run() -> void:
	game.state.gameOver = false
	game.state.paused = false
	game.state.selectingItem = false
	game.state.selectingPerk = false
	game.state.selectingModule = false
	game.state.selectingPaidReward = false
	game.hud.hide_choices()
	game.state.player.position = Vector2.ZERO
	game.state.player.hp = game.state.player.maxHP
	game.state.lastMoveDir = Vector2.RIGHT
	game.state.enemyTimer = 9999.0
	game.state.popupTimer = 9999.0
	game.state.firstPurchaseTimer = 9999.0
	game.state.xpNeed = 9999
	if game.data.ATTACK_MODULES.is_empty():
		failures.append("attack module data missing")
		return
	game.apply_attack_module_choice("primary", game.data.ATTACK_MODULES[0])
	game.state.moduleUpgrades.primary.form = game.default_form_for_module(game.state.primaryModule)
	game.state.moduleUpgrades.primary.mechanic = ""
	game.state.moduleUpgrades.primary.scaling = ""
	game.state.moduleTimers.primary = 0.0

func _clear_runtime() -> void:
	game.state.enemies.clear()
	game.state.projectiles.clear()
	game.state.mines.clear()
	game.state.turrets.clear()
	game.state.fields.clear()
	game.state.chargeCasts.clear()
	game.state.attacks.clear()
	game.state.pickups.clear()
	game.state.particles.clear()
	game.state.floatTexts.clear()
	game.state.openPopups.clear()
	game.state.pendingPopupSpawns.clear()
	game.popup_layer.sync(game.state)
	_prepare_open_run()

func _verify_player() -> void:
	_expect_true("player hp positive", float(game.state.player.hp) > 0.0)
	_expect_true("player radius positive", float(game.state.player.radius) > 0.0)
	_expect_true("world layer exists", game.world != null)
	_expect_true("hud layer exists", game.hud != null)
	_expect_true("popup layer exists", game.popup_layer != null)

func _verify_enemy_spawn_and_chase() -> void:
	_clear_runtime()
	var enemy = game.spawn_enemy(false)
	enemy.position = game.state.player.position + Vector2(160, 0)
	enemy.speed = 120.0
	var before = enemy.position.distance_to(game.state.player.position)
	game.update_enemies(0.25)
	var after = enemy.position.distance_to(game.state.player.position)
	_expect_equal("enemy spawned", game.state.enemies.has(enemy), true)
	_expect_true("enemy chases player", after < before)

func _verify_auto_attack_kill_and_drop() -> void:
	_clear_runtime()
	var enemy = game.spawn_enemy(false)
	enemy.position = game.state.player.position + Vector2(70, 0)
	enemy.hp = 1.0
	enemy.maxHP = 1.0
	enemy.speed = 0.0
	enemy.damage = 0.0
	game.state.moduleTimers.primary = 0.0
	var kill_before = int(game.state.killCount)
	for _i in range(40):
		game.update_game(0.05)
		if not game.state.enemies.has(enemy):
			break
	_expect_equal("auto attack removed enemy", game.state.enemies.has(enemy), false)
	_expect_equal("normal kill increments killCount", int(game.state.killCount), kill_before + 1)
	_expect_true("gold drop spawned", _has_pickup("gold", int(game.config.goldPerKill)))
	_expect_true("xp drop spawned", _has_pickup("xp", int(game.config.xpPerKill)))

func _verify_pickup_attraction_and_collect() -> void:
	_clear_runtime()
	var pickup_range = game.effective_pickup_range()
	var gold_before = int(game.state.gold)
	var pickup = {"position": game.state.player.position + Vector2(pickup_range, 0), "kind": "gold", "value": 7, "life": 18.0, "radius": 6.0}
	game.state.pickups.append(pickup)
	game.update_pickups(1.0 / 60.0)
	_expect_equal("pickup at range edge is not collected immediately", game.state.pickups.has(pickup), true)
	_expect_true("pickup moves toward player in range", pickup.position.distance_to(game.state.player.position) < pickup_range)
	_expect_equal("range-edge pickup does not grant gold immediately", int(game.state.gold), gold_before)
	pickup.position = game.state.player.position + Vector2(game.pickup_collection_radius(pickup) - 0.5, 0)
	game.update_pickups(1.0 / 60.0)
	_expect_equal("near pickup collected", game.state.pickups.has(pickup), false)
	_expect_equal("pickup grants gold", int(game.state.gold), gold_before + 7)

func _verify_hud_update() -> void:
	game.hud.update_from_state(game.state)
	_expect_equal("hud gold text updates", game.hud.ui.goldText.text, "%dG" % game.state.gold)
	_expect_equal("hud hp text updates", game.hud.ui.hpText.text, "%d / %d" % [ceil(game.state.player.hp), ceil(game.state.player.maxHP)])

func _verify_item_machine() -> void:
	_clear_runtime()
	game.state.itemRollCount = 0
	game.state.nextItemDiscounts.clear()
	var cost = game.current_item_roll_cost()
	game.state.gold = cost
	game.roll_item()
	_expect_equal("item roll spends gold", int(game.state.gold), 0)
	_expect_equal("item machine opens selection", game.state.selectingItem, true)
	_expect_equal("item machine pauses run", game.state.paused, true)
	_expect_equal("item machine overlay visible", game.hud.ui.choiceOverlay.visible, true)
	game.state.selectingItem = false
	game.state.paused = false
	game.hud.hide_choices()

func _verify_popup_spawn() -> void:
	_clear_runtime()
	var popup_def = game.popup_def_by_id("timed_reward")
	if popup_def.is_empty():
		failures.append("timed_reward popup definition missing")
		return
	var popup = game.create_popup(popup_def)
	popup.inputGrace = 0.0
	game.popup_layer.sync(game.state)
	_expect_equal("popup state spawned", game.state.openPopups.has(popup), true)
	_expect_equal("popup visual window spawned", game.popup_layer.windows.has(int(popup.id)), true)

func _verify_boss_reward_flow() -> void:
	_clear_runtime()
	game.state.xpNeed = 9999
	var boss = game.spawn_enemy(true)
	boss.position = game.state.player.position + Vector2(70, 0)
	boss.hp = 1.0
	boss.maxHP = 1.0
	boss.speed = 0.0
	boss.damage = 0.0
	game.state.moduleTimers.primary = 0.0
	var boss_kills_before = int(game.state.metrics.bossKills)
	for _i in range(40):
		game.update_game(0.05)
		if not game.state.enemies.has(boss):
			break
	_expect_equal("boss auto attack kill removes boss", game.state.enemies.has(boss), false)
	_expect_equal("boss kill metric increments", int(game.state.metrics.bossKills), boss_kills_before + 1)
	var package_popup = _first_popup_of_type("boss_package_ad")
	if package_popup == null:
		failures.append("boss package popup not spawned")
		return
	game.state.gold = max(int(game.state.gold), int(package_popup.packageCost))
	game.purchase_boss_package(int(package_popup.id))
	_expect_equal("boss package popup removed after purchase", game.popup_by_id(int(package_popup.id)), null)
	_expect_equal("boss package paid reward selection opens", game.state.selectingPaidReward, true)
	_expect_equal("boss package pending item count", game.state.pendingBossPackage.items.size(), 6)
	if game.state.pendingBossPackage.items.size() >= 2:
		var purchased_before = int(game.state.metrics.bossPackagesPurchased)
		game.toggle_boss_package_selection(game.state.pendingBossPackage.items[0])
		game.toggle_boss_package_selection(game.state.pendingBossPackage.items[1])
		_expect_equal("boss package purchase metric increments", int(game.state.metrics.bossPackagesPurchased), purchased_before + 1)
		_expect_equal("boss package selection closes", game.state.selectingPaidReward, false)
		_expect_equal("boss package resumes run", game.state.paused, false)

func _has_pickup(kind: String, value: int) -> bool:
	for pickup in game.state.pickups:
		if str(pickup.kind) == kind and int(pickup.value) == value:
			return true
	return false

func _first_popup_of_type(type: String):
	for popup in game.state.openPopups:
		if str(popup.def.type) == type:
			return popup
	return null

func _expect_true(label: String, condition: bool) -> void:
	if not condition:
		failures.append(label)

func _expect_equal(label: String, actual, expected) -> void:
	if actual != expected:
		failures.append("%s expected %s got %s" % [label, str(expected), str(actual)])
