#include <vector>
#include <optional>
#include <iostream>
#include <cstdint>
#include <chrono>
#include <thread>
#include <mutex>
#include "./sdl/game_window.hpp"
#include "cuda/cuda_simulation.hpp"

#define VIEWPORT_WIDTH 1280
#define VIEWPORT_HEIGHT 800
#define FRAME_DELAY 100
#define CUDA_DELAY 100
#define SIMULATION_GRID_DIMENSION 20000

int main() {
	GUI::GameWindow viewport(VIEWPORT_WIDTH, VIEWPORT_HEIGHT, 5, false);
	bool running = true;
	std::mutex viewportMutex;

	CUDASimulation::init(SIMULATION_GRID_DIMENSION, SIMULATION_GRID_DIMENSION, true);

	// Launch CUDA simulation in a seperate thread and keep run with a tick of 100ms
	// Prevents from blocking the main thread where to GUI runs
	std::jthread simThread([&]() {
		while (running) {
			auto tickStart = std::chrono::steady_clock::now();

			{
				std::scoped_lock lock(viewportMutex);
				CUDASimulation::advance();
			}

			auto elapsed = std::chrono::steady_clock::now() - tickStart;
			auto remaining = std::chrono::milliseconds(CUDA_DELAY) - std::chrono::duration_cast<std::chrono::milliseconds>(elapsed);
			if (remaining > std::chrono::milliseconds(0)) {
				std::this_thread::sleep_for(remaining);
			}
		}
		});

	while (running) {
		Uint32 frameStart = SDL_GetTicks();

		{
			std::scoped_lock lock(viewportMutex);
			viewport.processEvents();
			if (viewport.getClickedCellCoords().has_value()) {
				CUDASimulation::queueFlip(
					viewport.getClickedCellCoords().value().first,
					viewport.getClickedCellCoords().value().second);
			}

			while (viewport.panningModeOn()) {
				viewport.updateViewportOrigin({ SIMULATION_GRID_DIMENSION, SIMULATION_GRID_DIMENSION});
				viewport.processEvents();
				std::cout << "X: " << viewport.getViewportOriginCoords().first << " Y: " << viewport.getViewportOriginCoords().second << std::endl;
				auto viewportData = CUDASimulation::getViewportData(viewport.getViewportOriginCoords().first, viewport.getViewportOriginCoords().second, 
					VIEWPORT_WIDTH / viewport.getCellSquareSize(), VIEWPORT_HEIGHT / viewport.getCellSquareSize());
				if (viewportData.has_value()) {
					viewport.update(viewportData.value());
				} 
			}

			auto viewportData = CUDASimulation::getViewportData(viewport.getViewportOriginCoords().first, viewport.getViewportOriginCoords().second,
				VIEWPORT_WIDTH / viewport.getCellSquareSize(), VIEWPORT_HEIGHT / viewport.getCellSquareSize());
			if (viewportData.has_value()) {
				viewport.update(viewportData.value());
			}
		}
	
		running = viewport.windowRunning();

		Uint32 frameTime = SDL_GetTicks() - frameStart;
		if (frameTime < FRAME_DELAY) {
			SDL_Delay(FRAME_DELAY - frameTime);
		}

	}

    return 0;
}