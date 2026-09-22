class_name EndConditions
extends RefCounted

## Rule 8 - Winning and draw conditions.
##
## The game ends the moment a Lion is taken: the player who captured it wins and
## nothing more may be moved. Three positions end it in a draw instead - both
## sides reduced to their Lion alone, the same position arising for the third
## time, or thirty consecutive moves passing without a capture.
##
## Everything here is a pure function of the position, so the order the checks
## run in is the order of the rule: a win is decided before any draw is looked
## for, which matters when the capture of a Lion also leaves two lone Lions.

enum Kind { NONE, WIN, DRAW }

## Rule 8 - thirty consecutive valid moves with no capture is a draw. The count
## is of moves, not of rounds, so the two players contribute to the same clock.
const MOVES_WITHOUT_CAPTURE_LIMIT := 30

## Rule 8 - the third occurrence of a position is a draw, so the position that
## has just arisen ends the game when its running count reaches three.
const REPETITION_LIMIT := 3


## The position as one comparable string: every occupied cell in board order
## with the piece standing on it, then the side to move.
##
## Two layouts are only the same position if the same player is to move and the
## same continuations are open, so the side to move is part of the key, and so
## is a Snake's pending zig-zag direction - Rule 6 makes a Snake that owes a step
## to the left a different piece to play than one that owes a step to the right.
static func position_key(occupancy: Dictionary, player_to_move: int) -> String:
	var parts := PackedStringArray()
	for row_index in BoardData.SIZE:
		for column_index in BoardData.SIZE:
			var piece: PieceView = occupancy.get(Vector2i(column_index, row_index))
			if piece == null:
				continue
			var part := "%d%d%d%d" % [column_index, row_index, piece.player, piece.kind]
			if piece.kind == BoardData.PieceKind.SNAKE:
				part += "z%d" % signi(piece.last_step.x)
			parts.append(part)
	parts.append("m%d" % player_to_move)
	return "|".join(parts)


## Rule 8 - true when neither player has anything left but their Lion. Testing
## that every surviving piece is a Lion is enough: a game in which a Lion has
## been captured has already ended, so both Lions are still on the board here.
static func only_lions_remain(occupancy: Dictionary) -> bool:
	for piece: PieceView in occupancy.values():
		if piece.kind != BoardData.PieceKind.LION:
			return false
	return true


## The state of the game directly after a move, as
## {"kind": Kind, "text": String, "winner": int}, where "text" is the result to
## show the players and "winner" is only present on a win. Kind.NONE means the
## game carries on and the other two fields are absent.
##
## `captured` is the piece the move removed, or null; `mover` is the player who
## made it; `repetitions` is how many times the position now on the board has
## occurred, this occurrence included; `moves_since_capture` is the number of
## moves made since the last capture, this move included.
static func evaluate(
	occupancy: Dictionary,
	captured: PieceView,
	mover: int,
	repetitions: int,
	moves_since_capture: int
) -> Dictionary:
	if captured != null and captured.kind == BoardData.PieceKind.LION:
		return {
			"kind": Kind.WIN,
			"winner": mover,
			"text": "%s wins — %s's Lion was captured." % [
				BoardData.player_name(mover), BoardData.player_name(captured.player)
			],
		}
	if only_lions_remain(occupancy):
		return {
			"kind": Kind.DRAW,
			"text": "Draw — each player is down to their Lion alone.",
		}
	if repetitions >= REPETITION_LIMIT:
		return {
			"kind": Kind.DRAW,
			"text": "Draw — this position has occurred three times.",
		}
	if moves_since_capture >= MOVES_WITHOUT_CAPTURE_LIMIT:
		return {
			"kind": Kind.DRAW,
			"text": "Draw — %d moves have passed without a capture." % MOVES_WITHOUT_CAPTURE_LIMIT,
		}
	return {"kind": Kind.NONE}
