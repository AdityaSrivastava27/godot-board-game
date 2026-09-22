extends SceneTree

var _failures := 0


func _check(label: String, condition: bool) -> void:
	if condition:
		print("  ok    %s" % label)
	else:
		_failures += 1
		print("  FAIL  %s" % label)


func _piece(player: int, kind: int, last_step := Vector2i.ZERO) -> PieceView:
	var piece := PieceView.new()
	piece.setup(player, kind)
	piece.last_step = last_step
	return piece


func _initialize() -> void:
	_unit_tests()
	await process_frame
	await _repetition_playthrough()
	await _lion_capture_playthrough()
	print("\n%s" % ("ALL PASSED" if _failures == 0 else "%d FAILURE(S)" % _failures))
	quit(1 if _failures > 0 else 0)


func _unit_tests() -> void:
	print("EndConditions unit tests")
	var p1 := BoardData.Player.PLAYER_1
	var p2 := BoardData.Player.PLAYER_2
	var lion := BoardData.PieceKind.LION
	var rabbit := BoardData.PieceKind.RABBIT
	var snake := BoardData.PieceKind.SNAKE

	var lion_1 := _piece(p1, lion)
	var lion_2 := _piece(p2, lion)
	var rabbit_2 := _piece(p2, rabbit)
	var snake_1 := _piece(p1, snake, Vector2i(1, 1))
	var snake_1_other_way := _piece(p1, snake, Vector2i(-1, 1))

	var two_lions := {Vector2i(3, 0): lion_1, Vector2i(2, 5): lion_2}
	var with_rabbit := {Vector2i(3, 0): lion_1, Vector2i(2, 5): lion_2, Vector2i(3, 5): rabbit_2}

	# position_key
	_check(
		"same layout, same side to move -> same key",
		(
			EndConditions.position_key(two_lions, p1)
			== EndConditions.position_key({Vector2i(2, 5): lion_2, Vector2i(3, 0): lion_1}, p1)
		)
	)
	_check(
		"same layout, other side to move -> different key",
		EndConditions.position_key(two_lions, p1) != EndConditions.position_key(two_lions, p2)
	)
	_check(
		"same layout, Snake owing the other direction -> different key",
		(
			EndConditions.position_key({Vector2i(1, 1): snake_1}, p1)
			!= EndConditions.position_key({Vector2i(1, 1): snake_1_other_way}, p1)
		)
	)

	# only_lions_remain
	_check("two lone Lions -> only lions remain", EndConditions.only_lions_remain(two_lions))
	_check("a Rabbit is still on -> not only lions", not EndConditions.only_lions_remain(with_rabbit))

	# evaluate - win
	var win := EndConditions.evaluate(with_rabbit, lion_2, p1, 1, 1)
	_check("capturing a Lion is a win", win["kind"] == EndConditions.Kind.WIN)
	_check("the capturing player wins", win["winner"] == p1)
	_check("the win names both players", win["text"] == "Player 1 wins — Player 2's Lion was captured.")

	# evaluate - a win outranks the draws it would otherwise trigger
	var win_first := EndConditions.evaluate(
		two_lions, lion_2, p2, EndConditions.REPETITION_LIMIT, EndConditions.MOVES_WITHOUT_CAPTURE_LIMIT
	)
	_check("a Lion capture is decided before any draw", win_first["kind"] == EndConditions.Kind.WIN)

	# evaluate - draws
	_check(
		"two lone Lions is a draw",
		EndConditions.evaluate(two_lions, null, p1, 1, 1)["kind"] == EndConditions.Kind.DRAW
	)
	_check(
		"a third occurrence is a draw",
		(
			EndConditions.evaluate(with_rabbit, null, p1, EndConditions.REPETITION_LIMIT, 1)["kind"]
			== EndConditions.Kind.DRAW
		)
	)
	_check(
		"a second occurrence is not",
		EndConditions.evaluate(with_rabbit, null, p1, 2, 1)["kind"] == EndConditions.Kind.NONE
	)
	_check(
		"30 moves without a capture is a draw",
		(
			EndConditions.evaluate(
				with_rabbit, null, p1, 1, EndConditions.MOVES_WITHOUT_CAPTURE_LIMIT
			)["kind"]
			== EndConditions.Kind.DRAW
		)
	)
	_check(
		"29 moves without a capture is not",
		(
			EndConditions.evaluate(
				with_rabbit, null, p1, 1, EndConditions.MOVES_WITHOUT_CAPTURE_LIMIT - 1
			)["kind"]
			== EndConditions.Kind.NONE
		)
	)
	_check(
		"capturing anything but a Lion carries on",
		EndConditions.evaluate(with_rabbit, rabbit_2, p1, 1, 0)["kind"] == EndConditions.Kind.NONE
	)

	for piece: PieceView in [lion_1, lion_2, rabbit_2, snake_1, snake_1_other_way]:
		piece.free()


## Drives the real game: the two Lions shuffle out and back until the opening
## position has been on the board three times.
func _repetition_playthrough() -> void:
	print("\nRepetition draw, played through the real board")
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var lion_1_home := BoardData.parse_cell("A4")
	var lion_2_home := BoardData.parse_cell("F3")
	var lion_1_out := BoardData.parse_cell("B4")
	var lion_2_out := BoardData.parse_cell("E3")

	var moves := [
		[lion_1_home, lion_1_out],
		[lion_2_home, lion_2_out],
		[lion_1_out, lion_1_home],
		[lion_2_out, lion_2_home],
		[lion_1_home, lion_1_out],
		[lion_2_home, lion_2_out],
		[lion_1_out, lion_1_home],
		[lion_2_out, lion_2_home],
	]
	var move_number := 0
	for move: Array in moves:
		move_number += 1
		if main._game_over:
			_check("move %d was still allowed" % move_number, false)
			break
		var piece: PieceView = main._occupancy[move[0]]
		main._select(piece)
		main._move_selected_to(move[1])
		if move_number < moves.size():
			_check(
				"move %d (%s → %s) leaves the game running" % [
					move_number, BoardData.cell_name(move[0]), BoardData.cell_name(move[1])
				],
				not main._game_over
			)

	_check("the eighth move ends the game", main._game_over)
	_check("it is a draw by repetition", main._result.text == "Draw — this position has occurred three times.")
	_check("the turn label shows the game is over", main._turn.text == "Game over")

	# Rule 8 - the board must ignore clicks now.
	var idle_lion: PieceView = main._occupancy[lion_1_home]
	main._on_piece_picked(idle_lion)
	_check("clicking a piece after the result does nothing", main._selected == null)
	main._on_cell_clicked(lion_1_out)
	_check("clicking a cell after the result does nothing", main._occupancy.has(lion_1_home))
	_check("the result survives the clicks", main._result.text.begins_with("Draw"))

	_check("30-move clock counted every move", main._moves_since_capture == 8)

	main.free()


## Drives the real game to a Lion capture, with a Rabbit left on the board so
## that the two-lone-Lions draw cannot be what ends it.
func _lion_capture_playthrough() -> void:
	print("\nLion capture win, played through the real board")
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	# Clear everything but Player 1's Lion, Player 2's Lion and Player 2's
	# Rabbit, then stand the two Lions next to each other.
	for cell: Vector2i in main._occupancy.keys():
		var piece: PieceView = main._occupancy[cell]
		var keep := piece.kind == BoardData.PieceKind.LION or (
			piece.player == BoardData.Player.PLAYER_2
			and piece.kind == BoardData.PieceKind.RABBIT
		)
		if not keep:
			main._occupancy.erase(cell)
			piece.free()
	_move_piece(main, BoardData.parse_cell("A4"), BoardData.parse_cell("E3"))

	var lion_1: PieceView = main._occupancy[BoardData.parse_cell("E3")]
	main._select(lion_1)
	_check(
		"the enemy Lion's cell is offered as a capture",
		main._destinations.has(BoardData.parse_cell("F3"))
	)
	main._move_selected_to(BoardData.parse_cell("F3"))

	_check("taking the Lion ends the game", main._game_over)
	_check(
		"the capturing player is named the winner",
		main._result.text == "Player 1 wins — Player 2's Lion was captured."
	)
	_check("the turn label shows the game is over", main._turn.text == "Game over")
	_check(
		"the result is tinted in the winner's colour",
		main._result.get_theme_color("font_color") == PieceView.PLAYER_1_BODY
	)
	_check("the captured Lion is off the board", not main._occupancy.has(BoardData.parse_cell("E3")))

	main._on_piece_picked(main._occupancy[BoardData.parse_cell("F3")])
	_check("no piece may be picked up afterwards", main._selected == null)

	main.free()


func _move_piece(main: Control, from: Vector2i, to: Vector2i) -> void:
	var piece: PieceView = main._occupancy[from]
	main._occupancy.erase(from)
	main._occupancy[to] = piece
	piece.coordinate = to
	piece.position = main._board.cell_rect(to).position
