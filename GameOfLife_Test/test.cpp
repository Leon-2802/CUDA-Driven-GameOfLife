#include <gtest/gtest.h>
#include "cuda_simulation.hpp"

TEST(Initialization, EmptyGrid) {
	CUDASimulation::init(100, 100, false);

}