#include "game_window.hpp"
#include <SDL3/SDL.h>
#include <vector>

using namespace GUI;

GameWindow::GameWindow(int width, int height, int cellSquareSize, bool fullscreen) {
    SDL_Init(SDL_INIT_VIDEO);
    if (fullscreen) {
        this->window_ = SDL_CreateWindow("Game of Life", 0, 0, SDL_WINDOW_FULLSCREEN);
    }
    else {
		this->window_ = SDL_CreateWindow("Game of Life", width, height, 0);
    }
    this->renderer_ = SDL_CreateRenderer(this->window_, NULL);
    SDL_SetRenderVSync(renderer_, 1); // enable vsync
    SDL_GetWindowSize(this->window_, &width_, &height_);
    this->cellSquareSize_ = cellSquareSize;
}

GameWindow::~GameWindow() {
    SDL_DestroyRenderer(renderer_);
    SDL_DestroyWindow(window_);
    SDL_Quit();
}

void GameWindow::clear() const {
    SDL_SetRenderDrawColor(renderer_, 0, 0, 0, 255);
    SDL_RenderClear(renderer_);
}

void GameWindow::drawCell(int x, int y) {
	// implement drawing a cell at (x, y) using SDL_Renderer
}

bool GameWindow::userQuit() {
    while (SDL_PollEvent(&event_)) {
        if (event_.type == SDL_EVENT_QUIT)
            return false;
        if (event_.type == SDL_EVENT_KEY_DOWN && event_.key.key == SDLK_ESCAPE)
            return false;
    }
    return true;
}

int GameWindow::getCellSquareSize() const {
    return this->cellSquareSize_;
}

void GameWindow::update(std::vector<uint8_t> viewportData) const {
    SDL_SetRenderDrawColor(renderer_, 0, 0, 0, 255);
    SDL_RenderClear(renderer_);

    SDL_SetRenderDrawColor(renderer_, 255, 255, 255, 255);

    int gridWidth = width_ / cellSquareSize_;

    for (int i = 0; i < (int)viewportData.size(); i++) {
        if (viewportData[i] != 0) {
            int x = (i % gridWidth) * cellSquareSize_;
            int y = (i / gridWidth) * cellSquareSize_;
            const SDL_FRect rect = { x, y, cellSquareSize_, cellSquareSize_ };
            SDL_RenderFillRect(renderer_, &rect);
        }
    }

    SDL_RenderPresent(renderer_);
}