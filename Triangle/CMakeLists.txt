add_executable(triangle
    src/main.cpp
)

target_link_libraries(triangle
    PRIVATE
        nativelib
        filament
        backend
        utils
        math
        "-framework Metal"
        "-framework QuartzCore"
        "-framework Cocoa"
)

target_include_directories(triangle
    PRIVATE
        ${CMAKE_SOURCE_DIR}/external/filament/libs
        ${CMAKE_SOURCE_DIR}/NativeLib/include
        ${CMAKE_CURRENT_SOURCE_DIR}/cpp
)
