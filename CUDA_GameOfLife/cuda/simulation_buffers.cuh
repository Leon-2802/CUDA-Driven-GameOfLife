#pragma once
#include <utility>
#include <optional>
#include <vector>
#include "device_buffer.cuh"

namespace CUDASimulation {
    /**
    * @brief We want to keep the two generation buffers to be cuppled and only be used as a pair
    */
    class SimulationBuffers {
    public:
        SimulationBuffers(int width, int height) : current_(width, height), next_(width, height), width_(width), height_(height) {}

        uint8_t* currentPtr() const { return current_.ptr; }
        uint8_t* nextPtr() const { return next_.ptr; }
        int width() const { return width_ - 2; } // return width without padding
        int height() const { return height_ - 2; } // return height without padding
        int paddedWidth() const { return width_; }
        int paddedHeight() const { return height_; }

        std::optional<std::vector<uint8_t>> subgrid(int startX, int startY, int subgridWidth, int subgridHeight) const {
            return current_.extractSubgrid(startX, startY, subgridWidth, subgridHeight);
        }

        // Swapping the pointers between the two generation buffers after each iteration is a lot cheaper than copying data
        void swap() {
            std::swap(current_.ptr, next_.ptr);
        }

        void clearCurrent() {
            current_.clearGrid();
        }
        void clearNext() {
            next_.clearGrid();
        }
    private:
        DeviceGridBuffer_t current_;
        DeviceGridBuffer_t next_;
        int width_;
        int height_;
    };
}