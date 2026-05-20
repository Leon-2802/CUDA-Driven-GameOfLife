#pragma once
#include <vector>
#include <optional>
#include <cstdint>

namespace CUDASimulation {
	void init(const int gridWidth, const int gridHeight, bool randomCells);
	void advance();
	void queueFlip(const int x, const int y);

	/*
	* @brief Extract subgrid from the Game of Life grid and package it in vector of uint8_t values
	*/
	std::optional<std::vector<uint8_t>> getViewportData(const int startX, const int startY, const int viewportWidth, const int viewportHeight);
}