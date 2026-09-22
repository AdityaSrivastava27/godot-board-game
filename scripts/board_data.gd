class_name BoardData
extends RefCounted

## Rule 1 - Board.
## A square 6x6 board containing 36 cells.
## Columns are numbered 1 through 6, rows are labelled A through F.
## A cell is identified by its row letter followed by its column number (A1, A4, C3, F6).

const SIZE := 6

## Row index 0 is row "A" and is drawn at the bottom of the board,
## so that the letters read A (bottom) to F (top) up the left side.
const ROW_LETTERS := ["A", "B", "C", "D", "E", "F"]

## Column index 0 is column 1 and is drawn at the left of the board.
const COLUMN_NUMBERS := [1, 2, 3, 4, 5, 6]

## Rule 2 - Players. Two players, each owning exactly three pieces.
enum Player { PLAYER_1, PLAYER_2 }

## Rule 2 - Pieces. Every player has a Lion, a Rabbit and a Snake.
enum PieceKind { LION, RABBIT, SNAKE }

## Rule 3 - Initial positions.
const START_POSITIONS := [
	{"player": Player.PLAYER_1, "kind": PieceKind.RABBIT, "cell": "A3"},
	{"player": Player.PLAYER_1, "kind": PieceKind.LION, "cell": "A4"},
	{"player": Player.PLAYER_1, "kind": PieceKind.SNAKE, "cell": "A5"},
	{"player": Player.PLAYER_2, "kind": PieceKind.SNAKE, "cell": "F2"},
	{"player": Player.PLAYER_2, "kind": PieceKind.LION, "cell": "F3"},
	{"player": Player.PLAYER_2, "kind": PieceKind.RABBIT, "cell": "F4"},
]


static func player_name(player: int) -> String:
	return "Player 1" if player == Player.PLAYER_1 else "Player 2"


static func kind_name(kind: int) -> String:
	match kind:
		PieceKind.LION:
			return "Lion"
		PieceKind.RABBIT:
			return "Rabbit"
		PieceKind.SNAKE:
			return "Snake"
	return "Unknown"


## "C3" -> Vector2i(column index, row index); Vector2i(-1, -1) when the name is not a cell.
static func parse_cell(cell: String) -> Vector2i:
	if cell.length() != 2:
		return Vector2i(-1, -1)
	var row_index := ROW_LETTERS.find(cell.substr(0, 1).to_upper())
	var column_index := COLUMN_NUMBERS.find(cell.substr(1, 1).to_int())
	if row_index == -1 or column_index == -1:
		return Vector2i(-1, -1)
	return Vector2i(column_index, row_index)


## Vector2i(column index, row index) -> "C3".
static func cell_name(coordinate: Vector2i) -> String:
	if coordinate.x < 0 or coordinate.x >= SIZE or coordinate.y < 0 or coordinate.y >= SIZE:
		return ""
	return "%s%d" % [ROW_LETTERS[coordinate.y], COLUMN_NUMBERS[coordinate.x]]
