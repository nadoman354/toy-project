extends RefCounted
class_name RunCoordinator

var game = null

func _init(game_root = null) -> void:
	game = game_root

func tick(delta: float) -> void:
	if game == null or game.state.is_empty():
		return
	game.input_controller.update_shortcuts(game.state)
	var dt = min(delta * float(game.state.timeScale), 0.05)
	if not game.state.gameOver and not game.state.paused:
		game.update_game(dt)
	game.update_visual_timers(dt)
	game.popup_layer.sync(game.state)
	game.hud.update_from_state(game.state)
	game.world.queue_redraw()

