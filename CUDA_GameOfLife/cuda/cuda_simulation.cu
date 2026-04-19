// CUDA includes
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include "common_functions.h"
#include <math_functions.h>
#include "driver_types.h"

// Local includes
#include "simulation_buffers.cuh"
#include "cuda_simulation.hpp"

// standard library includes
#include <iostream>
#include <memory>
#include <chrono>



namespace CUDASimulation {

#define BLOCK_SIZE_X 16
#define BLOCK_SIZE_Y 16

	// Grid of Game of Life, to be allocated on the device (GPU)
	// Two are required to save redundant copying of data
	// Static to keep it local to this file
	static std::shared_ptr<SimulationBuffers> simulationBuffers = nullptr;

	// Keep track of origin of current viewport on the GUI
	static std::pair<int, int> currentViewportOrigin = { 0, 0 };

	// Helper macro for CUDA error checking
#define RANSAC_CUDA_CHECK(ans)                      \
    {                                               \
        ransacGpuAssert((ans), __FILE__, __LINE__); \
    }
	inline void ransacGpuAssert(cudaError_t code, const char* file, int line,
		bool abort = true)
	{
		if (code != cudaSuccess)
		{
			fprintf(stderr, "RANSAC_GPU_Assert: %s %s %d\n", cudaGetErrorString(code), file,
				line);
			if (abort)
				exit(code);
		}
	}

	/*
	* @brief Provides easier row and column based index for a 2D matrix that is layed out in 1D row-major order
	*/
	__device__ __forceinline__ int calcIdx(int row, int numCols, int col)
	{
		return row * numCols + col;
	}

	/*
	* @brief A noise-based RNG, reasonably well-known within game development circles.
	* Allows threads to compute their random value independently, based on their position on the grid.
	* It is not as stable and tested as other more well-known RNG algorithms, but more than sufficient in this case.
	*/
	__device__ uint32_t squirrel3(uint32_t pos, uint32_t seed = 0) {
		constexpr uint32_t BIT_NOISE1 = 0xB5297A4Du;
		constexpr uint32_t BIT_NOISE2 = 0x68E31DA4u;
		constexpr uint32_t BIT_NOISE3 = 0x1B56C4E9u;

		uint32_t mangled = pos;
		mangled *= BIT_NOISE1; // (1) multiply — spreads bits across the word
		mangled += seed; // (2) add seed — decorrelates different runs
		mangled ^= (mangled >> 8); // (3) xorshift — folds high bits into low bits
		mangled += BIT_NOISE2; // (4) add — breaks symmetry after the xorshift
		mangled ^= (mangled << 8); // (5) xorshift — folds low bits into high bits
		mangled *= BIT_NOISE3; // (6) multiply — avalanches the mixed bits
		mangled ^= (mangled >> 8); // (7) xorshift — final fold
		return mangled;
	}

	/**
	* @brief This CUDA kernel intializes the grid with random values for the cell states
	*/
	__global__ void initializeGridRandom(uint8_t* dGrid, const int width, const int height, const uint32_t seed) {
		const int paddedWidth = width + 2;

		// Padded coords
		const int px = blockIdx.x * blockDim.x + threadIdx.x + 1;
		const int py = blockIdx.y * blockDim.y + threadIdx.y + 1;
		// Guard against out of bounds access
		if ((px - 1) >= width || (py - 1) >= height) return;

		int idx = calcIdx(py, paddedWidth, px);
		dGrid[idx] = (squirrel3(idx, seed) >> 31) & (squirrel3(idx, seed + 1) >> 31); // 25% chance of value 1
	}

	/**
	* @brief Calculates the state of each cell on a seperate thread by reading neighbour cell states from global memory
	*/
	__global__ void calculateNextGeneration(uint8_t* dGridCurrent, uint8_t* dGridNext, const int width, const int height) {
		// REFACTOR: Add shared memory later to lower slow global memory traffic
		const int paddedWidth = width + 2;

		// Padded coords
		const int px = blockIdx.x * blockDim.x + threadIdx.x + 1; 
		const int py = blockIdx.y * blockDim.y + threadIdx.y + 1;
		// Guard against out of bounds access
		if ((px-1) >= width || (py-1) >= height) return;

		// Neighbor indices
		int left = px - 1;
		int right = px + 1;
		int up = py - 1;
		int down = py + 1;

		// Retrieve values of the 8 neighbors and increase sum by 1 if alive
		uint8_t aliveNeighbors =
			(dGridCurrent[calcIdx(up, paddedWidth, left)] != 0) +
			(dGridCurrent[calcIdx(up, paddedWidth, px)] != 0) +
			(dGridCurrent[calcIdx(up, paddedWidth, right)] != 0) +
			(dGridCurrent[calcIdx(py, paddedWidth, left)] != 0) +
			(dGridCurrent[calcIdx(py, paddedWidth, right)] != 0) +
			(dGridCurrent[calcIdx(down, paddedWidth, left)] != 0) +
			(dGridCurrent[calcIdx(down, paddedWidth, px)] != 0) +
			(dGridCurrent[calcIdx(down, paddedWidth, right)] != 0);

		uint8_t alive = dGridCurrent[calcIdx(py, paddedWidth, px)] != 0;
		
		// GoL rules:
		// - Live cell survives with 2 or 3 neighbors
		// - Dead cell born with exactly 3 neighbors
		// Use bitwise operators instead of logical operators to prevent warp divergence
		uint8_t survives = alive & ((aliveNeighbors == 2) | (aliveNeighbors == 3)); 
		uint8_t born = (1 - alive) & (aliveNeighbors == 3);

		dGridNext[calcIdx(py, paddedWidth, px)] = survives | born;
	}


	void init(const int gridWidth, const int gridHeight, bool randomCells) {
		// Allocate with zero-padded border
		const int paddedWidth = gridWidth + 2;
		const int paddedHeight = gridHeight + 2;
		simulationBuffers = std::make_shared<SimulationBuffers>(paddedWidth, paddedHeight);
		// Check for errors after allocating:
		RANSAC_CUDA_CHECK(cudaGetLastError());

		if (randomCells) {
			// Create CUDA events for timing
			cudaEvent_t start, stop;
			cudaEventCreate(&start);
			cudaEventCreate(&stop);
			// Record the start event
			cudaEventRecord(start);

			dim3 blockSize(BLOCK_SIZE_X, BLOCK_SIZE_Y);
			dim3 gridSize(
				(gridWidth + blockSize.x - 1) / blockSize.x, // ceiling division ensures every cell gets covered
				(gridHeight + blockSize.y - 1) / blockSize.y
			);
			// Aquire the seed based on current time in nanoseconds
			const uint32_t seed = static_cast<uint32_t>(std::chrono::high_resolution_clock::now().time_since_epoch().count());
			// Run the kernel
			initializeGridRandom << <gridSize, blockSize >> > (simulationBuffers->currentPtr(), gridWidth, gridHeight, seed);
			RANSAC_CUDA_CHECK(cudaGetLastError());

			// Record the stop event
			cudaEventRecord(stop);
			// Wait for the stop event to complete
			cudaEventSynchronize(stop);
			// Calculate the elapsed time
			float milliseconds = 0;
			cudaEventElapsedTime(&milliseconds, start, stop);
			std::cout << "Runtime for initialization with grid dimension " << gridWidth << " x " << gridHeight << " in milliseconds: " << milliseconds << std::endl;
			// Cleanup events
			cudaEventDestroy(start);
			cudaEventDestroy(stop);
		}
	}

	void advance() {
		// Create CUDA events for timing
		cudaEvent_t start, stop;
		cudaEventCreate(&start);
		cudaEventCreate(&stop);
		// Record the start event
		cudaEventRecord(start);

		dim3 blockSize(BLOCK_SIZE_X, BLOCK_SIZE_Y);
		dim3 gridSize(
			(simulationBuffers->paddedWidth() + blockSize.x - 1) / blockSize.x, // ceiling division ensures every cell gets covered
			(simulationBuffers->paddedHeight() + blockSize.y - 1) / blockSize.y
		);
		calculateNextGeneration << <gridSize, blockSize >> >
			(simulationBuffers->currentPtr(), simulationBuffers->nextPtr(), simulationBuffers->width(), simulationBuffers->height());
		RANSAC_CUDA_CHECK(cudaGetLastError());

		// Swap after computation -> the next generation becomes the current generation of the next step
		simulationBuffers->swap();

		// Record the stop event
		cudaEventRecord(stop);
		// Wait for the stop event to complete
		cudaEventSynchronize(stop);
		// Calculate the elapsed time
		float milliseconds = 0;
		cudaEventElapsedTime(&milliseconds, start, stop);
		std::cout << "Runtime for advance step with grid dimension " << simulationBuffers->width() << " x " << simulationBuffers->height() << " in milliseconds: " << milliseconds << std::endl;
		// Cleanup events
		cudaEventDestroy(start);
		cudaEventDestroy(stop);
	}

	std::optional<std::vector<uint8_t>> getViewportData(const int startX, const int startY, const int viewportWidth, const int viewportHeight) {
		currentViewportOrigin = { startX, startY };
		return simulationBuffers->subgrid(startX, startY, viewportWidth, viewportHeight);
	}
}