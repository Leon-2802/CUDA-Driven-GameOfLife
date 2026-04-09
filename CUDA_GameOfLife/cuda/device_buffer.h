#include <utility>
#include "cuda_runtime.h"

/**
* @brief A simple RAII wrapper for the Game Of Life grid
*/
struct DeviceGridBuffer {
    uint8_t* ptr = nullptr;
    size_t   size = 0;

    DeviceGridBuffer(size_t n) { cudaMalloc(&ptr, n); size = n; }
    ~DeviceGridBuffer() { cudaFree(ptr); }

    // Disable copy, allow move
    DeviceGridBuffer(const DeviceGridBuffer&) = delete;
    DeviceGridBuffer& operator=(const DeviceGridBuffer&) = delete;
} typedef DeviceGridBuffer_t;

/**
* @brief We want to keep the two generation buffers to be cuppled and only be used as a pair
*/
struct SimulationBuffers {
    DeviceGridBuffer_t current;
    DeviceGridBuffer_t next;

    SimulationBuffers(size_t n) : current(n), next(n) {}

    // Swapping the pointers between the two generation buffers after each iteration is a lot cheaper than copying data
    void swap() {
        std::swap(current.ptr, next.ptr);
    }
} typedef SimulationBuffers_t;