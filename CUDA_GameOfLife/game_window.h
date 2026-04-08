#pragma once
#include <SDL3/SDL.h>

/**
* @brief A class that manages the game window and rendering for the Game of Life application using SDL.
*/
class GameWindow {
public:
	GameWindow(int width, int height, bool fullscreen);
	~GameWindow();
	void clear() const;
	void drawCell(int x, int y);
	bool processEvents();
	void run() const;
private:
	SDL_Window* window_ = nullptr;
	SDL_Renderer* renderer_ = nullptr;
	SDL_Event event_;
	int width_;
	int height_;
};