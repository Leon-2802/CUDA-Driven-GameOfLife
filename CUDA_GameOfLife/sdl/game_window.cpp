#include "game_window.hpp"
#include <SDL3/SDL.h>
#include <vector>
#include <algorithm>

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
    this->windowClosed_ = false;
    this->panningModeOn_ = false;
    this->clickedCellCoords_ = std::nullopt;
    this->viewportOriginCoords_ = { 0U, 0U };
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

void GameWindow::processEvents() {
    while (SDL_PollEvent(&event_)) {
        switch (event_.type) {
            case SDL_EVENT_QUIT:
                windowClosed_ = true;
                break;
            case SDL_EVENT_KEY_DOWN:
                if (event_.key.key == SDLK_ESCAPE)
                    windowClosed_ = true;
                break;
            case SDL_EVENT_MOUSE_BUTTON_DOWN:
                handleMouseClickDown(event_);
                break;
            case SDL_EVENT_MOUSE_BUTTON_UP:
                handleMouseClickUp(event_);
        }
    }
}

void GameWindow::handleMouseClickDown(const SDL_Event& event) {
    if (event.button.button == SDL_BUTTON_LEFT) {
        // Only allow interactions with the grid when not panning
        if (panningModeOn_ == false) {
            int x = static_cast<int>(event.button.x / cellSquareSize_);
            int y = static_cast<int>(event.button.y / cellSquareSize_);
            clickedCellCoords_ = std::make_pair(x, y);
        }
    }
    else if (event.button.button == SDL_BUTTON_MIDDLE) {
        panningModeOn_ = true;
        panStart_ = { static_cast<uint32_t>(event.button.x / cellSquareSize_), 
            static_cast<uint32_t>(event.button.y / cellSquareSize_) };
    }
}
void GameWindow::handleMouseClickUp(const SDL_Event& event) {
    if (event.button.button == SDL_BUTTON_MIDDLE) {
        panningModeOn_ = false;
    }
}

void GameWindow::updateViewportOrigin(std::pair<uint32_t, uint32_t> simulationGridBounds) {
    if (!panningModeOn_) return;

    float x, y;
    SDL_GetMouseState(&x, &y);

    // Mouse position in cell units (ignore negative coordinates outside the window)
    const int cellX = static_cast<int>(SDL_max(0.0f, x) / cellSquareSize_);
    const int cellY = static_cast<int>(SDL_max(0.0f, y) / cellSquareSize_);

    const int offsetX = cellX - static_cast<int>(panStart_.first);
    const int offsetY = cellY - static_cast<int>(panStart_.second);

    // Viewport size in cells
    const int viewportCellsX = width_ / cellSquareSize_;
    const int viewportCellsY = height_ / cellSquareSize_;

    // The origin may not go past the point where the viewport's far edge hits the grid's right and upper edge
    const int maxOriginX = std::max(0, static_cast<int>(simulationGridBounds.first) - viewportCellsX);
    const int maxOriginY = std::max(0, static_cast<int>(simulationGridBounds.second) - viewportCellsY);

    // Do the math in signed ints, then clamp
    const int newX = std::clamp(static_cast<int>(viewportOriginCoords_.first) - offsetX, 0, maxOriginX);
    const int newY = std::clamp(static_cast<int>(viewportOriginCoords_.second) - offsetY, 0, maxOriginY);

    viewportOriginCoords_ = { static_cast<uint32_t>(newX), static_cast<uint32_t>(newY) };
    panStart_ = { static_cast<uint32_t>(cellX), static_cast<uint32_t>(cellY) };
}

int GameWindow::getCellSquareSize() const {
    return this->cellSquareSize_;
}

bool GameWindow::windowRunning() const {
    return !windowClosed_;
}

bool GameWindow::panningModeOn() const {
    return panningModeOn_;
}

std::optional<std::pair<int, int>> GameWindow::getClickedCellCoords() const {
    return clickedCellCoords_;
}
std::pair<uint32_t, uint32_t> GameWindow::getViewportOriginCoords() const {
    return viewportOriginCoords_;
}

void GameWindow::update(std::vector<uint8_t> viewportData) {
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

    // Reset this value, as it should only contain an std::pair<int, int> if the user clicked a cell before update
    this->clickedCellCoords_.reset();

    SDL_RenderPresent(renderer_);
}