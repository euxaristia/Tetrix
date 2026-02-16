extends Node2D

const TetrixEngine = preload("res://scripts/engine.gd")
const TetrixRenderer = preload("res://scripts/game_renderer.gd")
const TetrixInputHandler = preload("res://scripts/input_handler.gd")
const TetrixAudioPlayer = preload("res://scripts/audio_player.gd")
const TetrixSettings = preload("res://scripts/settings.gd")

var game: TetrixEngine
var renderer: TetrixRenderer
var input_handler: TetrixInputHandler
var audio_player: TetrixAudioPlayer

var music_enabled: bool = true
var is_fullscreen: bool = false
var high_score_saved: int = 0

func _ready() -> void:
	var settings := TetrixSettings.load_settings()
	high_score_saved = int(settings.get("high_score", 0))
	music_enabled = bool(settings.get("music_enabled", true))
	is_fullscreen = bool(settings.get("is_fullscreen", false))

	game = TetrixEngine.new(Time.get_unix_time_from_system())
	game.set_high_score(high_score_saved)

	input_handler = TetrixInputHandler.new()
	renderer = TetrixRenderer.new()
	if not OS.has_feature("headless") and DisplayServer.get_name() != "headless":
		audio_player = TetrixAudioPlayer.new()
		audio_player.set_enabled(music_enabled)
		add_child(audio_player)
		audio_player.start()
	else:
		audio_player = null

	_apply_fullscreen(is_fullscreen)
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	var old_music_enabled := music_enabled
	music_enabled = input_handler.update(game, delta, music_enabled)
	if old_music_enabled != music_enabled:
		_save_current_settings()

	if audio_player != null and music_enabled != audio_player.is_enabled():
		audio_player.set_enabled(music_enabled)

	renderer.use_controller = input_handler.is_using_controller()
	renderer.music_enabled = audio_player.is_enabled() if audio_player != null else music_enabled

	game.update(delta)

	if audio_player != null:
		if game.state == TetrixEngine.GameState.PLAYING:
			audio_player.play_music()
		else:
			audio_player.stop_music()
		audio_player.update_audio()

	if game.score > high_score_saved:
		high_score_saved = game.score
		_save_current_settings()

	if high_score_saved > game.high_score:
		game.set_high_score(high_score_saved)

	queue_redraw()

func _draw() -> void:
	if renderer != null and game != null:
		renderer.render(self, game, get_process_delta_time())

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event: InputEventKey = event
		match key_event.keycode:
			KEY_UP, KEY_W:
				game.rotate_piece()
			KEY_SPACE:
				game.hard_drop()
			KEY_ESCAPE:
				game.toggle_pause()
			KEY_R:
				if game.state == TetrixEngine.GameState.GAME_OVER:
					game.reset()
			KEY_M:
				if audio_player != null:
					audio_player.toggle_music()
					music_enabled = audio_player.is_enabled()
				else:
					music_enabled = not music_enabled
				_save_current_settings()
			KEY_F11:
				toggle_fullscreen()

func toggle_fullscreen() -> void:
	is_fullscreen = not is_fullscreen
	_apply_fullscreen(is_fullscreen)
	_save_current_settings()

func _apply_fullscreen(value: bool) -> void:
	if OS.has_feature("web"):
		is_fullscreen = false
		return
	if value:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _save_current_settings() -> void:
	var final_high := maxi(high_score_saved, game.high_score if game != null else high_score_saved)
	TetrixSettings.save_settings(final_high, music_enabled, is_fullscreen)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		_save_current_settings()

func _exit_tree() -> void:
	if audio_player != null:
		audio_player.deinit()
