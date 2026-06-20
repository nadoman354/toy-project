extends Node
class_name PrototypeGame

const PrototypeStateScript = preload("res://scripts/v2/prototype_state.gd")
const PrototypeWorldScript = preload("res://scripts/v2/prototype_world.gd")
const PrototypeHudScript = preload("res://scripts/v2/prototype_hud.gd")
const PrototypePopupLayerScript = preload("res://scripts/v2/prototype_popup_layer.gd")
const InputControllerScript = preload("res://scripts/v2/input_controller.gd")
const DataRegistryScript = preload("res://scripts/data/data_registry.gd")
const RunCoordinatorScript = preload("res://scripts/systems/run_coordinator.gd")
const PrototypeModalLayerScript = preload("res://scripts/ui/modal/prototype_modal_layer.gd")
const PrototypeDebugLayerScript = preload("res://scripts/debug/prototype_debug_layer.gd")
const PopupClosePolicyScript = preload("res://scripts/systems/popup_close_policy.gd")
const HtmlLayoutMetrics = preload("res://scripts/ui/html_layout_metrics.gd")

const DATA_PATH = "res://scripts/data/prototype_data.json"
const PROGRESSION_CHOICE_DEFAULTS = {
	"enableAdvancedBuildChoices": false,
	"enableBuildOptimizationChoices": false,
	"enableAttackFormChoices": true,
	"enableAttackMechanicChoices": true,
	"enableSynergyChoices": false,
	"enableDeepeningChoices": false,
}

var rng = RandomNumberGenerator.new()
var data = {}
var config = {}
var state = {}
var popup_id_seed = 1
var z_seed = 1200

var input_controller
var data_registry
var run_coordinator
var world
var hud
var popup_layer
var modal_layer
var debug_layer

func _ready() -> void:
	rng.randomize()
	_load_data()
	input_controller = InputControllerScript.new(self)
	_setup_scene_nodes()
	run_coordinator = RunCoordinatorScript.new(self)
	reset_game()

func _setup_scene_nodes() -> void:
	world = _resolve_or_create_child("WorldLayer", PrototypeWorldScript)
	world.setup(self)
	popup_layer = _resolve_or_create_child("PopupLayer", PrototypePopupLayerScript)
	popup_layer.setup(self)
	modal_layer = _resolve_or_create_child("ModalLayer", PrototypeModalLayerScript)
	modal_layer.setup(self)
	debug_layer = _resolve_or_create_child("DebugLayer", PrototypeDebugLayerScript)
	debug_layer.setup(self)
	hud = _resolve_or_create_child("HudLayer", PrototypeHudScript)
	hud.setup(self)

func _resolve_or_create_child(node_name: String, script_resource: Script) -> Node:
	var node = get_node_or_null(node_name)
	if node == null:
		node = script_resource.new()
		node.name = node_name
		add_child(node)
	elif node.get_script() == null:
		node.set_script(script_resource)
	return node

func _load_data() -> void:
	data_registry = DataRegistryScript.new(DATA_PATH)
	if not data_registry.load():
		data = {}
		config = {}
		return
	data = data_registry.data
	config = data_registry.config

func reset_game() -> void:
	popup_id_seed = 1
	z_seed = 1200
	state = PrototypeStateScript.create(config, rng)
	popup_layer.sync(state)
	hud.update_from_state(state)
	world.queue_redraw()
	call_deferred("open_attack_module_selection", "primary")

func _process(delta: float) -> void:
	run_coordinator.tick(delta)

func update_game(dt: float) -> void:
	state.elapsed += dt
	update_difficulty_stage_pulse(dt)
	update_wave_director(dt)
	update_cleanup_combo(dt)
	update_player(dt)
	update_enemies(dt)
	update_health_regen(dt)
	update_boss_spawns()
	update_module_upgrade_timers(dt)
	update_auto_attack(dt)
	update_charge_casts(dt)
	update_projectiles(dt)
	update_mines(dt)
	update_turrets(dt)
	update_fields(dt)
	update_pickups(dt)
	update_attacks(dt)
	update_particles(dt)
	update_float_texts(dt)
	update_popup_timers(dt)
	update_pending_popup_spawns(dt)
	update_timed_and_delayed_effects(dt)
	update_special_popups(dt)
	update_stock_market(dt)
	update_resident_programs(dt)
	update_first_purchase_offer(dt)

func update_visual_timers(dt: float) -> void:
	state.player.hitFlash = max(0.0, float(state.player.hitFlash) - dt)
	state.emergencyTimer = max(0.0, float(state.emergencyTimer) - dt)
	state.emergencyBoostTimer = max(0.0, float(state.emergencyBoostTimer) - dt)
	state.popupFreezeTimer = max(0.0, float(state.popupFreezeTimer) - dt)
	state.difficultyPulseTimer = max(0.0, float(state.difficultyPulseTimer) - dt)
	state.difficultyNoticeTimer = max(0.0, float(state.difficultyNoticeTimer) - dt)
	state.waveDirector.noticeTimer = max(0.0, float(state.waveDirector.noticeTimer) - dt)

func is_selecting() -> bool:
	return state.selectingItem or state.selectingPerk or state.selectingModule or state.selectingPaidReward

func progression_choice_enabled(key: String) -> bool:
	return bool(config.get(key, PROGRESSION_CHOICE_DEFAULTS.get(key, false)))

func advanced_build_choices_enabled() -> bool:
	return progression_choice_enabled("enableAdvancedBuildChoices")

func camera_position() -> Vector2:
	var viewport = get_viewport().get_visible_rect().size
	var target = state.player.position - viewport * 0.5
	state.camera.position = state.camera.position.lerp(target, 0.16)
	return state.camera.position

func update_player(dt: float) -> void:
	var input = input_controller.movement_vector(state)
	if input.length() > 0.01:
		state.lastMoveDir = input.normalized()
	state.player.position += input * effective_move_speed() * dt

func update_enemies(dt: float) -> void:
	state.enemyTimer -= dt
	if state.enemyTimer <= 0.0:
		spawn_enemy()
		var interval = float(config.enemySpawnInterval) / max(0.1, enemy_spawn_rate_scale() * wave_mode_spawn_multiplier())
		state.enemyTimer = max(float(config.enemySpawnIntervalMin), interval)
	for enemy in state.enemies.duplicate():
		var direction = state.player.position - enemy.position
		if direction.length() > 0.01:
			enemy.position += direction.normalized() * enemy.speed * dt
		enemy.contactTimer = max(0.0, enemy.get("contactTimer", 0.0) - dt)
		if enemy.position.distance_to(state.player.position) < enemy.radius + state.player.radius and enemy.contactTimer <= 0.0:
			damage_player(enemy.damage)
			enemy.contactTimer = 0.72

func spawn_enemy(force_boss = false) -> Dictionary:
	var mode = current_wave_mode()
	var pressure = difficulty_combat_pressure()
	var viewport = get_viewport().get_visible_rect().size
	var boss = force_boss
	var hp = current_normal_enemy_hp_estimate() * mode.get("hpMultiplier", 1.0)
	var speed = float(config.enemySpeed) * enemy_time_scale() * mode.get("speedMultiplier", 1.0)
	var radius = 15.0
	if boss:
		hp = boss_hp_estimate()
		speed *= 0.56
		radius = 34.0
	var enemy = {
		"type": "boss" if boss else "normal",
		"position": spawn_position_for_wave(mode, viewport),
		"radius": radius,
		"hp": hp,
		"maxHP": hp,
		"max_hp": hp,
		"speed": speed,
		"damage": float(config.enemyDamage) * (1.45 if boss else 1.0),
		"contactTimer": 0.0,
		"bossTier": max(1, state.bossSpawnIndex),
	}
	enemy.maxHP = hp
	state.enemies.append(enemy)
	return enemy

func spawn_position_for_wave(mode: Dictionary, viewport: Vector2) -> Vector2:
	var player_pos = state.player.position
	var margin = max(viewport.x, viewport.y) * 0.62 + 80.0
	match mode.get("pattern", "around"):
		"side":
			var side = -1.0 if state.waveDirector.side == "left" else 1.0
			return player_pos + Vector2(side * margin, rng.randf_range(-viewport.y * 0.48, viewport.y * 0.48))
		"ring":
			var angle = rng.randf_range(0.0, TAU)
			return player_pos + Vector2(cos(angle), sin(angle)) * margin
	var edge = rng.randi_range(0, 3)
	if edge == 0:
		return player_pos + Vector2(rng.randf_range(-viewport.x * 0.55, viewport.x * 0.55), -margin)
	if edge == 1:
		return player_pos + Vector2(rng.randf_range(-viewport.x * 0.55, viewport.x * 0.55), margin)
	if edge == 2:
		return player_pos + Vector2(-margin, rng.randf_range(-viewport.y * 0.55, viewport.y * 0.55))
	return player_pos + Vector2(margin, rng.randf_range(-viewport.y * 0.55, viewport.y * 0.55))

func damage_player(amount: float) -> void:
	if state.gameOver:
		return
	state.player.hp -= amount
	state.player.hitFlash = 0.24
	add_damage_number(state.player.position + Vector2(0, -28), "-%d" % ceil(amount), Color("#ff5964"))
	if state.player.hp <= 0.0:
		if state.stats.lowHpPopupFreeze > 0 and not state.lowHpFreezeUsed:
			state.lowHpFreezeUsed = true
			state.player.hp = 1.0
			state.popupFreezeTimer = 8.0
			add_damage_number(state.player.position + Vector2(0, -46), "집중 모드", Color("#4aa8ff"))
		else:
			end_game()

func heal_player(amount: float, source = "") -> void:
	if amount <= 0.0:
		return
	var scaled = amount * max(0.0, 1.0 + state.stats.healingMultiplier)
	state.player.hp = min(float(state.player.maxHP), float(state.player.hp) + scaled)

func update_health_regen(dt: float) -> void:
	var regen = effective_health_regen_per_second()
	if regen > 0.0:
		heal_player(regen * dt, "regen")

func effective_health_regen_per_second() -> float:
	var regen = float(state.stats.healthRegenPerSecond)
	var wound = owned_item_count("wound_engine")
	if wound > 0 and hp_ratio() <= 0.5:
		regen += 2.0 * wound
	regen += (1.0 - hp_ratio()) * float(state.stats.missingHpRegenMultiplier)
	return regen

func hp_ratio() -> float:
	return clamp(float(state.player.hp) / max(float(state.player.maxHP), 1.0), 0.0, 1.0)

func update_auto_attack(dt: float) -> void:
	for slot in ["primary", "secondary"]:
		if state["%sModule" % slot] == "":
			continue
		state.moduleTimers[slot] -= dt
		if is_slot_charging(slot):
			continue
		if state.moduleTimers[slot] <= 0.0:
			trigger_module_attack(slot)
			state.moduleTimers[slot] = effective_attack_interval(slot)

func is_slot_charging(slot: String) -> bool:
	for cast in state.chargeCasts:
		if cast.slot == slot and not cast.done:
			return true
	return false

func trigger_module_attack(slot: String) -> void:
	var module = module_by_id(state["%sModule" % slot])
	if module.is_empty():
		return
	var form = selected_form_for_slot(slot)
	var damage = effective_damage(slot)
	var range_value = effective_attack_range(slot)
	if state.popupCloseAttackPrimed and slot == "primary":
		damage *= 1.25
		state.popupCloseAttackPrimed = false
	match module.id:
		"ranged":
			if form.id == "ranged_laser":
				execute_ranged_laser(slot, damage, range_value)
			elif form.id == "ranged_scatter":
				execute_ranged_projectile(slot, damage * 0.75, range_value, 3, 0.25)
			elif form.id == "ranged_bounce":
				execute_ranged_bounce(slot, damage * 0.95, range_value)
			elif form.id == "ranged_charge_cannon":
				queue_charge_cast(slot, "ranged_charge_cannon", damage * 2.4, range_value * 1.15, 1.05)
			else:
				execute_ranged_projectile(slot, damage, range_value, 1, 0.0)
		"melee":
			if form.id == "melee_circle_slash":
				execute_melee_circle_slash(slot, damage, range_value)
			elif form.id == "melee_sword_wave":
				execute_ranged_projectile(slot, damage * 1.15, range_value * 1.2, 1, 0.0, true)
			elif form.id == "melee_dash_slash":
				execute_melee_dash_slash(slot, damage * 1.25, range_value * 1.45)
			elif form.id == "melee_charged_cleave":
				queue_charge_cast(slot, "melee_charged_cleave", damage * 2.0, range_value * 1.05, 0.8)
			else:
				execute_melee_forward_slash(slot, damage, range_value)
		"aura":
			if form.id == "aura_charged_nova":
				queue_charge_cast(slot, "aura_charged_nova", damage * 2.2, range_value * 1.2, 1.1)
			elif form.id == "aura_pulse":
				execute_aura_pulse(slot, damage * 1.65, range_value * 0.95)
			elif form.id == "aura_infection":
				execute_aura_infection(slot, damage, range_value)
			elif form.id == "aura_absorb":
				execute_aura_absorb(slot, damage * 0.82, range_value)
			else:
				execute_aura_pulse(slot, damage, range_value)
		"deploy":
			if form.id == "deploy_turret":
				execute_deploy_turret(slot, damage, range_value)
			elif form.id == "deploy_field":
				execute_deploy_field(slot, damage, range_value)
			elif form.id == "deploy_maturity_bomb":
				execute_deploy_maturity_bomb(slot, damage, range_value)
			else:
				execute_deploy_mine(slot, damage, range_value)

func execute_ranged_projectile(slot: String, damage: float, range_value: float, count: int, spread: float, sword_wave = false) -> void:
	var target = get_nearest_enemy_in_range(range_value)
	var base_dir = state.lastMoveDir
	if target != null:
		base_dir = (target.position - state.player.position).normalized()
	for index in range(count):
		var offset = (float(index) - float(count - 1) * 0.5) * spread
		var dir = base_dir.rotated(offset)
		spawn_projectile(slot, state.player.position + dir * 18.0, dir, damage, range_value, sword_wave)
	if state.stats.sponsoredDoubleHit > 0 and count_open_ad_popups() > 0:
		spawn_projectile(slot, state.player.position + base_dir.rotated(0.16) * 18.0, base_dir.rotated(0.16), damage * 0.55, range_value, sword_wave)

func execute_ranged_bounce(slot: String, damage: float, range_value: float) -> void:
	var target = get_nearest_enemy_in_range(range_value)
	var dir = state.lastMoveDir
	if target != null:
		dir = (target.position - state.player.position).normalized()
	var projectile = spawn_projectile(slot, state.player.position + dir * 18.0, dir, damage, range_value)
	projectile.bounceLeft = 1 + bounce_count_bonus(slot)
	projectile.bounceRange = range_value * 0.75

func spawn_projectile(slot: String, position: Vector2, dir: Vector2, damage: float, range_value: float, sword_wave = false) -> Dictionary:
	var projectile = {
		"kind": "projectile",
		"slot": slot,
		"position": position,
		"velocity": dir.normalized() * float(config.rangedProjectileSpeed),
		"radius": float(config.rangedProjectileRadius) * (2.0 if sword_wave else 1.0),
		"damage": damage,
		"life": range_value / max(float(config.rangedProjectileSpeed), 1.0),
		"maxLife": range_value / max(float(config.rangedProjectileSpeed), 1.0),
		"pierce": 1 + int(state.stats.extraTargets) + projectile_extra_targets_bonus(slot) + (1 if selected_mechanic_for_slot(slot).get("id", "") == "pierce" else 0),
		"swordWave": sword_wave,
		"hitIds": [],
	}
	state.projectiles.append(projectile)
	return projectile

func execute_ranged_laser(slot: String, damage: float, range_value: float) -> void:
	var target = get_nearest_enemy_in_range(range_value)
	var dir = state.lastMoveDir
	if target != null:
		dir = (target.position - state.player.position).normalized()
	var start = state.player.position
	var end = start + dir * range_value
	var width = 10.0 + beam_width_bonus(slot) + (8.0 if selected_mechanic_for_slot(slot).get("id", "") == "pierce" else 0.0)
	for enemy in state.enemies.duplicate():
		var closest = Geometry2D.get_closest_point_to_segment(enemy.position, start, end)
		if closest.distance_to(enemy.position) <= enemy.radius + width:
			damage_enemy_tracked(enemy, damage, slot)
	state.projectiles.append({"kind": "laser", "position": start, "endPosition": end, "width": width, "life": 0.13, "maxLife": 0.13})

func execute_melee_forward_slash(slot: String, damage: float, range_value: float) -> void:
	var start = state.player.position
	var end = start + state.lastMoveDir * range_value
	var width = float(config.meleeSlashWidth)
	for enemy in state.enemies.duplicate():
		var closest = Geometry2D.get_closest_point_to_segment(enemy.position, start, end)
		if closest.distance_to(enemy.position) <= enemy.radius + width * 0.5:
			damage_enemy_tracked(enemy, damage, slot)
	state.attacks.append({"kind": "slash", "position": start, "endPosition": end, "width": width, "life": 0.18, "maxLife": 0.18})

func execute_melee_dash_slash(slot: String, damage: float, range_value: float) -> void:
	var start = state.player.position
	var end = start + state.lastMoveDir * range_value
	var width = float(config.meleeSlashWidth) * 0.72
	for enemy in state.enemies.duplicate():
		var closest = Geometry2D.get_closest_point_to_segment(enemy.position, start, end)
		if closest.distance_to(enemy.position) <= enemy.radius + width * 0.5:
			damage_enemy_tracked(enemy, damage, slot)
	state.attacks.append({"kind": "slash", "position": start, "endPosition": end, "width": width, "life": 0.15, "maxLife": 0.15})

func execute_melee_circle_slash(slot: String, damage: float, range_value: float) -> void:
	var radius = range_value * 0.9
	for enemy in state.enemies.duplicate():
		if enemy.position.distance_to(state.player.position) <= radius + enemy.radius:
			damage_enemy_tracked(enemy, damage * 0.9, slot)
	state.attacks.append({"kind": "circle", "position": state.player.position, "radius": radius, "life": 0.22, "maxLife": 0.22})

func execute_aura_pulse(slot: String, damage: float, range_value: float) -> void:
	var radius = range_value
	for enemy in state.enemies.duplicate():
		if enemy.position.distance_to(state.player.position) <= radius + enemy.radius:
			damage_enemy_tracked(enemy, damage, slot)
	state.attacks.append({"kind": "circle", "position": state.player.position, "radius": radius, "life": 0.28, "maxLife": 0.28})

func execute_aura_infection(slot: String, damage: float, range_value: float) -> void:
	var radius = range_value * 1.08
	var pressure = 1.0 + state.heat * 0.06 + min(0.45, state.openPopups.size() * 0.045)
	for enemy in state.enemies.duplicate():
		if enemy.position.distance_to(state.player.position) <= radius + enemy.radius:
			damage_enemy_tracked(enemy, damage * pressure, slot)
	state.attacks.append({"kind": "circle", "position": state.player.position, "radius": radius, "life": 0.34, "maxLife": 0.34, "color": Color("#4bdd73")})

func execute_aura_absorb(slot: String, damage: float, range_value: float) -> void:
	var radius = range_value * 0.92
	var kills = 0
	for enemy in state.enemies.duplicate():
		if enemy.position.distance_to(state.player.position) <= radius + enemy.radius:
			if damage_enemy_tracked(enemy, damage, slot):
				kills += 1
	if kills > 0:
		add_gold(kills * 2, "auraAbsorb")
	state.attacks.append({"kind": "circle", "position": state.player.position, "radius": radius, "life": 0.3, "maxLife": 0.3, "color": Color("#7fffd0")})

func execute_deploy_mine(slot: String, damage: float, range_value: float) -> void:
	var pos = state.player.position + state.lastMoveDir * range_value
	state.mines.append({"position": pos, "damage": damage * 1.7, "radius": max(56.0, range_value * 0.9), "triggerRadius": float(config.deployTriggerRadius), "life": 10.0, "maxLife": 10.0, "slot": slot})

func execute_deploy_turret(slot: String, damage: float, range_value: float) -> void:
	var pos = state.player.position + state.lastMoveDir * range_value
	state.turrets.append({"position": pos, "damage": damage * 0.45, "range": range_value * 2.4, "timer": 0.1, "interval": 0.5, "life": 8.0, "maxLife": 8.0, "slot": slot})

func execute_deploy_field(slot: String, damage: float, range_value: float) -> void:
	var pos = state.player.position + state.lastMoveDir * range_value
	state.fields.append({"position": pos, "damage": damage * 0.32, "radius": range_value * 1.45, "tick": 0.0, "interval": 0.35, "life": 5.0, "maxLife": 5.0, "slot": slot})

func execute_deploy_maturity_bomb(slot: String, damage: float, range_value: float) -> void:
	var pos = state.player.position + state.lastMoveDir * range_value
	state.mines.append({"position": pos, "damage": damage * 1.1, "radius": max(64.0, range_value * 0.95), "triggerRadius": float(config.deployTriggerRadius) * 0.82, "life": 8.0, "maxLife": 8.0, "slot": slot, "maturity": true})

func queue_charge_cast(slot: String, kind: String, damage: float, range_value: float, duration: float) -> void:
	if selected_mechanic_for_slot(slot).get("id", "") == "overcharge":
		damage *= 1.3
		range_value *= 1.18
		duration *= 1.18
	state.chargeCasts.append({"slot": slot, "kind": kind, "origin": state.player.position, "direction": state.lastMoveDir, "damage": damage, "radius": range_value, "duration": duration, "elapsed": 0.0, "done": false})

func update_charge_casts(dt: float) -> void:
	for cast in state.chargeCasts.duplicate():
		cast.elapsed += dt
		if cast.elapsed >= cast.duration and not cast.done:
			cast.done = true
			if cast.kind == "ranged_charge_cannon":
				spawn_projectile(cast.slot, cast.origin, cast.direction, cast.damage, cast.radius, false)
			elif cast.kind == "melee_charged_cleave":
				var start = cast.origin
				var end = start + cast.direction * cast.radius
				for enemy in state.enemies.duplicate():
					var closest = Geometry2D.get_closest_point_to_segment(enemy.position, start, end)
					if closest.distance_to(enemy.position) <= enemy.radius + 58.0:
						damage_enemy_tracked(enemy, cast.damage, cast.slot)
				state.attacks.append({"kind": "slash", "position": start, "endPosition": end, "width": 96.0, "life": 0.28, "maxLife": 0.28})
			elif cast.kind == "aura_charged_nova":
				explode_at(cast.origin, cast.radius, cast.damage, cast.slot)
		if cast.elapsed >= cast.duration + 0.22:
			state.chargeCasts.erase(cast)

func update_projectiles(dt: float) -> void:
	for projectile in state.projectiles.duplicate():
		projectile.life -= dt
		if projectile.kind == "laser":
			if projectile.life <= 0.0:
				state.projectiles.erase(projectile)
			continue
		projectile.position += projectile.velocity * dt
		for enemy in state.enemies.duplicate():
			if enemy.position.distance_to(projectile.position) <= enemy.radius + projectile.radius:
				damage_enemy_tracked(enemy, projectile.damage, projectile.slot)
				if projectile.get("bounceLeft", 0) > 0:
					var next_target = get_nearest_enemy_from_excluding(enemy.position, projectile.get("bounceRange", 180.0), enemy)
					if next_target != null:
						projectile.bounceLeft -= 1
						projectile.position = enemy.position
						projectile.velocity = (next_target.position - projectile.position).normalized() * float(config.rangedProjectileSpeed)
						projectile.damage *= 0.72
						projectile.life = max(projectile.life, 0.18)
						break
				projectile.pierce -= 1
				if projectile.pierce <= 0:
					state.projectiles.erase(projectile)
					break
		if projectile.life <= 0.0 and state.projectiles.has(projectile):
			state.projectiles.erase(projectile)

func update_mines(dt: float) -> void:
	for mine in state.mines.duplicate():
		mine.life -= dt
		var triggered = false
		for enemy in state.enemies:
			if enemy.position.distance_to(mine.position) <= enemy.radius + mine.triggerRadius:
				triggered = true
				break
		if triggered:
			var damage = maturity_mine_damage(mine)
			explode_at(mine.position, mine.radius, damage, mine.slot)
			state.mines.erase(mine)
		elif mine.life <= 0.0:
			if mine.get("maturity", false):
				explode_at(mine.position, mine.radius, maturity_mine_damage(mine), mine.slot)
			state.mines.erase(mine)

func maturity_mine_damage(mine: Dictionary) -> float:
	if not mine.get("maturity", false):
		return float(mine.damage)
	var aged = 1.0 - clamp(float(mine.life) / max(float(mine.maxLife), 0.1), 0.0, 1.0)
	return float(mine.damage) * (1.0 + aged * 1.35)

func update_turrets(dt: float) -> void:
	for turret in state.turrets.duplicate():
		turret.life -= dt
		turret.timer -= dt
		if turret.timer <= 0.0:
			turret.timer = turret.interval
			var target = get_nearest_enemy_from(turret.position, turret.range)
			if target != null:
				spawn_projectile(turret.slot, turret.position, (target.position - turret.position).normalized(), turret.damage, turret.range)
		if turret.life <= 0.0:
			state.turrets.erase(turret)

func update_fields(dt: float) -> void:
	for field in state.fields.duplicate():
		field.life -= dt
		field.tick -= dt
		if field.tick <= 0.0:
			field.tick = field.interval
			for enemy in state.enemies.duplicate():
				if enemy.position.distance_to(field.position) <= field.radius + enemy.radius:
					damage_enemy_tracked(enemy, field.damage, field.slot)
		if field.life <= 0.0:
			state.fields.erase(field)

func explode_at(position: Vector2, radius: float, damage: float, slot: String) -> void:
	for enemy in state.enemies.duplicate():
		if enemy.position.distance_to(position) <= radius + enemy.radius:
			damage_enemy_tracked(enemy, damage, slot)
	state.attacks.append({"kind": "explosion", "position": position, "radius": radius, "life": 0.32, "maxLife": 0.32})

func damage_enemy_tracked(enemy: Dictionary, damage: float, slot = "primary") -> bool:
	var crit_source = damage_crit_source(slot)
	var crit_result = apply_crit_to_damage(damage, crit_source, slot) if crit_source != "" else {"damage": damage, "crit": false}
	var final_damage = float(crit_result.damage)
	var dealt = max(0.0, min(final_damage, float(enemy.hp)))
	enemy.hp -= final_damage
	if dealt > 0.0:
		add_damage_number(enemy.position + Vector2(0, -enemy.radius), "%d%s" % [ceil(dealt), "!" if crit_result.crit else ""], Color("#ffe86e") if crit_result.crit else Color("#edf2f7"), 20 if crit_result.crit else 14)
	if dealt > 0.0 and state.stats.lifeStealPercent > 0.0:
		heal_player(dealt * state.stats.lifeStealPercent + state.stats.lifeStealFlat, "lifesteal")
	if slot == "secondary" and state.moduleSynergy.get("id", "") == "secondary_haste":
		state.moduleTimers.primary = max(0.0, float(state.moduleTimers.primary) - 0.25)
	if enemy.hp <= 0.0:
		if slot == "primary" and state.moduleSynergy.get("id", "") == "primary_charge" and state.secondaryModule != "":
			state.moduleTimers.secondary = 0.0
		record_enemy_kill(enemy, slot)
		return true
	return false

func record_enemy_kill(enemy: Dictionary, slot: String) -> void:
	if not state.enemies.has(enemy):
		return
	state.enemies.erase(enemy)
	add_death_burst(enemy.position)
	if enemy.type == "boss":
		grant_boss_rewards(enemy)
	else:
		state.killCount += 1
		spawn_field_pickup(enemy.position, "gold", int(config.goldPerKill))
		spawn_field_pickup(enemy.position + Vector2(rng.randf_range(-12, 12), rng.randf_range(-12, 12)), "xp", int(config.xpPerKill))
		if rng.randf() < float(config.magnetPickupDropChance):
			spawn_special_consumable_drop(enemy.position, "magnet")
		if rng.randf() < float(config.healPickupDropChance):
			spawn_special_consumable_drop(enemy.position, "heal")
	if state.moduleUpgrades.has(slot) and selected_mechanic_for_slot(slot).get("id", "") == "kill_chain":
		explode_at(enemy.position, 58.0, effective_damage(slot) * 0.45, slot)

func apply_popup_close_damage() -> void:
	if state.stats.popupCloseDamage <= 0.0:
		return
	for enemy in state.enemies.duplicate():
		if enemy.position.distance_to(state.player.position) <= 145.0:
			damage_enemy_tracked(enemy, float(state.stats.popupCloseDamage), "")

func spawn_field_pickup(position: Vector2, kind: String, value: int) -> void:
	state.pickups.append({"position": position, "kind": kind, "value": value, "life": 18.0})

func spawn_special_consumable_drop(position: Vector2, kind: String) -> void:
	state.pickups.append({"position": position, "kind": kind, "value": 0, "life": 16.0})

func pickup_collection_radius(pickup: Dictionary) -> float:
	return float(state.player.radius) + float(pickup.get("radius", 6.0)) + 8.0

func update_pickups(dt: float) -> void:
	for pickup in state.pickups.duplicate():
		pickup.life -= dt
		if pickup.kind == "magnet":
			for other in state.pickups:
				if other != pickup:
					other.position = other.position.move_toward(state.player.position, 520.0 * dt)
		var distance = pickup.position.distance_to(state.player.position)
		if distance <= effective_pickup_range():
			pickup.position = pickup.position.move_toward(state.player.position, 520.0 * dt)
			distance = pickup.position.distance_to(state.player.position)
		if distance <= pickup_collection_radius(pickup):
			collect_pickup(pickup)
		elif pickup.life <= 0.0:
			state.pickups.erase(pickup)

func collect_pickup(pickup: Dictionary) -> void:
	if not state.pickups.has(pickup):
		return
	state.pickups.erase(pickup)
	match pickup.kind:
		"gold":
			var crowded_bonus = state.stats.crowdedGoldMultiplier if state.openPopups.size() >= 4 else 0.0
			add_gold(int(round(float(pickup.value) * max(0.1, 1.0 + crowded_bonus))), "pickup")
		"xp":
			add_xp(pickup.value)
		"heal":
			heal_player(float(config.healPickupFlat) + float(config.healPickupPercent) * float(state.player.maxHP), "pickup")
		"magnet":
			for other in state.pickups.duplicate():
				if other != pickup:
					collect_pickup(other)

func add_gold(amount: int, source = "") -> void:
	if amount <= 0:
		return
	var remaining = amount
	if should_recurring_investment_redirect(source):
		var recurring = active_recurring_investment()
		if recurring != null:
			var redirected = min(remaining, int(floor(float(remaining) * recurring.investment.redirectRatio)))
			recurring.investment.accumulated += redirected
			state.investedGold += redirected
			remaining -= redirected
	state.gold += remaining
	var source_name = str(source)
	if source_name != "" and source_name != "pickup" and source_name != "debug":
		state.metrics.passiveGoldEarned += max(0, remaining)

func should_recurring_investment_redirect(source: String) -> bool:
	return not ["pickup", "debug", "investmentPayout", "investmentRefund", "creditCashout", "loan"].has(source)

func add_xp(amount: int) -> void:
	state.xp += amount
	check_level_up()

func check_level_up() -> void:
	while state.xp >= state.xpNeed and not is_selecting():
		state.xp -= state.xpNeed
		state.level += 1
		state.xpNeed = int(ceil(float(state.xpNeed) * float(config.xpRequirementGrowth)))
		open_level_choice()
		if is_selecting():
			break

func open_level_choice() -> void:
	if is_selecting():
		return
	var label = next_growth_choice_label()
	if state.level >= 5 and state.secondaryModule == "":
		open_attack_module_selection("secondary")
	elif label == "공격 방식":
		open_attack_form_selection("primary")
	elif label == "공격 기믹":
		open_attack_mechanic_selection("primary")
	elif label == "빌드 최적화":
		open_build_scaling_selection("primary")
	elif label == "공격 연계":
		open_synergy_selection()
	elif label == "심화 선택":
		open_deepening_selection("primary")
	else:
		apply_automatic_mastery_level()

func next_growth_choice_label() -> String:
	if state.primaryModule == "":
		return "시작 선택"
	if state.level >= 5 and state.secondaryModule == "":
		return "보조 모듈"
	if progression_choice_enabled("enableAttackFormChoices") and state.level == 9:
		return "공격 방식"
	if progression_choice_enabled("enableAttackMechanicChoices") and state.level == 13:
		return "공격 기믹"
	if advanced_build_choices_enabled() and progression_choice_enabled("enableBuildOptimizationChoices") and state.level == 17:
		return "빌드 최적화"
	if advanced_build_choices_enabled() and progression_choice_enabled("enableSynergyChoices") and state.level == 15 and state.secondaryModule != "" and state.moduleSynergy.is_empty():
		return "공격 연계"
	if advanced_build_choices_enabled() and progression_choice_enabled("enableDeepeningChoices") and state.level % 4 == 0:
		return "심화 선택"
	return "패시브 보상"

func apply_automatic_mastery_level() -> void:
	if state.primaryModule != "":
		state.primaryMastery += 1
	if state.secondaryModule != "":
		state.secondaryMastery += 1
	state.recentPerkText = "숙련 상승: 1차 %d / 보조 %d" % [state.primaryMastery, state.secondaryMastery]
	hud.hide_choices()
	state.paused = false

func open_attack_module_selection(slot: String) -> void:
	state.selectingModule = true
	state.paused = true
	var title = "시작 1차 공격 모듈 선택" if slot == "primary" else "Lv.5 보조 공격 모듈 선택"
	var description = "선택 전까지 게임은 멈춥니다. 이번 런의 기본 공격 방식을 고르세요." if slot == "primary" else "1차 공격 모듈과 다른 보조 모듈을 선택합니다."
	hud.show_choices(title, description, data.ATTACK_MODULES, func(choice): apply_attack_module_choice(slot, choice), 3)

func apply_attack_module_choice(slot: String, choice: Dictionary) -> void:
	state["%sModule" % slot] = choice.id
	state["%sMastery" % slot] = max(1, int(state["%sMastery" % slot]))
	state.moduleUpgrades[slot].form = default_form_for_module(choice.id)
	state.recentPerkText = "%s 모듈: %s" % [slot_label(slot), choice.name]
	state.selectingModule = false
	hud.hide_choices()
	state.paused = false

func open_attack_form_selection(slot: String) -> void:
	var module_id = state["%sModule" % slot]
	var choices = data.ATTACK_FORMS.filter(func(form): return form.compatibleModules.has(module_id))
	state.selectingPerk = true
	state.paused = true
	hud.show_choices("공격 방식 선택", "현재 모듈의 실제 판정과 렌더링이 바뀝니다.", choices, func(choice): apply_attack_form_choice(slot, choice), 2)

func apply_attack_form_choice(slot: String, choice: Dictionary) -> void:
	state.moduleUpgrades[slot].form = choice.id
	state.recentPerkText = "%s 방식: %s" % [slot_label(slot), choice.name]
	finish_growth_choice()

func open_attack_mechanic_selection(slot: String) -> void:
	var form = selected_form_for_slot(slot)
	var tags = form.get("tags", [])
	var choices = data.ATTACK_MECHANICS.filter(func(mechanic): return mechanic.compatibleTags.has("any") or tags.any(func(tag): return mechanic.compatibleTags.has(tag)))
	state.selectingPerk = true
	state.paused = true
	hud.show_choices("공격 기믹 선택", "공격에 반사, 관통, 처치 연쇄 같은 규칙을 추가합니다.", choices, func(choice): apply_attack_mechanic_choice(slot, choice), 2)

func apply_attack_mechanic_choice(slot: String, choice: Dictionary) -> void:
	state.moduleUpgrades[slot].mechanic = choice.id
	state.recentPerkText = "%s 기믹: %s" % [slot_label(slot), choice.name]
	finish_growth_choice()

func open_build_scaling_selection(slot: String) -> void:
	var playstyle = active_playstyle_key()
	var choices = data.BUILD_SCALINGS.filter(func(scaling): return scaling.playstyle == playstyle or scaling.playstyle == "generic")
	state.selectingPerk = true
	state.paused = true
	hud.show_choices("빌드 최적화 선택", "현재 계약과 아이템 태그에 맞춘 스케일링을 적용합니다.", choices, func(choice): apply_build_scaling_choice(slot, choice), 2)

func apply_build_scaling_choice(slot: String, choice: Dictionary) -> void:
	state.moduleUpgrades[slot].scaling = choice.id
	state.recentPerkText = "%s 최적화: %s" % [slot_label(slot), choice.name]
	finish_growth_choice()

func open_synergy_selection() -> void:
	var choices = data.SYNERGY_OPTIONS.filter(func(option): return not option.get("hidden", false))
	state.selectingPerk = true
	state.selectingModule = true
	state.paused = true
	hud.show_choices("공격 연계 선택", "1차와 보조 공격이 서로 영향을 주는 임시 연계 규칙을 고릅니다.", choices, func(choice): apply_synergy_choice(choice), 2)

func apply_synergy_choice(choice: Dictionary) -> void:
	state.moduleSynergy = choice
	state.recentPerkText = "공격 연계: %s" % choice.name
	finish_growth_choice()

func open_deepening_selection(slot: String) -> void:
	state.selectingPerk = true
	state.paused = true
	hud.show_choices("심화 선택", "피해, 빈도, 범위 중 하나를 강화합니다.", data.DEEPENING_OPTIONS, func(choice): apply_deepening_choice(slot, choice), 3)

func apply_deepening_choice(slot: String, choice: Dictionary) -> void:
	state["%sDeepening" % slot] = choice
	state.recentPerkText = "%s 심화: %s" % [slot_label(slot), choice.name]
	finish_growth_choice()

func finish_growth_choice() -> void:
	if state.primaryModule != "":
		state.primaryMastery += 1
	if state.secondaryModule != "":
		state.secondaryMastery += 1
	state.selectingPerk = false
	state.selectingModule = false
	hud.hide_choices()
	state.paused = false

func roll_item() -> void:
	if state.gameOver or state.paused or is_selecting():
		return
	var cost = current_item_roll_cost()
	if state.gold < cost:
		return
	state.gold -= cost
	state.itemRollCount += 1
	consume_item_discounts()
	var count = 3 + int(state.nextItemExtraChoices)
	state.nextItemExtraChoices = 0
	open_item_selection(choose_item_options(count))

func open_item_selection(choices: Array) -> void:
	state.selectingItem = true
	state.paused = true
	hud.show_choices("아이템 선택", "골드를 지불했습니다. 패시브 아이템 1개를 선택해 현재 런 성능을 누적 성장시키세요.", choices, Callable(self, "apply_item_choice"), 3)

func apply_item_choice(item: Dictionary) -> void:
	apply_item_reward(item)
	if state.stats.purchaseDamageBurst > 0.0:
		state.timedEffects.append({"stat": "damageMultiplier", "value": state.stats.purchaseDamageBurst, "remaining": 10.0})
	state.selectingItem = false
	hud.hide_choices()
	state.paused = false

func open_item_like_overlay(title: String, description: String, choices: Array, callback: Callable) -> void:
	state.selectingPerk = true
	state.paused = true
	hud.show_choices(title, description, choices, callback, 3)

func apply_perk_choice(perk: Dictionary) -> void:
	apply_effect_container(perk)
	state.recentPerkText = "최근 성장: %s" % perk.name
	finish_growth_choice()

func apply_item_reward(item: Dictionary) -> void:
	apply_effect_container(item)
	if item.rarity == "Cursed" and not effect_container_has_stat(item, "heat"):
		state.heat += 1.0
	state.itemCounts[item.id] = int(state.itemCounts.get(item.id, 0)) + 1
	state.lastItemText = "%s [color=#9aa8ba]%s[/color]\n%s\n현재: %s" % [rarity_badge(item.rarity), item.name, item.description, describe_item_current(item, 0)]

func effect_container_has_stat(source: Dictionary, stat: String) -> bool:
	if source.has("effects") and effect_value_has_stat(source.effects, stat):
		return true
	if source.has("effect") and effect_value_has_stat(source.effect, stat):
		return true
	if source.has("reward") and effect_value_has_stat(source.reward, stat):
		return true
	return false

func effect_value_has_stat(value, stat: String) -> bool:
	if typeof(value) == TYPE_ARRAY:
		for effect in value:
			if effect_value_has_stat(effect, stat):
				return true
	elif typeof(value) == TYPE_DICTIONARY:
		return value.get("stat", "") == stat
	return false

func choose_item_options(count: int) -> Array:
	var pool = data.ITEMS.duplicate(true)
	var result = []
	for i in range(count):
		if pool.is_empty():
			break
		var index = weighted_item_index(pool)
		result.append(pool[index])
		pool.remove_at(index)
	return result

func choose_perk_options(count: int) -> Array:
	var pool = data.PERKS.duplicate(true)
	var result = []
	for i in range(count):
		if pool.is_empty():
			break
		var index = rng.randi_range(0, pool.size() - 1)
		result.append(pool[index])
		pool.remove_at(index)
	return result

func weighted_item_index(pool: Array) -> int:
	var rarity_weights = {"Common": 44.0, "Rare": 28.0, "Epic": 12.0, "Cursed": 7.0}
	var total = 0.0
	for item in pool:
		total += rarity_weights.get(item.get("rarity", "Common"), 10.0) * item_tag_weight_multiplier(item)
	var roll = rng.randf() * total
	for index in range(pool.size()):
		roll -= rarity_weights.get(pool[index].get("rarity", "Common"), 10.0) * item_tag_weight_multiplier(pool[index])
		if roll <= 0.0:
			return index
	return max(0, pool.size() - 1)

func item_tag_weight_multiplier(item: Dictionary) -> float:
	var playstyle = active_playstyle_key()
	if playstyle == "generic":
		return 1.0
	var tags = item.get("tags", [])
	if playstyle == "investor" and (tags.has("investor") or tags.has("gold") or tags.has("credit")):
		return 1.4
	if playstyle == "sponsored" and (tags.has("sponsored") or tags.has("ad_open") or tags.has("ad_completion")):
		return 1.35
	if playstyle == "clean" and (tags.has("clean") or tags.has("cleanup_combo") or tags.has("low_popup")):
		return 1.35
	if playstyle == "clutter" and (tags.has("clutter") or tags.has("popup_count") or tags.has("crowded")):
		return 1.35
	if playstyle == "curse" and (tags.has("curse") or tags.has("heat") or tags.has("risk")):
		return 1.35
	return 1.0

func apply_effect_container(source: Dictionary) -> void:
	if source.has("effects"):
		apply_effect_value(source.effects)
	elif source.has("effect"):
		apply_effect_value(source.effect)
	elif source.has("reward"):
		apply_effect_value(source.reward)

func apply_effect_value(value) -> void:
	if typeof(value) == TYPE_ARRAY:
		for effect in value:
			if typeof(effect) == TYPE_DICTIONARY:
				apply_effect(effect)
	elif typeof(value) == TYPE_DICTIONARY:
		apply_effect(value)

func apply_effect(effect: Dictionary) -> void:
	if effect.is_empty():
		return
	var type = effect.get("type", "stat")
	if type == "stat" and effect.has("stat"):
		if effect.has("delay") and effect.stat == "delayedMaxHPLoss":
			state.delayedEvents.append({"type": "maxHPLoss", "timer": float(effect.delay), "value": float(effect.get("value", 0.0))})
			return
		apply_stat(effect.stat, effect.get("value", 0.0))
	elif type == "gold":
		add_gold(int(effect.get("value", 0)), "reward")
	elif type == "timedStat":
		state.timedEffects.append({"stat": effect.stat, "value": effect.value, "remaining": effect.get("duration", 20.0)})
	elif type == "itemDiscount":
		state.nextItemDiscounts.append({"value": effect.get("value", 0.2), "uses": effect.get("uses", 1)})
	elif type == "extraItemChoice":
		state.nextItemExtraChoices += int(effect.get("value", 1))
	elif type == "freeSampleItem":
		for i in range(int(effect.get("count", 1))):
			var item = random_item_by_rarity(effect.get("rarity", "Common"))
			if not item.is_empty():
				apply_item_reward(item)
	elif type == "maxHPLoss":
		state.player.maxHP = max(1.0, state.player.maxHP - float(effect.get("value", 20)))
		state.player.hp = min(state.player.hp, state.player.maxHP)
	elif type == "heat":
		state.heat += float(effect.get("value", 1.0))

func apply_stat(stat: String, value) -> void:
	if stat == "maxHP":
		state.player.maxHP += float(value)
		state.player.hp += float(value)
	elif stat == "gold":
		add_gold(int(value), "reward")
	elif stat == "instantHeal":
		heal_player(float(value), "effect")
	elif stat == "heat":
		state.heat += float(value)
	elif stat == "delayedMaxHPLoss":
		state.delayedEvents.append({"type": "maxHPLoss", "timer": 60.0, "value": float(value)})
	elif state.stats.has(stat):
		state.stats[stat] += value

func update_timed_and_delayed_effects(dt: float) -> void:
	for effect in state.timedEffects.duplicate():
		effect.remaining -= dt
		if effect.remaining <= 0.0:
			state.timedEffects.erase(effect)
	for event in state.delayedEvents.duplicate():
		event.timer -= dt
		if event.timer <= 0.0:
			if event.type == "maxHPLoss":
				apply_effect({"type": "maxHPLoss", "value": event.value})
			elif event.type == "interestPayout":
				complete_interest_event(event)
			state.delayedEvents.erase(event)

func update_wave_director(dt: float) -> void:
	state.waveDirector.timer -= dt
	if state.waveDirector.timer <= 0.0:
		choose_next_wave_mode()

func choose_next_wave_mode() -> void:
	var candidates = ["normal", "side_push", "fast_horde"]
	if state.elapsed > 35.0:
		candidates.append("surround")
	if current_difficulty_score() > 4.0:
		candidates.append("dense_horde")
	if state.openPopups.size() >= 4:
		candidates.append("breather")
	var filtered = candidates.filter(func(id): return id != state.waveDirector.mode or candidates.size() <= 1)
	set_wave_mode(filtered[rng.randi_range(0, filtered.size() - 1)])

func set_wave_mode(mode_id: String, forced = false) -> void:
	var mode = wave_mode_by_id(mode_id)
	state.waveDirector.mode = mode.id
	state.waveDirector.timer = rng.randf_range(mode.duration[0], mode.duration[1])
	state.waveDirector.nextModeTimer = state.waveDirector.timer
	state.waveDirector.noticeTimer = 2.2
	state.waveDirector.noticeText = wave_mode_label(mode)
	state.waveDirector.side = "left" if rng.randf() < 0.5 else "right"

func update_difficulty_stage_pulse(dt: float) -> void:
	var info = difficulty_stage_info()
	if info.current.id != state.lastDifficultyStageId:
		state.lastDifficultyStageId = info.current.id
		state.difficultyPulseTimer = 1.0
		state.difficultyNoticeText = info.current.label
		state.difficultyNoticeTimer = 2.2

func current_difficulty_score() -> float:
	return state.heat + state.elapsed / 60.0 + max(0, state.openPopups.size() - 2) * 0.18

func difficulty_stage_info() -> Dictionary:
	var score = current_difficulty_score()
	var current = data.DIFFICULTY_STAGES[0]
	var next = null
	for stage in data.DIFFICULTY_STAGES:
		if score >= stage.min:
			current = stage
		elif next == null:
			next = stage
	var progress = 1.0
	if next != null:
		progress = clamp((score - current.min) / max(0.1, next.min - current.min), 0.0, 1.0)
	return {"current": current, "next": next, "progress": progress}

func difficulty_combat_pressure() -> Dictionary:
	var stage = difficulty_stage_info().current.id
	var map = {
		"normal": {"enemyHpMultiplier": 1.0, "enemySpeedMultiplier": 0.0, "enemySpawnMultiplier": 0.0, "popupSpawnMultiplier": 0.0},
		"warning": {"enemyHpMultiplier": 1.2, "enemySpeedMultiplier": 0.05, "enemySpawnMultiplier": 0.08, "popupSpawnMultiplier": 0.08},
		"danger": {"enemyHpMultiplier": 1.45, "enemySpeedMultiplier": 0.1, "enemySpawnMultiplier": 0.12, "popupSpawnMultiplier": 0.12},
		"overload": {"enemyHpMultiplier": 1.8, "enemySpeedMultiplier": 0.14, "enemySpawnMultiplier": 0.18, "popupSpawnMultiplier": 0.18},
		"collapse": {"enemyHpMultiplier": 2.25, "enemySpeedMultiplier": 0.18, "enemySpawnMultiplier": 0.25, "popupSpawnMultiplier": 0.25},
		"nightmare": {"enemyHpMultiplier": 2.8, "enemySpeedMultiplier": 0.24, "enemySpawnMultiplier": 0.32, "popupSpawnMultiplier": 0.32},
	}
	return map.get(stage, map.normal)

func enemy_time_scale() -> float:
	return 1.0 + min(0.9, state.elapsed / 360.0) + difficulty_combat_pressure().enemySpeedMultiplier

func enemy_spawn_rate_scale() -> float:
	return 1.0 + min(0.8, state.elapsed / 220.0) + difficulty_combat_pressure().enemySpawnMultiplier

func current_normal_enemy_hp_estimate() -> float:
	return float(config.enemyHP) * difficulty_combat_pressure().enemyHpMultiplier * (1.0 + state.elapsed / 420.0)

func wave_mode_by_id(id: String) -> Dictionary:
	for mode in data.WAVE_MODES:
		if mode.id == id:
			return mode
	return data.WAVE_MODES[0]

func current_wave_mode() -> Dictionary:
	return wave_mode_by_id(state.waveDirector.mode)

func wave_mode_label(mode = null) -> String:
	if mode == null:
		mode = current_wave_mode()
	return mode.label

func wave_mode_spawn_multiplier() -> float:
	return current_wave_mode().get("spawnMultiplier", 1.0)

func update_boss_spawns() -> void:
	var times = config.bossSpawnTimes
	if state.bossSpawnIndex < times.size() and state.elapsed >= times[state.bossSpawnIndex]:
		state.bossSpawnIndex += 1
		spawn_enemy(true)
		add_damage_number(state.player.position + Vector2(0, -60), "보스 소환", Color("#d26bff"), 18)

func boss_hp_estimate() -> float:
	var tier = max(1, state.bossSpawnIndex)
	return float(config.bossBaseHP) * (1.0 + 0.55 * float(tier - 1)) * difficulty_combat_pressure().enemyHpMultiplier

func grant_boss_rewards(enemy: Dictionary) -> void:
	var tier = enemy.get("bossTier", 1)
	add_gold(int(config.bossGoldReward) + (tier - 1) * 60, "boss")
	add_xp(int(config.bossXPReward) + (tier - 1) * 55)
	state.metrics.bossKills += 1
	create_boss_package_popup(tier)

func create_boss_package_popup(tier: int) -> void:
	var def = popup_def_by_id("boss_package_ad")
	if def.is_empty():
		return
	var package_def = def.duplicate(true)
	package_def.tier = tier
	package_def.packageCost = boss_package_cost(tier)
	package_def.packageItems = choose_boss_package_items()
	create_popup(package_def)

func boss_package_cost(tier: int) -> int:
	if tier <= 1:
		return 80
	if tier == 2:
		return 140
	return 220 + (tier - 3) * 90

func choose_boss_package_items() -> Array:
	return choose_item_options(6)

func purchase_boss_package(popup_id: int) -> void:
	var popup = popup_by_id(popup_id)
	if popup == null or state.gold < popup.packageCost or state.gameOver:
		return
	state.gold -= popup.packageCost
	state.pendingBossPackage = {"tier": popup.packageTier, "items": popup.packageItems, "cost": popup.packageCost, "selectedIds": []}
	state.selectingItem = true
	state.selectingPaidReward = true
	state.paused = true
	remove_popup_without_reward(popup_id)
	open_boss_package_selection()

func open_boss_package_selection() -> void:
	if state.pendingBossPackage.is_empty():
		return
	state.selectingItem = true
	state.selectingPaidReward = true
	state.paused = true
	hud.show_boss_package_choices("보스 패키지 보상 선택", "결제 완료. 아이템 6개 중 2개를 선택하면 즉시 적용됩니다.", state.pendingBossPackage.items, state.pendingBossPackage.selectedIds, Callable(self, "toggle_boss_package_selection"), 3)

func toggle_boss_package_selection(item: Dictionary) -> void:
	if state.pendingBossPackage.is_empty() or not item.has("id"):
		return
	var selected = state.pendingBossPackage.selectedIds
	var item_id = item.id
	if selected.has(item_id):
		selected.erase(item_id)
	elif selected.size() < 2:
		selected.append(item_id)
	if selected.size() == 2:
		complete_boss_package_selection()
	else:
		open_boss_package_selection()

func complete_boss_package_selection() -> void:
	if state.pendingBossPackage.is_empty() or state.pendingBossPackage.selectedIds.size() != 2:
		return
	var selected = state.pendingBossPackage.selectedIds
	for item in state.pendingBossPackage.items:
		if selected.has(item.id):
			apply_item_reward(item)
	state.metrics.bossPackagesPurchased += 1
	state.bossPackageCount += 1
	state.recentPerkText = "보스 패키지 완료: 아이템 2개 획득"
	state.pendingBossPackage = {}
	state.selectingItem = false
	state.selectingPaidReward = false
	hud.hide_choices()
	state.paused = false
	check_level_up()

func update_popup_timers(dt: float) -> void:
	if state.popupFreezeTimer <= 0.0:
		state.popupTimer -= dt
	if state.popupTimer <= 0.0:
		create_natural_popup()
		state.popupTimer = effective_popup_interval()
	for popup in state.openPopups.duplicate():
		popup.elapsed += dt
		popup.inputGrace = max(0.0, popup.get("inputGrace", 0.0) - dt)
		if popup.def.type == "moving_close":
			update_moving_popup_position(popup, dt)
	update_ad_passive_income(dt)

func update_special_popups(dt: float) -> void:
	for popup in state.openPopups.duplicate():
		var def = popup.def
		if float(def.get("autoClose", 0.0)) > 0.0 and popup.elapsed >= float(def.get("autoClose", 0.0)):
			remove_popup_without_reward(popup.id)
			continue
		match def.type:
			"sponsored_ad":
				var duration = timed_reward_duration(def)
				popup.progress = clamp(float(popup.elapsed) / max(duration, 0.1), 0.0, 1.0)
				if popup.elapsed >= duration and not popup.rewarded:
					popup.rewarded = true
					grant_sponsored_reward(popup)
					request_close_popup(popup.id, {"reason": "sponsored_complete"})
			"timed_reward":
				var duration = timed_reward_duration(def)
				popup.progress = clamp(float(popup.elapsed) / max(duration, 0.1), 0.0, 1.0)
				if popup.elapsed >= duration and not popup.rewarded:
					popup.rewarded = true
					grant_timed_reward(def)
					request_close_popup(popup.id, {"reason": "timed_complete"})
			"interest_offer":
				if popup.get("interestAccepted", false) and not popup.get("interestMatured", false):
					popup.interestMaturityProgress += dt
					popup.progress = clamp(popup.interestMaturityProgress / max(float(popup.interestMaturityTarget), 0.1), 0.0, 1.0)
					if popup.interestMaturityProgress >= popup.interestMaturityTarget:
						complete_interest_popup(popup)
			"recurring_investment":
				if popup.has("investment") and popup.investment.get("accepted", false):
					popup.investment.elapsed += dt
					popup.progress = clamp(popup.investment.elapsed / max(popup.investment.duration, 0.1), 0.0, 1.0)
					if popup.investment.elapsed >= popup.investment.duration:
						complete_recurring_investment(popup)
			"clean_challenge":
				if state.openPopups.size() <= def.get("targetOpenPopups", 2):
					popup.cleanProgress += dt
				else:
					popup.cleanProgress = max(0.0, popup.cleanProgress - dt * 0.75)
				popup.progress = clamp(popup.cleanProgress / max(def.get("duration", 10.0), 0.1), 0.0, 1.0)
				if popup.cleanProgress >= def.get("duration", 10.0):
					apply_effect(def.get("reward", {"type": "itemDiscount", "value": 0.2, "uses": 1}))
					request_close_popup(popup.id, {"reason": "clean_complete"})
				elif popup.elapsed >= def.get("duration", 10.0) * 2.2:
					request_close_popup(popup.id, {"reason": "clean_failed"})
			"volatile_popup":
				popup.progress = clamp(popup.elapsed / max(def.get("duration", 8.0), 0.1), 0.0, 1.0)
				if popup.elapsed >= def.get("duration", 8.0):
					state.popupTimer = min(state.popupTimer, 1.0)
					request_close_popup(popup.id, {"reason": "volatile_timeout"})
			"infection":
				var target = choose_infection_target(popup)
				if target != null:
					popup.infectionTimer += dt
				else:
					popup.infectionTimer = 0.0
				popup.progress = clamp(popup.infectionTimer / max(float(popup.infectionDuration), 0.1), 0.0, 1.0)
				if target != null and popup.infectionTimer >= popup.infectionDuration and not popup.get("infectionResolved", false):
					popup.infectionResolved = infect_popup(popup)
					request_close_popup(popup.id, {"reason": "infection_resolved"})
			"stock_market":
				update_stock_market_popup(popup, dt)
			"popup_store":
				var duration = float(def.get("duration", 18.0))
				popup.progress = clamp(float(popup.elapsed) / max(duration, 0.1), 0.0, 1.0)
				if popup.elapsed >= duration:
					request_close_popup(popup.id, {"reason": "store_expired"})

func create_natural_popup() -> void:
	if state.openPopups.size() >= max_open_popups():
		return
	var def = pick_weighted_popup()
	if not def.is_empty():
		schedule_popup_spawn(def)

func schedule_popup_spawn(def: Dictionary) -> void:
	var duration = popup_telegraph_duration(def)
	if duration <= 0.0:
		create_popup(def)
	else:
		state.pendingPopupSpawns.append({"def": def, "timer": duration, "duration": duration, "position": choose_popup_position(def)})

func popup_telegraph_label(def: Dictionary) -> String:
	match def.get("copyTone", ""):
		"legal_contract":
			return "약관 창 예정"
		"finance", "broker_app":
			return "금융 창 예정"
		"sponsored_reward":
			return "스폰서 광고 예정"
		"game_package":
			return "패키지 창 예정"
		"cleanup_utility":
			return "정리 유틸 예정"
		"security_installer":
			return "보안 설치 창 예정"
	return "팝업 예정"

func update_pending_popup_spawns(dt: float) -> void:
	for pending in state.pendingPopupSpawns.duplicate():
		pending.timer -= dt
		if pending.timer <= 0.0:
			var popup = create_popup(pending.def)
			popup.position = pending.position
			state.pendingPopupSpawns.erase(pending)

func pick_weighted_popup() -> Dictionary:
	var defs = available_popup_definitions()
	var total = 0.0
	for def in defs:
		total += weighted_value(def)
	var roll = rng.randf() * max(total, 0.001)
	for def in defs:
		roll -= weighted_value(def)
		if roll <= 0.0:
			return def
	return defs.back() if not defs.is_empty() else {}

func available_popup_definitions() -> Array:
	var defs = data.POPUP_DEFINITIONS.filter(func(def): return float(def.get("weight", 0.0)) > 0.0)
	var playstyle = active_playstyle_key()
	if playstyle == "generic":
		return defs.filter(func(def): return not popup_in_family(def, "investor"))
	var family_map = {
		"investor": ["investor", "security", "system"],
		"sponsored": ["sponsored", "generic", "security", "system"],
		"clean": ["clean", "generic", "security", "system"],
		"clutter": ["clutter", "generic", "security", "system"],
		"curse": ["curse", "generic", "security", "system"],
	}
	var families = family_map.get(playstyle, ["generic", "security", "system"])
	var filtered = defs.filter(func(def): return families.any(func(family): return popup_in_family(def, family)))
	return filtered if not filtered.is_empty() else defs

func popup_in_family(def: Dictionary, family: String) -> bool:
	return def.get("families", []).has(family)

func weighted_value(def: Dictionary) -> float:
	var weight = float(def.get("weight", 1.0))
	match def.type:
		"terms":
			weight *= 1.0 + state.stats.termsPopupWeightMultiplier
		"sponsored_ad":
			weight *= 1.0 + state.stats.sponsoredPopupWeightMultiplier
		"interest_offer":
			weight *= 1.0 + state.stats.interestPopupWeightMultiplier
		"popup_store":
			weight *= 1.0 + state.stats.popupStoreWeightMultiplier
	if active_playstyle_key() == "investor" and ["interest_offer", "recurring_investment", "loan_offer", "stock_broker_app", "stock_market"].has(def.type):
		weight *= 1.45
	return max(0.0, weight)

func create_popup(def: Dictionary) -> Dictionary:
	var popup = {
		"id": popup_id_seed,
		"def": def.duplicate(true),
		"position": choose_popup_position(def),
		"size": popup_size_for(def),
		"elapsed": 0.0,
		"life": 0.0,
		"progress": 0.0,
		"rewarded": false,
		"locked": false,
		"inputGrace": popup_input_grace(def),
		"z": z_seed,
		"minimized": false,
		"velocity": Vector2(rng.randf_range(-70.0, 70.0), rng.randf_range(-55.0, 55.0)),
		"cleanProgress": 0.0,
	}
	popup_id_seed += 1
	z_seed += 1
	initialize_popup_runtime_state(popup)
	state.openPopups.append(popup)
	return popup

func initialize_popup_runtime_state(popup: Dictionary) -> void:
	match popup.def.type:
		"recurring_investment":
			popup.investment = {"accepted": false, "elapsed": 0.0, "duration": popup.def.get("duration", 30.0), "redirectRatio": popup.def.get("redirectRatio", 0.35), "maturityBonus": popup.def.get("maturityBonus", 0.28), "accumulated": 0, "matured": false}
		"interest_offer":
			popup.interestAccepted = false
			popup.interestMatured = false
			popup.depositOptions = [
				{"label": "소액 예치", "ratio": 0.25, "bonus": 0.2},
				{"label": "중간 예치", "ratio": 0.5, "bonus": 0.35},
				{"label": "대형 예치", "ratio": 0.75, "bonus": 0.55},
			]
			popup.interestPrincipal = 0
			popup.interestPayout = 0
			popup.interestMaturityType = "time"
			popup.interestMaturityTarget = 24.0
			popup.interestMaturityProgress = 0.0
		"stock_market":
			popup.stock = {
				"invested": false,
				"principal": 0,
				"currentValue": 0.0,
				"elapsed": 0.0,
				"tickTimer": 1.0,
				"volatility": popup.def.get("volatility", 0.06),
				"drift": popup.def.get("drift", 0.003),
				"lastTrend": "대기 중",
				"history": [],
			}
		"infection":
			popup.infectionTimer = 0.0
			popup.infectionDuration = float(popup.def.get("duration", 7.5))
			popup.infectionTargetId = 0
			popup.infectionResolved = false
		"terms":
			popup.termsRiskChecked = true
		"security_installer":
			popup.locked = false
		"boss_package_ad":
			popup.packageTier = int(popup.def.get("tier", max(1, state.bossPackageCount + 1)))
			popup.packageCost = int(popup.def.get("packageCost", boss_package_cost(popup.packageTier)))
			popup.packageItems = popup.def.get("packageItems", choose_boss_package_items())
		"popup_store":
			popup.storeProducts = popup.def.get("storeProducts", data.POPUP_STORE_CATALOG).duplicate(true)

func popup_input_grace(def: Dictionary) -> float:
	if ["volatile_popup", "infection", "moving_close"].has(def.type):
		return 0.35
	return 0.18

func popup_telegraph_duration(def: Dictionary) -> float:
	if ["moving_close", "volatile_popup", "infection"].has(def.type):
		return 0.55
	return 0.0

func popup_size_for(def: Dictionary) -> Vector2:
	return HtmlLayoutMetrics.popup_size_for_type(str(def.get("type", "")))

func choose_popup_position(def: Dictionary) -> Vector2:
	var viewport = get_viewport().get_visible_rect().size
	var size = popup_size_for(def)
	var margin = 12.0
	var safe_scale = max(0.5, (1.0 + float(state.stats.safeZoneMultiplier)) * max(0.7, 1.0 - current_difficulty_score() * 0.015))
	var safe_size = Vector2(viewport.x * float(config.get("centralSafeZoneWidthRatio", 0.38)) * safe_scale, viewport.y * float(config.get("centralSafeZoneHeightRatio", 0.38)) * safe_scale)
	var player_screen = state.player.position - state.camera.position
	var safe_center = Vector2(clamp(player_screen.x, 0.0, viewport.x), clamp(player_screen.y, 0.0, viewport.y))
	var avoid_rects = [Rect2(safe_center - safe_size * 0.5, safe_size)]
	avoid_rects.append_array(hud_avoid_rects(viewport))
	var pointer_rect = pointer_avoid_rect()
	if pointer_rect != null:
		avoid_rects.append(pointer_rect)
	var best = null
	var best_score = INF
	for i in range(80):
		var candidate = popup_candidate_position(i, viewport, size, margin)
		var rect = Rect2(Vector2(clamp(candidate.x, margin, max(margin, viewport.x - size.x - margin)), clamp(candidate.y, margin, max(margin, viewport.y - size.y - margin))), size)
		var pushed = push_rect_out_of_popup_overlap(rect, margin, viewport.x, viewport.y)
		var score = popup_placement_score(pushed, avoid_rects)
		if score < best_score:
			best = pushed
			best_score = score
		if is_equal_approx(score, 0.0):
			return pushed.position
	var grid_position = popup_grid_fallback_position(size, margin, viewport, avoid_rects)
	if grid_position != null:
		return grid_position
	if best != null:
		return best.position
	var fallback = push_rect_out_of_popup_overlap(Rect2(Vector2(max(margin, viewport.x - size.x - margin), margin), size), margin, viewport.x, viewport.y)
	return fallback.position

func popup_grid_fallback_position(size: Vector2, margin: float, viewport: Vector2, avoid_rects: Array):
	var step = 48.0
	var max_x = max(margin, viewport.x - size.x - margin)
	var max_y = max(margin, viewport.y - size.y - margin)
	var y = margin
	while y <= max_y:
		var x = margin
		while x <= max_x:
			var rect = push_rect_out_of_popup_overlap(Rect2(Vector2(x, y), size), margin, viewport.x, viewport.y)
			if is_equal_approx(popup_placement_score(rect, avoid_rects), 0.0):
				return rect.position
			x += step
		y += step
	return null

func popup_candidate_position(index: int, viewport: Vector2, size: Vector2, margin: float) -> Vector2:
	var fixed = [
		Vector2(margin, viewport.y * 0.30),
		Vector2(viewport.x - size.x - margin, viewport.y * 0.30),
		Vector2(margin, viewport.y * 0.50 - size.y * 0.5),
		Vector2(viewport.x - size.x - margin, viewport.y * 0.50 - size.y * 0.5),
		Vector2(margin, viewport.y * 0.70 - size.y * 0.5),
		Vector2(viewport.x - size.x - margin, viewport.y * 0.70 - size.y * 0.5),
		Vector2(viewport.x * 0.32, margin),
		Vector2(viewport.x * 0.50 - size.x * 0.5, margin),
		Vector2(viewport.x * 0.32, viewport.y - size.y - margin),
		Vector2(viewport.x * 0.50 - size.x * 0.5, viewport.y - size.y - margin),
		Vector2(viewport.x * 0.36, viewport.y * 0.30),
		Vector2(viewport.x * 0.50 - size.x * 0.5, viewport.y * 0.30),
		Vector2(viewport.x * 0.36, viewport.y * 0.58),
		Vector2(viewport.x * 0.50 - size.x * 0.5, viewport.y * 0.58),
	]
	if index < fixed.size():
		return fixed[index]
	match index % 6:
		0:
			return Vector2(random_between(margin, viewport.x * 0.28), random_between(margin, viewport.y * 0.25))
		1:
			return Vector2(random_between(viewport.x * 0.66, viewport.x - size.x - margin), random_between(margin, viewport.y * 0.25))
		2:
			return Vector2(random_between(margin, viewport.x * 0.28), random_between(viewport.y * 0.66, viewport.y - size.y - margin))
		3:
			return Vector2(random_between(viewport.x * 0.66, viewport.x - size.x - margin), random_between(viewport.y * 0.66, viewport.y - size.y - margin))
		4:
			return Vector2(random_between(margin, viewport.x - size.x - margin), random_between(margin, viewport.y * 0.16))
	return Vector2(random_between(margin, viewport.x - size.x - margin), random_between(viewport.y * 0.82, viewport.y - size.y - margin))

func random_between(a: float, b: float) -> float:
	var low = min(a, b)
	var high = max(a, b)
	if is_equal_approx(low, high):
		return low
	return rng.randf_range(low, high)

func hud_avoid_rects(viewport: Vector2) -> Array:
	var rects = [
		_padded_layout_rect(HtmlLayoutMetrics.combat_hud_rect(viewport), 10),
		_padded_layout_rect(HtmlLayoutMetrics.economy_hud_rect(viewport), 10),
		_padded_layout_rect(HtmlLayoutMetrics.difficulty_hud_rect(viewport), 10),
		_padded_layout_rect(HtmlLayoutMetrics.status_hud_rect(viewport), 8),
	]
	if HtmlLayoutMetrics.debug_visible_for_viewport(viewport):
		rects.append(_padded_layout_rect(HtmlLayoutMetrics.debug_hud_rect(viewport), 8))
	if state.cleanupComboValue > 0:
		rects.append(_padded_layout_rect(HtmlLayoutMetrics.cleanup_hud_rect(viewport), 8))
	return rects

func _padded_layout_rect(rect: Rect2, padding: float) -> Rect2:
	return padded_rect(rect.position, rect.size, padding)

func padded_rect(position: Vector2, size: Vector2, padding: float) -> Rect2:
	return Rect2(position - Vector2(padding, padding), size + Vector2(padding * 2.0, padding * 2.0))

func pointer_avoid_rect():
	if state.pointerScreenX == null or state.pointerScreenY == null:
		return null
	return Rect2(Vector2(float(state.pointerScreenX) - 70.0, float(state.pointerScreenY) - 50.0), Vector2(140, 100))

func reserved_popup_rects(ignore_id := -1) -> Array:
	var rects = []
	for popup in state.openPopups:
		if int(popup.id) != ignore_id:
			rects.append(Rect2(popup.position, popup.size))
	for pending in state.pendingPopupSpawns:
		if pending.has("position") and pending.has("def"):
			rects.append(Rect2(pending.position, popup_size_for(pending.def)))
	return rects

func overlap_size(a: Rect2, b: Rect2) -> Vector2:
	var width = max(0.0, min(a.position.x + a.size.x, b.position.x + b.size.x) - max(a.position.x, b.position.x))
	var height = max(0.0, min(a.position.y + a.size.y, b.position.y + b.size.y) - max(a.position.y, b.position.y))
	return Vector2(width, height)

func popup_overlap_conflict(rect: Rect2, ignore_id := -1):
	for other in reserved_popup_rects(ignore_id):
		var overlap = overlap_size(rect, other)
		var max_width = min(rect.size.x, other.size.x) * float(config.get("popupOverlapMaxWidthRatio", 0.5))
		var max_height = min(rect.size.y, other.size.y) * float(config.get("popupOverlapMaxHeightRatio", 0.5))
		if overlap.x > max_width and overlap.y > max_height:
			return {"other": other, "overlap": overlap, "maxWidth": max_width, "maxHeight": max_height}
	return null

func popup_placement_score(rect: Rect2, avoid_rects: Array, ignore_id := -1) -> float:
	var score = 0.0
	for avoid in avoid_rects:
		var overlap = overlap_size(rect, avoid)
		if overlap.x > 0.0 and overlap.y > 0.0:
			score += 100000.0 + overlap.x * overlap.y * 20.0
	for other in reserved_popup_rects(ignore_id):
		var overlap = overlap_size(rect, other)
		var max_width = min(rect.size.x, other.size.x) * float(config.get("popupOverlapMaxWidthRatio", 0.5))
		var max_height = min(rect.size.y, other.size.y) * float(config.get("popupOverlapMaxHeightRatio", 0.5))
		if overlap.x > max_width and overlap.y > max_height:
			score += 1000000.0 + overlap.x * overlap.y * 50.0
		score += max(0.0, overlap.x - max_width) * max(0.0, overlap.y - max_height)
	return score

func push_rect_out_of_popup_overlap(rect: Rect2, margin: float, layer_width: float, layer_height: float, ignore_id := -1) -> Rect2:
	var moved = rect
	for i in range(10):
		var conflict = popup_overlap_conflict(moved, ignore_id)
		if conflict == null:
			break
		var center = moved.position + moved.size * 0.5
		var other: Rect2 = conflict.other
		var other_center = other.position + other.size * 0.5
		var push_x = float(conflict.overlap.x) - float(conflict.maxWidth) + 10.0
		var push_y = float(conflict.overlap.y) - float(conflict.maxHeight) + 10.0
		if push_x <= push_y:
			moved.position.x += push_x if center.x >= other_center.x else -push_x
		else:
			moved.position.y += push_y if center.y >= other_center.y else -push_y
		moved.position.x = clamp(moved.position.x, margin, max(margin, layer_width - moved.size.x - margin))
		moved.position.y = clamp(moved.position.y, margin, max(margin, layer_height - moved.size.y - margin))
	return moved

func update_moving_popup_position(popup: Dictionary, dt: float) -> void:
	var viewport = get_viewport().get_visible_rect().size
	popup.position += popup.velocity * dt
	if popup.position.x < 0.0 or popup.position.x + popup.size.x > viewport.x:
		popup.velocity.x *= -1.0
	if popup.position.y < 0.0 or popup.position.y + popup.size.y > viewport.y:
		popup.velocity.y *= -1.0
	clamp_popup_to_layer(popup)

func clamp_popup_to_layer(popup: Dictionary) -> void:
	var viewport = get_viewport().get_visible_rect().size
	var margin = 4.0
	popup.position.x = clamp(popup.position.x, margin, max(margin, viewport.x - popup.size.x - margin))
	popup.position.y = clamp(popup.position.y, margin, max(margin, viewport.y - popup.size.y - margin))

func bring_popup_to_front(id: int) -> void:
	var popup = popup_by_id(id)
	if popup == null:
		return
	popup.z = z_seed
	z_seed += 1
	state.openPopups.erase(popup)
	state.openPopups.append(popup)

func start_dragging_popup(id: int) -> void:
	state.draggingPopup = id

func popup_drag_multiplier() -> float:
	return max(0.5, 1.0 + float(state.stats.popupDragSpeedMultiplier))

func move_popup(id: int, position: Vector2) -> void:
	var popup = popup_by_id(id)
	if popup == null:
		return
	popup.position = position
	clamp_popup_to_layer(popup)

func settle_dragged_popup(id: int) -> void:
	var popup = popup_by_id(id)
	state.draggingPopup = null
	if popup == null:
		return
	if Rect2(popup.position, popup.size).intersects(trash_zone_rect()):
		request_close_popup(id, {"reason": "trash"})
		return
	var viewport = get_viewport().get_visible_rect().size
	var settled = push_rect_out_of_popup_overlap(Rect2(popup.position, popup.size), 4.0, viewport.x, viewport.y, id)
	popup.position = settled.position

func trash_zone_rect() -> Rect2:
	var viewport = get_viewport().get_visible_rect().size
	return Rect2(Vector2((viewport.x - 160.0) * 0.5, viewport.y - 72.0), Vector2(160.0, 58.0))

func toggle_popup_minimized(id: int) -> void:
	var popup = popup_by_id(id)
	if popup != null:
		popup.minimized = not popup.get("minimized", false)

func request_close_popup(id: int, options = {}) -> void:
	var popup = popup_by_id(id)
	if popup == null:
		return
	var close_policy = PopupClosePolicyScript.policy_for(popup)
	match close_policy:
		PopupClosePolicyScript.MINIMIZE_ONLY:
			create_system_growth_popup("증권 앱 고정", "증권 앱은 닫을 수 없습니다. 최소화하거나 전량 매도만 할 수 있습니다.")
			return
		PopupClosePolicyScript.FORCED_CHOICE:
			create_system_growth_popup("첫 결제 대기", "첫 결제 팝업은 창 닫기나 긴급 닫기로 닫을 수 없습니다. 결제하거나 거절을 선택하세요.")
			return
		PopupClosePolicyScript.INTERNAL_RESOLVE:
			create_system_growth_popup("정산 필요", "돈이 걸린 팝업은 내부의 정산/해지/매도 버튼으로 처리해야 닫을 수 있습니다.")
			return
		PopupClosePolicyScript.INPUT_GRACE:
			create_system_growth_popup("입력 유예 중", "잠시 후 다시 닫을 수 있습니다.")
			return
	var reason = options.get("reason", "button")
	if reason == "volatile":
		trigger_volatile_popup_close(id)
		return
	if popup.def.type == "infected_popup":
		state.heat += 0.15
	if state.moduleSynergy.get("id", "") == "popup_trigger":
		trigger_module_attack("primary")
	if selected_mechanic_for_slot("primary").get("id", "") == "popup_close_trigger":
		state.popupCloseAttackPrimed = true
	var is_real_popup = popup.def.get("category", "") != "system" and popup.def.type != "first_purchase_package"
	if is_real_popup and is_cleanup_combo_reason(reason, popup):
		register_cleanup_combo(reason)
		if state.stats.goldPerPopupClose > 0:
			add_gold(int(state.stats.goldPerPopupClose), "popupClose")
		if state.stats.popupCloseDamage > 0:
			apply_popup_close_damage()
	clear_popup_runtime_links(popup)
	state.openPopups.erase(popup)

func remove_popup_without_reward(id: int) -> void:
	var popup = popup_by_id(id)
	if popup != null:
		clear_popup_runtime_links(popup)
		state.openPopups.erase(popup)

func clear_popup_runtime_links(popup: Dictionary) -> void:
	if popup.def.type == "infection":
		clear_infection_target(popup)
	if int(popup.get("infectionSourceId", 0)) != 0:
		var source = popup_by_id(int(popup.infectionSourceId))
		if source != null and int(source.get("infectionTargetId", 0)) == int(popup.id):
			source.infectionTargetId = 0
			source.infectionTimer = 0.0
		popup.infectedByPopup = false
		popup.infectionSourceId = 0

func is_popup_locked(popup: Dictionary) -> bool:
	return not [PopupClosePolicyScript.NORMAL, PopupClosePolicyScript.AUTO_CLOSE].has(PopupClosePolicyScript.policy_for(popup))

func is_emergency_closable_popup(popup: Dictionary) -> bool:
	return [PopupClosePolicyScript.NORMAL, PopupClosePolicyScript.AUTO_CLOSE].has(PopupClosePolicyScript.policy_for(popup))

func emergency_close_oldest_popup() -> void:
	if state.gameOver or is_selecting() or state.stats.emergencyCloseDisabled > 0 or state.emergencyTimer > 0.0 or state.openPopups.is_empty():
		return
	var target = null
	if state.stats.smartEmergencyClose > 0:
		for popup in state.openPopups:
			if ["volatile_popup", "infection", "infected_popup", "terms"].has(popup.def.type) and is_emergency_closable_popup(popup):
				target = popup
				break
	if target == null:
		for popup in state.openPopups:
			if is_emergency_closable_popup(popup):
				target = popup
				break
	if target == null:
		if state.openPopups.any(func(popup): return popup.def.type == "stock_broker_app"):
			create_system_growth_popup("긴급 닫기 실패", "증권 앱은 긴급 닫기 대상이 아닙니다.")
		else:
			create_system_growth_popup("긴급 닫기 실패", "열린 팝업이 모두 정산 필요 상태입니다.")
		return
	request_close_popup(target.id, {"reason": "emergency"})
	state.emergencyTimer = float(config.emergencyCloseCooldown) * max(0.2, 1.0 + state.stats.emergencyCooldownMultiplier)
	state.emergencyBoostTimer = 5.0

func is_cleanup_combo_reason(reason: String, popup: Dictionary) -> bool:
	return ["button", "manual", "emergency", "trash", "auto_cleanup"].has(reason)

func register_cleanup_combo(reason = "") -> void:
	state.cleanupComboStacks = min(state.cleanupComboMax, state.cleanupComboStacks + 1)
	state.cleanupComboValue = state.cleanupComboStacks
	state.cleanupComboTimer = effective_cleanup_combo_grace()
	state.cleanupComboPulse = 0.5

func update_cleanup_combo(dt: float) -> void:
	state.cleanupComboPulse = max(0.0, state.cleanupComboPulse - dt)
	if state.cleanupComboTimer > 0.0:
		state.cleanupComboTimer -= dt
		if state.cleanupComboTimer <= 0.0:
			state.cleanupComboStacks = 0

func effective_cleanup_combo_grace() -> float:
	return state.cleanupComboGrace + state.stats.cleanupComboGraceBonus

func cleanup_combo_meta() -> String:
	if state.cleanupComboValue <= 0:
		return "대기 중"
	if state.cleanupComboTimer > 0:
		return "%.1fs 유지" % state.cleanupComboTimer
	return "감소 중"

func trigger_volatile_popup_close(id: int) -> void:
	var popup = popup_by_id(id)
	if popup == null:
		return
	explode_at(state.player.position, 150.0, 60.0, "primary")
	state.metrics.volatileClosures += 1
	state.openPopups.erase(popup)
	register_cleanup_combo("volatile")

func infection_forbidden_type(type: String) -> bool:
	return ["infection", "infected_popup", "first_purchase_package", "boss_package_ad", "stock_broker_app", "system_notice", "interest_offer", "recurring_investment", "loan_offer", "stock_market"].has(type)

func is_eligible_infection_target(source_popup: Dictionary, target_popup) -> bool:
	if target_popup == null or source_popup.id == target_popup.id:
		return false
	if infection_forbidden_type(target_popup.def.type) or target_popup.def.get("category", "") == "system" or is_popup_locked(target_popup):
		return false
	if target_popup.get("infectedByPopup", false) and int(target_popup.get("infectionSourceId", 0)) != int(source_popup.id):
		return false
	if target_popup.get("securityQuarantineTimer", 0.0) > 0.0:
		return false
	return ["sponsored_ad", "timed_reward", "clean_challenge", "popup_store", "volatile_popup", "moving_close"].has(target_popup.def.type) or target_popup.def.get("copyTone", "") == "product_ad"

func infection_priority(popup: Dictionary) -> int:
	var scores = {
		"sponsored_ad": 6,
		"timed_reward": 5,
		"clean_challenge": 5,
		"popup_store": 4,
		"volatile_popup": 3,
		"moving_close": 2,
	}
	return int(scores.get(popup.def.type, 1 if popup.def.get("copyTone", "") == "product_ad" else 0))

func clear_infection_target(source_popup: Dictionary) -> void:
	if int(source_popup.get("infectionTargetId", 0)) == 0:
		return
	var target = popup_by_id(int(source_popup.infectionTargetId))
	if target != null and int(target.get("infectionSourceId", 0)) == int(source_popup.id):
		target.infectedByPopup = false
		target.infectionSourceId = 0
	source_popup.infectionTargetId = 0

func choose_infection_target(source_popup: Dictionary):
	var current = popup_by_id(int(source_popup.get("infectionTargetId", 0)))
	if is_eligible_infection_target(source_popup, current):
		return current
	clear_infection_target(source_popup)
	var candidates = state.openPopups.filter(func(popup): return is_eligible_infection_target(source_popup, popup))
	if candidates.is_empty():
		return null
	candidates.sort_custom(func(a, b):
		var diff = infection_priority(b) - infection_priority(a)
		if diff != 0:
			return diff < 0
		return int(a.id) < int(b.id)
	)
	var target = candidates[0]
	source_popup.infectionTargetId = target.id
	source_popup.infectionTimer = 0.0
	target.infectedByPopup = true
	target.infectionSourceId = source_popup.id
	return target

func infect_popup(source_popup: Dictionary) -> bool:
	var target = popup_by_id(int(source_popup.get("infectionTargetId", 0)))
	if not is_eligible_infection_target(source_popup, target):
		source_popup.infectionTimer = 0.0
		clear_infection_target(source_popup)
		return false
	var original_title = target.def.get("title", "팝업")
	var pos = target.position
	clear_infection_target(source_popup)
	remove_popup_without_reward(target.id)
	var infected = create_popup(infected_popup_definition(original_title))
	infected.position = pos
	infected.inputGrace = 0.15
	state.recentPerkText = "팝업 감염: %s 창이 감염되어 보상과 기능이 손상되었습니다." % original_title
	return true

func infected_popup_definition(original_title := "팝업") -> Dictionary:
	return {"id": "infected_popup", "title": "감염된 팝업", "body": "'%s' 창이 오염되었습니다. 원래 보상과 기능은 손상되었고, 이 창은 직접 닫아야 합니다." % original_title, "type": "infected_popup", "copyTone": "product_ad", "families": ["generic", "clutter"], "duration": 0.0, "weight": 0.0}

func create_system_growth_popup(title: String, detail: String) -> void:
	create_popup({
		"id": "system_notice_%d" % Time.get_ticks_msec(),
		"title": "시스템 알림",
		"body": "%s\n%s" % [title, detail],
		"type": "system_notice",
		"category": "system",
		"families": ["system"],
		"copyTone": "system_warning",
		"autoClose": 3.4,
		"weight": 0.0,
	})

func timed_reward_duration(def: Dictionary) -> float:
	return float(def.get("duration", 15.0)) * max(0.25, 1.0 + state.stats.timedRewardDurationMultiplier)

func update_ad_passive_income(dt: float) -> void:
	var open_ads = count_open_ad_popups()
	if open_ads <= 0 or state.stats.adGoldPerSecond <= 0.0:
		return
	state.adOpenTime += float(open_ads) * dt
	state.adGoldBank += float(open_ads) * state.stats.adGoldPerSecond * max(0.1, 1.0 + state.stats.adGoldMultiplier) * dt
	var payout = int(floor(state.adGoldBank))
	if payout > 0:
		add_gold(payout, "adPassive")
		state.adGoldBank -= payout

func grant_timed_reward(def: Dictionary) -> void:
	if def.has("rewardGold"):
		var amount = int(round(float(def.rewardGold) * max(0.1, 1.0 + state.stats.rewardGoldMultiplier)))
		add_gold(amount, "timedReward")
	else:
		apply_effect(def.get("reward", {"type": "gold", "value": 30}))

func grant_sponsored_reward(popup: Dictionary) -> void:
	var rewards = popup.def.get("completionRewards", popup.def.get("rewardEffects", []))
	if rewards.is_empty() and popup.def.has("reward"):
		rewards = [popup.def.reward]
	for effect in rewards:
		apply_sponsored_reward(effect)
	state.sponsoredCompletions += 1
	if state.activePlaystyle == "sponsored_starter":
		state.sponsoredAttackBoostStacks = min(20, state.sponsoredAttackBoostStacks + 5)

func apply_sponsored_reward(effect: Dictionary) -> void:
	if effect.is_empty():
		return
	state.metrics.sponsoredRewards += 1
	match effect.get("type", "stat"):
		"gold":
			var amount = int(round(float(effect.get("value", 0)) * max(0.1, 1.0 + state.stats.sponsoredRewardMultiplier)))
			add_gold(amount, "sponsored")
		"itemDiscount":
			state.nextItemDiscounts.append({"value": effect.get("value", 0.2), "uses": effect.get("uses", 1)})
		"freeSampleItem":
			for i in range(int(effect.get("count", 1))):
				var item = random_item_by_rarity(effect.get("rarity", "Common"))
				if not item.is_empty():
					apply_item_reward(item)
		"extraItemChoice":
			state.nextItemExtraChoices += int(effect.get("value", 1))
		_:
			apply_effect(effect)

func count_open_ad_popups() -> int:
	var count = 0
	for popup in state.openPopups:
		if popup.def.type == "sponsored_ad":
			count += 1
	return count

func accept_terms_popup(id: int, risky: bool) -> void:
	var popup = popup_by_id(id)
	if popup == null:
		return
	var def = popup.def
	if risky:
		apply_terms_reward_effects(def.get("riskyRewardEffects", [{"type": "gold", "value": def.get("rewardGold", 50)}]), true)
		if state.stats.termsPenaltyShield > 0:
			state.stats.termsPenaltyShield -= 1
		else:
			state.termsPenaltyCount += 1
			for penalty in def.get("penaltyEffects", [{"type": "stat", "stat": def.get("penaltyStat", "heat"), "value": def.get("penaltyValue", 1)}]):
				apply_effect(penalty)
			if state.stats.goldPerTermsPenalty > 0:
				add_gold(state.stats.goldPerTermsPenalty, "termsPenalty")
		state.heat += float(def.get("heatOnRisk", 1.0))
	else:
		apply_terms_reward_effects(def.get("safeRewardEffects", [{"type": "gold", "value": def.get("safeRewardGold", 20)}]), false)
	request_close_popup(id, {"reason": "terms_accept"})

func toggle_terms_risk(id: int) -> void:
	var popup = popup_by_id(id)
	if popup == null or popup.def.type != "terms":
		return
	popup.termsRiskChecked = not popup.get("termsRiskChecked", true)

func apply_terms_reward_effects(effects: Array, risky: bool) -> void:
	var heat_reward_multiplier = 1.15 if risky and state.heat >= 3.0 else 1.0
	for effect in effects:
		if effect.get("type", "") == "gold":
			add_gold(int(round(float(effect.get("value", 0)) * heat_reward_multiplier)), "terms")
		else:
			apply_effect(effect)

func accept_interest_offer(id: int, ratio: float) -> void:
	var popup = popup_by_id(id)
	if popup == null or popup.get("interestAccepted", false):
		return
	var selected = interest_deposit_option(popup, ratio)
	var principal = int(floor(state.gold * float(selected.get("ratio", ratio))))
	if principal < 30 or state.gold < principal:
		return
	state.gold -= principal
	state.investedGold += principal
	popup.interestAccepted = true
	popup.interestMatured = false
	popup.interestPrincipal = principal
	popup.interestPayout = int(round(principal * (1.0 + float(selected.get("bonus", 0.2)))))
	popup.interestMaturityProgress = 0.0
	popup.progress = 0.0
	state.metrics.interestAccepted += 1
	add_credit_score(2, "예치 상품 수락")

func interest_payout(principal: int) -> int:
	return int(round(principal * (1.22 + state.stats.interestPayoutMultiplier)))

func interest_deposit_option(popup: Dictionary, ratio: float) -> Dictionary:
	for option in popup.get("depositOptions", []):
		if abs(float(option.get("ratio", 0.0)) - ratio) < 0.001:
			return option
	return {"label": "예치", "ratio": ratio, "bonus": 0.2}

func interest_popup_payout(popup: Dictionary) -> int:
	return int(round(float(popup.interestPayout) * max(0.1, 1.0 + state.stats.interestPayoutMultiplier)))

func cancel_interest_offer(id: int) -> void:
	var popup = popup_by_id(id)
	if popup == null or not popup.get("interestAccepted", false) or popup.get("interestMatured", false):
		request_close_popup(id, {"reason": "interest_cancel"})
		return
	var refund = int(floor(float(popup.interestPrincipal) * 0.4))
	popup.interestMatured = true
	state.investedGold = max(0, state.investedGold - int(popup.interestPrincipal))
	add_gold(refund, "investmentRefund")
	add_credit_score(-8, "예치 상품 중도 해지")
	state.metrics.interestLost += 1
	remove_popup_without_reward(id)

func complete_interest_popup(popup: Dictionary) -> void:
	if popup == null or popup.get("interestMatured", false) or not popup.get("interestAccepted", false):
		return
	popup.interestMatured = true
	state.investedGold = max(0, state.investedGold - int(popup.interestPrincipal))
	add_gold(interest_popup_payout(popup), "interest")
	add_credit_score(8, "예치 상품 만기 정산")
	state.metrics.interestCompleted += 1
	remove_popup_without_reward(popup.id)

func complete_interest_event(event: Dictionary) -> void:
	state.investedGold = max(0, state.investedGold - event.principal)
	add_gold(event.payout, "investmentPayout")
	add_credit_score(8, "예치 상품 만기 정산")
	state.metrics.interestCompleted += 1

func accept_recurring_investment(id: int) -> void:
	var popup = popup_by_id(id)
	if popup == null:
		return
	popup.investment.accepted = true
	popup.investment.elapsed = 0.0
	add_credit_score(2, "자동 적립 수락")

func cancel_recurring_investment(id: int) -> void:
	var popup = popup_by_id(id)
	if popup == null:
		return
	var refund = int(round(popup.investment.accumulated * 0.72))
	popup.investment.matured = true
	state.investedGold = max(0, state.investedGold - popup.investment.accumulated)
	add_gold(refund, "investmentRefund")
	add_credit_score(-8, "자동 적립 중도 해지")
	remove_popup_without_reward(id)

func complete_recurring_investment(popup: Dictionary) -> void:
	var payout = int(round(popup.investment.accumulated * (1.0 + popup.investment.get("maturityBonus", 0.28))))
	popup.investment.matured = true
	state.investedGold = max(0, state.investedGold - popup.investment.accumulated)
	add_gold(payout, "investmentPayout")
	add_credit_score(8, "자동 적립 만기")
	state.metrics.interestCompleted += 1
	remove_popup_without_reward(popup.id)

func active_recurring_investment():
	for popup in state.openPopups:
		if popup.def.type == "recurring_investment" and popup.has("investment") and popup.investment.get("accepted", false) and not popup.investment.get("matured", false):
			return popup
	return null

func credit_cashout_options() -> Array:
	return [
		{"id": "small", "label": "소액 현금화", "creditCost": 6, "gold": 50},
		{"id": "medium", "label": "중간 현금화", "creditCost": 12, "gold": 110},
		{"id": "large", "label": "대형 현금화", "creditCost": 20, "gold": 210},
	]

func accept_credit_cashout(id: int, option: Dictionary) -> void:
	if state.creditScore < option.creditCost:
		return
	add_credit_score(-option.creditCost, "신용 현금화")
	add_gold(option.gold, "creditCashout")
	request_close_popup(id, {"reason": "loan_accept"})

func add_credit_score(delta: int, reason = "") -> void:
	state.creditScore = clamp(state.creditScore + delta, 0, 100)

func update_stock_market(dt: float) -> void:
	var market = state.stockMarket
	market.tickTimer -= dt
	if market.tickTimer > 0.0:
		return
	market.tickTimer = 1.0
	var stock = market.stock
	var bias = stock_market_bias()
	var change = bias.drift + rng.randfn(0.0, bias.volatility)
	stock.price = max(2.0, stock.price * (1.0 + change))
	stock.lastChange = change
	stock.history.append(stock.price)
	if stock.history.size() > 64:
		stock.history.pop_front()
	market.lastBiasLabel = bias.label

func stock_market_bias() -> Dictionary:
	if current_difficulty_score() >= 11.0:
		return {"label": "붕괴장", "drift": -0.006, "volatility": 0.16}
	if state.openPopups.size() >= 5:
		return {"label": "과열장", "drift": 0.008, "volatility": 0.13}
	if active_playstyle_key() == "investor":
		return {"label": "우호장", "drift": 0.006, "volatility": 0.075}
	return {"label": "조용한 장세", "drift": 0.003, "volatility": 0.085}

func update_stock_market_popup(popup: Dictionary, dt: float) -> void:
	if not popup.has("stock") or not popup.stock.get("invested", false):
		return
	var stock = popup.stock
	stock.elapsed += dt
	stock.tickTimer -= dt
	if stock.tickTimer > 0.0:
		return
	stock.tickTimer = 1.0
	var change = float(stock.drift) + rng.randf_range(-float(stock.volatility), float(stock.volatility))
	stock.currentValue = max(1.0, float(stock.currentValue) * (1.0 + change))
	stock.lastTrend = "%s %+d%%" % ["상승" if change >= 0.0 else "하락", round(change * 100.0)]
	stock.history.append(float(stock.currentValue))
	if stock.history.size() > 60:
		stock.history.pop_front()
	popup.progress = clamp(float(stock.currentValue) / max(float(stock.principal) * 2.0, 1.0), 0.0, 1.0)

func invest_stock_popup(id: int, principal: int) -> void:
	var popup = popup_by_id(id)
	if popup == null or not popup.has("stock") or popup.stock.get("invested", false):
		return
	if state.gameOver or state.gold < principal:
		return
	state.gold -= principal
	state.investedGold += principal
	popup.stock.invested = true
	popup.stock.principal = principal
	popup.stock.currentValue = float(principal)
	popup.stock.elapsed = 0.0
	popup.stock.tickTimer = 0.0
	popup.stock.lastTrend = "매수 완료"
	popup.stock.history = [float(principal)]
	popup.progress = 0.5

func sell_stock_popup(id: int) -> void:
	var popup = popup_by_id(id)
	if popup == null or not popup.has("stock") or not popup.stock.get("invested", false):
		return
	var stock = popup.stock
	var payout = max(1, int(floor(float(stock.currentValue))))
	var principal = int(stock.principal)
	var profit = payout - principal
	state.investedGold = max(0, state.investedGold - principal)
	add_gold(payout, "stock")
	if profit >= 0:
		add_credit_score(5, "주식 수익 매도")
	else:
		add_credit_score(-8, "주식 손실 매도")
		if popup.def.get("cursedLossDifficulty", 0) > 0:
			state.heat += float(popup.def.cursedLossDifficulty)
	popup.stock.invested = false
	remove_popup_without_reward(id)

func ensure_stock_broker_app() -> void:
	for popup in state.openPopups:
		if popup.def.type == "stock_broker_app":
			return
	create_popup(popup_def_by_id("stock_broker_app"))

func buy_stock(count: int) -> void:
	var stock = state.stockMarket.stock
	var cost = int(ceil(stock.price * count))
	if count <= 0 or state.gold < cost:
		return
	var previous_value = stock.avgCost * stock.shares
	state.gold -= cost
	stock.shares += count
	stock.avgCost = (previous_value + cost) / max(1, stock.shares)
	state.investedGold += cost

func buy_max_stock() -> void:
	var stock = state.stockMarket.stock
	var count = int(floor(state.gold / max(stock.price, 1.0)))
	buy_stock(count)

func sell_stock_shares(count: int) -> void:
	var stock = state.stockMarket.stock
	count = min(count, stock.shares)
	if count <= 0:
		return
	var proceeds = int(floor(stock.price * count))
	var principal = stock.avgCost * count
	var profit = proceeds - principal
	stock.shares -= count
	if stock.shares <= 0:
		stock.avgCost = 0.0
	state.investedGold = max(0, state.investedGold - int(round(principal)))
	add_gold(proceeds, "stockSale")
	if profit >= 0.0:
		add_credit_score(4, "주식 수익 매도")
	else:
		add_credit_score(-6, "주식 손실 매도")
		if current_difficulty_score() >= 4.0:
			state.heat += 0.2

func sell_all_stock() -> void:
	sell_stock_shares(state.stockMarket.stock.shares)

func update_resident_programs(dt: float) -> void:
	update_security_quarantines(dt)
	if state.stats.autoCloseBasicInterval > 0.0:
		state.autoCloseBasicTimer -= dt
		if state.autoCloseBasicTimer <= 0.0:
			state.autoCloseBasicTimer = max(2.0, state.stats.autoCloseBasicInterval)
			for popup in state.openPopups:
				if ["sponsored_ad", "moving_close", "infection", "infected_popup", "volatile_popup"].has(popup.def.type):
					request_close_popup(popup.id, {"reason": "auto_cleanup"})
					break
	for program in state.residentPrograms:
		program.angle = float(program.get("angle", 0.0)) + dt * 1.75
		if program.get("suspended", false):
			program.suspendedTimer -= dt
			if program.suspendedTimer <= 0.0:
				program.suspended = false
		if program.get("suspended", false):
			continue
		update_resident_program_notice_timer(program, dt)
		update_resident_program_upkeep(program, dt)
		if program.get("suspended", false):
			continue
		update_resident_program(program, dt)

func update_security_quarantines(dt: float) -> void:
	var ready = []
	for popup in state.openPopups:
		if popup.get("securityQuarantineTimer", 0.0) <= 0.0:
			continue
		popup.securityQuarantineTimer = max(0.0, float(popup.securityQuarantineTimer) - dt)
		if popup.securityQuarantineTimer <= 0.0:
			ready.append(popup.id)
	for id in ready:
		request_close_popup(id, {"reason": "security"})

func update_resident_program_notice_timer(program: Dictionary, dt: float) -> void:
	program.updateTimer = float(program.get("updateTimer", rng.randf_range(24.0, 34.0))) - dt
	if program.updateTimer > 0.0:
		return
	var def = program.def
	var interval = def.get("updateInterval", [24.0, 34.0])
	program.updateTimer = rng.randf_range(float(interval[0]), float(interval[1]))
	if state.openPopups.size() + state.pendingPopupSpawns.size() < max_open_popups():
		var popup_def = popup_def_by_id("security_update_notice").duplicate(true)
		popup_def.title = "%s 알림" % program.name
		popup_def.body = "%s 업데이트 확인이 필요합니다. 자동 보호는 유지되지만 이 창은 직접 확인해야 사라집니다." % program.name
		create_popup(popup_def)

func update_resident_program_upkeep(program: Dictionary, dt: float) -> void:
	var def = program.def
	if not def.has("upkeepInterval"):
		return
	program.upkeepTimer = float(program.get("upkeepTimer", def.upkeepInterval)) - dt
	if program.upkeepTimer > 0.0:
		return
	program.upkeepTimer = float(def.upkeepInterval)
	var cost = int(def.get("upkeepGold", 0))
	if cost <= 0:
		return
	if state.gold >= cost:
		state.gold -= cost
	else:
		program.suspended = true
		program.suspendedTimer = max(6.0, float(def.upkeepInterval) * 0.5)
		if state.openPopups.size() + state.pendingPopupSpawns.size() < max_open_popups():
			var popup_def = popup_def_by_id("security_update_notice").duplicate(true)
			popup_def.title = "%s 결제 실패" % program.name
			popup_def.body = "%s 유지비 %dG 결제 실패. 프로그램이 일시 정지되었습니다." % [program.name, cost]
			create_popup(popup_def)

func update_resident_program(program: Dictionary, dt: float) -> void:
	var def = program.def
	if def.has("attackInterval"):
		program.attackTimer = float(program.get("attackTimer", 0.0)) - dt
		if program.attackTimer <= 0.0:
			run_security_orbit_attack(program)
			program.attackTimer = float(def.attackInterval)
	if def.has("scanInterval"):
		program.scanTimer = float(program.get("scanTimer", def.scanInterval)) - dt
		if program.scanTimer <= 0.0:
			program.scanTimer = float(def.scanInterval)
			run_security_scan(program)
	if def.has("quarantineInterval"):
		program.quarantineTimer = float(program.get("quarantineTimer", def.quarantineInterval)) - dt
		if program.quarantineTimer <= 0.0:
			program.quarantineTimer = float(def.quarantineInterval)
			var target = find_security_quarantine_target()
			if target != null:
				start_security_quarantine(target)

func run_security_orbit_attack(program: Dictionary) -> void:
	var def = program.def
	var origin = security_orbit_position(program)
	var target = get_nearest_enemy_from(origin, float(def.get("range", 42.0)))
	if target == null:
		return
	damage_enemy_tracked(target, float(def.get("damage", 6.0)), "security")
	var direction = (target.position - origin).normalized() if target.position.distance_to(origin) > 0.01 else Vector2.RIGHT
	target.position += direction * float(def.get("knockback", 70.0)) * 0.08
	state.attacks.append({"kind": "slash", "position": origin, "endPosition": target.position, "width": 10.0, "life": 0.12, "maxLife": 0.12})

func security_orbit_position(program: Dictionary) -> Vector2:
	var angle = float(program.get("angle", 0.0))
	var radius = float(program.def.get("orbitRadius", 58.0))
	return state.player.position + Vector2(cos(angle), sin(angle)) * radius

func run_security_scan(program: Dictionary) -> void:
	var def = program.def
	var radius = float(def.get("scanRadius", def.get("range", 80)))
	var damage = float(def.get("damage", 8)) * float(program.get("damageBoost", 1.0))
	for enemy in state.enemies.duplicate():
		if enemy.position.distance_to(state.player.position) <= radius + enemy.radius:
			damage_enemy_tracked(enemy, damage, "security")
			if def.get("knockback", 0) > 0:
				var direction = (enemy.position - state.player.position).normalized() if enemy.position.distance_to(state.player.position) > 0.01 else Vector2.RIGHT
				enemy.position += direction * float(def.knockback) * 0.08
	state.attacks.append({"kind": "circle", "position": state.player.position, "radius": radius, "life": 0.22, "maxLife": 0.22})
	if program.type == "realtime_guard":
		for popup in state.openPopups:
			if popup.def.type == "infection":
				popup.infectionTimer = max(0.0, float(popup.get("infectionTimer", 0.0)) - 1.4)
	if program.type == "kernel_guard" and rng.randf() < 0.45:
		var target = find_security_quarantine_target()
		if target != null:
			start_security_quarantine(target)

func find_security_quarantine_target():
	for popup in state.openPopups:
		if popup.get("securityQuarantineTimer", 0.0) > 0.0 or is_popup_locked(popup):
			continue
		if ["timed_reward", "infection", "infected_popup", "moving_close"].has(popup.def.type) or popup.def.get("copyTone", "") == "product_ad":
			return popup
	return null

func start_security_quarantine(popup: Dictionary) -> bool:
	if popup == null:
		return false
	popup.securityQuarantineTimer = 1.2
	return true

func install_resident_program(type: String, popup_id = 0, free := false) -> bool:
	var def = security_program_def(type)
	if def.is_empty() or installed_resident_program(type) != null:
		create_system_growth_popup("보안 설치 취소", "이미 설치된 보안 프로그램입니다.")
		return false
	if not free and state.gold < int(def.installCost):
		create_system_growth_popup("설치 실패", "보안 프로그램 설치 비용이 부족합니다.")
		return false
	if not free:
		state.gold -= int(def.installCost)
	var program = make_resident_program(def)
	if type == "kernel_guard" and state.activePlaystyle == "risky_terms_starter":
		state.heat += 1.0
		program.damageBoost = 1.25
	state.residentPrograms.append(program)
	if def.has("reservedMaxHP"):
		state.reservedMaxHP += int(def.reservedMaxHP)
		state.player.maxHP = max(1.0, state.player.maxHP - int(def.reservedMaxHP))
		state.player.hp = min(state.player.hp, state.player.maxHP)
	create_system_growth_popup("보안 설치 완료", "%s 상주 프로그램이 활성화되었습니다." % program.name)
	if popup_id != 0:
		request_close_popup(popup_id, {"reason": "security_installed"})
	return true

func installed_resident_program(type: String):
	for program in state.residentPrograms:
		if program.type == type:
			return program
	return null

func make_resident_program(def: Dictionary) -> Dictionary:
	var interval = def.get("updateInterval", [24.0, 34.0])
	var program = {
		"id": state.residentProgramIdSeed,
		"type": def.type,
		"name": def.name,
		"def": def,
		"angle": rng.randf_range(0.0, TAU),
		"attackTimer": rng.randf_range(0.1, 0.6),
		"scanTimer": def.get("scanInterval", def.get("attackInterval", 1.0)),
		"quarantineTimer": def.get("quarantineInterval", 1.0),
		"updateTimer": rng.randf_range(float(interval[0]), float(interval[1])),
		"upkeepTimer": def.get("upkeepInterval", 0.0),
		"suspended": false,
		"suspendedTimer": 0.0,
	}
	state.residentProgramIdSeed += 1
	return program

func clear_resident_programs() -> void:
	state.residentPrograms.clear()
	state.player.maxHP += state.reservedMaxHP
	state.player.hp = min(state.player.maxHP, state.player.hp + state.reservedMaxHP)
	state.reservedMaxHP = 0
	create_system_growth_popup("보안 프로그램 제거", "상주 보안 프로그램을 모두 제거하고 점유 HP를 복구했습니다.")

func apply_security_update(id: int) -> void:
	if state.gold >= 20:
		state.gold -= 20
		add_credit_score(1, "보안 업데이트")
		request_close_popup(id, {"reason": "security_update"})

func suspend_security_from_popup(id: int) -> void:
	for program in state.residentPrograms:
		program.suspended = true
		program.suspendedTimer = 8.0
	request_close_popup(id, {"reason": "security_suspend"})

func security_program_def(type: String) -> Dictionary:
	for def in data.SECURITY_PROGRAM_DEFS:
		if def.type == type:
			return def
	return {}

func update_first_purchase_offer(dt: float) -> void:
	if state.firstPurchaseOfferShown:
		return
	state.firstPurchaseTimer -= dt
	if state.firstPurchaseTimer <= 0.0:
		state.firstPurchaseOfferShown = true
		create_popup(popup_def_by_id("first_purchase_package"))

func first_purchase_cost() -> int:
	if data.get("FIRST_PURCHASE_PACKAGES", []).is_empty():
		return 10
	return int(data.FIRST_PURCHASE_PACKAGES[0].get("cost", 10))

func first_purchase_status_text() -> String:
	if state.firstPurchasePackageChosen != "":
		return state.firstPurchasePackageChosen
	if state.firstPurchasePaid:
		return "결제 완료, 계약 선택 대기"
	return "미결제"

func complete_first_purchase_payment(id: int) -> void:
	var cost = first_purchase_cost()
	if state.gameOver or state.firstPurchasePaid or state.gold < cost:
		return
	var popup = popup_by_id(id)
	if popup == null:
		return
	state.gold -= cost
	state.firstPurchasePaid = true
	state.firstPurchasePackageChosen = "결제 완료, 계약 선택 대기"
	remove_popup_without_reward(id)
	open_first_purchase_package_selection()

func open_first_purchase_package_selection() -> void:
	state.selectingItem = true
	state.selectingPaidReward = true
	state.paused = true
	var choices = []
	for package in data.FIRST_PURCHASE_PACKAGES:
		var benefits = "\n".join(package.get("benefits", []))
		var copy = package.duplicate(true)
		copy.description = "%s\n%s\n%s\n%s" % [package.get("efficiencyLabel", ""), package.get("theme", ""), package.get("description", ""), benefits]
		choices.append(copy)
	hud.show_choices("스타터 계약 패키지 선택", "결제 완료. 한정 스타터 계약 1개를 선택해 이번 런의 성장 효율을 확정하세요.", choices, func(choice): apply_first_purchase_package_choice(choice), 2, 1.7)

func apply_first_purchase_package(_id: int, package: Dictionary) -> void:
	apply_first_purchase_package_choice(package)

func apply_first_purchase_package_choice(package: Dictionary) -> void:
	if state.gameOver or not state.firstPurchasePaid or state.firstPurchasePackageChosen == package.name:
		return
	apply_effect_container(package)
	state.firstPurchasePackageChosen = package.name
	state.activePlaystyle = package.id
	state.activePlaystyleName = package.name
	state.recentPerkText = "첫 계약: %s\n%s" % [package.name, package.get("description", "")]
	if package.id == "investor_starter":
		ensure_stock_broker_app()
	state.selectingItem = false
	state.selectingPaidReward = false
	hud.hide_choices()
	state.paused = false

func reject_first_purchase_package(id: int) -> void:
	state.firstPurchasePackageChosen = "거절"
	remove_popup_without_reward(id)

func effective_damage(slot: String) -> float:
	var module = module_by_id(state["%sModule" % slot])
	var base = float(module.get("baseDamage", config.playerDamage))
	if slot == "secondary":
		base *= 0.72
	base *= max(0.1, 1.0 + float(state["%sMastery" % slot]) * 0.15)
	var multiplier = 1.0 + global_damage_multiplier() + dynamic_item_damage_multiplier()
	var deepening = state["%sDeepening" % slot]
	multiplier += deepening.get("damage", 0.0)
	multiplier += scaling_damage_bonus(slot)
	if state.popupCloseAttackPrimed and slot == "primary":
		multiplier += 0.25
	return max(1.0, base * multiplier)

func effective_attack_interval(slot: String) -> float:
	var module = module_by_id(state["%sModule" % slot])
	var interval = float(module.get("baseCooldown", config.playerAttackInterval))
	interval *= max(0.12, 1.0 + state.stats.attackIntervalMultiplier - float(state["%sMastery" % slot]) * 0.03 + open_popup_stat_bonus("attackIntervalMultiplier") + active_timed_multiplier("attackIntervalMultiplier") + active_starter_combat_bonuses().cooldownMultiplier + dynamic_item_cooldown_multiplier() + dynamic_cooldown_bonus(slot))
	var deepening = state["%sDeepening" % slot]
	interval *= max(0.12, 1.0 + deepening.get("cooldown", 0.0))
	interval *= form_cooldown_multiplier(slot)
	if slot == "secondary":
		interval *= 1.18
	return max(0.08, interval)

func effective_attack_range(slot: String) -> float:
	var module = module_by_id(state["%sModule" % slot])
	var range_value = float(module.get("baseRange", config.playerAttackRange))
	range_value *= 1.0 + state.stats.attackRangeMultiplier + float(state["%sMastery" % slot]) * 0.04 + active_starter_combat_bonuses().rangeMultiplier + dynamic_item_range_multiplier() + dynamic_range_bonus(slot)
	var deepening = state["%sDeepening" % slot]
	range_value *= 1.0 + deepening.get("range", 0.0)
	return max(28.0, range_value)

func form_cooldown_multiplier(slot: String) -> float:
	match selected_form_for_slot(slot).get("id", ""):
		"aura_pulse":
			return 1.25
		"ranged_charge_cannon":
			return 1.6
		"melee_charged_cleave":
			return 1.45
		"aura_charged_nova":
			return 1.8
		"deploy_maturity_bomb":
			return 1.1
	return 1.0

func global_damage_multiplier() -> float:
	var multiplier = state.stats.damageMultiplier
	multiplier += get_open_ad_buff_multiplier()
	multiplier += active_starter_combat_bonuses().damageMultiplier
	multiplier += active_timed_multiplier("damageMultiplier")
	multiplier += state.heat * state.stats.critDamagePerDifficulty
	if state.openPopups.size() <= 2:
		multiplier += state.stats.cleanDeskDamageMultiplier
	if state.openPopups.size() >= 5:
		multiplier += 0.25 * owned_item_count("overload_cache")
	if state.cleanupComboTimer > 0.0:
		multiplier += min(0.2, state.cleanupComboValue * 0.02 * owned_item_count("empty_slot_charger"))
	if hp_ratio() <= 0.3:
		multiplier += state.stats.lowHpDamageMultiplier
	multiplier += min(1.2, floor(state.gold / 50.0) * state.stats.goldBulletDamageMultiplier)
	multiplier += min(1.6, state.sponsoredAttackBoostStacks * 0.08 * owned_item_count("sponsor_rounds"))
	return multiplier

func get_open_ad_buff_multiplier() -> float:
	return open_popup_stat_bonus("damageMultiplier")

func open_popup_stat_bonus(stat: String) -> float:
	var buff = 0.0
	for popup in state.openPopups:
		if popup.def.type == "sponsored_ad":
			for effect in popup.def.get("ongoingBuffs", []):
				if effect.get("stat", "") == stat:
					buff += effect.get("value", 0.0)
			if stat == "damageMultiplier":
				buff += state.stats.adBuffMultiplier
	return buff

func active_timed_multiplier(stat: String) -> float:
	var total = 0.0
	for effect in state.timedEffects:
		if effect.stat == stat:
			total += effect.value
	return total

func dynamic_item_damage_multiplier() -> float:
	var multiplier = 0.0
	multiplier += state.heat * 0.05 * owned_item_count("heat_blade")
	multiplier += min(0.36, floor(state.investedGold / 100.0) * 0.06 * owned_item_count("compound_barrel"))
	multiplier += min(0.2, state.cleanupComboValue * 0.02 * owned_item_count("empty_slot_charger"))
	multiplier += floor(state.player.maxHP / 100.0) * 0.05 * owned_item_count("crimson_core")
	return multiplier

func dynamic_item_range_multiplier() -> float:
	var multiplier = 0.0
	if state.creditScore >= 80:
		multiplier += 0.18 * owned_item_count("credit_scope")
	elif state.creditScore >= 60:
		multiplier += 0.1 * owned_item_count("credit_scope")
	multiplier += min(0.18, state.openPopups.size() * 0.03 * owned_item_count("popup_resonator"))
	if state.openPopups.size() <= 1:
		multiplier += 0.18 * owned_item_count("focus_lens")
	return multiplier

func dynamic_item_cooldown_multiplier() -> float:
	var multiplier = 0.0
	if state.stats.clutterAttackIntervalPerPopup < 0.0:
		multiplier += max(-0.2, state.openPopups.size() * state.stats.clutterAttackIntervalPerPopup)
	if state.openPopups.is_empty():
		multiplier -= 0.18 * owned_item_count("quiet_trigger")
	if state.cleanupComboTimer > 0.0:
		multiplier -= 0.15 * owned_item_count("close_combo")
	if hp_ratio() <= 0.35:
		multiplier += state.stats.lowHpCooldownMultiplier - 0.1 * owned_item_count("wound_engine")
	if state.draggingPopup != null:
		multiplier += state.stats.dragAttackIntervalMultiplier
	return multiplier

func dynamic_cooldown_bonus(slot: String) -> float:
	var scaling = selected_scaling_for_slot(slot).get("id", "")
	match scaling:
		"investor_credit_precision":
			return -0.15 if state.creditScore >= 80 else (-0.08 if state.creditScore >= 60 else 0.0)
		"clutter_adaptation":
			return -min(0.2, state.openPopups.size() * 0.025)
		"sponsored_monetization":
			return -min(0.18, state.sponsoredCompletions * 0.015)
		"cleanup_combo_precision":
			if state.cleanupComboValue > 0:
				return -min(5, int(floor(state.cleanupComboValue))) * 0.018
		"generic_combat_maintenance":
			return -0.08
		"generic_stable_output":
			return -0.08
	return 0.0

func dynamic_range_bonus(slot: String) -> float:
	var scaling = selected_scaling_for_slot(slot).get("id", "")
	match scaling:
		"investor_reserve_range":
			return min(0.24, floor(state.gold / 100.0) * 0.04)
		"gold_reserve_range":
			return min(0.25, floor(state.gold / 100.0) * 0.05)
		"sponsored_brand_expansion":
			return min(0.24, count_open_ad_popups() * 0.08)
		"clutter_resonance":
			return min(1.0, state.openPopups.size() * 0.12)
		"clutter_noise_amplifier":
			return min(0.3, state.openPopups.size() * 0.04)
		"clean_precision":
			return 0.25 if state.openPopups.is_empty() else (0.15 if state.openPopups.size() == 1 else 0.0)
		"clean_clear_sight":
			return 0.22 if state.openPopups.is_empty() else (0.14 if state.openPopups.size() <= 1 else 0.0)
		"cleanup_combo_precision":
			if state.cleanupComboValue > 0:
				return min(5, int(floor(state.cleanupComboValue))) * 0.035
		"risk_liability_waiver":
			return 0.08 if hp_ratio() <= 0.35 else 0.0
		"risk_premium":
			return min(0.3, difficulty_stage_index() * 0.05)
		"generic_expanded_ballistics":
			return 0.14
		"generic_combat_maintenance":
			return 0.04
		"generic_stable_output":
			return 0.12
	return 0.0

func scaling_damage_bonus(slot: String) -> float:
	var scaling = selected_scaling_for_slot(slot).get("id", "")
	match scaling:
		"investor_capital_amplifier":
			return min(1.6, floor(state.investedGold / 50.0) * 0.08)
		"sponsored_overcharge":
			return min(1.6, state.sponsoredCompletions * 0.08)
		"clutter_resonance":
			return state.openPopups.size() * 0.08
		"clean_precision":
			return 0.8 if state.openPopups.is_empty() else (0.45 if state.openPopups.size() == 1 else 0.0)
		"curse_heat_overload":
			return state.heat * 0.1
		"risk_liability_waiver":
			return (0.08 if hp_ratio() <= 0.7 else 0.0) + min(0.18, state.termsPenaltyCount * 0.04)
		"risk_premium":
			return min(0.25, difficulty_stage_index() * 0.035)
		"generic_stable_output":
			return 0.25
	return 0.0

func difficulty_stage_index() -> int:
	var current = difficulty_stage_info().current.id
	for index in range(data.DIFFICULTY_STAGES.size()):
		if data.DIFFICULTY_STAGES[index].id == current:
			return index
	return 0

func projectile_extra_targets_bonus(slot: String) -> int:
	var form = selected_form_for_slot(slot)
	if selected_scaling_for_slot(slot).get("id", "") == "generic_expanded_ballistics" and form.get("tags", []).has("projectile"):
		return 1
	return 0

func beam_width_bonus(slot: String) -> float:
	var scaling = selected_scaling_for_slot(slot).get("id", "")
	match scaling:
		"clutter_noise_amplifier":
			return min(8.0, float(state.openPopups.size()))
		"clean_clear_sight":
			return 6.0 if state.openPopups.is_empty() else (4.0 if state.openPopups.size() <= 1 else 0.0)
		"generic_expanded_ballistics":
			return 4.0
	return 0.0

func bounce_count_bonus(slot: String) -> int:
	var bonus = 0
	if selected_mechanic_for_slot(slot).get("id", "") == "bounce_plus":
		bonus += 1
	if selected_scaling_for_slot(slot).get("id", "") == "clutter_noise_amplifier" and state.openPopups.size() >= 5:
		bonus += 1
	return bonus

func effective_move_speed() -> float:
	var multiplier = 1.0 + state.stats.moveSpeedMultiplier + active_timed_multiplier("moveSpeedMultiplier")
	if state.emergencyBoostTimer > 0.0:
		multiplier += state.stats.emergencyMoveSpeedMultiplier
	for program in state.residentPrograms:
		if program.get("suspended", false):
			continue
		multiplier += program.def.get("moveSpeedPenalty", 0.0)
	return float(config.playerMoveSpeed) * max(0.25, multiplier)

func effective_pickup_range() -> float:
	var multiplier = 1.0 + state.stats.pickupRangeMultiplier
	if state.cleanupComboTimer > 0.0:
		multiplier += state.stats.cleanupComboPickupRangeMultiplier
	return float(config.pickupRange) * multiplier + state.stats.pickupRangeFlat

func damage_crit_source(slot) -> String:
	if slot != "primary" and slot != "secondary":
		return ""
	var form_id = selected_form_for_slot(slot).get("id", "")
	if ["aura_steady", "aura_infection", "aura_absorb"].has(form_id):
		return "aura_tick"
	return "attack"

func effective_crit_chance(source = "attack") -> float:
	var chance = float(state.stats.critChance)
	if source == "aura_tick":
		chance *= 0.5
	return clamp(chance, 0.0, 0.95)

func effective_crit_damage_multiplier(source = "attack", slot = "primary") -> float:
	var multiplier = max(0.0, float(state.stats.critDamageMultiplier))
	multiplier += max(0.0, state.heat) * float(state.stats.critDamagePerDifficulty)
	if state.moduleUpgrades.has(slot) and selected_scaling_for_slot(slot).get("id", "") == "curse_heat_overload" and state.heat >= 8:
		multiplier += 0.5
	return multiplier

func apply_crit_to_damage(damage: float, source = "attack", slot = "primary") -> Dictionary:
	var chance = effective_crit_chance(source)
	if rng.randf() >= chance:
		return {"damage": damage, "crit": false}
	return {"damage": damage * (1.0 + effective_crit_damage_multiplier(source, slot)), "crit": true}

func update_module_upgrade_timers(dt: float) -> void:
	state.popupExecutionWindow = max(0.0, state.popupExecutionWindow - dt)
	state.popupCloseAttackPrimed = state.popupCloseAttackPrimed and state.popupExecutionWindow > 0.0

func update_attacks(dt: float) -> void:
	for attack in state.attacks.duplicate():
		attack.life -= dt
		if attack.life <= 0.0:
			state.attacks.erase(attack)

func update_particles(dt: float) -> void:
	for particle in state.particles.duplicate():
		particle.life -= dt
		particle.position += particle.velocity * dt
		if particle.life <= 0.0:
			state.particles.erase(particle)

func update_float_texts(dt: float) -> void:
	for text in state.floatTexts.duplicate():
		text.life -= dt
		text.position.y -= 24.0 * dt
		if text.life <= 0.0:
			state.floatTexts.erase(text)

func add_death_burst(position: Vector2) -> void:
	for i in range(5):
		var dir = Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU))
		state.particles.append({"position": position, "velocity": dir * rng.randf_range(24.0, 78.0), "radius": rng.randf_range(2.0, 4.0), "color": Color("#ff5964"), "life": 0.35, "maxLife": 0.35})

func add_damage_number(position: Vector2, text: String, color: Color, size = 14) -> void:
	state.floatTexts.append({"position": position, "text": text, "color": color, "size": size, "life": 0.75, "maxLife": 0.75})
	if state.floatTexts.size() > 90:
		state.floatTexts.pop_front()

func random_item_by_rarity(rarity: String) -> Dictionary:
	var matches = data.ITEMS.filter(func(item): return item.rarity == rarity)
	if matches.is_empty():
		return {}
	return matches[rng.randi_range(0, matches.size() - 1)]

func current_item_roll_cost() -> int:
	var base = float(config.itemRollCost) * pow(float(config.itemRollCostGrowth), state.itemRollCount)
	if config.itemRollCostCap != null:
		base = min(base, float(config.itemRollCostCap))
	base *= 1.0 + state.stats.debtItemCostMultiplier + total_resident_item_cost_multiplier()
	return max(1, int(round(base * (1.0 - current_item_discount()))))

func current_item_discount() -> float:
	var discount = 0.0
	for entry in state.nextItemDiscounts:
		discount += entry.get("value", 0.0)
	if state.openPopups.size() >= 5:
		discount += state.stats.crowdedItemDiscount
	return clamp(discount, 0.0, 0.8)

func consume_item_discounts() -> void:
	for entry in state.nextItemDiscounts.duplicate():
		entry.uses = entry.get("uses", 1) - 1
		if entry.uses <= 0:
			state.nextItemDiscounts.erase(entry)

func popup_store_price(product: Dictionary) -> int:
	return max(1, int(round(float(product.price) * (1.0 - state.stats.popupStoreDiscountMultiplier))))

func purchase_popup_store_item(id: int, product: Dictionary) -> void:
	var price = popup_store_price(product)
	if state.gold < price:
		return
	state.gold -= price
	state.metrics.popupStorePurchases += 1
	var item = random_item_by_rarity(product.rarity)
	if not item.is_empty():
		apply_item_reward(item)
	request_close_popup(id, {"reason": "store_purchase"})

func max_open_popups() -> int:
	return max(1, int(state.stats.maxOpenPopups))

func effective_popup_interval() -> float:
	var ramp = clamp(state.elapsed / float(config.popupPressureRampSeconds), 0.0, 1.0)
	var base = lerp(float(config.popupBaseSpawnInterval), float(config.popupMinSpawnInterval), ramp)
	var multiplier = max(0.18, 1.0 - state.stats.popupSpawnRateMultiplier)
	multiplier *= max(0.25, 1.0 - difficulty_combat_pressure().popupSpawnMultiplier)
	multiplier *= 1.0 / max(0.3, wave_mode_spawn_multiplier())
	return max(float(config.popupMinSpawnInterval), base * multiplier)

func total_resident_item_cost_multiplier() -> float:
	var total = 0.0
	for program in state.residentPrograms:
		if program.get("suspended", false):
			continue
		total += program.def.get("itemCostMultiplier", 0.0)
	return total

func popup_def_by_id(id: String) -> Dictionary:
	for def in data.POPUP_DEFINITIONS:
		if def.id == id:
			return def
	return {}

func popup_by_id(id: int):
	for popup in state.openPopups:
		if int(popup.id) == id:
			return popup
	return null

func module_by_id(id: String) -> Dictionary:
	for module in data.ATTACK_MODULES:
		if module.id == id:
			return module
	return {}

func module_name(id: String, fallback: String) -> String:
	var module = module_by_id(id)
	return fallback if module.is_empty() else module.name

func module_detail(slot: String) -> String:
	if state["%sModule" % slot] == "":
		return "대기 중" if slot == "secondary" else "기본형"
	var form = selected_form_for_slot(slot)
	var mechanic = selected_mechanic_for_slot(slot)
	var scaling = selected_scaling_for_slot(slot)
	var parts = [form.get("name", "기본형")]
	if not mechanic.is_empty():
		parts.append(mechanic.name)
	if not scaling.is_empty():
		parts.append(scaling.name)
	return " / ".join(parts)

func default_form_for_module(module_id: String) -> String:
	var map = {"ranged": "ranged_projectile", "melee": "melee_forward_slash", "aura": "aura_steady", "deploy": "deploy_mine"}
	return map.get(module_id, "")

func form_by_id(id: String) -> Dictionary:
	for form in data.ATTACK_FORMS:
		if form.id == id:
			return form
	return {}

func mechanic_by_id(id: String) -> Dictionary:
	for mechanic in data.ATTACK_MECHANICS:
		if mechanic.id == id:
			return mechanic
	return {}

func scaling_by_id(id: String) -> Dictionary:
	for scaling in data.BUILD_SCALINGS:
		if scaling.id == id:
			return scaling
	return {}

func selected_form_for_slot(slot: String) -> Dictionary:
	var id = state.moduleUpgrades[slot].form
	if id == "":
		id = default_form_for_module(state["%sModule" % slot])
	return form_by_id(id)

func selected_mechanic_for_slot(slot: String) -> Dictionary:
	return mechanic_by_id(state.moduleUpgrades[slot].mechanic)

func selected_scaling_for_slot(slot: String) -> Dictionary:
	return scaling_by_id(state.moduleUpgrades[slot].scaling)

func slot_label(slot: String) -> String:
	return "1차" if slot == "primary" else "보조"

func get_nearest_enemy_in_range(range_value: float):
	return get_nearest_enemy_from(state.player.position, range_value)

func get_nearest_enemy_from(position: Vector2, range_value: float):
	var best = null
	var best_distance = range_value
	for enemy in state.enemies:
		var distance = enemy.position.distance_to(position)
		if distance <= best_distance:
			best = enemy
			best_distance = distance
	return best

func get_nearest_enemy_from_excluding(position: Vector2, range_value: float, excluded):
	var best = null
	var best_distance = range_value
	for enemy in state.enemies:
		if enemy == excluded:
			continue
		var distance = enemy.position.distance_to(position)
		if distance <= best_distance:
			best = enemy
			best_distance = distance
	return best

func owned_item_count(id: String) -> int:
	return int(state.itemCounts.get(id, 0))

func has_item(id: String) -> bool:
	return owned_item_count(id) > 0

func active_playstyle_key() -> String:
	var map = {
		"investor_starter": "investor",
		"sponsored_starter": "sponsored",
		"clutter_chaos_starter": "clutter",
		"clean_desk_starter": "clean",
		"risky_terms_starter": "curse",
	}
	if state.activePlaystyle == "":
		return "generic"
	return map.get(state.activePlaystyle, state.activePlaystyle)

func investor_bonus_values() -> Dictionary:
	return {
		"investedDamage": min(0.6, floor(max(0, state.investedGold) / 50.0) * 0.04),
		"creditCooldown": -0.1 if state.creditScore >= 80 else (-0.05 if state.creditScore >= 60 else 0.0),
		"heldGoldRange": min(0.15, floor(state.gold / 100.0) * 0.03),
	}

func active_starter_combat_bonuses() -> Dictionary:
	var bonuses = {
		"damageMultiplier": 0.0,
		"rangeMultiplier": 0.0,
		"cooldownMultiplier": 0.0,
		"notes": [],
	}
	match state.activePlaystyle:
		"investor_starter":
			var investor = investor_bonus_values()
			bonuses.damageMultiplier += investor.investedDamage
			bonuses.cooldownMultiplier += investor.creditCooldown
			bonuses.rangeMultiplier += investor.heldGoldRange
			if investor.investedDamage > 0.0:
				bonuses.notes.append("투자 피해 %+d%%" % round(investor.investedDamage * 100.0))
			if investor.creditCooldown < 0.0:
				bonuses.notes.append("신용 템포 %+d%%" % round(investor.creditCooldown * 100.0))
			if investor.heldGoldRange > 0.0:
				bonuses.notes.append("자금 사거리 %+d%%" % round(investor.heldGoldRange * 100.0))
		"sponsored_starter":
			if count_open_ad_popups() > 0:
				bonuses.damageMultiplier += 0.1
				bonuses.notes.append("광고 중 피해 +10%")
			if state.sponsoredAttackBoostStacks > 0:
				bonuses.notes.append("후원탄 %d스택" % state.sponsoredAttackBoostStacks)
		"clutter_chaos_starter":
			var count = state.openPopups.size()
			if count >= 3:
				bonuses.rangeMultiplier += 0.1
			if count >= 5:
				bonuses.damageMultiplier += 0.15
			if count >= 7:
				bonuses.cooldownMultiplier -= 0.1
				bonuses.notes.append("과밀 III")
			elif count >= 5:
				bonuses.notes.append("과밀 II")
			elif count >= 3:
				bonuses.notes.append("과밀 I")
		"clean_desk_starter":
			var count = state.openPopups.size()
			if count == 0:
				bonuses.damageMultiplier += 0.18
				bonuses.rangeMultiplier += 0.1
				bonuses.notes.append("완전 정리")
			elif count <= 1:
				bonuses.damageMultiplier += 0.1
				bonuses.rangeMultiplier += 0.07
				bonuses.notes.append("정밀화 활성")
			if state.cleanupComboValue >= 1:
				var combo = int(floor(state.cleanupComboValue))
				bonuses.cooldownMultiplier -= min(0.22, combo * 0.02)
				bonuses.rangeMultiplier += min(0.15, combo * 0.012)
				bonuses.notes.append("정리 콤보 x%d" % combo)
		"risky_terms_starter":
			var heat_damage = state.heat * 0.04 + (0.1 if state.heat >= 5.0 else 0.0)
			if heat_damage > 0.0:
				bonuses.damageMultiplier += heat_damage
				bonuses.notes.append("난이도 화력 %+d%%" % round(heat_damage * 100.0))
	if bonuses.notes.is_empty():
		bonuses.notes.append("대기 중" if state.activePlaystyle != "" else "미적용")
	return bonuses

func starter_combat_bonus_summary() -> String:
	return " / ".join(active_starter_combat_bonuses().notes)

func rarity_badge(rarity: String) -> String:
	var color = "#edf2f7"
	if rarity == "Rare":
		color = "#4aa8ff"
	elif rarity == "Epic":
		color = "#d26bff"
	elif rarity == "Cursed":
		color = "#ff5964"
	return "[color=%s]%s[/color]" % [color, rarity]

func describe_item_current(item: Dictionary, extra_count: int) -> String:
	var count = owned_item_count(item.id) + extra_count
	if item.has("effect"):
		var effect = item.effect
		return "%s %s (x%d)" % [effect.get("stat", effect.get("type", "effect")), signed_number_text(effect.get("value", 0.0)), count]
	if item.has("effects"):
		return "%d개 효과 (x%d)" % [item.effects.size(), count]
	return "누적 x%d" % count

func signed_number_text(value) -> String:
	var number = float(value)
	var sign = "+" if number >= 0.0 else ""
	return "%s%.2f" % [sign, number]

func inventory_text() -> String:
	if state.itemCounts.is_empty():
		return "보유 아이템 없음"
	var lines = []
	for id in state.itemCounts.keys():
		var item = data.ITEMS.filter(func(candidate): return candidate.id == id)
		var name = id if item.is_empty() else item[0].name
		lines.append("%s x%d" % [name, state.itemCounts[id]])
	return "\n".join(lines)

func resident_program_hud_text() -> String:
	if state.residentPrograms.is_empty():
		return "보안 프로그램\n설치 없음"
	var lines = ["보안 프로그램 %d" % state.residentPrograms.size()]
	for program in state.residentPrograms:
		var status = "일시정지" if program.get("suspended", false) else "작동 중"
		var next = ""
		if program.def.get("upkeepGold", 0) > 0:
			next = " / %.0fs 후 %dG" % [float(program.get("upkeepTimer", 0.0)), int(program.def.upkeepGold)]
		else:
			next = " / %.0fs 후 업데이트" % float(program.get("updateTimer", 0.0))
		lines.append("%s: %s%s" % [program.name, status, next])
	if state.reservedMaxHP > 0:
		lines.append("점유 HP: %d" % state.reservedMaxHP)
	var item_burden = total_resident_item_cost_multiplier()
	if item_burden > 0.0:
		lines.append("아이템 비용 부담 +%d%%" % round(item_burden * 100.0))
	return "\n".join(lines)

func investor_dashboard_text() -> String:
	if active_playstyle_key() != "investor" and state.investedGold <= 0 and state.debtGold <= 0:
		return "투자자 계약 대기 중"
	return "신용 %d / 투자 %dG / 부채 %dG\n%s\n계약 특전: %s" % [state.creditScore, state.investedGold, state.debtGold, investor_bonus_breakdown(), starter_combat_bonus_summary()]

func investor_bonus_breakdown() -> String:
	var values = investor_bonus_values()
	return "투자 피해 +%d%% / 신용 템포 %d%% / 자금 사거리 +%d%%" % [round(values.investedDamage * 100.0), round(values.creditCooldown * 100.0), round(values.heldGoldRange * 100.0)]

func difficulty_effect_summary() -> String:
	var pressure = difficulty_combat_pressure()
	var notice = (" / " + state.difficultyNoticeText) if state.difficultyNoticeTimer > 0 else ""
	var wave_notice = (" / " + state.waveDirector.noticeText) if state.waveDirector.noticeTimer > 0 else ""
	return "선택 난이도 +%.1f / 팝업 압박 +%d%%%s%s" % [state.heat, round(pressure.popupSpawnMultiplier * 100), notice, wave_notice]

func run_stats_text() -> String:
	return "조작: WASD 이동, Space 긴급 닫기, P 일시정지, R 재시작.\n생존 %s / 처치 %d / 계약 %s / 긴급 %.1fs / 웨이브 %s\n치명타 %d%% / 치명 피해 +%d%%" % [format_time(state.elapsed), state.killCount, state.activePlaystyleName, state.emergencyTimer, wave_mode_label(), round(effective_crit_chance("attack") * 100.0), round(effective_crit_damage_multiplier("attack", "primary") * 100.0)]

func debug_stats_text() -> String:
	var pressure = difficulty_combat_pressure()
	var stock = state.stockMarket.stock
	var stock_value = int(floor(stock.price * stock.shares))
	var stock_principal = int(round(stock.avgCost * stock.shares))
	var popup_multiplier = max(0.2, 1.0 + state.stats.popupSpawnRateMultiplier + difficulty_combat_pressure().popupSpawnMultiplier)
	return "성능: FPS %.0f / 객체: 적 %d / 투사체 %d / 픽업 %d / 팝업 %d / 예고 %d\n현재 가격: %dG / 배속: x%.1f / 구매·처치: %d / %d\n선택 난이도: +%.1f / 신용도: %d / 계약: %s\n1차: %s / 보조: %s / 웨이브: %s %.1fs\n재생·흡혈·획득: +%.1f/s / %d%% / %.0f\n피해·사거리·공격간격: %.1f / %.0f / %.2fs\n치명타·치명피해: %d%% / +%d%%\n적 HP 스케일: x%.2f / 현재 일반 적 HP: %d / 다음 보스 HP: %d\n보안 프로그램: %d개 / 점유 HP %d / 아이템 비용 +%d%%\n투자금·주식 평가·원금·부채: %dG / %dG / %dG / %dG\n정리 콤보: x%d %.1fs / 할인·선택지: %d%% / +%d\n스폰서 완료·보상·후원탄: %d / %d / %d\n다음 팝업: %.1fs / 팝업 생성 배율: x%.2f / 시장: %.1fG %s" % [
		Engine.get_frames_per_second(), state.enemies.size(), state.projectiles.size(), state.pickups.size(), state.openPopups.size(), state.pendingPopupSpawns.size(),
		current_item_roll_cost(), state.timeScale, state.itemRollCount, state.killCount,
		state.heat, state.creditScore, state.activePlaystyleName,
		module_name(state.primaryModule, "미선택"), module_name(state.secondaryModule, "없음"), wave_mode_label(), max(0.0, float(state.waveDirector.timer)),
		effective_health_regen_per_second(), round(state.stats.lifeStealPercent * 100.0), effective_pickup_range(),
		effective_damage("primary"), effective_attack_range("primary"), effective_attack_interval("primary"),
		round(effective_crit_chance("attack") * 100.0), round(effective_crit_damage_multiplier("attack", "primary") * 100.0),
		enemy_time_scale() * (1.0 + float(pressure.enemyHpMultiplier)), round(current_normal_enemy_hp_estimate()), round(boss_hp_estimate()),
		state.residentPrograms.size(), state.reservedMaxHP, round(total_resident_item_cost_multiplier() * 100.0),
		state.investedGold, stock_value, stock_principal, state.debtGold,
		floor(state.cleanupComboValue), state.cleanupComboTimer, round(current_item_discount() * 100.0), state.nextItemExtraChoices,
		state.sponsoredCompletions, state.metrics.sponsoredRewards, state.sponsoredAttackBoostStacks,
		max(0.0, state.popupTimer), popup_multiplier, stock.price, state.stockMarket.lastBiasLabel,
	]

func stock_broker_text() -> String:
	var stock = state.stockMarket.stock
	var value = int(floor(stock.price * stock.shares))
	var principal = int(round(stock.avgCost * stock.shares))
	var profit = value - principal
	return "%s %.1fG (%+.1f%%)\n보유 %d주 / 평가 %dG / 손익 %+dG\n흐름: %s" % [stock.name, stock.price, stock.lastChange * 100.0, stock.shares, value, profit, state.stockMarket.lastBiasLabel]

func stock_market_popup_text(popup: Dictionary) -> String:
	if not popup.has("stock"):
		return "주식 데이터를 초기화하는 중입니다."
	var stock = popup.stock
	if not stock.get("invested", false):
		return "변동성: %d%% / 기대 흐름: %+d%%\n투자 후 매도 전까지 창이 잠깁니다." % [round(float(stock.volatility) * 100.0), round(float(stock.drift) * 100.0)]
	var payout = int(floor(float(stock.currentValue)))
	var principal = int(stock.principal)
	var profit = payout - principal
	return "원금: %dG\n현재 평가액: %dG\n평가손익: %+dG\n흐름: %s / 경과 %.1fs" % [principal, payout, profit, stock.lastTrend, float(stock.elapsed)]

func infection_popup_text(popup: Dictionary) -> String:
	var target = popup_by_id(int(popup.get("infectionTargetId", 0)))
	var target_text = "감염할 대상 없음" if target == null else "감염 대상: %s" % target.def.get("title", "팝업")
	return "%s\n감염 진행 %.0f%%" % [target_text, popup.get("progress", 0.0) * 100.0]

func interest_popup_text(popup: Dictionary) -> String:
	if popup.get("interestAccepted", false):
		return "예치금 %dG / 만기 지급 %dG\n만기 조건: %.0f초 유지\n진행 %.1f / %.0f초\n중도 해지 시 원금 40%%만 반환됩니다." % [popup.interestPrincipal, interest_popup_payout(popup), popup.interestMaturityTarget, popup.interestMaturityProgress, popup.interestMaturityTarget]
	return "현재 보유 골드 일부를 한 번 예치합니다.\n만기 조건: 24초 유지\n만기 후 원금+수익 지급 / 중도 해지 시 원금 40%% 반환"

func recurring_investment_text(popup: Dictionary) -> String:
	if popup.has("investment") and popup.investment.get("accepted", false):
		return "현재 적립 %dG / 남은 %.1fs" % [popup.investment.accumulated, max(0.0, popup.investment.duration - popup.investment.elapsed)]
	return "수락 후 주요 골드 수익의 35%를 자동 적립합니다."

func security_installer_text(type: String) -> String:
	var def = security_program_def(type)
	if def.is_empty():
		return ""
	return "비용 %dG\n%s\n상주 부담: %s" % [def.installCost, def.summary, security_program_burden_text(def)]

func security_program_burden_text(def: Dictionary) -> String:
	var parts = []
	if def.get("moveSpeedPenalty", 0.0) != 0.0:
		parts.append("이동 %+d%%" % round(float(def.moveSpeedPenalty) * 100.0))
	if def.get("itemCostMultiplier", 0.0) > 0.0:
		parts.append("아이템 비용 +%d%%" % round(float(def.itemCostMultiplier) * 100.0))
	if def.get("reservedMaxHP", 0) > 0:
		parts.append("최대 HP 점유 %d" % int(def.reservedMaxHP))
	if def.get("upkeepGold", 0) > 0:
		parts.append("%dG/%.0fs 유지비" % [int(def.upkeepGold), float(def.get("upkeepInterval", 20.0))])
	if parts.is_empty():
		parts.append("업데이트 팝업 발생")
	return " / ".join(parts)

func open_inventory_overview() -> void:
	state.selectingItem = true
	state.paused = true
	hud.show_inventory_overview(func(): close_inventory_overview())

func close_inventory_overview() -> void:
	state.selectingItem = false
	hud.hide_choices()
	state.paused = false

func set_speed_index(index: int) -> void:
	var values = [0.5, 1.0, 1.5, 2.0]
	state.timeScale = values[clamp(index, 0, values.size() - 1)]

func toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func debug_action(action: String) -> void:
	match action:
		"gold":
			add_gold(25, "debug")
		"gold100":
			add_gold(100, "debug")
		"xp10":
			add_xp(10)
		"xp":
			add_xp(state.xpNeed)
		"forceLevel":
			add_xp(max(1, state.xpNeed - state.xp))
		"formSelect":
			open_attack_form_selection("primary")
		"mechanicSelect":
			open_attack_mechanic_selection("primary")
		"scalingSelect":
			open_build_scaling_selection("primary")
		"executionWindow":
			register_cleanup_combo("debug")
		"cleanupCombo5":
			for i in range(5):
				register_cleanup_combo("debug")
		"waveNormal":
			set_wave_mode("normal", true)
		"waveSide":
			set_wave_mode("side_push", true)
		"waveSurround":
			set_wave_mode("surround", true)
		"waveFast":
			set_wave_mode("fast_horde", true)
		"waveDense":
			set_wave_mode("dense_horde", true)
		"dropMagnetPickup":
			spawn_special_consumable_drop(state.player.position + Vector2(42, 0), "magnet")
		"dropHealPickup":
			spawn_special_consumable_drop(state.player.position + Vector2(42, 0), "heal")
		"installKeyboardSecurity":
			debug_install_security("keyboard_security")
		"installRealtimeGuard":
			debug_install_security("realtime_guard")
		"installPopupQuarantine":
			debug_install_security("popup_quarantine")
		"installKernelGuard":
			debug_install_security("kernel_guard")
		"clearResidentPrograms":
			clear_resident_programs()
		"invested100":
			state.investedGold += 100
		"sponsoredStacks":
			state.sponsoredAttackBoostStacks = min(20, state.sponsoredAttackBoostStacks + 5)
		"randomItem":
			if not data.ITEMS.is_empty():
				apply_item_reward(data.ITEMS[rng.randi_range(0, data.ITEMS.size() - 1)])
		"allItems":
			for item in data.ITEMS:
				apply_item_reward(item)
		"boss":
			spawn_enemy(true)
		"bossPackage":
			add_gold(boss_package_cost(1), "debug")
			create_boss_package_popup(1)
		"rate":
			state.stats.popupSpawnRateMultiplier += 1.0
		"heat":
			state.heat += 1.0
		"creditPlus":
			add_credit_score(10, "debug")
		"creditMinus":
			add_credit_score(-10, "debug")
		"clear":
			state.pendingPopupSpawns.clear()
			for popup in state.openPopups.duplicate():
				if not ["stock_broker_app", "first_purchase_package"].has(popup.def.type):
					remove_popup_without_reward(popup.id)
		"telegraphMoving":
			schedule_popup_spawn(popup_def_by_id("moving_close"))
		"investorMode":
			state.activePlaystyle = "investor_starter"
			state.activePlaystyleName = "투자자 스타터 계약"
			state.firstPurchasePaid = true
			state.firstPurchasePackageChosen = state.activePlaystyleName
		"clearPlaystyle":
			state.activePlaystyle = ""
			state.activePlaystyleName = "미선택"
			state.firstPurchasePaid = false
			state.firstPurchasePackageChosen = ""
		_:
			var def = popup_def_by_id(action)
			if not def.is_empty():
				create_popup(def)

func debug_install_security(type: String) -> void:
	install_resident_program(type, 0, true)

func end_game() -> void:
	state.gameOver = true
	state.paused = true
	state.player.hp = 0.0

func format_time(seconds: float) -> String:
	var minutes = int(seconds / 60.0)
	var rest = int(seconds) % 60
	return "%d:%02d" % [minutes, rest]
