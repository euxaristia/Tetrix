class_name TetrixRenderer
extends RefCounted

const TetrixBoard = preload("res://scripts/board.gd")
const TetrixEngine = preload("res://scripts/engine.gd")
const TetrixTetromino = preload("res://scripts/tetromino.gd")

const CELL_SIZE: int = 30
const BOARD_PIXEL_WIDTH: int = TetrixBoard.BOARD_WIDTH * CELL_SIZE
const BOARD_PIXEL_HEIGHT: int = TetrixBoard.BOARD_HEIGHT * CELL_SIZE
const SIDE_PANEL_WIDTH: int = 200
const PADDING: int = 20
const WINDOW_WIDTH: int = BOARD_PIXEL_WIDTH + SIDE_PANEL_WIDTH + PADDING * 2
const WINDOW_HEIGHT: int = BOARD_PIXEL_HEIGHT + PADDING * 2

const BG_COLOR: Color = Color8(20, 20, 30)
const BOARD_BG_COLOR: Color = Color8(30, 30, 40)
const BOARD_BORDER_COLOR: Color = Color8(100, 100, 120)
const TEXT_COLOR: Color = Color.WHITE
const FLASH_COLOR: Color = Color8(255, 255, 200)

var fps: float = 0.0
var frame_count: int = 0
var fps_timer: float = 0.0
var music_enabled: bool = true
var use_controller: bool = false

var _font: Font = ThemeDB.fallback_font

func render(canvas: Node2D, game: TetrixEngine, delta_time: float) -> void:
	frame_count += 1
	fps_timer += delta_time
	if fps_timer >= 1.0:
		fps = float(frame_count) / fps_timer
		frame_count = 0
		fps_timer = 0.0

	canvas.draw_rect(Rect2(Vector2.ZERO, Vector2(WINDOW_WIDTH, WINDOW_HEIGHT)), BG_COLOR, true)
	_draw_board_background(canvas)
	_draw_board(canvas, game.game_board)

	var ghost := game.get_ghost_piece()
	if ghost != null:
		_draw_ghost_piece(canvas, ghost)

	if game.current_piece != null:
		_draw_piece(canvas, game.current_piece)

	_draw_ui(canvas, game)

	if game.state == TetrixEngine.GameState.PAUSED:
		_draw_pause_overlay(canvas)
	elif game.state == TetrixEngine.GameState.GAME_OVER:
		_draw_game_over_overlay(canvas)

func _draw_board_background(canvas: Node2D) -> void:
	canvas.draw_rect(Rect2(PADDING - 4, PADDING - 4, BOARD_PIXEL_WIDTH + 8, BOARD_PIXEL_HEIGHT + 8), BOARD_BORDER_COLOR, true)
	canvas.draw_rect(Rect2(PADDING, PADDING, BOARD_PIXEL_WIDTH, BOARD_PIXEL_HEIGHT), BOARD_BG_COLOR, true)

func _draw_board(canvas: Node2D, game_board: TetrixBoard) -> void:
	for y in TetrixBoard.BOARD_HEIGHT:
		for x in TetrixBoard.BOARD_WIDTH:
			var cell: Dictionary = game_board.cells[y][x]
			if cell["filled"]:
				var px := PADDING + x * CELL_SIZE
				var py := PADDING + y * CELL_SIZE
				if game_board.is_clearing_line(y):
					_draw_clearing_block(canvas, px, py, cell["color"], game_board)
				else:
					_draw_block(canvas, px, py, cell["color"])

func _draw_block(canvas: Node2D, x: int, y: int, color: Color) -> void:
	canvas.draw_rect(Rect2(x + 1, y + 1, CELL_SIZE - 2, CELL_SIZE - 2), color, true)
	canvas.draw_rect(Rect2(x + 1, y + 1, CELL_SIZE - 2, CELL_SIZE - 2), Color(1, 1, 1, 0.4), false, 1.0)

func _draw_clearing_block(canvas: Node2D, x: int, y: int, color: Color, game_board: TetrixBoard) -> void:
	var anim := game_board.get_animation_progress()
	if anim["phase"] == "flash":
		_draw_block(canvas, x, y, color)
		var flash_intensity := sin(anim["progress"] * PI * 4.0) * 0.5 + 0.5
		var alpha := flash_intensity * 0.78
		canvas.draw_rect(Rect2(x - 2, y - 2, CELL_SIZE + 4, CELL_SIZE + 4), Color(FLASH_COLOR.r, FLASH_COLOR.g, FLASH_COLOR.b, alpha), true)
		canvas.draw_rect(Rect2(x - 4, y - 4, CELL_SIZE + 8, CELL_SIZE + 8), Color(FLASH_COLOR.r, FLASH_COLOR.g, FLASH_COLOR.b, alpha * 0.5), true)
	else:
		var fade_alpha: float = 1.0 - float(anim["progress"])
		canvas.draw_rect(Rect2(x + 1, y + 1, CELL_SIZE - 2, CELL_SIZE - 2), Color(color.r, color.g, color.b, fade_alpha), true)

func _draw_ghost_piece(canvas: Node2D, ghost: TetrixTetromino) -> void:
	for block in ghost.get_blocks():
		if block.y >= 0:
			var px := PADDING + block.x * CELL_SIZE
			var py := PADDING + block.y * CELL_SIZE
			canvas.draw_rect(Rect2(px + 1, py + 1, CELL_SIZE - 2, CELL_SIZE - 2), Color(1, 1, 1, 0.35), false, 1.0)

func _draw_piece(canvas: Node2D, piece: TetrixTetromino) -> void:
	for block in piece.get_blocks():
		if block.y >= 0:
			_draw_block(canvas, PADDING + block.x * CELL_SIZE, PADDING + block.y * CELL_SIZE, piece.get_color())

func _draw_ui(canvas: Node2D, game: TetrixEngine) -> void:
	var panel_x := PADDING + BOARD_PIXEL_WIDTH + 20
	var y := PADDING
	_draw_text(canvas, "Score: %d" % game.score, panel_x, y, TEXT_COLOR)
	y += 28
	_draw_text(canvas, "High: %d" % game.high_score, panel_x, y, TEXT_COLOR)
	y += 28
	_draw_text(canvas, "Lines: %d" % game.lines_cleared, panel_x, y, TEXT_COLOR)
	y += 28
	_draw_text(canvas, "Level: %d" % game.level, panel_x, y, TEXT_COLOR)
	y += 28

	var fps_color := Color8(100, 255, 100) if fps >= 170.0 else Color8(255, 200, 100)
	_draw_text(canvas, "FPS: %.1f" % fps, panel_x, y, fps_color)
	y += 22
	_draw_text(canvas, "Renderer: Compatibility", panel_x, y, Color8(160, 200, 255))
	y += 30

	_draw_text(canvas, "Next:", panel_x, y, TEXT_COLOR)
	y += 28
	_draw_preview_piece(canvas, game.next_piece, panel_x, y, 1.0)
	y += 70

	_draw_text(canvas, "After:", panel_x, y, Color8(200, 200, 200))
	y += 28
	_draw_preview_piece(canvas, game.next_next_piece, panel_x, y, 0.6)

	_draw_controls(canvas, panel_x, WINDOW_HEIGHT - 150)

func _draw_preview_piece(canvas: Node2D, piece_type: int, x: int, y: int, scale_factor: float) -> void:
	var offsets := TetrixTetromino.preview_offsets(piece_type)
	var color := TetrixTetromino.color_for_type(piece_type)
	var size := int(float(CELL_SIZE) * scale_factor)

	var min_x := offsets[0].x
	var max_x := offsets[0].x
	var min_y := offsets[0].y
	var max_y := offsets[0].y
	for offset in offsets:
		min_x = mini(min_x, offset.x)
		max_x = maxi(max_x, offset.x)
		min_y = mini(min_y, offset.y)
		max_y = maxi(max_y, offset.y)

	var width_blocks := max_x - min_x + 1
	var height_blocks := max_y - min_y + 1
	var preview_width_px := 4 * size
	var preview_height_px := 2 * size
	var piece_width_px := width_blocks * size
	var piece_height_px := height_blocks * size
	var center_x_offset := int((preview_width_px - piece_width_px) / 2)
	var center_y_offset := int((preview_height_px - piece_height_px) / 2)

	for offset in offsets:
		var px := x + center_x_offset + (offset.x - min_x) * size
		var py := y + center_y_offset + (offset.y - min_y) * size
		canvas.draw_rect(Rect2(px, py, size - 2, size - 2), color, true)

func _draw_controls(canvas: Node2D, x: int, start_y: int) -> void:
	var y := start_y
	_draw_text(canvas, "Controls:", x, y, Color8(150, 150, 150))
	y += 18
	if use_controller:
		_draw_text(canvas, "D-Pad: Move", x, y, Color8(130, 130, 130)); y += 18
		_draw_text(canvas, "D-Pad Dn: Drop", x, y, Color8(130, 130, 130)); y += 18
		_draw_text(canvas, "Up/X: Rotate", x, y, Color8(130, 130, 130)); y += 18
		_draw_text(canvas, "Start: Pause", x, y, Color8(130, 130, 130)); y += 18
		_draw_text(canvas, "Back: Restart", x, y, Color8(130, 130, 130)); y += 18
	else:
		_draw_text(canvas, "WASD/Arrows", x, y, Color8(130, 130, 130)); y += 18
		_draw_text(canvas, "Space: Drop", x, y, Color8(130, 130, 130)); y += 18
		_draw_text(canvas, "ESC: Pause", x, y, Color8(130, 130, 130)); y += 18
		_draw_text(canvas, "F11: Fullscreen", x, y, Color8(130, 130, 130)); y += 18
	_draw_text(canvas, "M: Music", x, y, Color8(130, 130, 130))
	_draw_text(canvas, "(ON)" if music_enabled else "(OFF)", x + 86, y, Color8(100, 255, 100) if music_enabled else Color8(255, 100, 100))

func _draw_pause_overlay(canvas: Node2D) -> void:
	canvas.draw_rect(Rect2(PADDING, PADDING, BOARD_PIXEL_WIDTH, BOARD_PIXEL_HEIGHT), Color(0, 0, 0, 0.6), true)
	_draw_text(canvas, "PAUSED", PADDING + BOARD_PIXEL_WIDTH / 2 - 54, PADDING + BOARD_PIXEL_HEIGHT / 2 - 12, Color.YELLOW, 24)
	_draw_text(canvas, "Press Start" if use_controller else "Press ESC", PADDING + BOARD_PIXEL_WIDTH / 2 - 52, PADDING + BOARD_PIXEL_HEIGHT / 2 + 26, Color8(200, 200, 200))

func _draw_game_over_overlay(canvas: Node2D) -> void:
	var box := Rect2(PADDING + BOARD_PIXEL_WIDTH / 2 - 100, PADDING + BOARD_PIXEL_HEIGHT / 2 - 50, 200, 88)
	canvas.draw_rect(Rect2(box.position - Vector2(4, 4), box.size + Vector2(8, 8)), Color(0, 0, 0, 0.8), true)
	canvas.draw_rect(box, Color(0.12, 0.12, 0.16, 0.95), true)
	_draw_text(canvas, "GAME OVER", int(box.position.x + 20), int(box.position.y + 18), Color8(255, 80, 80), 24)
	_draw_text(canvas, "Press Back" if use_controller else "Press R", int(box.position.x + 58), int(box.position.y + 58), Color8(200, 200, 200))

func _draw_text(canvas: Node2D, text: String, x: int, y: int, color: Color, size: int = 16) -> void:
	canvas.draw_string(_font, Vector2(x, y + size), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
