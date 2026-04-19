#pragma once
#include <SDL3/SDL.h>
#include <vector>
#include <cstdint>

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
		bool userQuit();
		void update(std::vector<uint8_t> viewportData) const;
		int getCellSquareSize() const;
	private:
		SDL_Window* window_ = nullptr;
		SDL_Renderer* renderer_ = nullptr;
		SDL_Event event_;
		int width_;
		int height_;
		int cellSquareSize_;
	};
}