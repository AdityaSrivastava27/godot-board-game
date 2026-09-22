extends Control

## Builds the board and places the six pieces on their starting cells.
## Rules 1-3 only: this scene is the starting position, it carries no
## movement, capture or turn logic because no such rules are defined.

const BACKGROUND := Color("#241a12")
const HEADING_COLOR := Color("#f3e7cd")
const NOTE_COLOR := Color("#b39d7d")

var _board: BoardView


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
	column.add_theme_constant_override("separation", 18)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(column)

	column.add_child(_make_label("6 × 6 Board — Starting Position", 26, HEADING_COLOR))

	_board = BoardView.new()
	_board.cell_size = 92.0
	_board.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(_board)

	_place_starting_pieces()

	column.add_child(_make_legend())
	column.add_child(
		_make_label(
			"Rows A–F read upwards on the left, columns 1–6 read across the bottom.", 15, NOTE_COLOR
		)
	)


## Rule 3 - each piece is instantiated on the cell named in the rules.
func _place_starting_pieces() -> void:
	for entry: Dictionary in BoardData.START_POSITIONS:
		var coordinate := BoardData.parse_cell(entry["cell"])
		if coordinate.x == -1:
			push_error("Starting cell '%s' is not a cell on the board." % entry["cell"])
			continue

		var piece := PieceView.new()
		piece.setup(entry["player"], entry["kind"])
		piece.mouse_filter = Control.MOUSE_FILTER_PASS
		_board.add_child(piece)

		var rect := _board.cell_rect(coordinate)
		piece.position = rect.position
		piece.size = rect.size


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
