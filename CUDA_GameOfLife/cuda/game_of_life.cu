// CUDA includes
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include "common_functions.h"
#include "driver_types.h"

// System includes
#include <iostream>

// Local includes
#include "device_buffer.h"


#define NUM_THREADS_PER_BLOCK 1024


namespace CUDASimulation {
	// Grid of Game of Life, to be allocated on the device (GPU)
	// Two are required to save redundant copying of data
	// Static to keep it local to this file
	static SimulationBuffers_t simumationBuffers;

	__device__ __forceinline__ int calcIdx(int row, int numCols, int col)
	{
		return row * numCols + col;
	}

	/**
	* @brief This CUDA kernel intializes the grid with random values for the cell states
	*/
	__global__ void intializeGridRandom(uint8_t* dGrid, const int totalCells) {
		int idx = blockIdx.x * blockDim.x + threadIdx.x;

		// guard against out-of-bounds access (necessary as last thread block may be partial)
		if (idx >= totalCells) return;  

		//REFACTOR Use cuRAND 
		dGrid[idx] = (idx * 1664525u + 1013904223u) >> 31;  // 0 or 1
	}

	void init(int gridWidth, int gridHeight) {
		const int totalCells = gridWidth * gridHeight;
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
		constexpr int blockMatrixSize = NUM_THREADS_PER_BLOCK * NUM_THREADS_PER_BLOCK;
		constexpr size_t sharedMemSize = sizeof(int) * blockMatrixSize;
		intializeGridRandom << <numBlocks, NUM_THREADS_PER_BLOCK, blockMatrixSize >> > (simumationBuffers.current.ptr, totalCells);

		err = cudaGetLastError();
		if (err != cudaSuccess) std::cerr << cudaGetErrorString(err) << std::endl;

		// Record the stop event
		cudaEventRecord(stop);
		// Wait for the stop event to complete
		cudaEventSynchronize(stop);
		// Calculate the elapsed time
		float milliseconds = 0;
		cudaEventElapsedTime(&milliseconds, start, stop);
		std::cout << "Runtime for initialization with grid dimension " << gridWidth << " x " << gridHeight << ": " << milliseconds << std::endl;
		// Cleanup events
		cudaEventDestroy(start);
		cudaEventDestroy(stop);
	}

	void advance() {

	}
}