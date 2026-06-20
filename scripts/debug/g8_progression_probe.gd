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
	_prepare_primary()
	_verify_growth_labels()
	_verify_non_special_auto_mastery()
	_verify_level_up_stops_on_secondary_choice()
	_verify_level_up_opens_form_and_mechanic()
	if failures.is_empty():
		print("g8_progression_probe passed")
		get_tree().quit()
		return
	for failure in failures:
		push_error(str(failure))
	get_tree().quit(1)

func _prepare_primary() -> void:
	game.state.selectingModule = false
	game.state.selectingPerk = false
	game.state.selectingItem = false
	game.state.selectingPaidReward = false
	game.state.paused = false
	game.hud.hide_choices()
	game.apply_attack_module_choice("primary", game.data.ATTACK_MODULES[0])
	game.state.moduleUpgrades.primary.mechanic = ""
	game.state.moduleUpgrades.primary.scaling = ""

func _verify_growth_labels() -> void:
	_prepare_primary()
	game.state.level = 2
	game.state.secondaryModule = ""
	_expect_equal("level 2 passive", game.next_growth_choice_label(), "패시브 보상")
	game.state.level = 5
	_expect_equal("level 5 secondary", game.next_growth_choice_label(), "보조 모듈")
	game.state.secondaryModule = game.data.ATTACK_MODULES[1].id
	game.state.level = 8
	_expect_equal("level 8 passive", game.next_growth_choice_label(), "패시브 보상")
	game.state.level = 9
	_expect_equal("level 9 form", game.next_growth_choice_label(), "공격 방식")
	game.state.level = 12
	_expect_equal("level 12 passive", game.next_growth_choice_label(), "패시브 보상")
	game.state.level = 13
	_expect_equal("level 13 mechanic", game.next_growth_choice_label(), "공격 기믹")
	game.state.level = 17
	_expect_equal("level 17 scaling gated by default", game.next_growth_choice_label(), "패시브 보상")

func _verify_non_special_auto_mastery() -> void:
	_prepare_primary()
	game.state.secondaryModule = game.data.ATTACK_MODULES[1].id
	game.state.level = 6
	game.state.primaryMastery = 1
	game.state.secondaryMastery = 1
	game.open_level_choice()
	_expect_equal("non-special does not pause", game.state.paused, false)
	_expect_equal("non-special does not select", game.is_selecting(), false)
	_expect_equal("non-special overlay hidden", game.hud.ui.choiceOverlay.visible, false)
	_expect_equal("non-special primary mastery increments", game.state.primaryMastery, 2)
	_expect_equal("non-special secondary mastery increments", game.state.secondaryMastery, 2)

func _verify_level_up_stops_on_secondary_choice() -> void:
	_prepare_primary()
	game.state.secondaryModule = ""
	game.state.level = 4
	game.state.xpNeed = 10
	game.state.xp = 100
	game.check_level_up()
	_expect_equal("secondary gate reaches level 5 only", game.state.level, 5)
	_expect_equal("secondary gate opens module selection", game.state.selectingModule, true)
	_expect_equal("secondary gate overlay visible", game.hud.ui.choiceOverlay.visible, true)

func _verify_level_up_opens_form_and_mechanic() -> void:
	_prepare_primary()
	game.state.secondaryModule = game.data.ATTACK_MODULES[1].id
	game.state.level = 8
	game.state.xpNeed = 10
	game.state.xp = 10
	game.check_level_up()
	_expect_equal("form gate reaches level 9", game.state.level, 9)
	_expect_equal("form gate opens selection", game.state.selectingPerk, true)
	_expect_equal("form gate title", game.hud.ui.choiceTitle.text, "공격 방식 선택")
	game.state.selectingPerk = false
	game.hud.hide_choices()
	game.state.paused = false
	game.state.level = 12
	game.state.xpNeed = 10
	game.state.xp = 10
	game.check_level_up()
	_expect_equal("mechanic gate reaches level 13", game.state.level, 13)
	_expect_equal("mechanic gate opens selection", game.state.selectingPerk, true)
	_expect_equal("mechanic gate title", game.hud.ui.choiceTitle.text, "공격 기믹 선택")

func _expect_equal(label: String, actual, expected) -> void:
	if actual != expected:
		failures.append("%s expected %s got %s" % [label, str(expected), str(actual)])
