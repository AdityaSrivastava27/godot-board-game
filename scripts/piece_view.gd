class_name PieceView
extends Control

## Draws a single piece. Rule 2 requires the two players' pieces to be
## visually distinguishable, so ownership is carried by the disc colour
## while the animal is carried by the mark drawn on top of it.

signal picked(piece: PieceView)

const PLAYER_1_BODY := Color("#e8a33d")
const PLAYER_1_EDGE := Color("#5a3208")
const PLAYER_1_MARK := Color("#3a2006")

const PLAYER_2_BODY := Color("#4a86c8")
const PLAYER_2_EDGE := Color("#0e2846")
const PLAYER_2_MARK := Color("#eaf2fb")

var player: int = BoardData.Player.PLAYER_1
var kind: int = BoardData.PieceKind.LION
## The cell this piece stands on, as (column index, row index).
var coordinate := Vector2i(-1, -1)


func setup(owning_player: int, piece_kind: int) -> void:
	player = owning_player
	kind = piece_kind
	tooltip_text = "%s %s" % [BoardData.player_name(player), BoardData.kind_name(kind)]
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button == null or not button.pressed or button.button_index != MOUSE_BUTTON_LEFT:
		return
	picked.emit(self)
	accept_event()


func _draw() -> void:
	var is_player_1 := player == BoardData.Player.PLAYER_1
	var body := PLAYER_1_BODY if is_player_1 else PLAYER_2_BODY
	var edge := PLAYER_1_EDGE if is_player_1 else PLAYER_2_EDGE
	var mark := PLAYER_1_MARK if is_player_1 else PLAYER_2_MARK

	var center := size * 0.5
	var radius: float = minf(size.x, size.y) * 0.42

	draw_circle(center, radius, body)
	draw_arc(center, radius, 0.0, TAU, 64, edge, maxf(2.0, radius * 0.10), true)
	# Player 2's discs carry a second ring, so the two sides stay distinct
	# even for a viewer who cannot separate the two hues.
	if not is_player_1:
		draw_arc(center, radius * 0.80, 0.0, TAU, 64, edge, maxf(1.5, radius * 0.06), true)

	match kind:
		BoardData.PieceKind.LION:
			_draw_lion(center, radius, mark, body)
		BoardData.PieceKind.RABBIT:
			_draw_rabbit(center, radius, mark)
		BoardData.PieceKind.SNAKE:
			_draw_snake(center, radius, mark)


## A maned head: a spiked ring with a plain face punched out of it.
func _draw_lion(center: Vector2, radius: float, mark: Color, body: Color) -> void:
	var head := center - Vector2(0.0, radius * 0.10)
	var spikes := 11
	var points := PackedVector2Array()
	for i in spikes * 2:
		var angle := TAU * float(i) / float(spikes * 2) - PI * 0.5
		var length := radius * (0.62 if i % 2 == 0 else 0.44)
		points.append(head + Vector2(cos(angle), sin(angle)) * length)
	draw_colored_polygon(points, mark)
	draw_circle(head, radius * 0.30, body)
	draw_circle(head + Vector2(-radius * 0.12, -radius * 0.06), radius * 0.06, mark)
	draw_circle(head + Vector2(radius * 0.12, -radius * 0.06), radius * 0.06, mark)


## A head with two long upright ears.
func _draw_rabbit(center: Vector2, radius: float, mark: Color) -> void:
	var head := center + Vector2(0.0, radius * 0.20)
	for side: float in [-1.0, 1.0]:
		var ear_center := head + Vector2(side * radius * 0.26, -radius * 0.56)
		draw_colored_polygon(
			_ellipse_points(ear_center, radius * 0.14, radius * 0.42, side * 0.28, 28), mark
		)
	draw_colored_polygon(_ellipse_points(head, radius * 0.34, radius * 0.30, 0.0, 32), mark)


## A body drawn as a thick S curve, with a raised head at the top.
func _draw_snake(center: Vector2, radius: float, mark: Color) -> void:
	var points := PackedVector2Array()
	var steps := 26
	for i in steps + 1:
		var t := float(i) / float(steps)
		var y := lerpf(radius * 0.62, -radius * 0.54, t)
		var x := sin(t * TAU) * radius * 0.42
		points.append(center + Vector2(x, y))
	draw_polyline(points, mark, radius * 0.17, true)
	draw_circle(points[points.size() - 1], radius * 0.15, mark)


func _ellipse_points(
	center: Vector2, radius_x: float, radius_y: float, rotation: float, steps: int
) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in steps:
		var angle := TAU * float(i) / float(steps)
		var point := Vector2(cos(angle) * radius_x, sin(angle) * radius_y).rotated(rotation)
		points.append(center + point)
	return points
