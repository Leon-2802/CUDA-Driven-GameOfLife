## 1. Set up
- Seperate graphics (SDL3) from the underlying game of life logic in cuda
- Started with a CUDA kernel that intializes the grid with each thread processing one cell 
	- For very large grids (>65535 blocks) probably need each thread to compute more than one cell
	- Great results during intial tests for a grid size of 10_000 x 10_000: 
	- Speedup factor of 3945 compared to the sequential C# grid initialization 
- Use two grid buffers on the device that can be swapped to save on memory copy operation each generation
- Allocate the grid data solely on the GPU

## 2. Intial implementation of the advance step calculation
- Only copy the data visible in the current viewport to the CPU each step

## Possible further optimization
- Pinned memory (cudaMallocHost)?
- Less threads per block, each thread in block handles a few cells
- Asynchronous memory management and streams