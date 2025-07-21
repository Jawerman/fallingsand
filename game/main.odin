package game

import "core:log"
import "core:math"
import "core:math/rand"

import sdl "vendor:sdl3"

WIDTH :: 800
HEIGHT :: 600
SPAWN_RATIO :: 0.05
SAND_BRUSH_SIZE :: 15

SPEED :: 3

SIM_SIZE :: WIDTH * HEIGHT

SAND_COLORS: []u32 = {0xf2cc0dff, 0xf5d63dff, 0xf9e586ff, 0xfaeb9eff, 0xfcf5cfff}
WATER_COLOR: u32 = 0x0000ffff
SOLID_COLOR: u32 = 0x3f3f3fff
NONE_COLOR: u32 = 0x000000ff

MATERIALS: []MaterialType = {MaterialType.SOLID, MaterialType.SAND, MaterialType.LIQUID}
current_material_index := 0

main :: proc() {
	context.logger = log.create_console_logger()

	ok := sdl.Init({.VIDEO});assert(ok)
	defer sdl.Quit()

	window := sdl.CreateWindow("Falling Sand", WIDTH, HEIGHT, {.RESIZABLE});assert(window != nil)
	defer sdl.DestroyWindow(window)

	renderer := sdl.CreateRenderer(window, nil);assert(renderer != nil)
	defer sdl.DestroyRenderer(renderer)

	texture := sdl.CreateTexture(
		renderer,
		.RGBA8888,
		.STREAMING,
		WIDTH,
		HEIGHT,
	);assert(texture != nil)

	pixels := make([]u32, SIM_SIZE)
	defer delete(pixels)

	board := make([]Particle, SIM_SIZE)
	defer delete(board)

	clear_cellular_board(board)

	dt: f64 = 1000.0 / (60 * SPEED)
	accumulator := 0.0
	lastTime := sdl.GetPerformanceCounter()
	freq: f64 = (f64)(sdl.GetPerformanceFrequency())

	start_line: [2]int = {-1, -1}

	main_loop: for {
		// clear_texture(pixels)

		now := sdl.GetPerformanceCounter()
		frameTime := (f64)(now - lastTime) / freq * 1000.0
		lastTime = now
		accumulator += frameTime

		// proccess events

		ev: sdl.Event = ---
		for sdl.PollEvent(&ev) {
			#partial switch ev.type {
			case .QUIT:
				break main_loop
			case .KEY_DOWN:
				if ev.key.scancode == .ESCAPE do break main_loop
				if ev.key.scancode == .DELETE do clear_cellular_board(board)
				if ev.key.scancode == .S do current_material_index = (current_material_index + 1) % len(MATERIALS)
			}
		}
		// update game state
		mx, my: f32 = ---, ---
		buttons := sdl.GetMouseState(&mx, &my)

		right_mouse_down := (buttons & sdl.BUTTON_RMASK) == sdl.MouseButtonFlags{.RIGHT}
		left_mouse_down := (buttons & sdl.BUTTON_LMASK) == sdl.MouseButtonFlags{.LEFT}

		// checks
		window_size_x: i32 = ---
		window_size_y: i32 = ---

		sdl.GetWindowSizeInPixels(window, &window_size_x, &window_size_y)

		mx = mx / (f32)(window_size_x) * (f32)(WIDTH)
		my = my / (f32)(window_size_y) * (f32)(HEIGHT)

		x := (int)(math.floor(mx))
		y := (int)(math.floor(my))

		// if start_line.x < 0 && left_mouse_down {
		// 	start_line.x = x
		// 	start_line.y = y
		// }
		//
		// if start_line.x >= 0 && left_mouse_down {
		// 	raster_line(pixels, rand.choice(SAND_COLORS), start_line.x, start_line.y, x, y)
		// }
		//
		// if !left_mouse_down {
		// 	start_line.x = -1
		// 	start_line.y = -1
		// }

		if left_mouse_down {
			current_material := MATERIALS[current_material_index]
			ratio: f32 = SPAWN_RATIO
			if (current_material == MaterialType.SOLID) {
				ratio = 1.0
			}
			brush_paint_particle(board, x, y, generate_particle(current_material), ratio)
		}

		if right_mouse_down {
			brush_paint_particle(
				board,
				x,
				y,
				Particle{material_type = MaterialType.NONE, color = NONE_COLOR},
				1.0,
			)
		}

		for accumulator >= dt {
			simulate_step(board)
			accumulator = accumulator - dt
		}

		update_texture(pixels, board)


		// render
		ptr := cast(rawptr)&(pixels[0])
		ok := sdl.UpdateTexture(texture, nil, ptr, WIDTH * 4);assert(ok)

		ok = sdl.RenderClear(renderer);assert(ok)
		ok = sdl.RenderTexture(renderer, texture, nil, nil);assert(ok)
		ok = sdl.RenderPresent(renderer);assert(ok)
	}

}
