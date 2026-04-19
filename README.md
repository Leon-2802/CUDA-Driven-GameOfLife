# CUDA_GameOfLife
## About
Work in Progress!

This project is a continuation of my [prior implementation](https://github.com/Leon-2802/GameOfLife) of Conway's Game Of Life in C#. Here the goal is to pick up where I left of: Increase performance and problem size through the means of parallel computing.
### My goals in this project
- Implement the Game Of Life in CUDA C++ with a focus on performance and scalability.
- Develop a clean architecture that allows for easy maintenance and future enhancements.
- Learn and apply best practices in CUDA programming, including memory management and optimization techniques.
### Expected challenges
- Efficiently managing memory and data transfer between the CPU and GPU.
	- Keeping the stored state of the game as small as possible to allow for larger problem sizes.
	- Only transfer the necessary data back to the CPU each generation to minimize overhead.
- Difficult testing and debugging of CUDA code, especially when it comes to performance optimization.
- Difficult to design a clean architecture from the start, probably will have to refactor the code multiple times as I learn more about CUDA and how to best structure the code for performance and maintainability.
### Architecture
- The frontend is written with help of the SDL3 graphics library
- The simulation runs with CUDA via the use of CUDA kernels that run on the GPU using millions of threads
- Only the relevant data of the current viewport is passed to the frontend for rendering
## Experience and learnings
Here I list my experience and  learnings as I work on this project. This will include both technical learnings about CUDA programming and general software development practices. A detailed step-by-step report of my development progress can be found in the [project report](./project_report.md).