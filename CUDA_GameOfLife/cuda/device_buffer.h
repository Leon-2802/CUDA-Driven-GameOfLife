#pragma once
#include <utility>
#include "cuda_runtime.h"

namespace CUDASimulation {
    /**
    * @brief A simple RAII wrapper for the Game Of Life grid
    */
    struct DeviceGridBuffer {
        uint8_t* ptr = nullptr;
        size_t   size = 0;

        DeviceGridBuffer(size_t n) { cudaMalloc((void**)&ptr, n); size = n; }
        ~DeviceGridBuffer() { cudaFree(ptr); }

        // Disable copy, allow move
        DeviceGridBuffer(const DeviceGridBuffer&) = delete;
        DeviceGridBuffer& operator=(const DeviceGridBuffer&) = delete;
    } typedef DeviceGridBuffer_t;

    /**
    * @brief We want to keep the two generation buffers to be cuppled and only be used as a pair
    */
    class SimulationBuffers {
    public:
        SimulationBuffers(int width, int height) : current_(width*height), next_(width*height), width_(width), height_(height) {}

        uint8_t* currentPtr() const { return current_.ptr; }
        uint8_t* nextPtr() const { return next_.ptr; }
        int width() const { return width_; }
        int height() const { return height_; }

        // Swapping the pointers between the two generation buffers after each iteration is a lot cheaper than copying data
        void swap() {
            std::swap(current_.ptr, next_.ptr);
        }
    private:
        DeviceGridBuffer_t current_;
        DeviceGridBuffer_t next_;
        int width_;
        int height_;
    };
}