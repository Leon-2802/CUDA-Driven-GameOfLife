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
- Around 6.8ms per advance step (with blockSize 16x16) -> Speedup of 5137 compared to sequential C# advance-step, and 549 times faster than parallel C# advance-step
### Trying out bigger problem sizes:
- 20_000 x 20_000: Around 31ms -> 0.2 times slower than for 10_000 x 10_000 
	- GPU usage: 34%
	- 1GB VRAM occupied
- 30_000 x 30_000: Around 51.5ms
	- GPU usage: 51-52%
	- 1.9 GB VRAM occupied
- 40_000 x 40_000: Around 93/94ms, rare spikes slightly above 100ms -> **Current maximum problem size!**
	- GPU usage: 91-92%
	- 3.2 GB VRAM occupied (1.6GB for each simulation buffer)

## Possible further optimization
- Pinned memory (cudaMallocHost)?
- Less threads per block, each thread in block handles a few cells
- Asynchronous memory management and streams