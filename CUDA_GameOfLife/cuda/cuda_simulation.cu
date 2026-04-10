// CUDA includes
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include "common_functions.h"
#include "driver_types.h"

// System includes
#include <iostream>
#include <memory>
#include <chrono>

// Local includes
#include "device_buffer.h"
#include "cuda_simulation.h"




namespace CUDASimulation {

#define NUM_THREADS_PER_BLOCK 1024

	// Grid of Game of Life, to be allocated on the device (GPU)
	// Two are required to save redundant copying of data
	// Static to keep it local to this file
	static std::shared_ptr<SimulationBuffers> simumationBuffers = nullptr;

	/**
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
	__global__ void initializeGridRandom(uint8_t* dGrid, const int totalCells, uint32_t seed) {
		int idx = blockIdx.x * blockDim.x + threadIdx.x;

		// guard against out-of-bounds access (necessary as last thread block may be partial)
		if (idx >= totalCells) return;  

		// Aquire random value based on current position
		dGrid[idx] = squirrel3(idx, seed) >> 31; // 0 or 1
	}

	/**
	* @brief Calculates the state of each cell on a seperate thread by reading neighbour cell states from global memory
	*/
	__global__ void calculateNextGeneration(uint8_t* dGrid, const int width, const int height) {
		// REFACTOR: Add shared memory later to lower slow global memory traffic
	}

	void init(int gridWidth, int gridHeight) {
		const int totalCells = gridWidth * gridHeight;
		simumationBuffers = std::make_shared<SimulationBuffers>(gridWidth, gridHeight);
		// Check for errors after allocating:
		cudaError_t err = cudaGetLastError();
		if (err != cudaSuccess) std::cerr << cudaGetErrorString(err) << std::endl;

		// Create CUDA events for timing
		cudaEvent_t start, stop;
		cudaEventCreate(&start);
		cudaEventCreate(&stop);
		// Record the start event
		cudaEventRecord(start);

		// Each thread covers one cell; ceiling division ensures every cell gets covered
		const int numBlocks = (totalCells + NUM_THREADS_PER_BLOCK - 1) / NUM_THREADS_PER_BLOCK;
		// Aquire the seed based on current time in nanoseconds
		const uint32_t seed = static_cast<uint32_t>(std::chrono::high_resolution_clock::now().time_since_epoch().count());
		// Run the kernel
		initializeGridRandom << <numBlocks, NUM_THREADS_PER_BLOCK >> > (simumationBuffers->currentPtr(), totalCells, seed);

		err = cudaGetLastError();
		if (err != cudaSuccess) std::cerr << cudaGetErrorString(err) << std::endl;

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

	void advance() {
		const int totalCells = simumationBuffers->width() * simumationBuffers->height();

		// Create CUDA events for timing
		cudaEvent_t start, stop;
		cudaEventCreate(&start);
		cudaEventCreate(&stop);
		// Record the start event
		cudaEventRecord(start);

		// Each thread covers one cell; ceiling division ensures every cell gets covered
		const int numBlocks = (totalCells + NUM_THREADS_PER_BLOCK - 1) / NUM_THREADS_PER_BLOCK;

		cudaError_t err = cudaGetLastError();
		if (err != cudaSuccess) std::cerr << cudaGetErrorString(err) << std::endl;

		// Record the stop event
		cudaEventRecord(stop);
		// Wait for the stop event to complete
		cudaEventSynchronize(stop);
		// Calculate the elapsed time
		float milliseconds = 0;
		cudaEventElapsedTime(&milliseconds, start, stop);
		std::cout << "Runtime for advance step with grid dimension " << simumationBuffers->width() << " x " << simumationBuffers->height() << " in milliseconds: " << milliseconds << std::endl;
		// Cleanup events
		cudaEventDestroy(start);
		cudaEventDestroy(stop);
	}

	std::vector<bool> getViewportData(int startX, int startY, int viewportWidth, int viewportHeight) {
		std::vector<bool> subgrid;
		// Reserve the necessary space of the subgrid (note that the origin of the grid is at the top left corner of the screen)
		subgrid.reserve((viewportWidth - startX) * (viewportHeight - startY));
		//TODO memcpy from simumationBuffers->currentPtr to subgrid
		return subgrid;
	}
}