#pragma once
#include <vector>
#include <cstdint>
#include <optional>
#include <iostream>
#include <cuda_runtime_api.h>
#include <driver_types.h>

namespace CUDASimulation {

    /**
    * @brief A simple RAII wrapper for the Game Of Life grid on the device (GPU)
    */
    struct DeviceGridBuffer {
        uint8_t* ptr = nullptr;
        size_t   size = 0;
        int      gridWidth = 0;
        int      gridHeight = 0;

        DeviceGridBuffer(int w, int h) { 
            gridWidth = w; 
            gridHeight = h; 
            size = static_cast<size_t>(w) * static_cast<size_t>(h); 
            cudaMalloc((void**)&ptr, size * sizeof(uint8_t)); 
            cudaMemset(ptr, 0, size * sizeof(uint8_t));
        }
        ~DeviceGridBuffer() { cudaFree(ptr); }

        // Disable copy, allow move
        DeviceGridBuffer(const DeviceGridBuffer&) = delete;
        DeviceGridBuffer& operator=(const DeviceGridBuffer&) = delete;

        // Extract a rectangular subgrid from the device buffer and return a host-allocated buffer
        std::optional<std::vector<uint8_t>> extractSubgrid(int startX, int startY, int width, int height) const {
            // Sanity checking to the bounds of the game of life grid
            if (startX < 0 || startX + width > gridWidth || startY < 0 || startY + height > gridHeight) {
                return std::nullopt;
            }

            std::vector<uint8_t> hostBuf(width * height);

            uint8_t* deviceStartCell = ptr + startY * gridWidth + startX;

            // Copies a matrix in one batch
            cudaMemcpy2D(
                hostBuf.data(), // destination
                width * sizeof(uint8_t), // destination stride
                deviceStartCell, // src start
                gridWidth * sizeof(uint8_t), // src stride
                width * sizeof(uint8_t), // bytes per row to copy
                height, // number of rows
                cudaMemcpyDeviceToHost
            );

            cudaError_t err = cudaGetLastError();
            if (err != cudaSuccess) std::cerr << cudaGetErrorString(err) << std::endl;

            return hostBuf;
        }

        void clearGrid() const {
            cudaMemset(ptr, 0, size * sizeof(uint8_t));
        }
    };
    using DeviceGridBuffer_t = DeviceGridBuffer;
}