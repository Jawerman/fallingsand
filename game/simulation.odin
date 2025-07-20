package game

import "core:log"
import "core:math/rand"
import sdl "vendor:sdl3"

// TODO: Especificar el tipo subyacendte del enum
// no estoy seguro pero creo que se puede especificar el tipo que usa la struct (u8, u16, ...)
// interesante usar el tipo más pequeño para aprovechar la cache

MaterialType :: enum {
	NONE,
	SOLID,
	LIQUID,
	SAND,
}

Particle :: struct {
	material_type: MaterialType,
	color:         u32,
}

generate_particle :: proc(particle_type: MaterialType) -> Particle {
	color: u32 = ---

	switch particle_type {
	case MaterialType.SAND:
		color = rand.choice(SAND_COLORS)
	case MaterialType.LIQUID:
		color = WATER_COLOR
	case MaterialType.SOLID:
		color = SOLID_COLOR
	case MaterialType.NONE:
		color = NONE_COLOR
	}

	return Particle{material_type = particle_type, color = color}
}


get_particle_index :: proc(x, y: int) -> int {
	return (y * WIDTH) + x
}

get_particle_coords :: proc(index: int) -> (x: int, y: int) {
	y = index / WIDTH
	x = index % WIDTH

	return
}

brush_paint_particle :: proc(board: []Particle, x, y: int, particle: Particle, ratio: f32) {
	for i in 0 ..< SAND_BRUSH_SIZE {
		for j in 0 ..< SAND_BRUSH_SIZE {
			new_particle_y := y - (SAND_BRUSH_SIZE / 2) + i
			new_particle_x := x - (SAND_BRUSH_SIZE / 2) + j
			if is_out_of_bounds(new_particle_x, new_particle_y) || rand.float32() > ratio {
				continue
			}
			set_cellular_board_particle(board, particle, new_particle_x, new_particle_y)
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
		pixels[i] = board[i].color
	}
}

simulate_step :: proc(board: []Particle) {
	for i := HEIGHT - 1; i >= 0; i -= 1 {
		simulate_row(board, i, i % 2 == 0)
	}
}

simulate_row :: proc(board: []Particle, y: int, backwards: bool) {
	if backwards {
		for i := WIDTH - 1; i >= 0; i -= 1 {
			simulate_particle(board, i, y)
		}
	} else {
		for i := 0; i < WIDTH; i += 1 {
			simulate_particle(board, i, y)
		}
	}
}

simulate_particle :: proc(board: []Particle, x, y: int) -> bool {
	index := get_particle_index(x, y)
	particle := board[index]

	switch particle.material_type {

	case MaterialType.SAND:
		return simulate_sand_step(board, index)
	case MaterialType.LIQUID:
		return simulate_liquid_step(board, index)
	case MaterialType.NONE:
		return false
	case MaterialType.SOLID:
		return false
	}
	return false
}


simulate_sand_step :: proc(board: []Particle, index: int) -> bool {
	x, y := get_particle_coords(index)
	destination_y := y + 1

	if is_position_free(board, x, destination_y) {
		move_particle(board, x, y, x, destination_y)
		return true
	}

	check_order := []int{-1, 1}
	if (rand.float32() > 0.5) {
		check_order = []int{1, -1}
	}

	for order in check_order {
		destination_x := x + order
		if is_position_free(board, destination_x, destination_y) {
			move_particle(board, x, y, destination_x, destination_y)
			return true
		}
	}
	return false
}

simulate_liquid_step :: proc(board: []Particle, index: int) -> bool {
	x, y := get_particle_coords(index)


	destination_y := y + 1

	if is_position_free(board, x, destination_y) {
		move_particle(board, x, y, x, destination_y)
		return true
	}

	check_order := []int{-1, 1}
	if (rand.float32() > 0.5) {
		check_order = []int{1, -1}
	}

	for order in check_order {
		destination_x := x + order
		if is_position_free(board, destination_x, destination_y) {
			move_particle(board, x, y, destination_x, destination_y)
			return true
		}
	}

	for order in check_order {
		destination_y := y
		destination_x := x + order
		if is_position_free(board, destination_x, destination_y) {
			move_particle(board, x, y, destination_x, destination_y)
			return true
		}
	}
	return false
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
