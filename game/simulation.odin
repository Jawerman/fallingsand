package game

import "core:log"
import "core:math/rand"
import sdl "vendor:sdl3"

// TODO: Especificar el tipo subyacendte del enum
// no estoy seguro pero creo que se puede especificar el tipo que usa la struct (u8, u16, ...)
// interesante usar el tipo más pequeño para aprovechar la cache

MaterialType :: enum {
	NONE,
	SAND,
}

Particle :: struct {
	material_type: MaterialType,
}

get_particle_index :: proc(x, y: int) -> int {
	return (y * WIDTH) + x
}

get_particle_coords :: proc(index: int) -> (x: int, y: int) {
	y = index / WIDTH
	x = index % WIDTH

	return
}

brush_paint :: proc(board: []Particle, x, y: int) {
	for i in 0 ..< SAND_BRUSH_SIZE {
		for j in 0 ..< SAND_BRUSH_SIZE {
			new_particle_y := y - (SAND_BRUSH_SIZE / 2) + i
			new_particle_x := x - (SAND_BRUSH_SIZE / 2) + j

			if is_out_of_bounds(new_particle_x, new_particle_y) ||
			   rand.float32() > SAND_SPAWN_RATIO {
				continue
			}
			set_cellular_board_particle(
				board,
				Particle{material_type = MaterialType.SAND},
				new_particle_x,
				new_particle_y,
			)
		}
	}

}

clear_cellular_board :: proc(board: []Particle) {
	for i in 0 ..< SIM_SIZE {
		board[i] = Particle {
			material_type = MaterialType.NONE,
		}
	}
}

set_cellular_board_particle :: proc(board: []Particle, particle: Particle, x, y: int) {
	index := get_particle_index(x, y)
	board[index] = particle
}

update_texture :: proc(pixels: []u32, board: []Particle) {
	for i in 0 ..< len(board) {
		color: u32 = ---
		switch board[i].material_type {

		case MaterialType.SAND:
			color = 0xffffffff
		case MaterialType.NONE:
			color = 0x000000ff
		}
		pixels[i] = color
	}
}

simulate_step :: proc(board: []Particle) {

	for i := len(board) - 1; i >= 0; i -= 1 {
		switch board[i].material_type {

		case MaterialType.SAND:
			simulate_sand_step(board, i)
		case MaterialType.NONE:

		}
	}
}


simulate_sand_step :: proc(board: []Particle, index: int) {
	x, y := get_particle_coords(index)
	destination_y := y + 1

	if is_position_free(board, x, destination_y) {
		move_particle(board, x, y, x, destination_y)
		return
	}

	check_order := []int{-1, 1}
	if (rand.float32() > 0.5) {
		check_order = []int{1, -1}
	}

	for order in check_order {
		destination_x := x + order
		if is_position_free(board, destination_x, destination_y) {
			move_particle(board, x, y, destination_x, destination_y)
			break
		}
	}

}

is_position_free :: proc(board: []Particle, x, y: int) -> bool {
	if (is_out_of_bounds(x, y)) {
		return false
	}
	index := get_particle_index(x, y)
	return board[index].material_type == MaterialType.NONE
}

is_out_of_bounds :: proc(x, y: int) -> bool {
	return x < 0 || x >= WIDTH || y < 0 || y >= HEIGHT
}


move_particle :: proc(board: []Particle, origin_x, origin_y, destination_x, destination_y: int) {
	origin_index := get_particle_index(origin_x, origin_y)
	destination_index := get_particle_index(destination_x, destination_y)
	move_particle_by_index(board, origin_index, destination_index)
}


move_particle_by_index :: proc(board: []Particle, origin_index: int, destination_index: int) {
	board[destination_index] = board[origin_index]
	board[origin_index] = Particle {
		material_type = MaterialType.NONE,
	}
}
