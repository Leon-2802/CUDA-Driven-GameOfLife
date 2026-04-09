#include "./sdl/game_window.h"
#include "cuda/cuda_simulation.h"

int main() {
	GUI::GameWindow window(800, 600, false);
	bool running = true;

	CUDASimulation::init(10000, 10000);

	while (running) {
		window.run();
		running = window.processEvents();
	}

    return 0;
}