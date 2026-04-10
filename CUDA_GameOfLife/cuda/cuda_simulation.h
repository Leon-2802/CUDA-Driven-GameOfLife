#pragma once
#include <vector>

namespace CUDASimulation {
	void init(int width, int height);
	void advance();
	std::vector<bool> getViewportData(int startX, int startY, int viewportWdth, int viewportHeight);
}