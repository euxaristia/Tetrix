class_name TetrixEngine
extends RefCounted

const TetrixBoard = preload("res://scripts/board.gd")
const TetrixTetromino = preload("res://scripts/tetromino.gd")

enum GameState {
	PLAYING,
	PAUSED,
	GAME_OVER,
}

const SPAWN_X: int = 4
const SPAWN_Y: int = 0
const BASE_DROP_INTERVAL: float = 1.0
const MIN_DROP_INTERVAL: float = 0.1
const LOCK_DELAY: float = 0.5

var game_board: TetrixBoard
var current_piece: TetrixTetromino
var next_piece: int = TetrixTetromino.PieceType.I
var next_next_piece: int = TetrixTetromino.PieceType.I
var state: int = GameState.PLAYING
var score: int = 0
var high_score: int = 0
var lines_cleared: int = 0
var level: int = 1
var drop_timer: float = 0.0
var drop_interval: float = BASE_DROP_INTERVAL
var pending_lines: int = 0
var lock_delay_timer: float = 0.0
var is_touching_ground: bool = false

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init(seed: int) -> void:
	_rng.seed = seed
	game_board = TetrixBoard.new()
	next_piece = _random_piece()
	next_next_piece = _random_piece()
	spawn_new_piece()

func _random_piece() -> int:
	return _rng.randi_range(0, 6)

func reset() -> void:
	game_board.reset()
	current_piece = null
	next_piece = _random_piece()
	next_next_piece = _random_piece()
	state = GameState.PLAYING
	score = 0
	lines_cleared = 0
	level = 1
	drop_timer = 0.0
	drop_interval = BASE_DROP_INTERVAL
	pending_lines = 0
	lock_delay_timer = 0.0
	is_touching_ground = false
	spawn_new_piece()

func update(delta_time: float) -> void:
	if state != GameState.PLAYING:
		return

	if game_board.is_clearing:
		if game_board.update_animation(delta_time):
			_apply_line_score(pending_lines)
			pending_lines = 0
			spawn_new_piece()
		return

	var can_move_down := false
	if current_piece != null:
		can_move_down = game_board.can_place(current_piece.moved(0, 1))

	if not can_move_down:
		if not is_touching_ground:
			is_touching_ground = true
			lock_delay_timer = 0.0
		else:
			lock_delay_timer += delta_time
			if lock_delay_timer >= LOCK_DELAY:
				_lock_piece()
				return
	else:
		if is_touching_ground:
			is_touching_ground = false
			lock_delay_timer = 0.0

	drop_timer += delta_time
	if drop_timer >= drop_interval:
		drop_timer = 0.0
		if not move_down() and not is_touching_ground:
			_lock_piece()

func spawn_new_piece() -> void:
	var piece := TetrixTetromino.new(next_piece, SPAWN_X, SPAWN_Y)
	if not game_board.can_place(piece):
		state = GameState.GAME_OVER
		current_piece = null
		return
	current_piece = piece
	next_piece = next_next_piece
	next_next_piece = _random_piece()
	is_touching_ground = false
	lock_delay_timer = 0.0

func _lock_piece() -> void:
	if current_piece == null:
		return
	game_board.place_piece(current_piece)
	current_piece = null
	var lines := game_board.check_lines()
	if lines > 0:
		pending_lines = lines
	else:
		spawn_new_piece()

func _apply_line_score(lines: int) -> void:
	lines_cleared += lines
	var points := 0
	match lines:
		1: points = 100 * level
		2: points = 300 * level
		3: points = 500 * level
		4: points = 800 * level
	score += points
	if score > high_score:
		high_score = score
	level = int(lines_cleared / 10) + 1
	_update_drop_interval()

func _update_drop_interval() -> void:
	var level_factor := mini(level, 10)
	var factor := float(level_factor) * 0.09
	drop_interval = maxf(MIN_DROP_INTERVAL, BASE_DROP_INTERVAL - factor)

func move_left() -> bool:
	if state != GameState.PLAYING or game_board.is_clearing:
		return false
	if is_touching_ground and lock_delay_timer >= LOCK_DELAY:
		return false
	if current_piece == null:
		return false
	var next: Variant = current_piece.moved(-1, 0)
	if game_board.can_place(next):
		current_piece = next
		return true
	return false

func move_right() -> bool:
	if state != GameState.PLAYING or game_board.is_clearing:
		return false
	if is_touching_ground and lock_delay_timer >= LOCK_DELAY:
		return false
	if current_piece == null:
		return false
	var next: Variant = current_piece.moved(1, 0)
	if game_board.can_place(next):
		current_piece = next
		return true
	return false

func move_down() -> bool:
	if state != GameState.PLAYING or game_board.is_clearing:
		return false
	if current_piece == null:
		return false
	var next: Variant = current_piece.moved(0, 1)
	if game_board.can_place(next):
		current_piece = next
		return true
	return false

func rotate_piece() -> bool:
	if state != GameState.PLAYING or game_board.is_clearing:
		return false
	if is_touching_ground and lock_delay_timer >= LOCK_DELAY:
		return false
	if current_piece == null:
		return false

	var rotated: Variant = current_piece.rotated()
	if game_board.can_place(rotated):
		current_piece = rotated
		return true

	for offset in [-1, 1, -2, 2]:
		var kicked: Variant = rotated.moved(offset, 0)
		if game_board.can_place(kicked):
			current_piece = kicked
			return true
	return false

func hard_drop() -> int:
	if state != GameState.PLAYING or game_board.is_clearing or current_piece == null:
		return 0
	var cells_dropped := 0
	var dropped: Variant = current_piece
	while game_board.can_place(dropped.moved(0, 1)):
		dropped = dropped.moved(0, 1)
		cells_dropped += 1
	current_piece = dropped
	score += cells_dropped * 2
	if score > high_score:
		high_score = score
	_lock_piece()
	drop_timer = 0.0
	return cells_dropped

func soft_drop() -> bool:
	if move_down():
		drop_timer = 0.0
		return true
	return false

func pause_game() -> void:
	if state == GameState.PLAYING:
		state = GameState.PAUSED

func resume_game() -> void:
	if state == GameState.PAUSED:
		state = GameState.PLAYING

func toggle_pause() -> void:
	if state == GameState.PLAYING:
		pause_game()
	elif state == GameState.PAUSED:
		resume_game()

func get_ghost_piece() -> TetrixTetromino:
	if current_piece == null:
		return null
	return game_board.get_ghost_position(current_piece)

func set_high_score(value: int) -> void:
	high_score = value
