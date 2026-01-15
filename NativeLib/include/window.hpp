#pragma once
#include <functional>
#include <unordered_map>

// Event structures
struct KeyEvent {
    unsigned short keyCode;
    bool isPressed;  // true for press, false for release
    bool shift;
    bool ctrl;
    bool alt;
    bool cmd;
};

struct MouseButtonEvent {
    int button;  // 0=left, 1=right, 2=middle
    bool isPressed;
    float x, y;
};

struct MouseMoveEvent {
    float x, y;
    float deltaX, deltaY;
};

struct ScrollEvent {
    float deltaX, deltaY;
};

struct WindowResizeEvent {
    int width, height;
};

// Event callbacks
struct WindowCallbacks {
    std::function<void(const KeyEvent&)> onKey;
    std::function<void(const MouseButtonEvent&)> onMouseButton;
    std::function<void(const MouseMoveEvent&)> onMouseMove;
    std::function<void(const ScrollEvent&)> onScroll;
    std::function<void(const WindowResizeEvent&)> onResize;
    std::function<bool()> onRender;  // Return false to quit
};

class Window
{
public:
    Window(int width, int height, char const* title);
    ~Window();

    void show();
    void run(const WindowCallbacks& callbacks);
    void run(std::function<bool()> renderCallback = nullptr);

    void* getNativeHandle() const;
    void* getMetalLayerHandle() const;
    
    void getSize(int& width, int& height) const;
    void getMousePosition(float& x, float& y) const;
    bool isKeyPressed(unsigned short keyCode) const;
    
    // Request the application to quit
    void quit();
    
private:
    void*                                       impl;        // NSWindow
    void*                                       metalLayer;  // CAMetalLayer
    void*                                       timer;
    void*                                       delegate;    // Window delegate for events
    void*                                       eventView;   // Custom view for event handling
    WindowCallbacks*                            callbacks;   // Store callbacks
    std::unordered_map<unsigned short, bool>*   keyStates;   // Key state tracking
};

// Common macOS key codes for convenience
namespace KeyCode
{
    constexpr unsigned short A = 0x00;
    constexpr unsigned short S = 0x01;
    constexpr unsigned short D = 0x02;
    constexpr unsigned short F = 0x03;
    constexpr unsigned short H = 0x04;
    constexpr unsigned short G = 0x05;
    constexpr unsigned short Z = 0x06;
    constexpr unsigned short X = 0x07;
    constexpr unsigned short C = 0x08;
    constexpr unsigned short V = 0x09;
    constexpr unsigned short B = 0x0B;
    constexpr unsigned short Q = 0x0C;
    constexpr unsigned short W = 0x0D;
    constexpr unsigned short E = 0x0E;
    constexpr unsigned short R = 0x0F;
    constexpr unsigned short Y = 0x10;
    constexpr unsigned short T = 0x11;
    
    constexpr unsigned short Space = 0x31;
    constexpr unsigned short Return = 0x24;
    constexpr unsigned short Escape = 0x35;
    constexpr unsigned short Delete = 0x33;
    constexpr unsigned short Tab = 0x30;
    
    constexpr unsigned short LeftArrow = 0x7B;
    constexpr unsigned short RightArrow = 0x7C;
    constexpr unsigned short DownArrow = 0x7D;
    constexpr unsigned short UpArrow = 0x7E;
}
