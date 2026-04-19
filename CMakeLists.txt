cmake_minimum_required(VERSION 3.20)
project(CUDA_GoL LANGUAGES CXX CUDA)

# Set C++ & CUDA standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)

file(GLOB_RECURSE SRC_CPP CONFIGURE_DEPENDS "CUDA_GameOfLife/*.cpp" "CUDA_GameOfLife/*.cxx" "CUDA_GameOfLife/*.hpp") 
file(GLOB_RECURSE SRC_CU CONFIGURE_DEPENDS "CUDA_GameOfLife/*.cu")

list(APPEND SOURCES ${SRC_CPP} ${SRC_CU})
add_executable(CUDA_GameOfLife ${SOURCES})

target_include_directories(CUDA_GameOfLife PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/CUDA_GameOfLife)
set_target_properties(CUDA_GameOfLife PROPERTIES CUDA_SEPARABLE_COMPILATION ON)
target_compile_options(CUDA_GameOfLife PRIVATE $<$<COMPILE_LANGUAGE:CUDA>:-std=c++17> )

find_package(SDL3 QUIET)
if (SDL3_FOUND) 
    message(STATUS "SDL3 found: ${SDL3_VERSION}")
    message(STATUS "SDL3 include: ${SDL3_INCLUDE_DIRS}")
    message(STATUS "SDL3 libs: ${SDL3_LIBRARIES}")
	target_link_libraries(CUDA_GameOfLife PRIVATE SDL3::SDL3) 
else() 
    # Manual fallback
    if(SDL3_INCLUDE_DIR AND SDL3_LIBRARY)
        target_include_directories(CUDA_GameOfLife PRIVATE ${SDL3_INCLUDE_DIR})
        target_link_libraries(CUDA_GameOfLife PRIVATE ${SDL3_LIBRARY})
        message(STATUS "Using manually specified SDL3")
    else()
        message(FATAL_ERROR "SDL3 not found. Install via vcpkg or set SDL3_INCLUDE_DIR and SDL3_LIBRARY.")
    endif()
endif()