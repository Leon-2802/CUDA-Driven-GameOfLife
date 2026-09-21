#pragma once
#include <SDL3/SDL.h>
#include <vector>
#include <cstdint>
#include <optional>
#include <utility>

namespace GUI {
	/**
	* @brief A class that manages the game window and rendering for the Game of Life application using SDL.
	*/
	class GameWindow {
	public:
		GameWindow(int width, int height, int cellSquareSize, bool fullscreen);
		~GameWindow();
		void clear() const;
		void drawCell(int x, int y);
		void processEvents();
		void handleMouseClickDown(const SDL_Event& event);
		void handleMouseClickUp(const SDL_Event& event);
		void updateViewportOrigin(std::pair<uint32_t, uint32_t> simulationGridBounds);
		void update(std::vector<uint8_t> viewportData);
		int getCellSquareSize() const;
		bool windowRunning() const;
		bool panningModeOn() const;
		std::optional<std::pair<int, int>> getClickedCellCoords() const;
		std::pair<uint32_t, uint32_t> getViewportOriginCoords() const;
	private:
		SDL_Window* window_ = nullptr;
		SDL_Renderer* renderer_ = nullptr;
		SDL_Event event_;
		bool windowClosed_;
		std::pair<uint32_t, uint32_t> viewportOriginCoords_;
		std::pair<uint32_t, uint32_t> panStart_;
		bool panningModeOn_;
		int width_;
		int height_;
		int cellSquareSize_;
		std::optional<std::pair<int, int>> clickedCellCoords_;
	};
}