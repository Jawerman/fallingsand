package game

import "core:log"
import "core:math"
import sdl "vendor:sdl3"

WIDTH :: 800
HEIGHT :: 600
SAND_SPAWN_RATIO :: 0.005
SAND_BRUSH_SIZE :: 15

SIM_SIZE :: WIDTH * HEIGHT

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

	dt: f64 = 1000.0 / 60
	accumulator := 0.0
	lastTime := sdl.GetPerformanceCounter()
	freq: f64 = (f64)(sdl.GetPerformanceFrequency())


	main_loop: for {
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
			}
		}
		// update game state
		mx, my: f32 = ---, ---
		buttons := sdl.GetMouseState(&mx, &my)

		if ((buttons & sdl.BUTTON_LMASK) == sdl.MouseButtonFlags{.LEFT}) {
			window_size_x: i32 = ---
			window_size_y: i32 = ---

			sdl.GetWindowSizeInPixels(window, &window_size_x, &window_size_y)

			mx = mx / (f32)(window_size_x) * (f32)(WIDTH)
			my = my / (f32)(window_size_y) * (f32)(HEIGHT)

			x := (int)(math.floor(mx))
			y := (int)(math.floor(my))
			particle := Particle {
				material_type = MaterialType.SAND,
			}
			brush_paint(board, x, y)
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
