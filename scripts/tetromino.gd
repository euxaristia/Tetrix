class_name TetrixTetromino
extends RefCounted

enum PieceType {
	I,
	O,
	T,
	S,
	Z,
	J,
	L,
}

const PIECE_COLORS: Dictionary = {
	PieceType.I: Color8(0, 255, 255),
	PieceType.O: Color8(255, 255, 0),
	PieceType.T: Color8(200, 0, 255),
	PieceType.S: Color8(0, 255, 0),
	PieceType.Z: Color8(255, 0, 0),
	PieceType.J: Color8(0, 100, 255),
	PieceType.L: Color8(255, 165, 0),
}

var piece_type: int
var position: Vector2i
var rotation: int = 0

func _init(p_type: int, x: int, y: int) -> void:
	piece_type = p_type
	position = Vector2i(x, y)

func get_blocks() -> Array[Vector2i]:
	var blocks: Array[Vector2i] = []
	for offset in _get_block_offsets(piece_type, rotation):
		blocks.append(position + offset)
	return blocks

func get_color() -> Color:
	return color_for_type(piece_type)

func moved(dx: int, dy: int) -> TetrixTetromino:
	var next := get_script().new(piece_type, position.x + dx, position.y + dy) as TetrixTetromino
	next.rotation = rotation
	return next

func rotated() -> TetrixTetromino:
	var max_rotations := 1 if piece_type == PieceType.O else 4
	var next := get_script().new(piece_type, position.x, position.y) as TetrixTetromino
	next.rotation = (rotation + 1) % max_rotations
	return next

static func color_for_type(p_type: int) -> Color:
	return PIECE_COLORS.get(p_type, Color.WHITE)

static func preview_offsets(p_type: int) -> Array[Vector2i]:
	return _get_block_offsets(p_type, 0)

static func _get_block_offsets(p_type: int, rot: int) -> Array[Vector2i]:
	match p_type:
		PieceType.I:
			match rot % 4:
				0: return [Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
				1: return [Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)]
				2: return [Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]
				_: return [Vector2i(0, -1), Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)]
		PieceType.O:
			return [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
		PieceType.T:
			match rot % 4:
				0: return [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1)]
				1: return [Vector2i(0, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(1, 0)]
				2: return [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)]
				_: return [Vector2i(0, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0)]
		PieceType.S:
			if rot % 2 == 0:
				return [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1)]
			return [Vector2i(0, 0), Vector2i(0, -1), Vector2i(1, 0), Vector2i(1, 1)]
		PieceType.Z:
			if rot % 2 == 0:
				return [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(1, 1)]
			return [Vector2i(0, 0), Vector2i(1, -1), Vector2i(1, 0), Vector2i(0, 1)]
		PieceType.J:
			match rot % 4:
				0: return [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, -1)]
				1: return [Vector2i(0, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(1, -1)]
				2: return [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(1, 1)]
				_: return [Vector2i(0, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 1)]
		PieceType.L:
			match rot % 4:
				0: return [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(1, -1)]
				1: return [Vector2i(0, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(1, 1)]
				2: return [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1)]
				_: return [Vector2i(0, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, -1)]
		_:
			return [Vector2i.ZERO, Vector2i.ZERO, Vector2i.ZERO, Vector2i.ZERO]
