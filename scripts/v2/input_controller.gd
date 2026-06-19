extends RefCounted
class_name InputController

var game = null

func _init(game_root = null) -> void:
	game = game_root

func movement_vector(state: Dictionary) -> Vector2:
	var input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if state.has("mobileInput") and state.mobileInput.get("active", false):
		var mobile = Vector2(float(state.mobileInput.get("x", 0.0)), float(state.mobileInput.get("y", 0.0)))
		if mobile.length() > input.length():
			input = mobile.limit_length(1.0)
	return input

func update_shortcuts(state: Dictionary) -> void:
	if Input.is_action_just_pressed("pause") and not state.gameOver and not _is_selecting(state):
		state.paused = not state.paused
	if Input.is_action_just_pressed("restart"):
		game.reset_game()
	if Input.is_action_just_pressed("emergency_close"):
		game.emergency_close_oldest_popup()

func _is_selecting(state: Dictionary) -> bool:
	return state.selectingItem or state.selectingPerk or state.selectingModule or state.selectingPaidReward

func start_mobile_joystick(state: Dictionary, screen_position: Vector2) -> void:
	state.mobileInput.active = true
	state.mobileInput.baseX = screen_position.x
	state.mobileInput.baseY = screen_position.y
	state.mobileInput.x = 0.0
	state.mobileInput.y = 0.0

func update_mobile_joystick(state: Dictionary, screen_position: Vector2, radius: float) -> void:
	if not state.mobileInput.active:
		return
	var delta = screen_position - Vector2(state.mobileInput.baseX, state.mobileInput.baseY)
	var normalized = delta / max(radius, 1.0)
	normalized = normalized.limit_length(1.0)
	state.mobileInput.x = normalized.x
	state.mobileInput.y = normalized.y

func finish_mobile_joystick(state: Dictionary) -> void:
	state.mobileInput.active = false
	state.mobileInput.x = 0.0
	state.mobileInput.y = 0.0
