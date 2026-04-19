#include <gtest/gtest.h>
#include "cuda_simulation.hpp"

TEST(Initialization, EmptyGrid) {
	CUDASimulation::init(100, 100, false);
	auto subgrid = CUDASimulation::getViewportData(0, 0, 10, 10);
	EXPECT_TRUE(subgrid.has_value());
	EXPECT_EQ(subgrid.value()[0], 0U);
	EXPECT_EQ(subgrid.value()[1], 0U);
	EXPECT_EQ(subgrid.value()[3], 0U);
}