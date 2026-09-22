class_name MovementRules
extends RefCounted

## Rule 4 - Piece movement. Each kind has a fixed set of offsets it may move by,
## measured in (column, row) steps.
##
## Rule 5 - Blocking and capture. A cell held by a piece of the moving player's
## own side is never a legal destination. A cell held by an opponent's piece is,
## and landing on it removes that piece from the board.

## Lion: exactly one cell horizontally, vertically or diagonally.
const LION_STEPS: Array[Vector2i] = [
	Vector2i(-1, -1),
	Vector2i(0, -1),
	Vector2i(1, -1),
	Vector2i(-1, 0),
	Vector2i(1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
	Vector2i(1, 1),
]

## Rabbit: exactly two cells horizontally or vertically, never diagonally.
const RABBIT_STEPS: Array[Vector2i] = [
	Vector2i(0, -2),
	Vector2i(-2, 0),
	Vector2i(2, 0),
	Vector2i(0, 2),
]

## Snake: exactly one cell diagonally, never horizontally or vertically.
const SNAKE_STEPS: Array[Vector2i] = [
	Vector2i(-1, -1),
	Vector2i(1, -1),
	Vector2i(-1, 1),
	Vector2i(1, 1),
]


static func steps_for(kind: int) -> Array[Vector2i]:
	match kind:
		BoardData.PieceKind.LION:
			return LION_STEPS
		BoardData.PieceKind.RABBIT:
			return RABBIT_STEPS
		BoardData.PieceKind.SNAKE:
			return SNAKE_STEPS
	return []


static func is_on_board(coordinate: Vector2i) -> bool:
	return (
		coordinate.x >= 0
		and coordinate.x < BoardData.SIZE
		and coordinate.y >= 0
		and coordinate.y < BoardData.SIZE
	)


## Every cell a `player`'s piece of this `kind` may move to from `from`, in board
## order. `occupied` maps Vector2i cell -> PieceView; cells holding one of the
## player's own pieces are dropped, cells holding an opponent's piece are kept
## because moving there is a capture.
static func legal_destinations(
	kind: int, player: int, from: Vector2i, occupied: Dictionary
) -> Array[Vector2i]:
	var destinations: Array[Vector2i] = []
	for step: Vector2i in steps_for(kind):
		var target := from + step
		if not is_on_board(target):
			continue
		var blocker: PieceView = occupied.get(target)
		if blocker != null and blocker.player == player:
			continue
		destinations.append(target)
	destinations.sort_custom(_before)
	return destinations


## The subset of `destinations` that is occupied, i.e. that a move would capture.
## Only opponents' pieces can appear here: `legal_destinations` has already
## dropped every cell held by the moving player's own side.
static func captures_among(
	destinations: Array[Vector2i], occupied: Dictionary
) -> Array[Vector2i]:
	var captures: Array[Vector2i] = []
	for cell: Vector2i in destinations:
		if occupied.has(cell):
			captures.append(cell)
	return captures


## Board order: bottom row first, then left to right within a row.
static func _before(a: Vector2i, b: Vector2i) -> bool:
	if a.y != b.y:
		return a.y < b.y
	return a.x < b.x
