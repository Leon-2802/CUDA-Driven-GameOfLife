#include <vector>
#include <chrono>
#include <thread>
#include "./sdl/game_window.h"
#include "cuda/cuda_simulation.h"

#define VIEWPORT_WIDTH 800
#define VIEWPORT_HEIGHT 600

int main() {
	GUI::GameWindow viewport(VIEWPORT_WIDTH, VIEWPORT_HEIGHT, false);
	bool running = true;

	CUDASimulation::init(10000, 10000);

	// Launch CUDA simulation in a seperate thread and keep run with a tick of 100ms
	// Prevents from blocking the main thread where to GUI runs
	std::jthread simThread([&]() {
		while (running) {
			auto tickStart = std::chrono::steady_clock::now();

			CUDASimulation::advance();

			auto elapsed = std::chrono::steady_clock::now() - tickStart;
			auto remaining = std::chrono::milliseconds(100) - std::chrono::duration_cast<std::chrono::milliseconds>(elapsed);
			if (remaining > std::chrono::milliseconds(0))
				std::this_thread::sleep_for(remaining);
		}
		});

	while (running) {
		//TODO maybe add a tick here too (be careful as not to become out of sync with the simThread
		std::vector<bool> viewportData = CUDASimulation::getViewportData(0, 0, VIEWPORT_WIDTH, VIEWPORT_HEIGHT);
		viewport.run(viewportData);
		running = viewport.processEvents();
	}

	simThread.join();

    return 0;
}