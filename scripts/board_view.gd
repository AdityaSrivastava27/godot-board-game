class_name BoardView
extends Control

## Rule 1 - the 6x6 grid of 36 cells, with the column numbers along the bottom
## and the row letters along the left side. The labels sit in the gutters
## outside the grid: they identify positions and are not playable cells.

const CELL_LIGHT := Color("#f0e4c9")
const CELL_DARK := Color("#c8a87e")
const GRID_LINE := Color("#8a6b48")
const FRAME := Color("#3f2b19")
const LABEL_COLOR := Color("#ead9b8")

@export var cell_size: float = 96.0:
	set(value):
		cell_size = value
		_update_minimum_size()
		queue_redraw()

@export var gutter: float = 46.0:
	set(value):
		gutter = value
		_update_minimum_size()
		queue_redraw()

@export var label_font_size: int = 22


func _ready() -> void:
	_update_minimum_size()


## Top-left corner of the grid itself, inside this control.
func board_origin() -> Vector2:
	return Vector2(gutter, 0.0)


func board_length() -> float:
	return cell_size * float(BoardData.SIZE)


## Screen rect of one cell, addressed by column index and row index.
## Row index 0 is row A and lands on the bottom row of the grid.
func cell_rect(coordinate: Vector2i) -> Rect2:
	var origin := board_origin()
	return Rect2(
		origin
		+ Vector2(
			float(coordinate.x) * cell_size,
			float(BoardData.SIZE - 1 - coordinate.y) * cell_size
		),
		Vector2(cell_size, cell_size)
	)


func cell_rect_by_name(cell: String) -> Rect2:
	var coordinate := BoardData.parse_cell(cell)
	if coordinate.x == -1:
		return Rect2()
	return cell_rect(coordinate)


func _update_minimum_size() -> void:
	custom_minimum_size = Vector2(gutter + board_length(), board_length() + gutter)


func _draw() -> void:
	var origin := board_origin()
	var length := board_length()

	var frame_width := 5.0
	draw_rect(
		Rect2(origin - Vector2(frame_width, frame_width), Vector2(length, length) + Vector2(frame_width, frame_width) * 2.0),
		FRAME
	)

	for row_index in BoardData.SIZE:
		for column_index in BoardData.SIZE:
			var rect := cell_rect(Vector2i(column_index, row_index))
			var is_light := (row_index + column_index) % 2 == 1
			draw_rect(rect, CELL_LIGHT if is_light else CELL_DARK)

	for i in range(1, BoardData.SIZE):
		var offset := float(i) * cell_size
		draw_line(origin + Vector2(offset, 0.0), origin + Vector2(offset, length), GRID_LINE, 1.0)
		draw_line(origin + Vector2(0.0, offset), origin + Vector2(length, offset), GRID_LINE, 1.0)

	_draw_labels()


func _draw_labels() -> void:
	var font := get_theme_default_font()
	if font == null:
		return

	# Row letters A (bottom) to F (top), in the left gutter.
	for row_index in BoardData.SIZE:
		var rect := cell_rect(Vector2i(0, row_index))
		var text: String = BoardData.ROW_LETTERS[row_index]
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, label_font_size)
		var baseline := Vector2(
			gutter * 0.5 - text_size.x * 0.5 - 6.0,
			rect.position.y + cell_size * 0.5 + text_size.y * 0.32
		)
		draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, label_font_size, LABEL_COLOR)

	# Column numbers 1 to 6, in the bottom gutter.
	for column_index in BoardData.SIZE:
		var rect := cell_rect(Vector2i(column_index, 0))
		var text := str(BoardData.COLUMN_NUMBERS[column_index])
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, label_font_size)
		var baseline := Vector2(
			rect.position.x + cell_size * 0.5 - text_size.x * 0.5,
			board_length() + gutter * 0.62
		)
		draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, label_font_size, LABEL_COLOR)
