extends Node
class_name GameRoot

const GameDataScript = preload("res://scripts/data/game_data.gd")
const WorldScript = preload("res://scripts/world_2d.gd")
const HudScript = preload("res://scripts/hud_layer.gd")
const PopupScript = preload("res://scripts/popup_layer.gd")

var config = GameData.CONFIG
var items = []
var perks = []
var popups = []
var attack_modules = []
var attack_forms = []
var attack_mechanics = []
var build_scalings = []
var difficulty_stages = []
var wave_modes = []
var security_programs = []

var world
var hud
var popup_layer
var state = {}
var popup_id_seed = 1
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	items = GameDataScript.items()
	perks = GameDataScript.perks()
	popups = GameDataScript.popup_definitions()
	attack_modules = GameDataScript.attack_modules()
	attack_forms = GameDataScript.attack_forms()
	attack_mechanics = GameDataScript.attack_mechanics()
	build_scalings = GameDataScript.build_scalings()
	difficulty_stages = GameDataScript.difficulty_stages()
	wave_modes = GameDataScript.wave_modes()
	security_programs = GameDataScript.security_programs()

	world = WorldScript.new()
	world.name = "World2D"
	add_child(world)
	world.setup(self)

	popup_layer = PopupScript.new()
	popup_layer.name = "PopupLayer"
	add_child(popup_layer)
	popup_layer.setup(self)

	hud = HudScript.new()
	hud.name = "HudLayer"
	add_child(hud)
	hud.setup(self)

	reset_game()

func reset_game() -> void:
	popup_id_seed = 1
	state = _create_initial_state()
	popup_layer.sync_from_state(state)
	hud.update_from_state(state)
	world.queue_redraw()
	call_deferred("open_attack_module_selection", "primary")

func _create_initial_state() -> Dictionary:
	var player_max_hp = config.player_max_hp
	return {
		"elapsed": 0.0,
		"paused": true,
		"selecting": false,
		"game_over": false,
		"time_scale": 1.0,
		"gold": 0,
		"xp": 0,
		"xp_need": config.xp_base_requirement,
		"level": 1,
		"heat": 0.0,
		"credit_score": 50,
		"invested_gold": 0,
		"debt_gold": 0,
		"sponsored_completions": 0,
		"sponsored_attack_boost_stacks": 0,
		"next_item_discounts": [],
		"next_item_extra_choices": 0,
		"kill_count": 0,
		"item_roll_count": 0,
		"terms_penalty_count": 0,
		"active_playstyle": "",
		"active_playstyle_name": "미선택",
		"first_purchase_offer_shown": false,
		"first_purchase_timer": rng.randf_range(3.0, 5.0),
		"last_item_text": "최근 아이템: 없음",
		"recent_perk_text": "공격 모듈을 선택하세요.",
		"primary_module": "",
		"secondary_module": "",
		"primary_mastery": 0,
		"secondary_mastery": 0,
		"primary_deepening": {},
		"secondary_deepening": {},
		"module_synergy": {},
		"module_upgrades": {
			"primary": {"form": "", "mechanic": "", "scaling": ""},
			"secondary": {"form": "", "mechanic": "", "scaling": ""},
		},
		"module_timers": {"primary": 0.25, "secondary": 0.75},
		"boss_spawn_index": 0,
		"boss_package_count": 0,
		"pending_boss_package": {},
		"item_counts": {},
		"timed_effects": [],
		"delayed_events": [],
		"enemy_timer": 0.8,
		"popup_timer": 12.0,
		"emergency_timer": 0.0,
		"emergency_boost_timer": 0.0,
		"auto_close_basic_timer": 8.0,
		"popup_freeze_timer": 0.0,
		"low_hp_freeze_used": false,
		"cleanup_combo_stacks": 0,
		"cleanup_combo_timer": 0.0,
		"cleanup_combo_grace": 4.0,
		"cleanup_combo_max": 20,
		"popup_close_attack_primed": false,
		"resident_programs": [],
		"reserved_max_hp": 0.0,
		"security_update_timer": rng.randf_range(18.0, 26.0),
		"security_billing_timer": 0.0,
		"stock_market": {
			"tick_timer": 1.0,
			"last_bias_label": "조용한 장세",
			"stock": {"symbol": "POP", "name": "팝업 테마주", "price": 100.0, "history": [100.0], "shares": 0, "avg_cost": 0.0, "last_change": 0.0},
		},
		"player": {"position": Vector2.ZERO, "radius": 13.0, "hp": player_max_hp, "max_hp": player_max_hp, "hit_flash": 0.0},
		"last_move_dir": Vector2.RIGHT,
		"stats": _create_base_stats(),
		"enemies": [],
		"mines": [],
		"turrets": [],
		"fields": [],
		"projectiles": [],
		"pickups": [],
		"attacks": [],
		"float_texts": [],
		"open_popups": [],
		"pending_popup_spawns": [],
		"wave_director": {"mode": "normal", "timer": rng.randf_range(15.0, 25.0), "notice_timer": 0.0, "notice_text": "", "side": "left"},
		"metrics": {"boss_kills": 0, "boss_packages_purchased": 0, "sponsored_rewards": 0, "interest_completed": 0, "popup_store_purchases": 0, "volatile_closures": 0},
	}

func _create_base_stats() -> Dictionary:
	return {
		"damage_multiplier": 0.0,
		"attack_interval_multiplier": 0.0,
		"attack_range_multiplier": 0.0,
		"move_speed_multiplier": 0.0,
		"popup_drag_speed_multiplier": 0.0,
		"popup_spawn_rate_multiplier": 0.0,
		"ad_gold_per_second": 0.0,
		"ad_gold_multiplier": 0.0,
		"ad_buff_multiplier": 0.0,
		"sponsored_reward_multiplier": 0.0,
		"sponsored_popup_weight_multiplier": 0.0,
		"timed_reward_duration_multiplier": 0.0,
		"max_open_popups": config.max_open_popups,
		"extra_targets": 0,
		"clean_desk_damage_multiplier": 0.0,
		"clutter_attack_interval_per_popup": 0.0,
		"gold_bullet_damage_multiplier": 0.0,
		"emergency_move_speed_multiplier": 0.0,
		"auto_close_basic_interval": 0.0,
		"sponsored_double_hit": 0,
		"purchase_damage_burst": 0.0,
		"drag_attack_interval_multiplier": 0.0,
		"popup_close_damage": 0.0,
		"terms_popup_weight_multiplier": 0.0,
		"gold_per_popup_close": 0,
		"safe_zone_multiplier": 0.0,
		"emergency_cooldown_multiplier": 0.0,
		"terms_penalty_shield": 0,
		"crowded_gold_multiplier": 0.0,
		"smart_emergency_close": 0,
		"low_hp_popup_freeze": 0,
		"gold_per_terms_penalty": 0,
		"crowded_item_discount": 0.0,
		"emergency_close_disabled": 0,
		"reward_gold_multiplier": 0.0,
		"interest_popup_weight_multiplier": 0.0,
		"interest_payout_multiplier": 0.0,
		"popup_store_weight_multiplier": 0.0,
		"popup_store_discount_multiplier": 0.0,
		"health_regen_per_second": 0.0,
		"life_steal_percent": 0.0,
		"healing_multiplier": 0.0,
		"pickup_range_multiplier": 0.0,
		"pickup_range_flat": 0.0,
		"cleanup_combo_pickup_range_multiplier": 0.0,
		"cleanup_combo_grace_bonus": 0.0,
		"crit_chance": 0.0,
		"crit_damage_multiplier": 0.5,
		"crit_damage_per_difficulty": 0.0,
		"invested_gold_damage_multiplier": 0.0,
		"credit_range_bonus": 0,
		"sponsored_stack_damage_multiplier": 0.0,
		"sponsored_open_haste": 0.0,
		"popup_count_range_multiplier": 0.0,
		"overload_cache_damage_multiplier": 0.0,
		"focus_lens_range_multiplier": 0.0,
		"quiet_trigger_haste": 0.0,
		"cleanup_combo_damage_multiplier": 0.0,
		"close_combo_haste": 0.0,
		"heat_damage_multiplier": 0.0,
		"wound_engine": 0,
	}

func _process(delta: float) -> void:
	if state.is_empty():
		return
	var dt = min(delta * state.time_scale, 0.05)
	if Input.is_action_just_pressed("pause") and not state.game_over and not state.selecting:
		state.paused = not state.paused
	if Input.is_action_just_pressed("restart"):
		reset_game()
	if Input.is_action_just_pressed("emergency_close"):
		emergency_close_oldest_popup()

	if not state.paused and not state.game_over:
		_update_game(dt)
	_update_visual_timers(dt)
	popup_layer.sync_from_state(state)
	hud.update_from_state(state)
	world.queue_redraw()

func _update_game(dt: float) -> void:
	state.elapsed += dt
	_update_timed_effects(dt)
	_update_delayed_events(dt)
	_update_wave_director(dt)
	_update_player(dt)
	_update_enemies(dt)
	_update_health_regen(dt)
	_update_boss_spawns()
	_update_auto_attack(dt)
	_update_projectiles(dt)
	_update_mines(dt)
	_update_turrets(dt)
	_update_fields(dt)
	_update_pickups(dt)
	_update_attacks(dt)
	_update_float_texts(dt)
	_update_cleanup_combo(dt)
	_update_popups(dt)
	_update_stock_market(dt)
	_update_resident_programs(dt)
	_update_first_purchase_offer(dt)

func _update_visual_timers(dt: float) -> void:
	if state.has("player"):
		state.player.hit_flash = max(0.0, state.player.hit_flash - dt)
	state.emergency_timer = max(0.0, state.emergency_timer - dt)
	state.emergency_boost_timer = max(0.0, state.emergency_boost_timer - dt)
	state.popup_freeze_timer = max(0.0, state.popup_freeze_timer - dt)

func _update_player(dt: float) -> void:
	var input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input.length() > 0.01:
		state.last_move_dir = input.normalized()
	var speed = effective_move_speed()
	state.player.position += input * speed * dt

func _update_enemies(dt: float) -> void:
	state.enemy_timer -= dt
	if state.enemy_timer <= 0.0:
		spawn_enemy()
		var interval = config.enemy_spawn_interval / max(0.1, enemy_spawn_rate_scale() * current_wave_mode().spawn_multiplier)
		state.enemy_timer = max(config.enemy_spawn_interval_min, interval)

	var player_pos: Vector2 = state.player.position
	for enemy in state.enemies.duplicate():
		var dir: Vector2 = player_pos - enemy.position
		if dir.length() > 0.01:
			enemy.position += dir.normalized() * enemy.speed * dt
		enemy.contact_timer = max(0.0, enemy.get("contact_timer", 0.0) - dt)
		if enemy.position.distance_to(player_pos) <= enemy.radius + state.player.radius and enemy.contact_timer <= 0.0:
			damage_player(enemy.damage)
			enemy.contact_timer = 0.75

func spawn_enemy(force_boss = false) -> Dictionary:
	var mode = current_wave_mode()
	var is_boss = force_boss
	var viewport = get_viewport().get_visible_rect().size
	var radius = 15.0 if not is_boss else 34.0
	var position = _spawn_position(mode.pattern, viewport)
	var pressure = difficulty_combat_pressure()
	var enemy = {
		"type": "boss" if is_boss else "normal",
		"position": position,
		"radius": radius,
		"hp": 0.0,
		"max_hp": 0.0,
		"speed": 0.0,
		"damage": config.enemy_damage,
		"contact_timer": 0.0,
		"boss_tier": max(1, state.boss_spawn_index),
	}
	var hp = config.enemy_hp * pressure.enemy_hp_multiplier * mode.hp_multiplier
	var speed = config.enemy_speed * (1.0 + pressure.enemy_speed_multiplier) * mode.speed_multiplier
	if is_boss:
		hp = boss_hp_estimate()
		speed *= 0.55
		enemy.damage = config.enemy_damage * 1.45
	enemy.hp = hp
	enemy.max_hp = hp
	enemy.speed = speed
	state.enemies.append(enemy)
	return enemy

func _spawn_position(pattern: String, viewport: Vector2) -> Vector2:
	var player_pos: Vector2 = state.player.position
	var margin = max(viewport.x, viewport.y) * 0.62 + 80.0
	if pattern == "side":
		var side = state.wave_director.side
		var x = -margin if side == "left" else margin
		return player_pos + Vector2(x, rng.randf_range(-viewport.y * 0.45, viewport.y * 0.45))
	if pattern == "ring":
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

func _update_boss_spawns() -> void:
	var times: Array = config.boss_spawn_times
	if state.boss_spawn_index < times.size() and state.elapsed >= times[state.boss_spawn_index]:
		state.boss_spawn_index += 1
		spawn_enemy(true)
		add_float_text(state.player.position + Vector2(0, -54), "보스 감지", Color("#d26bff"))

func boss_hp_estimate() -> float:
	var tier = max(1, state.boss_spawn_index)
	return config.boss_base_hp * (1.0 + 0.55 * float(tier - 1)) * difficulty_combat_pressure().enemy_hp_multiplier

func damage_player(amount: float) -> void:
	if state.game_over:
		return
	state.player.hp -= amount
	state.player.hit_flash = 0.25
	add_float_text(state.player.position + Vector2(0, -24), "-%d" % ceil(amount), Color("#ff5964"))
	if state.player.hp <= 0.0:
		if state.stats.low_hp_popup_freeze > 0 and not state.low_hp_freeze_used:
			state.low_hp_freeze_used = true
			state.popup_freeze_timer = 8.0
			state.player.hp = 1.0
			add_float_text(state.player.position + Vector2(0, -38), "집중 모드", Color("#4aa8ff"))
		else:
			end_game()

func heal_player(amount: float) -> void:
	var scaled = amount * max(0.0, 1.0 + state.stats.healing_multiplier)
	state.player.hp = min(state.player.max_hp, state.player.hp + scaled)

func _update_health_regen(dt: float) -> void:
	var regen = state.stats.health_regen_per_second
	if state.stats.wound_engine > 0 and hp_ratio() <= 0.5:
		regen += 2.0 * state.stats.wound_engine
	if regen > 0.0:
		heal_player(regen * dt)

func hp_ratio() -> float:
	return clamp(state.player.hp / max(state.player.max_hp, 1.0), 0.0, 1.0)

func _update_auto_attack(dt: float) -> void:
	for slot in ["primary", "secondary"]:
		if state["%s_module" % slot] == "":
			continue
		state.module_timers[slot] -= dt
		if state.module_timers[slot] <= 0.0:
			trigger_module_attack(slot)
			state.module_timers[slot] = effective_attack_interval(slot)

func trigger_module_attack(slot: String) -> void:
	var module_id = state["%s_module" % slot]
	var form_id = selected_form_for_slot(slot)
	var damage = effective_damage(slot)
	var range = effective_attack_range(slot)
	if state.popup_close_attack_primed and slot == "primary":
		damage *= 1.25
		state.popup_close_attack_primed = false

	if module_id == "ranged":
		if form_id == "ranged_laser":
			_execute_laser(damage, range, slot)
		elif form_id == "ranged_scatter":
			_execute_projectile(damage * 0.75, range, slot, 3, 0.28)
		elif form_id == "ranged_charge_cannon":
			_execute_projectile(damage * 2.4, range * 1.15, slot, 1, 0.0, 12.0)
		else:
			_execute_projectile(damage, range, slot, 1, 0.0)
	elif module_id == "melee":
		if form_id == "melee_circle_slash":
			_execute_circle_attack(damage * 0.9, range * 0.75, slot)
		elif form_id == "melee_sword_wave":
			_execute_projectile(damage * 1.1, range * 0.95, slot, 1, 0.0, 10.0, true)
		elif form_id == "melee_charged_cleave":
			_execute_slash(damage * 2.0, range * 0.95, slot, 74.0)
		else:
			_execute_slash(damage, range * 0.7, slot, 42.0)
	elif module_id == "aura":
		var multiplier = 1.0
		if form_id == "aura_pulse":
			multiplier = 1.55
		elif form_id == "aura_charged_nova":
			multiplier = 2.4
		_execute_circle_attack(damage * multiplier, range * 0.72, slot)
	elif module_id == "deploy":
		if form_id == "deploy_turret":
			_spawn_turret(damage, range, slot)
		elif form_id == "deploy_field":
			_spawn_field(damage, range, slot)
		else:
			_spawn_mine(damage, range, slot)

func _execute_projectile(damage: float, range: float, slot: String, count: int, spread: float, radius = 5.0, sword_wave = false) -> void:
	var target = get_nearest_enemy(range)
	var base_dir = state.last_move_dir
	if target != null:
		base_dir = (target.position - state.player.position).normalized()
	for index in range(count):
		var angle_offset = 0.0
		if count > 1:
			angle_offset = (float(index) - float(count - 1) * 0.5) * spread
		var dir = base_dir.rotated(angle_offset)
		state.projectiles.append({
			"kind": "projectile",
			"slot": slot,
			"position": state.player.position + dir * 18.0,
			"velocity": dir * config.ranged_projectile_speed,
			"radius": radius,
			"damage": damage,
			"life": range / config.ranged_projectile_speed,
			"max_life": range / config.ranged_projectile_speed,
			"pierce": 1 + int(state.stats.extra_targets) + (1 if selected_mechanic_for_slot(slot) == "pierce" else 0),
			"sword_wave": sword_wave,
		})
	if state.stats.sponsored_double_hit > 0 and count == 1 and count_open_sponsored_popups() > 0:
		state.projectiles.append({
			"kind": "projectile",
			"slot": slot,
			"position": state.player.position + base_dir.rotated(0.18) * 18.0,
			"velocity": base_dir.rotated(0.18) * config.ranged_projectile_speed,
			"radius": radius,
			"damage": damage * 0.55,
			"life": range / config.ranged_projectile_speed,
			"max_life": range / config.ranged_projectile_speed,
			"pierce": 1,
			"sword_wave": sword_wave,
		})

func _execute_laser(damage: float, range: float, slot: String) -> void:
	var target = get_nearest_enemy(range)
	var dir = state.last_move_dir
	if target != null:
		dir = (target.position - state.player.position).normalized()
	var start = state.player.position
	var end = start + dir * range
	var width = 12.0 + (8.0 if selected_mechanic_for_slot(slot) == "pierce" else 0.0)
	for enemy in state.enemies.duplicate():
		var distance = Geometry2D.get_closest_point_to_segment(enemy.position, start, end).distance_to(enemy.position)
		if distance <= enemy.radius + width:
			damage_enemy(enemy, damage, slot)
	state.projectiles.append({"kind": "laser", "position": start, "end_position": end, "width": width, "life": 0.12, "max_life": 0.12})

func _execute_slash(damage: float, range: float, slot: String, width: float) -> void:
	var start = state.player.position
	var end = start + state.last_move_dir * range
	for enemy in state.enemies.duplicate():
		var point = Geometry2D.get_closest_point_to_segment(enemy.position, start, end)
		if enemy.position.distance_to(point) <= enemy.radius + width * 0.5:
			damage_enemy(enemy, damage, slot)
	state.attacks.append({"kind": "slash", "position": start, "end_position": end, "width": width, "life": 0.18, "max_life": 0.18})

func _execute_circle_attack(damage: float, range: float, slot: String) -> void:
	var center: Vector2 = state.player.position
	for enemy in state.enemies.duplicate():
		if enemy.position.distance_to(center) <= range + enemy.radius:
			damage_enemy(enemy, damage, slot)
	state.attacks.append({"kind": "circle", "position": center, "radius": range, "life": 0.28, "max_life": 0.28})

func _spawn_mine(damage: float, range: float, slot: String) -> void:
	var pos: Vector2 = state.player.position + state.last_move_dir * 44.0
	state.mines.append({"position": pos, "damage": damage * 1.65, "radius": min(92.0, range * 0.5), "trigger": 26.0, "life": 10.0, "max_life": 10.0, "slot": slot})

func _spawn_turret(damage: float, range: float, slot: String) -> void:
	var pos: Vector2 = state.player.position + state.last_move_dir * 52.0
	state.turrets.append({"position": pos, "damage": damage * 0.45, "range": range * 0.9, "timer": 0.2, "interval": 0.55, "life": 8.0, "max_life": 8.0, "slot": slot})

func _spawn_field(damage: float, range: float, slot: String) -> void:
	var pos: Vector2 = state.player.position + state.last_move_dir * 58.0
	state.fields.append({"position": pos, "damage": damage * 0.32, "radius": range * 0.45, "tick": 0.0, "interval": 0.42, "life": 5.0, "max_life": 5.0, "slot": slot})

func _update_projectiles(dt: float) -> void:
	for projectile in state.projectiles.duplicate():
		projectile.life -= dt
		if projectile.get("kind", "projectile") == "projectile":
			projectile.position += projectile.velocity * dt
			for enemy in state.enemies.duplicate():
				if enemy.position.distance_to(projectile.position) <= enemy.radius + projectile.radius:
					damage_enemy(enemy, projectile.damage, projectile.slot)
					projectile.pierce -= 1
					if projectile.pierce <= 0:
						state.projectiles.erase(projectile)
						break
		if projectile.life <= 0.0 and state.projectiles.has(projectile):
			state.projectiles.erase(projectile)

func _update_mines(dt: float) -> void:
	for mine in state.mines.duplicate():
		mine.life -= dt
		var triggered = false
		for enemy in state.enemies:
			if enemy.position.distance_to(mine.position) <= enemy.radius + mine.trigger:
				triggered = true
				break
		if triggered:
			_explode_at(mine.position, mine.radius, mine.damage, mine.slot)
			state.mines.erase(mine)
		elif mine.life <= 0.0:
			state.mines.erase(mine)

func _update_turrets(dt: float) -> void:
	for turret in state.turrets.duplicate():
		turret.life -= dt
		turret.timer -= dt
		if turret.timer <= 0.0:
			turret.timer = turret.interval
			var target = get_nearest_enemy_from(turret.position, turret.range)
			if target != null:
				var dir: Vector2 = (target.position - turret.position).normalized()
				state.projectiles.append({"kind": "projectile", "slot": turret.slot, "position": turret.position, "velocity": dir * config.ranged_projectile_speed, "radius": 4.0, "damage": turret.damage, "life": turret.range / config.ranged_projectile_speed, "max_life": turret.range / config.ranged_projectile_speed, "pierce": 1})
		if turret.life <= 0.0:
			state.turrets.erase(turret)

func _update_fields(dt: float) -> void:
	for field in state.fields.duplicate():
		field.life -= dt
		field.tick -= dt
		if field.tick <= 0.0:
			field.tick = field.interval
			for enemy in state.enemies.duplicate():
				if enemy.position.distance_to(field.position) <= enemy.radius + field.radius:
					damage_enemy(enemy, field.damage, field.slot)
		if field.life <= 0.0:
			state.fields.erase(field)

func _explode_at(position: Vector2, radius: float, damage: float, slot: String) -> void:
	for enemy in state.enemies.duplicate():
		if enemy.position.distance_to(position) <= enemy.radius + radius:
			damage_enemy(enemy, damage, slot)
	state.attacks.append({"kind": "explosion", "position": position, "radius": radius, "life": 0.32, "max_life": 0.32})

func damage_enemy(enemy: Dictionary, amount: float, slot = "primary") -> bool:
	var final_damage = apply_crit_to_damage(amount)
	enemy.hp -= final_damage
	add_float_text(enemy.position + Vector2(0, -enemy.radius), "%d" % ceil(final_damage), Color("#edf2f7"))
	if state.stats.life_steal_percent > 0.0:
		heal_player(final_damage * state.stats.life_steal_percent)
	if enemy.hp <= 0.0:
		kill_enemy(enemy, slot)
		return true
	return false

func kill_enemy(enemy: Dictionary, slot: String) -> void:
	if not state.enemies.has(enemy):
		return
	state.enemies.erase(enemy)
	if enemy.type == "boss":
		grant_boss_rewards(enemy)
	else:
		state.kill_count += 1
		spawn_field_pickup(enemy.position, "gold", config.gold_per_kill)
		spawn_field_pickup(enemy.position + Vector2(rng.randf_range(-10.0, 10.0), rng.randf_range(-10.0, 10.0)), "xp", config.xp_per_kill)
		if rng.randf() < 0.025:
			spawn_field_pickup(enemy.position, "heal", 20)
		if rng.randf() < 0.025:
			spawn_field_pickup(enemy.position, "magnet", 0)
	if selected_mechanic_for_slot(slot) == "kill_chain":
		_explode_at(enemy.position, 54.0, effective_damage(slot) * 0.45, slot)

func spawn_field_pickup(position: Vector2, kind: String, value: int) -> void:
	state.pickups.append({"position": position, "kind": kind, "value": value, "life": 18.0})

func _update_pickups(dt: float) -> void:
	var range = effective_pickup_range()
	for pickup in state.pickups.duplicate():
		pickup.life -= dt
		if pickup.kind == "magnet":
			for other in state.pickups:
				if other != pickup:
					other.position = other.position.move_toward(state.player.position, 520.0 * dt)
		if pickup.position.distance_to(state.player.position) <= range:
			collect_pickup(pickup)
		elif pickup.life <= 0.0:
			state.pickups.erase(pickup)

func collect_pickup(pickup: Dictionary) -> void:
	if not state.pickups.has(pickup):
		return
	state.pickups.erase(pickup)
	if pickup.kind == "gold":
		add_gold(pickup.value, "pickup")
	elif pickup.kind == "xp":
		add_xp(pickup.value)
	elif pickup.kind == "heal":
		heal_player(config.heal_pickup_flat if config.has("heal_pickup_flat") else 20)
	elif pickup.kind == "magnet":
		for other in state.pickups.duplicate():
			if other != pickup:
				collect_pickup(other)

func add_gold(amount: int, source = "") -> void:
	if amount <= 0:
		return
	var remaining = amount
	var recurring = active_recurring_investment()
	if recurring != null and not ["pickup", "debug", "investment_payout", "investment_refund", "credit_cashout", "loan"].has(source):
		var redirected = int(floor(float(remaining) * recurring.investment.redirect_ratio))
		if redirected > 0:
			recurring.investment.accumulated += redirected
			state.invested_gold += redirected
			remaining -= redirected
	var multiplier = 1.0 + state.stats.reward_gold_multiplier
	if state.open_popups.size() >= 4:
		multiplier += state.stats.crowded_gold_multiplier
	state.gold += int(round(float(remaining) * multiplier))

func add_xp(amount: int) -> void:
	state.xp += amount
	check_level_up()

func check_level_up() -> void:
	while state.xp >= state.xp_need:
		state.xp -= state.xp_need
		state.level += 1
		state.xp_need = int(ceil(float(state.xp_need) * config.xp_requirement_growth))
		open_level_choice()

func open_level_choice() -> void:
	if state.selecting:
		return
	var choice_label = next_growth_choice_label()
	if state.level == 3 and state.secondary_module == "":
		open_attack_module_selection("secondary")
	elif choice_label == "공격 방식":
		open_attack_form_selection("primary")
	elif choice_label == "공격 기믹":
		open_attack_mechanic_selection("primary")
	elif choice_label == "빌드 최적화":
		open_build_scaling_selection("primary")
	elif choice_label == "심화 선택":
		open_deepening_selection("primary")
	else:
		open_item_like_selection("성장 보상", "전투와 팝업 관리에 도움이 되는 패시브를 선택하세요.", _choose_random_perks(3), Callable(self, "apply_perk_choice"))

func next_growth_choice_label() -> String:
	if state.primary_module == "":
		return "시작 선택"
	if state.level == 3 and state.secondary_module == "":
		return "보조 모듈"
	if [5, 9].has(state.level):
		return "공격 방식"
	if [7, 13].has(state.level):
		return "공격 기믹"
	if [11, 17].has(state.level):
		return "빌드 최적화"
	if state.level % 4 == 0:
		return "심화 선택"
	return "패시브 보상"

func open_attack_module_selection(slot: String) -> void:
	state.selecting = true
	var title = "1차 모듈 선택" if slot == "primary" else "보조 모듈 선택"
	hud.show_choices(title, "공격 모듈을 선택하면 런이 시작됩니다.", attack_modules, func(choice): apply_attack_module_choice(slot, choice))

func apply_attack_module_choice(slot: String, choice: Dictionary) -> void:
	state["%s_module" % slot] = choice.id
	state.module_upgrades[slot].form = choice.base_form
	state.recent_perk_text = "%s 모듈 선택: %s" % ["1차" if slot == "primary" else "보조", choice.name]
	state.selecting = false
	state.paused = false

func open_attack_form_selection(slot: String) -> void:
	var module_id = state["%s_module" % slot]
	var choices = attack_forms.filter(func(form): return form.compatible_modules.has(module_id))
	_open_growth_choices("공격 방식 선택", "현재 모듈의 공격 형태를 바꿉니다.", choices, func(choice): apply_form_choice(slot, choice))

func apply_form_choice(slot: String, choice: Dictionary) -> void:
	state.module_upgrades[slot].form = choice.id
	state.recent_perk_text = "%s 방식: %s" % [slot_label(slot), choice.name]
	_finish_growth_choice()

func open_attack_mechanic_selection(slot: String) -> void:
	var form = form_by_id(selected_form_for_slot(slot))
	var tags = form.get("tags", ["any"])
	var choices = attack_mechanics.filter(func(mechanic):
		return mechanic.compatible_tags.has("any") or tags.any(func(tag): return mechanic.compatible_tags.has(tag))
	)
	_open_growth_choices("공격 기믹 선택", "공격에 보조 규칙을 추가합니다.", choices, func(choice): apply_mechanic_choice(slot, choice))

func apply_mechanic_choice(slot: String, choice: Dictionary) -> void:
	state.module_upgrades[slot].mechanic = choice.id
	state.recent_perk_text = "%s 기믹: %s" % [slot_label(slot), choice.name]
	_finish_growth_choice()

func open_build_scaling_selection(slot: String) -> void:
	var playstyle = state.active_playstyle if state.active_playstyle != "" else "generic"
	var choices = build_scalings.filter(func(scaling): return scaling.playstyle == playstyle or scaling.playstyle == "generic")
	_open_growth_choices("빌드 최적화 선택", "현재 계약/상태에 맞춰 공격 스케일링을 추가합니다.", choices.slice(0, min(choices.size(), 5)), func(choice): apply_scaling_choice(slot, choice))

func apply_scaling_choice(slot: String, choice: Dictionary) -> void:
	state.module_upgrades[slot].scaling = choice.id
	state.recent_perk_text = "%s 최적화: %s" % [slot_label(slot), choice.name]
	_finish_growth_choice()

func open_deepening_selection(slot: String) -> void:
	_open_growth_choices("심화 선택", "현재 모듈의 피해/빈도/범위를 강화합니다.", GameDataScript.deepening_options(), func(choice): apply_deepening_choice(slot, choice))

func apply_deepening_choice(slot: String, choice: Dictionary) -> void:
	state["%s_deepening" % slot] = choice
	state.recent_perk_text = "%s 심화: %s" % [slot_label(slot), choice.name]
	_finish_growth_choice()

func _open_growth_choices(title: String, description: String, choices: Array, callback: Callable) -> void:
	state.selecting = true
	hud.show_choices(title, description, choices, callback)

func _finish_growth_choice() -> void:
	state.primary_mastery += 1
	state.selecting = false
	state.paused = false

func open_item_like_selection(title: String, description: String, choices: Array, callback: Callable) -> void:
	state.selecting = true
	hud.show_choices(title, description, choices, callback)

func apply_perk_choice(choice: Dictionary) -> void:
	apply_reward_effects(choice)
	state.recent_perk_text = "최근 성장: %s" % choice.name
	_finish_growth_choice()

func roll_item() -> void:
	if state.game_over or state.paused or state.selecting:
		return
	var cost = current_item_roll_cost()
	if state.gold < cost:
		return
	state.gold -= cost
	state.item_roll_count += 1
	var count = 3 + state.next_item_extra_choices
	state.next_item_extra_choices = 0
	var choices = choose_item_options(count)
	state.selecting = true
	state.paused = true
	hud.show_choices("아이템 선택", "골드를 지불했습니다. 패시브 아이템 1개를 선택하세요.", choices, Callable(self, "apply_item_choice"))

func apply_item_choice(choice: Dictionary) -> void:
	apply_item_reward(choice)
	state.selecting = false
	state.paused = false

func apply_item_reward(item: Dictionary) -> void:
	var id = item.id
	state.item_counts[id] = state.item_counts.get(id, 0) + 1
	apply_reward_effects(item)
	state.last_item_text = "최근 아이템: %s x%d" % [item.name, state.item_counts[id]]
	if item.has("rarity") and item.rarity == "Cursed":
		state.heat += 0.35

func choose_item_options(count: int) -> Array:
	var pool = items.duplicate()
	var result = []
	for i in range(count):
		if pool.is_empty():
			break
		var index = _weighted_item_index(pool)
		result.append(pool[index])
		pool.remove_at(index)
	return result

func _choose_random_perks(count: int) -> Array:
	var pool = perks.duplicate()
	var result = []
	for i in range(count):
		if pool.is_empty():
			break
		var index = rng.randi_range(0, pool.size() - 1)
		result.append(pool[index])
		pool.remove_at(index)
	return result

func _weighted_item_index(pool: Array) -> int:
	var weights = {"Common": 44.0, "Rare": 28.0, "Epic": 12.0, "Cursed": 7.0}
	var total = 0.0
	for item in pool:
		total += weights.get(item.rarity, 10.0)
	var roll = rng.randf() * total
	for i in range(pool.size()):
		roll -= weights.get(pool[i].rarity, 10.0)
		if roll <= 0.0:
			return i
	return pool.size() - 1

func apply_reward_effects(source: Dictionary) -> void:
	if source.has("effects"):
		for effect in source.effects:
			apply_effect(effect)
	elif source.has("effect"):
		apply_effect(source.effect)
	elif source.has("stat"):
		apply_effect({"stat": source.stat, "value": source.get("value", 0)})

func apply_effect(effect: Dictionary) -> void:
	var type = effect.get("type", "stat")
	if type == "gold":
		add_gold(effect.get("value", 0), "reward")
	elif type == "heal":
		heal_player(effect.get("value", 0))
	elif type == "heat":
		state.heat += effect.get("value", 0)
	elif type == "item_discount":
		state.next_item_discounts.append({"value": effect.get("value", 0.2), "uses": effect.get("uses", 1)})
	elif type == "extra_item_choice":
		state.next_item_extra_choices += effect.get("value", 1)
	elif type == "free_sample_item":
		var sample = random_item_by_rarity(effect.get("rarity", "Common"))
		if not sample.is_empty():
			apply_item_reward(sample)
	elif type == "delayed_max_hp_loss":
		state.delayed_events.append({"type": "max_hp_loss", "value": effect.get("value", 20), "timer": effect.get("delay", 60.0)})
	elif effect.has("duration"):
		state.timed_effects.append({"stat": effect.get("stat", ""), "value": effect.get("value", 0.0), "remaining": effect.get("duration", 20.0)})
	else:
		var stat = effect.get("stat", "")
		if stat == "":
			return
		if stat == "max_hp":
			state.player.max_hp += effect.get("value", 0)
			state.player.hp += effect.get("value", 0)
		elif state.stats.has(stat):
			state.stats[stat] += effect.get("value", 0)
			if stat == "max_open_popups":
				state.stats[stat] = int(state.stats[stat])

func _update_timed_effects(dt: float) -> void:
	for effect in state.timed_effects.duplicate():
		effect.remaining -= dt
		if effect.remaining <= 0.0:
			state.timed_effects.erase(effect)

func _update_delayed_events(dt: float) -> void:
	for event in state.delayed_events.duplicate():
		event.timer -= dt
		if event.timer <= 0.0:
			if event.type == "max_hp_loss":
				state.player.max_hp = max(1.0, state.player.max_hp - event.value)
				state.player.hp = min(state.player.hp, state.player.max_hp)
			elif event.type == "interest_payout":
				_update_delayed_interest(event)
			state.delayed_events.erase(event)

func random_item_by_rarity(rarity: String) -> Dictionary:
	var matches = items.filter(func(item): return item.rarity == rarity)
	if matches.is_empty():
		return {}
	return matches[rng.randi_range(0, matches.size() - 1)]

func _update_wave_director(dt: float) -> void:
	state.wave_director.timer -= dt
	state.wave_director.notice_timer = max(0.0, state.wave_director.notice_timer - dt)
	if state.wave_director.timer <= 0.0:
		var candidates = wave_modes.duplicate()
		var next = candidates[rng.randi_range(0, candidates.size() - 1)]
		set_wave_mode(next.id)

func set_wave_mode(mode_id: String) -> void:
	var mode = wave_mode_by_id(mode_id)
	state.wave_director.mode = mode.id
	state.wave_director.side = "left" if rng.randf() < 0.5 else "right"
	state.wave_director.timer = rng.randf_range(mode.duration[0], mode.duration[1])
	state.wave_director.notice_timer = 2.5
	state.wave_director.notice_text = mode.label

func _update_first_purchase_offer(dt: float) -> void:
	if state.first_purchase_offer_shown:
		return
	state.first_purchase_timer -= dt
	if state.first_purchase_timer <= 0.0:
		state.first_purchase_offer_shown = true
		create_popup_by_id("first_purchase_package")

func _update_popups(dt: float) -> void:
	if state.popup_freeze_timer <= 0.0:
		state.popup_timer -= dt
	if state.popup_timer <= 0.0:
		create_natural_popup()
		state.popup_timer = effective_popup_interval()
	for popup in state.open_popups.duplicate():
		_update_popup_runtime(popup, dt)

func create_natural_popup() -> void:
	if state.open_popups.size() >= max_open_popups():
		return
	var def = pick_weighted_popup()
	if not def.is_empty():
		create_popup(def)

func pick_weighted_popup() -> Dictionary:
	var available = popups.filter(func(def): return def.weight > 0.0)
	var total = 0.0
	for def in available:
		total += popup_weight(def)
	var roll = rng.randf() * total
	for def in available:
		roll -= popup_weight(def)
		if roll <= 0.0:
			return def
	return available.back() if not available.is_empty() else {}

func popup_weight(def: Dictionary) -> float:
	var weight = def.weight
	var type = def.type
	if type == "terms":
		weight *= 1.0 + state.stats.terms_popup_weight_multiplier
	if type == "sponsored_ad":
		weight *= 1.0 + state.stats.sponsored_popup_weight_multiplier
	if type == "interest_offer":
		weight *= 1.0 + state.stats.interest_popup_weight_multiplier
	if type == "popup_store":
		weight *= 1.0 + state.stats.popup_store_weight_multiplier
	if state.active_playstyle == "investor" and ["interest_offer", "recurring_investment", "loan_offer", "stock_broker_app"].has(type):
		weight *= 1.45
	return max(0.0, weight)

func create_popup_by_id(id: String) -> Dictionary:
	var def = popup_def_by_id(id)
	if def.is_empty():
		return {}
	return create_popup(def)

func create_popup(def: Dictionary) -> Dictionary:
	var popup = {
		"runtime_id": popup_id_seed,
		"def": def.duplicate(true),
		"position": choose_popup_position(def),
		"size": popup_size_for(def),
		"elapsed": 0.0,
		"progress": 0.0,
		"rewarded": false,
		"life": 0.0,
		"clean_progress": 0.0,
		"velocity": Vector2(rng.randf_range(-70.0, 70.0), rng.randf_range(-55.0, 55.0)),
	}
	popup_id_seed += 1
	if def.type == "recurring_investment":
		popup.investment = {"accepted": false, "elapsed": 0.0, "duration": def.duration, "redirect_ratio": 0.35, "accumulated": 0}
	if def.type == "boss_package_ad":
		var tier = max(1, state.boss_package_count + 1)
		popup.package_cost = 55 + tier * 35
		popup.package_items = choose_item_options(3)
	state.open_popups.append(popup)
	return popup

func _update_popup_runtime(popup: Dictionary, dt: float) -> void:
	var def = popup.def
	popup.elapsed += dt
	popup.life += dt
	if def.type == "moving_close":
		_update_moving_popup(popup, dt)
	if def.type == "sponsored_ad":
		var duration = def.duration
		popup.progress = clamp(popup.elapsed / max(duration, 0.1), 0.0, 1.0)
		if popup.elapsed >= duration and not popup.rewarded:
			popup.rewarded = true
			state.sponsored_completions += 1
			state.sponsored_attack_boost_stacks += 1
			state.metrics.sponsored_rewards += 1
			apply_effect(def.get("reward", {"type": "gold", "value": 20}))
			request_close_popup(popup.runtime_id, {"reason": "sponsored_complete"})
	elif def.type == "timed_reward":
		var duration = def.duration * max(0.25, 1.0 + state.stats.timed_reward_duration_multiplier)
		popup.progress = clamp(popup.elapsed / max(duration, 0.1), 0.0, 1.0)
		if popup.elapsed >= duration and not popup.rewarded:
			popup.rewarded = true
			apply_effect(def.get("reward", {"type": "gold", "value": 30}))
			request_close_popup(popup.runtime_id, {"reason": "timed_complete"})
	elif def.type == "clean_challenge":
		if state.open_popups.size() <= def.get("target_open_popups", 2):
			popup.clean_progress += dt
		else:
			popup.clean_progress = max(0.0, popup.clean_progress - dt * 0.75)
		popup.progress = clamp(popup.clean_progress / def.duration, 0.0, 1.0)
		if popup.clean_progress >= def.duration:
			apply_effect(def.get("reward", {"type": "item_discount", "value": 0.2, "uses": 1}))
			request_close_popup(popup.runtime_id, {"reason": "clean_complete"})
		elif popup.elapsed >= def.duration * 2.2:
			request_close_popup(popup.runtime_id, {"reason": "clean_failed"})
	elif def.type == "volatile_popup":
		popup.progress = clamp(popup.elapsed / max(def.duration, 0.1), 0.0, 1.0)
		if popup.elapsed >= def.duration:
			state.popup_timer = min(state.popup_timer, 1.0)
			request_close_popup(popup.runtime_id, {"reason": "volatile_timeout"})
	elif def.type == "infection":
		popup.progress = clamp(popup.elapsed / max(def.duration, 0.1), 0.0, 1.0)
		if popup.elapsed >= def.duration:
			infect_popup_target()
			request_close_popup(popup.runtime_id, {"reason": "infection_resolved"})
	elif def.duration > 0.0 and popup.elapsed >= def.duration and ["stock_market"].has(def.type):
		request_close_popup(popup.runtime_id, {"reason": "timeout"})

func _update_moving_popup(popup: Dictionary, dt: float) -> void:
	var viewport = get_viewport().get_visible_rect().size
	popup.position += popup.velocity * dt
	if popup.position.x < 0.0 or popup.position.x + popup.size.x > viewport.x:
		popup.velocity.x *= -1.0
	if popup.position.y < 0.0 or popup.position.y + popup.size.y > viewport.y:
		popup.velocity.y *= -1.0
	popup.position.x = clamp(popup.position.x, 0.0, max(0.0, viewport.x - popup.size.x))
	popup.position.y = clamp(popup.position.y, 0.0, max(0.0, viewport.y - popup.size.y))

func infect_popup_target() -> void:
	for popup in state.open_popups:
		if not ["infection", "infected_popup"].has(popup.def.type):
			popup.def = {"id": "infected_popup", "title": "감염된 팝업", "body": "보상 기능이 손상되었습니다. 닫아서 정리하세요.", "type": "infected_popup", "duration": 0.0, "weight": 0.0}
			return

func request_close_popup(runtime_id: int, options = {}) -> void:
	var popup = popup_by_runtime_id(runtime_id)
	if popup == null:
		return
	var reason = options.get("reason", "button")
	if reason == "volatile":
		_explode_at(state.player.position, 150.0, 60.0, "primary")
		state.metrics.volatile_closures += 1
	if popup.def.type == "infected_popup":
		state.heat += 0.15
	if state.stats.gold_per_popup_close > 0:
		add_gold(state.stats.gold_per_popup_close, "popup_close")
	if state.stats.popup_close_damage > 0.0:
		_explode_at(state.player.position, 96.0, state.stats.popup_close_damage, "primary")
	if state.module_synergy.get("id", "") == "popup_trigger":
		trigger_module_attack("primary")
	if selected_mechanic_for_slot("primary") == "popup_close_trigger":
		state.popup_close_attack_primed = true
	register_cleanup_combo()
	state.open_popups.erase(popup)

func bring_popup_to_front(runtime_id: int) -> void:
	var popup = popup_by_runtime_id(runtime_id)
	if popup == null:
		return
	state.open_popups.erase(popup)
	state.open_popups.append(popup)

func move_popup(runtime_id: int, position: Vector2) -> void:
	var popup = popup_by_runtime_id(runtime_id)
	if popup == null:
		return
	var viewport = get_viewport().get_visible_rect().size
	popup.position.x = clamp(position.x, 0.0, max(0.0, viewport.x - popup.size.x))
	popup.position.y = clamp(position.y, 0.0, max(0.0, viewport.y - popup.size.y))

func emergency_close_oldest_popup() -> void:
	if state.game_over or state.stats.emergency_close_disabled > 0 or state.emergency_timer > 0.0:
		return
	if state.open_popups.is_empty():
		return
	var target = state.open_popups[0]
	if state.stats.smart_emergency_close > 0:
		for popup in state.open_popups:
			if ["volatile_popup", "infection", "infected_popup", "terms"].has(popup.def.type):
				target = popup
				break
	request_close_popup(target.runtime_id, {"reason": "emergency"})
	state.emergency_timer = config.emergency_close_cooldown * max(0.2, 1.0 + state.stats.emergency_cooldown_multiplier)
	state.emergency_boost_timer = 5.0

func register_cleanup_combo() -> void:
	state.cleanup_combo_stacks = min(state.cleanup_combo_max, state.cleanup_combo_stacks + 1)
	state.cleanup_combo_timer = effective_cleanup_combo_grace()

func effective_cleanup_combo_grace() -> float:
	return state.cleanup_combo_grace + state.stats.cleanup_combo_grace_bonus

func _update_cleanup_combo(dt: float) -> void:
	if state.cleanup_combo_timer > 0.0:
		state.cleanup_combo_timer -= dt
		if state.cleanup_combo_timer <= 0.0:
			state.cleanup_combo_stacks = 0

func _update_attacks(dt: float) -> void:
	for attack in state.attacks.duplicate():
		attack.life -= dt
		if attack.life <= 0.0:
			state.attacks.erase(attack)

func _update_float_texts(dt: float) -> void:
	for text in state.float_texts.duplicate():
		text.life -= dt
		text.position.y -= 22.0 * dt
		if text.life <= 0.0:
			state.float_texts.erase(text)

func add_float_text(position: Vector2, text: String, color: Color) -> void:
	state.float_texts.append({"position": position, "text": text, "color": color, "life": 0.75, "max_life": 0.75})
	if state.float_texts.size() > 80:
		state.float_texts.pop_front()

func apply_first_purchase_package(runtime_id: int, package: Dictionary) -> void:
	state.active_playstyle = package.playstyle
	state.active_playstyle_name = package.name
	add_gold(package.gold, "first_purchase")
	for effect in package.effects:
		apply_effect(effect)
	request_close_popup(runtime_id, {"reason": "first_purchase"})
	state.recent_perk_text = "계약 선택: %s" % package.name

func grant_boss_rewards(enemy: Dictionary) -> void:
	var tier = enemy.get("boss_tier", 1)
	add_gold(config.boss_gold_reward + (tier - 1) * 60, "boss")
	add_xp(config.boss_xp_reward + (tier - 1) * 55)
	state.metrics.boss_kills += 1
	state.boss_package_count += 1
	create_popup_by_id("boss_package_ad")

func purchase_boss_package(runtime_id: int) -> void:
	var popup = popup_by_runtime_id(runtime_id)
	if popup == null:
		return
	var cost = popup.get("package_cost", 80)
	if state.gold < cost:
		return
	state.gold -= cost
	state.metrics.boss_packages_purchased += 1
	var choices = popup.get("package_items", choose_item_options(3))
	state.selecting = true
	state.paused = true
	hud.show_choices("보스 패키지 선택", "구매한 보스 패키지에서 아이템을 선택하세요.", choices, Callable(self, "apply_item_choice"))
	request_close_popup(runtime_id, {"reason": "boss_package_purchase"})

func accept_terms_popup(runtime_id: int, risky: bool) -> void:
	var popup = popup_by_runtime_id(runtime_id)
	if popup == null:
		return
	var def = popup.def
	if risky:
		if def.has("risky_stat"):
			apply_effect(def.risky_stat)
		else:
			add_gold(def.get("risky_gold", 55), "terms")
		if state.stats.terms_penalty_shield > 0:
			state.stats.terms_penalty_shield -= 1
		else:
			state.terms_penalty_count += 1
			state.heat += 0.45
			apply_effect(def.get("penalty", {}))
			if state.stats.gold_per_terms_penalty > 0:
				add_gold(state.stats.gold_per_terms_penalty, "terms_penalty")
	else:
		if def.has("safe_stat"):
			apply_effect(def.safe_stat)
		else:
			add_gold(def.get("safe_gold", 20), "terms")
	request_close_popup(runtime_id, {"reason": "terms_accept"})

func accept_interest_offer(runtime_id: int, ratio: float) -> void:
	var popup = popup_by_runtime_id(runtime_id)
	if popup == null:
		return
	var principal = max(10, int(floor(state.gold * ratio)))
	if state.gold < principal:
		return
	state.gold -= principal
	state.invested_gold += principal
	state.delayed_events.append({"type": "interest_payout", "timer": 18.0, "principal": principal, "payout": int(round(principal * (1.22 + state.stats.interest_payout_multiplier)))})
	add_credit_score(2)
	request_close_popup(runtime_id, {"reason": "interest_accept"})

func accept_recurring_investment(runtime_id: int) -> void:
	var popup = popup_by_runtime_id(runtime_id)
	if popup == null:
		return
	popup.investment.accepted = true
	popup.investment.elapsed = 0.0
	add_credit_score(2)

func cancel_recurring_investment(runtime_id: int) -> void:
	var popup = popup_by_runtime_id(runtime_id)
	if popup == null:
		return
	var refund = int(round(popup.investment.accumulated * 0.72))
	state.invested_gold = max(0, state.invested_gold - popup.investment.accumulated)
	add_gold(refund, "investment_refund")
	add_credit_score(-8)
	request_close_popup(runtime_id, {"reason": "recurring_cancel"})

func active_recurring_investment():
	for popup in state.open_popups:
		if popup.def.type == "recurring_investment" and popup.has("investment") and popup.investment.get("accepted", false):
			return popup
	return null

func _update_resident_programs(dt: float) -> void:
	state.security_update_timer -= dt
	if state.security_update_timer <= 0.0:
		state.security_update_timer = rng.randf_range(28.0, 42.0)
		if not state.resident_programs.is_empty():
			create_popup_by_id("security_update_notice")
	if state.stats.auto_close_basic_interval > 0.0:
		state.auto_close_basic_timer -= dt
		if state.auto_close_basic_timer <= 0.0:
			state.auto_close_basic_timer = max(2.0, state.stats.auto_close_basic_interval)
			for popup in state.open_popups:
				if ["sponsored_ad", "moving_close", "infection", "infected_popup", "volatile_popup"].has(popup.def.type):
					request_close_popup(popup.runtime_id, {"reason": "auto_cleanup"})
					return

func install_resident_program(program_type: String, popup_id = 0) -> void:
	var def = security_program_by_type(program_type)
	if def.is_empty():
		return
	if state.gold < def.cost:
		return
	state.gold -= def.cost
	state.resident_programs.append(def)
	state.reserved_max_hp += def.reserved_hp
	state.player.max_hp = max(1.0, state.player.max_hp - def.reserved_hp)
	state.player.hp = min(state.player.hp, state.player.max_hp)
	apply_effect(def.effect)
	if popup_id != 0:
		request_close_popup(popup_id, {"reason": "security_installed"})

func apply_security_update(runtime_id: int) -> void:
	if state.gold < 20:
		return
	state.gold -= 20
	add_credit_score(1)
	request_close_popup(runtime_id, {"reason": "security_update"})

func clear_resident_programs() -> void:
	state.resident_programs.clear()
	state.player.max_hp += state.reserved_max_hp
	state.player.hp = min(state.player.max_hp, state.player.hp + state.reserved_max_hp)
	state.reserved_max_hp = 0.0

func accept_credit_cashout(runtime_id: int, credit_cost: int, gold: int) -> void:
	if state.credit_score < credit_cost:
		return
	add_credit_score(-credit_cost)
	state.debt_gold += int(round(gold * 0.25))
	add_gold(gold, "credit_cashout")
	request_close_popup(runtime_id, {"reason": "loan_accept"})

func _update_stock_market(dt: float) -> void:
	var market = state.stock_market
	market.tick_timer -= dt
	if market.tick_timer > 0.0:
		return
	market.tick_timer = 1.0
	var stock = market.stock
	var bias = stock_market_bias()
	var drift = bias.drift
	var volatility = bias.volatility
	var change = drift + rng.randfn(0.0, volatility)
	stock.price = max(2.0, stock.price * (1.0 + change))
	stock.last_change = change
	stock.history.append(stock.price)
	if stock.history.size() > 48:
		stock.history.pop_front()
	market.last_bias_label = bias.label

func stock_market_bias() -> Dictionary:
	var score = current_difficulty_score()
	if score >= 11.0:
		return {"label": "붕괴장", "drift": -0.006, "volatility": 0.16}
	if state.open_popups.size() >= 5:
		return {"label": "과열장", "drift": 0.008, "volatility": 0.13}
	if state.active_playstyle == "investor":
		return {"label": "우호장", "drift": 0.006, "volatility": 0.075}
	return {"label": "조용한 장세", "drift": 0.003, "volatility": 0.085}

func ensure_stock_broker_app() -> void:
	for popup in state.open_popups:
		if popup.def.type == "stock_broker_app":
			return
	create_popup_by_id("stock_broker_app")

func buy_stock(count: int) -> void:
	var stock = state.stock_market.stock
	var cost = int(ceil(stock.price * count))
	if count <= 0 or state.gold < cost:
		return
	var previous_value = stock.avg_cost * stock.shares
	state.gold -= cost
	stock.shares += count
	stock.avg_cost = (previous_value + cost) / max(1, stock.shares)

func buy_max_stock() -> void:
	var stock = state.stock_market.stock
	var count = int(floor(state.gold / max(stock.price, 1.0)))
	buy_stock(count)

func sell_stock_shares(count: int) -> void:
	var stock = state.stock_market.stock
	count = min(count, stock.shares)
	if count <= 0:
		return
	var proceeds = int(floor(stock.price * count))
	var loss = stock.price < stock.avg_cost
	stock.shares -= count
	if stock.shares <= 0:
		stock.avg_cost = 0.0
	add_gold(proceeds, "stock_sale")
	if loss and state.heat >= 4.0:
		state.heat += 0.2

func sell_all_stock() -> void:
	sell_stock_shares(state.stock_market.stock.shares)

func _update_delayed_interest(event: Dictionary) -> void:
	state.invested_gold = max(0, state.invested_gold - event.principal)
	add_gold(event.payout, "investment_payout")
	state.metrics.interest_completed += 1
	add_credit_score(8)

func add_credit_score(delta: int) -> void:
	state.credit_score = clamp(state.credit_score + delta, 0, 100)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()

func end_game() -> void:
	state.game_over = true
	state.paused = true
	state.player.hp = 0.0

func debug_action(action: String) -> void:
	match action:
		"gold":
			add_gold(25, "debug")
		"gold100":
			add_gold(100, "debug")
		"xp10":
			add_xp(10)
		"xp":
			add_xp(state.xp_need)
		"force_level":
			add_xp(max(1, state.xp_need - state.xp))
		"form_select":
			open_attack_form_selection("primary")
		"mechanic_select":
			open_attack_mechanic_selection("primary")
		"scaling_select":
			open_build_scaling_selection("primary")
		"combo":
			register_cleanup_combo()
		"combo5":
			for i in range(5):
				register_cleanup_combo()
		"wave_normal":
			set_wave_mode("normal")
		"wave_side":
			set_wave_mode("side_push")
		"wave_surround":
			set_wave_mode("surround")
		"wave_fast":
			set_wave_mode("fast_horde")
		"wave_dense":
			set_wave_mode("dense_horde")
		"drop_magnet":
			spawn_field_pickup(state.player.position + Vector2(36, 0), "magnet", 0)
		"drop_heal":
			spawn_field_pickup(state.player.position + Vector2(36, 0), "heal", 20)
		"install_keyboard":
			_debug_install_security("keyboard_security")
		"install_realtime":
			_debug_install_security("realtime_guard")
		"install_quarantine":
			_debug_install_security("popup_quarantine")
		"install_kernel":
			_debug_install_security("kernel_guard")
		"clear_security":
			clear_resident_programs()
		"invested100":
			state.invested_gold += 100
		"sponsored5":
			state.sponsored_attack_boost_stacks += 5
			state.sponsored_completions += 5
		"boss":
			spawn_enemy(true)
		"boss_package":
			create_popup_by_id("boss_package_ad")
		"rate":
			state.popup_timer = 0.1
		"heat":
			state.heat += 1.0
		"credit_plus":
			add_credit_score(10)
		"credit_minus":
			add_credit_score(-10)
		"clear_popups":
			state.open_popups.clear()
		"telegraph_moving":
			create_popup_by_id("moving_close")
		"investor_mode":
			state.active_playstyle = "investor"
			state.active_playstyle_name = "투자자 모드"
		"clear_playstyle":
			state.active_playstyle = ""
			state.active_playstyle_name = "미선택"
		_:
			if not popup_def_by_id(action).is_empty():
				create_popup_by_id(action)

func _debug_install_security(program_type: String) -> void:
	var def = security_program_by_type(program_type)
	if def.is_empty():
		return
	state.resident_programs.append(def)
	apply_effect(def.effect)

func current_item_discount() -> float:
	var discount = 0.0
	for item in state.next_item_discounts:
		discount += item.get("value", 0.0)
	if state.open_popups.size() >= 5:
		discount += state.stats.crowded_item_discount
	return clamp(discount, 0.0, 0.75)

func current_item_roll_cost() -> int:
	var base = config.item_roll_cost * pow(config.item_roll_cost_growth, state.item_roll_count)
	base *= 1.0 + max(0.0, state.debt_gold / 400.0)
	return max(1, int(round(base * (1.0 - current_item_discount()))))

func popup_store_price(product: Dictionary) -> int:
	return max(1, int(round(product.price * (1.0 - state.stats.popup_store_discount_multiplier))))

func purchase_popup_store_item(runtime_id: int, product: Dictionary) -> void:
	var price = popup_store_price(product)
	if state.gold < price:
		return
	state.gold -= price
	state.metrics.popup_store_purchases += 1
	var item = random_item_by_rarity(product.rarity)
	if not item.is_empty():
		apply_item_reward(item)
	request_close_popup(runtime_id, {"reason": "store_purchase"})

func max_open_popups() -> int:
	return max(1, int(state.stats.max_open_popups))

func effective_popup_interval() -> float:
	var ramp = clamp(state.elapsed / config.popup_pressure_ramp_seconds, 0.0, 1.0)
	var base = lerp(config.popup_base_spawn_interval, config.popup_min_spawn_interval, ramp)
	var multiplier = max(0.15, 1.0 - state.stats.popup_spawn_rate_multiplier)
	multiplier *= max(0.25, 1.0 - difficulty_combat_pressure().popup_spawn_multiplier)
	multiplier *= 1.0 / max(0.2, current_wave_mode().spawn_multiplier)
	return max(config.popup_min_spawn_interval, base * multiplier)

func effective_move_speed() -> float:
	var multiplier = 1.0 + state.stats.move_speed_multiplier
	if state.emergency_boost_timer > 0.0:
		multiplier += state.stats.emergency_move_speed_multiplier
	for program in state.resident_programs:
		multiplier -= program.get("move_penalty", 0.0)
	return config.player_move_speed * max(0.25, multiplier)

func effective_pickup_range() -> float:
	var multiplier = 1.0 + state.stats.pickup_range_multiplier
	if state.cleanup_combo_timer > 0.0:
		multiplier += state.stats.cleanup_combo_pickup_range_multiplier
	return config.pickup_range * multiplier + state.stats.pickup_range_flat

func effective_damage(slot: String) -> float:
	var damage = config.player_damage
	damage *= 1.0 + global_damage_multiplier()
	var deepening = state["%s_deepening" % slot]
	damage *= 1.0 + deepening.get("damage", 0.0)
	if state.module_upgrades[slot].scaling != "":
		damage *= 1.0 + scaling_damage_bonus(slot)
	return max(1.0, damage)

func effective_attack_interval(slot: String) -> float:
	var interval = config.player_attack_interval
	if slot == "secondary":
		interval *= 1.35
	interval *= max(0.12, 1.0 + state.stats.attack_interval_multiplier + dynamic_cooldown_bonus(slot))
	var deepening = state["%s_deepening" % slot]
	interval *= max(0.12, 1.0 + deepening.get("cooldown", 0.0))
	return max(0.08, interval)

func effective_attack_range(slot: String) -> float:
	var range = config.player_attack_range
	range *= 1.0 + state.stats.attack_range_multiplier + dynamic_range_bonus(slot)
	var deepening = state["%s_deepening" % slot]
	range *= 1.0 + deepening.get("range", 0.0)
	return max(32.0, range)

func global_damage_multiplier() -> float:
	var multiplier = state.stats.damage_multiplier
	multiplier += count_open_sponsored_popups() * (0.15 + state.stats.ad_buff_multiplier)
	multiplier += min(1.2, floor(state.gold / 50.0) * state.stats.gold_bullet_damage_multiplier)
	multiplier += min(1.6, state.sponsored_attack_boost_stacks * state.stats.sponsored_stack_damage_multiplier)
	multiplier += state.heat * state.stats.heat_damage_multiplier
	if state.open_popups.size() <= 2:
		multiplier += state.stats.clean_desk_damage_multiplier
	if state.open_popups.size() >= 5:
		multiplier += state.stats.overload_cache_damage_multiplier
	if state.cleanup_combo_timer > 0.0:
		multiplier += min(0.2, state.cleanup_combo_stacks * state.stats.cleanup_combo_damage_multiplier)
	if state.stats.wound_engine > 0 and hp_ratio() <= 0.3:
		multiplier += 0.15 * state.stats.wound_engine
	for effect in state.timed_effects:
		if effect.stat == "damage_multiplier":
			multiplier += effect.value
	return multiplier

func dynamic_cooldown_bonus(slot: String) -> float:
	var bonus = 0.0
	bonus += min(0.0, min(5, state.open_popups.size()) * state.stats.clutter_attack_interval_per_popup)
	if state.open_popups.is_empty():
		bonus += state.stats.quiet_trigger_haste
	if state.cleanup_combo_timer > 0.0:
		bonus += state.stats.close_combo_haste
	if count_open_sponsored_popups() > 0:
		bonus += state.stats.sponsored_open_haste
	if state.stats.wound_engine > 0 and hp_ratio() <= 0.3:
		bonus -= 0.1 * state.stats.wound_engine
	var scaling = state.module_upgrades[slot].scaling
	if scaling == "investor_credit_precision":
		bonus += -0.15 if state.credit_score >= 80 else (-0.08 if state.credit_score >= 60 else 0.0)
	elif scaling == "clutter_adaptation":
		bonus += -min(0.24, state.open_popups.size() * 0.04)
	elif scaling == "generic_stable_output":
		bonus -= 0.08
	return bonus

func dynamic_range_bonus(slot: String) -> float:
	var bonus = 0.0
	bonus += min(0.18, state.open_popups.size() * state.stats.popup_count_range_multiplier)
	if state.open_popups.size() <= 1:
		bonus += state.stats.focus_lens_range_multiplier
	if state.stats.credit_range_bonus > 0:
		bonus += 0.18 if state.credit_score >= 80 else (0.1 if state.credit_score >= 60 else 0.0)
	var scaling = state.module_upgrades[slot].scaling
	if scaling == "investor_reserve_range" or scaling == "gold_reserve_range":
		bonus += min(0.25, floor(state.gold / 100.0) * 0.05)
	elif scaling == "clutter_resonance":
		bonus += state.open_popups.size() * 0.12
	elif scaling == "clean_precision":
		bonus += 0.25 if state.open_popups.is_empty() else (0.15 if state.open_popups.size() == 1 else 0.0)
	elif scaling == "generic_stable_output":
		bonus += 0.12
	return bonus

func scaling_damage_bonus(slot: String) -> float:
	var scaling = state.module_upgrades[slot].scaling
	match scaling:
		"investor_capital_amplifier":
			return min(1.6, floor(state.invested_gold / 50.0) * 0.08)
		"sponsored_overcharge":
			return min(1.6, state.sponsored_completions * 0.08)
		"clutter_resonance":
			return state.open_popups.size() * 0.08
		"clean_precision":
			return 0.8 if state.open_popups.is_empty() else (0.45 if state.open_popups.size() == 1 else 0.0)
		"curse_heat_overload":
			return state.heat * 0.1
		"generic_stable_output":
			return 0.25
	return 0.0

func apply_crit_to_damage(damage: float) -> float:
	var chance = clamp(state.stats.crit_chance, 0.0, 0.95)
	var crit = rng.randf() < chance
	if not crit:
		return damage
	var multiplier = 1.0 + state.stats.crit_damage_multiplier + state.heat * state.stats.crit_damage_per_difficulty
	return damage * multiplier

func current_difficulty_score() -> float:
	return state.heat + state.elapsed / 55.0 + max(0.0, state.open_popups.size() - 2) * 0.18

func difficulty_stage_info() -> Dictionary:
	var score = current_difficulty_score()
	var current = difficulty_stages[0]
	var next = null
	for stage in difficulty_stages:
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
		"normal": {"enemy_hp_multiplier": 1.0, "enemy_speed_multiplier": 0.0, "enemy_spawn_multiplier": 0.0, "popup_spawn_multiplier": 0.0},
		"warning": {"enemy_hp_multiplier": 1.2, "enemy_speed_multiplier": 0.05, "enemy_spawn_multiplier": 0.08, "popup_spawn_multiplier": 0.08},
		"danger": {"enemy_hp_multiplier": 1.45, "enemy_speed_multiplier": 0.1, "enemy_spawn_multiplier": 0.12, "popup_spawn_multiplier": 0.12},
		"overload": {"enemy_hp_multiplier": 1.8, "enemy_speed_multiplier": 0.14, "enemy_spawn_multiplier": 0.18, "popup_spawn_multiplier": 0.18},
		"collapse": {"enemy_hp_multiplier": 2.25, "enemy_speed_multiplier": 0.18, "enemy_spawn_multiplier": 0.25, "popup_spawn_multiplier": 0.25},
		"nightmare": {"enemy_hp_multiplier": 2.8, "enemy_speed_multiplier": 0.24, "enemy_spawn_multiplier": 0.32, "popup_spawn_multiplier": 0.32},
	}
	return map.get(stage, map.normal)

func enemy_spawn_rate_scale() -> float:
	return 1.0 + state.elapsed / 240.0 + difficulty_combat_pressure().enemy_spawn_multiplier

func get_nearest_enemy(range: float):
	return get_nearest_enemy_from(state.player.position, range)

func get_nearest_enemy_from(position: Vector2, range: float):
	var best = null
	var best_distance = range
	for enemy in state.enemies:
		var d = enemy.position.distance_to(position)
		if d <= best_distance:
			best = enemy
			best_distance = d
	return best

func count_open_sponsored_popups() -> int:
	var count = 0
	for popup in state.open_popups:
		if popup.def.type == "sponsored_ad":
			count += 1
	return count

func current_wave_mode() -> Dictionary:
	return wave_mode_by_id(state.wave_director.mode)

func wave_mode_by_id(id: String) -> Dictionary:
	for mode in wave_modes:
		if mode.id == id:
			return mode
	return wave_modes[0]

func popup_def_by_id(id: String) -> Dictionary:
	for def in popups:
		if def.id == id:
			return def
	return {}

func popup_by_runtime_id(runtime_id: int):
	for popup in state.open_popups:
		if popup.runtime_id == runtime_id:
			return popup
	return null

func module_by_id(id: String) -> Dictionary:
	for module in attack_modules:
		if module.id == id:
			return module
	return {}

func form_by_id(id: String) -> Dictionary:
	for form in attack_forms:
		if form.id == id:
			return form
	return {}

func security_program_by_type(type: String) -> Dictionary:
	for program in security_programs:
		if program.type == type:
			return program
	return {}

func selected_form_for_slot(slot: String) -> String:
	var form_id = state.module_upgrades[slot].form
	if form_id != "":
		return form_id
	var module = module_by_id(state["%s_module" % slot])
	return module.get("base_form", "")

func selected_mechanic_for_slot(slot: String) -> String:
	return state.module_upgrades[slot].mechanic

func slot_label(slot: String) -> String:
	return "1차" if slot == "primary" else "보조"

func module_summary(slot: String) -> String:
	var module_id = state["%s_module" % slot]
	if module_id == "":
		return "미선택" if slot == "primary" else "없음"
	var module = module_by_id(module_id)
	var form = form_by_id(selected_form_for_slot(slot))
	var mechanic = selected_mechanic_for_slot(slot)
	var suffix = form.get("name", "기본형")
	if mechanic != "":
		suffix += " / " + attack_mechanics.filter(func(m): return m.id == mechanic)[0].name
	return "%s (%s)" % [module.get("name", module_id), suffix]

func resident_program_summary() -> String:
	if state.resident_programs.is_empty():
		return "보안 프로그램: 설치 없음"
	var names = []
	for program in state.resident_programs:
		names.append(program.name)
	return "보안 프로그램: %s" % ", ".join(names)

func inventory_summary() -> String:
	if state.item_counts.is_empty():
		return "보유 아이템 없음"
	var lines = []
	for id in state.item_counts.keys():
		var item = items.filter(func(candidate): return candidate.id == id)
		var name = id if item.is_empty() else item[0].name
		lines.append("%s x%d" % [name, state.item_counts[id]])
	return "\n".join(lines)

func run_stats_text() -> String:
	return "WASD 이동, Space 긴급 닫기, P 일시정지, R 재시작.\n시간 %s / 처치 %d / 계약 %s / 긴급 %.1fs" % [format_time(state.elapsed), state.kill_count, state.active_playstyle_name, state.emergency_timer]

func debug_stats_text() -> String:
	return "적 %d / 투사체 %d / 픽업 %d / 팝업 %.1fs / FPS %.0f\n난이도 %.1f / 웨이브 %s / 주식 %.1fG %s" % [
		state.enemies.size(),
		state.projectiles.size(),
		state.pickups.size(),
		state.popup_timer,
		Engine.get_frames_per_second(),
		current_difficulty_score(),
		current_wave_mode().label,
		state.stock_market.stock.price,
		state.stock_market.last_bias_label,
	]

func open_inventory_overview() -> void:
	hud.show_inventory_panel("보유 아이템", inventory_summary() + "\n\n" + resident_program_summary())

func resume_after_overlay() -> void:
	state.selecting = false
	if not state.game_over:
		state.paused = false

func popup_size_for(def: Dictionary) -> Vector2:
	match def.type:
		"terms":
			return Vector2(330, 230)
		"stock_broker_app":
			return Vector2(360, 260)
		"popup_store", "boss_package_ad", "first_purchase_package":
			return Vector2(340, 300)
		"security_installer":
			return Vector2(310, 210)
		_:
			return Vector2(300, 190)

func choose_popup_position(def: Dictionary) -> Vector2:
	var viewport = get_viewport().get_visible_rect().size
	var size = popup_size_for(def)
	for i in range(24):
		var pos = Vector2(rng.randf_range(340.0, max(340.0, viewport.x - size.x - 20.0)), rng.randf_range(28.0, max(28.0, viewport.y - size.y - 28.0)))
		var center_rect = Rect2(viewport * 0.5 - Vector2(190, 130) * (1.0 + state.stats.safe_zone_multiplier), Vector2(380, 260) * (1.0 + state.stats.safe_zone_multiplier))
		if not center_rect.has_point(pos + size * 0.5):
			return pos
	return Vector2(max(12.0, viewport.x - size.x - 24.0), 60.0)

func format_time(seconds: float) -> String:
	var minutes = int(seconds / 60.0)
	var rest = int(seconds) % 60
	return "%d:%02d" % [minutes, rest]
