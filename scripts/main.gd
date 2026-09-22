extends Control

## Builds the board, places the six pieces on their starting cells and lets a
## piece be picked up and moved according to its movement rule.
##
## Click a piece to select it; its legal destinations are marked on the board,
## with the ones that would capture an opponent's piece outlined in red.
## Click a destination to move there, or click anywhere else to deselect.
##
## The specification defines movement, blocking and capture only, so there is
## deliberately no turn order or win condition here: any piece may be moved at
## any time.

const BACKGROUND := Color("#241a12")
const HEADING_COLOR := Color("#f3e7cd")
const NOTE_COLOR := Color("#b39d7d")
const MOVE_DURATION := 0.16

var _board: BoardView
var _status: Label
var _selected: PieceView = null
var _destinations: Array[Vector2i] = []
## Cell -> PieceView for every piece on the board.
var _occupancy := {}


func _ready() -> void:
	var background := ColorRect.new()
	background.color = BACKGROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(column)

	column.add_child(_make_label("6 × 6 Board", 26, HEADING_COLOR))

	_board = BoardView.new()
	_board.cell_size = 92.0
	_board.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_board.cell_clicked.connect(_on_cell_clicked)
	column.add_child(_board)

	_place_starting_pieces()

	_status = _make_label("", 17, HEADING_COLOR)
	column.add_child(_status)
	column.add_child(_make_legend())
	column.add_child(
		_make_label(
			"Lion: one cell any direction.  Rabbit: two cells straight.  Snake: one cell diagonally.",
			15,
			NOTE_COLOR
		)
	)
	column.add_child(
		_make_label(
			"Your own pieces block you; moving onto an opponent's piece captures it.",
			15,
			NOTE_COLOR
		)
	)

	_clear_selection()


## Rule 3 - each piece is instantiated on the cell named in the rules.
func _place_starting_pieces() -> void:
	for entry: Dictionary in BoardData.START_POSITIONS:
		var coordinate := BoardData.parse_cell(entry["cell"])
		if coordinate.x == -1:
			push_error("Starting cell '%s' is not a cell on the board." % entry["cell"])
			continue

		var piece := PieceView.new()
		piece.setup(entry["player"], entry["kind"])
		piece.picked.connect(_on_piece_picked)
		_board.add_child(piece)

		var rect := _board.cell_rect(coordinate)
		piece.position = rect.position
		piece.size = rect.size
		piece.coordinate = coordinate
		_occupancy[coordinate] = piece


func _on_piece_picked(piece: PieceView) -> void:
	# Clicking the selected piece again puts it back down.
	if piece == _selected:
		_clear_selection()
		return
	_select(piece)


func _on_cell_clicked(coordinate: Vector2i) -> void:
	if _selected == null:
		return
	if _destinations.has(coordinate):
		_move_selected_to(coordinate)
	else:
		_clear_selection()


func _select(piece: PieceView) -> void:
	_selected = piece
	_destinations = MovementRules.legal_destinations(
		piece.kind, piece.player, piece.coordinate, _occupancy
	)
	var captures := MovementRules.captures_among(_destinations, _occupancy)
	_board.show_selection(piece.coordinate, _destinations, captures)

	var description := "%s %s on %s" % [
		BoardData.player_name(piece.player),
		BoardData.kind_name(piece.kind),
		BoardData.cell_name(piece.coordinate),
	]
	if _destinations.is_empty():
		_status.text = "%s has no legal move." % description
	elif captures.is_empty():
		_status.text = "%s can move to %s." % [description, _cell_list(_destinations)]
	else:
		_status.text = "%s can move to %s, capturing on %s." % [
			description, _cell_list(_destinations), _cell_list(captures)
		]


func _move_selected_to(coordinate: Vector2i) -> void:
	var piece := _selected
	var from := piece.coordinate
	# Rule 5 - the destination may hold an opponent's piece, which this move removes.
	var captured: PieceView = _occupancy.get(coordinate)

	_occupancy.erase(from)
	_occupancy[coordinate] = piece
	piece.coordinate = coordinate
	# Keep the mover in front of the piece it is landing on while both are on screen.
	_board.move_child(piece, -1)
	if captured != null:
		_remove_captured(captured)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(piece, "position", _board.cell_rect(coordinate).position, MOVE_DURATION)

	_selected = null
	_destinations = []
	_board.clear_selection()
	var move_text := "%s %s moved %s → %s" % [
		BoardData.player_name(piece.player),
		BoardData.kind_name(piece.kind),
		BoardData.cell_name(from),
		BoardData.cell_name(coordinate),
	]
	if captured == null:
		_status.text = move_text + "."
	else:
		_status.text = "%s and captured %s %s." % [
			move_text,
			BoardData.player_name(captured.player),
			BoardData.kind_name(captured.kind),
		]


## Rule 5 - a captured piece leaves the board. It fades out over the same beat as
## the move, so the two read as one action.
func _remove_captured(piece: PieceView) -> void:
	piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fade := create_tween()
	fade.tween_property(piece, "modulate:a", 0.0, MOVE_DURATION)
	fade.tween_callback(piece.queue_free)


func _clear_selection() -> void:
	_selected = null
	_destinations = []
	_board.clear_selection()
	_status.text = "Click a piece to see where it can move."


func _cell_list(cells: Array[Vector2i]) -> String:
	var names := PackedStringArray()
	for cell: Vector2i in cells:
		names.append(BoardData.cell_name(cell))
	return ", ".join(names)


func _make_legend() -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 26)

	for player: int in [BoardData.Player.PLAYER_1, BoardData.Player.PLAYER_2]:
		var group := HBoxContainer.new()
		group.add_theme_constant_override("separation", 8)
		group.add_child(_make_label(BoardData.player_name(player) + ":", 16, HEADING_COLOR))
		for kind: int in [
			BoardData.PieceKind.LION, BoardData.PieceKind.RABBIT, BoardData.PieceKind.SNAKE
		]:
			var swatch := PieceView.new()
			swatch.custom_minimum_size = Vector2(46.0, 46.0)
			swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
			swatch.setup(player, kind)
			group.add_child(swatch)
			group.add_child(_make_label(BoardData.kind_name(kind), 15, NOTE_COLOR))
		row.add_child(group)

	return row


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
