#pragma once

class Window
{
public:
    Window(int width, int height, const char* title);
    ~Window();

    void show();
    void run();

private:
    void* impl;
};
