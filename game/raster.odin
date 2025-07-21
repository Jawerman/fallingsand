package game

import "core:log"
import "core:math"

raster_line :: proc(pixels: []u32, color: u32, x0, y0, x1, y1: int) {
	x0 := x0
	y0 := y0

	dx := math.abs(x1 - x0)
	sx := x0 < x1 ? 1 : -1

	dy := -math.abs(y1 - y0)
	sy := y0 < y1 ? 1 : -1

	err := dx + dy

	loop: for {
		pixels[get_particle_index(x0, y0)] = color

		if x0 == x1 && y0 == y1 do break loop

		e2 := 2 * err

		if e2 >= dy {
			err += dy
			x0 += sx
		}

		if e2 <= dx {
			err += dx
			y0 += sy
		}
	}
}

update_texture :: proc(pixels: []u32, board: []Particle) {
	for i in 0 ..< len(board) {
		color: u32 = ---
		pixels[i] = board[i].color
	}
}

clear_texture :: proc(pixels: []u32) {
	for i in 0 ..< len(pixels) {
		pixels[i] = NONE_COLOR
	}
}
