### 1. Set up
- Seperate graphics (sdl) from the underlying game of life logic in cuda
- Started with a CUDA kernel that intializes the grid with each thread processing one cell 
	- For very large grids (>65535 blocks) probably need each thread to compute more than one cell
- Use two grid buffers on the device that can be swapped to save on memory copy operation each generation