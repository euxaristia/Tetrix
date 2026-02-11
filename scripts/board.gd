class_name TetrixBoard
extends RefCounted

const TetrixTetromino = preload("res://scripts/tetromino.gd")

const BOARD_WIDTH: int = 10
const BOARD_HEIGHT: int = 20

const FLASH_DURATION: float = 0.35
const FADE_DURATION: float = 0.25
const TOTAL_ANIMATION_DURATION: float = FLASH_DURATION + FADE_DURATION

var cells: Array = []
var clearing_lines: Array[bool] = []
var clearing_animation_time: float = 0.0
var is_clearing: bool = false

func _init() -> void:
	reset()

func reset() -> void:
	cells.clear()
	for y in BOARD_HEIGHT:
		var row: Array = []
		for x in BOARD_WIDTH:
			row.append({"filled": false, "color": Color.BLACK})
		cells.append(row)
	clearing_lines = []
	for y in BOARD_HEIGHT:
		clearing_lines.append(false)
	clearing_animation_time = 0.0
	is_clearing = false

func can_place(piece: TetrixTetromino) -> bool:
	for block in piece.get_blocks():
		if block.x < 0 or block.x >= BOARD_WIDTH:
			return false
		if block.y >= BOARD_HEIGHT:
			return false
		if block.y < 0:
			continue
		if cells[block.y][block.x]["filled"]:
			return false
	return true

func place_piece(piece: TetrixTetromino) -> void:
	var color := piece.get_color()
	for block in piece.get_blocks():
		if block.y >= 0 and block.y < BOARD_HEIGHT and block.x >= 0 and block.x < BOARD_WIDTH:
			cells[block.y][block.x] = {"filled": true, "color": color}

func check_lines() -> int:
	var lines_to_clear := 0
	for y in BOARD_HEIGHT:
		clearing_lines[y] = false
		var full := true
		for x in BOARD_WIDTH:
			if not cells[y][x]["filled"]:
				full = false
				break
		if full:
			clearing_lines[y] = true
			lines_to_clear += 1
	if lines_to_clear > 0:
		is_clearing = true
		clearing_animation_time = 0.0
	return lines_to_clear

func update_animation(delta_time: float) -> bool:
	if not is_clearing:
		return false
	clearing_animation_time += delta_time
	if clearing_animation_time >= TOTAL_ANIMATION_DURATION:
		_clear_lines()
		is_clearing = false
		clearing_animation_time = 0.0
		return true
	return false

func _clear_lines() -> void:
	var write_row := BOARD_HEIGHT - 1
	for read_row in range(BOARD_HEIGHT - 1, -1, -1):
		if not clearing_lines[read_row]:
			if write_row != read_row:
				cells[write_row] = cells[read_row].duplicate(true)
			write_row -= 1
	while write_row >= 0:
		var empty_row: Array = []
		for x in BOARD_WIDTH:
			empty_row.append({"filled": false, "color": Color.BLACK})
		cells[write_row] = empty_row
		write_row -= 1
	for y in BOARD_HEIGHT:
		clearing_lines[y] = false

func get_animation_progress() -> Dictionary:
	if clearing_animation_time < FLASH_DURATION:
		return {"phase": "flash", "progress": clearing_animation_time / FLASH_DURATION}
	return {
		"phase": "fade",
		"progress": (clearing_animation_time - FLASH_DURATION) / FADE_DURATION,
	}

func get_ghost_position(piece: TetrixTetromino) -> TetrixTetromino:
	var ghost := piece
	while can_place(ghost.moved(0, 1)):
		ghost = ghost.moved(0, 1)
	return ghost

func is_clearing_line(y: int) -> bool:
	return clearing_lines[y]
