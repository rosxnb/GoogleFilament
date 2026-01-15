add_library(nativelib
    OBJECT
        src/window.mm
)

target_link_libraries(nativelib
    PRIVATE
        "-framework Cocoa"
)

target_include_directories(nativelib
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_compile_options(nativelib
    PRIVATE
        $<$<COMPILE_LANGUAGE:OBJCXX>:-fno-objc-arc>
)
