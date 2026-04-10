## 1. Set up
- Seperate graphics (sdl) from the underlying game of life logic in cuda
- Started with a CUDA kernel that intializes the grid with each thread processing one cell 
	- For very large grids (>65535 blocks) probably need each thread to compute more than one cell
	- Great results during intial tests: Speedup factor of 3945 compared to the C# version for a grid size of 10_000 x 10_000
- Use two grid buffers on the device that can be swapped to save on memory copy operation each generation