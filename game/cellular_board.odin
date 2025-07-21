package game
import "core:math/rand"

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
