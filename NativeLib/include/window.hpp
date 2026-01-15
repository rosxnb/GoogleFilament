#pragma once
#include <functional>

class Window
{
public:
    Window(int width, int height, char const* title);
    ~Window();

    void show();
    void run(std::function<bool()> renderCallback = nullptr);

    void* getNativeHandle() const;
    void* getMetalLayerHandle() const;

    void debugPrintHandle();
    
private:
    void* impl;
    void* metalLayer;
    void* timer;
};
