cmake_minimum_required(VERSION 4.0)
project(filament_triangle LANGUAGES CXX OBJCXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

if(APPLE)
    add_compile_options(-Wno-deprecated-declarations)
    add_compile_options(-Wno-error=deprecated-declarations)
    # set(FILAMENT_ENABLE_WERROR OFF CACHE BOOL "" FORCE)
endif()

set(BUILD_TESTING OFF CACHE BOOL "" FORCE)

set(FILAMENT_ENABLE_SAMPLES OFF CACHE BOOL "" FORCE)
set(FILAMENT_ENABLE_TESTS   OFF CACHE BOOL "" FORCE)
set(FILAMENT_ENABLE_TOOLS   OFF CACHE BOOL "" FORCE)

set(FILAMENT_BACKEND METAL CACHE STRING "" FORCE)

set(FILAMENT_SUPPORTS_METAL ON CACHE BOOL "" FORCE)
set(FILAMENT_SUPPORTS_OPENGL ON CACHE BOOL "" FORCE)

add_subdirectory(external/filament EXCLUDE_FROM_ALL)

# find_package(glfw3 CONFIG REQUIRED)

add_subdirectory(NativeLib)
add_subdirectory(Triangle)
