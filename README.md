# godot-board-game

A 6×6 turn-based board game built in Godot 4.7 (`scenes/main.tscn`).

## What is implemented

Rules 1–3 of the supplied specification, and nothing beyond them:

| Rule | Implementation |
| --- | --- |
| 1. Board | `scripts/board_view.gd` draws the 6×6 grid of 36 cells, the column numbers 1–6 along the bottom and the row letters A–F up the left side. The labels live in the gutters outside the grid and are not playable cells. |
| 2. Players & pieces | `scripts/piece_view.gd` draws one piece. Ownership is shown by the disc colour (Player 1 amber, Player 2 blue, with a second inner ring so the sides stay distinct without relying on hue); the animal is shown by the mark on the disc (maned head, long ears, S-curve). |
| 3. Initial positions | `BoardData.START_POSITIONS` in `scripts/board_data.gd` holds Player 1 Rabbit A3, Lion A4, Snake A5 and Player 2 Snake F2, Lion F3, Rabbit F4. `scripts/main.gd` instantiates them onto those cells. |

Row A is drawn along the bottom of the board so the letters read A upwards to F, matching the numbers reading 1 to 6 left to right.

## What is not implemented

The specification stops after the initial positions, so there are no movement,
capture, turn-order or win rules — and therefore no turn logic or interaction in
this scene. It renders the starting position only. `BoardData.parse_cell` / `BoardData.cell_name` and
`BoardView.cell_rect` already provide the coordinate plumbing a rules layer
would need once rules 4 onwards are defined.

## Running

Open the project in Godot 4.7 and press F5, or:

```
Godot_v4.7.2-stable_mono_win64.exe --path .
```
