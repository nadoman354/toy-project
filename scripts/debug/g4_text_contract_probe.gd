extends Node

const MainScene = preload("res://scenes/main/Main.tscn")

var game
var failures: Array = []

func _ready() -> void:
	game = MainScene.instantiate()
	add_child(game)
	while game.state.is_empty():
		await get_tree().process_frame
	await get_tree().process_frame
	for viewport_size in [Vector2i(960, 540), Vector2i(1152, 648), Vector2i(390, 844)]:
		await _verify_text_contracts(viewport_size)
	if failures.is_empty():
		print("g4_text_contract_probe passed")
		get_tree().quit()
		return
	for failure in failures:
		push_error(str(failure))
	get_tree().quit(1)

func _verify_text_contracts(viewport_size: Vector2i) -> void:
	get_window().size = viewport_size
	await get_tree().process_frame
	await get_tree().process_frame
	game.hud.update_from_state(game.state)
	_verify_hud_text_contracts(str(viewport_size))
	_verify_choice_text_contracts(str(viewport_size))
	_verify_popup_text_contracts(str(viewport_size))

func _verify_hud_text_contracts(label: String) -> void:
	for key in ["difficultyStage", "difficultyScore", "difficultyEffect", "cleanupCount", "cleanupMeta", "hpText", "levelText", "xpText", "goldText", "itemCostText", "statusTitle", "debugTitle", "popupCountText", "nextChoiceText"]:
		_expect_single_line("%s hud %s" % [label, key], game.hud.ui.get(key, null))
	for key in ["lastItem", "itemInventory", "recentPerk", "runStats", "debugStats"]:
		_expect_rich_body("%s hud body %s" % [label, key], game.hud.ui.get(key, null))

func _verify_choice_text_contracts(label: String) -> void:
	var long_item = game.data.ITEMS[0].duplicate(true)
	long_item.name = "매우 긴 선택지 제목 검증 텍스트"
	long_item.description = "긴 설명 검증: 카드 본문은 안정된 카드 폭 안에서 단어 기준으로 줄바꿈되어야 하며 제목처럼 한 글자씩 세로로 쪼개지면 안 됩니다."
	var long_module = game.data.ATTACK_MODULES[0].duplicate(true)
	long_module.name = "매우 긴 모듈 선택지 제목 검증 텍스트"
	long_module.description = "긴 모듈 설명 검증: 기본 공격 방식과 쿨타임, 범위 설명이 카드 안에서 줄바꿈되어야 합니다."
	game.hud.show_choices("매우 긴 선택 오버레이 제목 검증 텍스트", "긴 오버레이 설명 검증: 설명은 RichText 본문 영역에서 줄바꿈됩니다.", [long_item, long_module], func(_choice): pass, 2)
	await get_tree().process_frame
	_expect_single_line("%s choice title" % label, game.hud.ui.choiceTitle)
	_expect_rich_body("%s choice description" % label, game.hud.ui.choiceDescription)
	for card in game.hud.ui.choiceGrid.get_children():
		_expect_single_line("%s choice card title" % label, _find_node_named(card, "choiceTitleText"))
		_expect_body_label("%s choice card description" % label, _find_node_named(card, "choiceDescriptionText"))
		var meta = _find_node_named(card, "choiceMetaText")
		if meta != null:
			_expect_body_label("%s choice card meta" % label, meta)
		for tag in _nodes_named(card, ["itemTag", "itemTagBuild", "rarityBadge", "selectedBadge"]):
			_expect_single_line("%s choice tag" % label, tag)
	game.hud.hide_choices()

func _verify_popup_text_contracts(label: String) -> void:
	game.state.openPopups.clear()
	var popup = game.create_popup(game.popup_def_by_id("terms_ad_tracking"))
	popup.inputGrace = 0.0
	game.popup_layer.sync(game.state)
	await get_tree().process_frame
	game.popup_layer.sync(game.state)
	var record = game.popup_layer.windows.get(int(popup.id), null)
	if record == null:
		failures.append("%s popup record missing" % label)
	else:
		_expect_single_line("%s popup title" % label, record.title)
		_expect_rich_body("%s popup body" % label, record.body)
		_expect_rich_body("%s popup detail" % label, record.detail)
		for button in _buttons_under(record.controls):
			_expect_wrapping_button("%s popup button" % label, button)
	game.remove_popup_without_reward(popup.id)
	var grace_popup = game.create_popup(game.popup_def_by_id("timed_reward"))
	game.popup_layer.sync(game.state)
	await get_tree().process_frame
	game.popup_layer.sync(game.state)
	var grace_record = game.popup_layer.windows.get(int(grace_popup.id), null)
	if grace_record != null:
		for child in grace_record.statusBadges.get_children():
			_expect_single_line("%s popup status badge" % label, child)
	game.remove_popup_without_reward(grace_popup.id)
	game.popup_layer.sync(game.state)

func _expect_single_line(label: String, node) -> void:
	if not node is Label:
		failures.append("%s missing Label" % label)
		return
	if node.autowrap_mode != TextServer.AUTOWRAP_OFF:
		failures.append("%s should not autowrap" % label)
	if not node.clip_text:
		failures.append("%s should clip text" % label)
	if node.text_overrun_behavior != TextServer.OVERRUN_TRIM_ELLIPSIS:
		failures.append("%s should ellipsize overflow" % label)

func _expect_body_label(label: String, node) -> void:
	if not node is Label:
		failures.append("%s missing Label" % label)
		return
	if node.autowrap_mode != TextServer.AUTOWRAP_WORD_SMART:
		failures.append("%s should wrap by words" % label)
	if node.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING:
		failures.append("%s should not ellipsize body text" % label)

func _expect_rich_body(label: String, node) -> void:
	if not node is RichTextLabel:
		failures.append("%s missing RichTextLabel" % label)
		return
	if node.autowrap_mode != TextServer.AUTOWRAP_WORD_SMART:
		failures.append("%s should wrap by words" % label)
	if not node.clip_contents:
		failures.append("%s should clip to stable body rect" % label)

func _expect_wrapping_button(label: String, node) -> void:
	if not node is Button:
		failures.append("%s missing Button" % label)
		return
	if node.autowrap_mode != TextServer.AUTOWRAP_WORD_SMART:
		failures.append("%s should allow multi-line button text" % label)
	if not node.clip_contents:
		failures.append("%s should clip button contents" % label)

func _find_node_named(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var found = _find_node_named(child, node_name)
		if found != null:
			return found
	return null

func _nodes_named(node: Node, names: Array) -> Array:
	var result = []
	if names.has(str(node.name)):
		result.append(node)
	for child in node.get_children():
		result.append_array(_nodes_named(child, names))
	return result

func _buttons_under(node: Node) -> Array:
	var result = []
	if node is Button:
		result.append(node)
	for child in node.get_children():
		result.append_array(_buttons_under(child))
	return result
