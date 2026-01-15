#include <window.hpp>

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CAMetalLayer.h>
#import <objc/runtime.h>
#import <Metal/Metal.h>


// Timer for render loop
@interface RenderTimer : NSObject
@property (nonatomic, copy) BOOL (^renderCallback)(void);
- (void)tick: (NSTimer*)timer;
@end

@implementation RenderTimer
- (void)tick: (NSTimer*)timer
{
    if (self.renderCallback) {
        if (!self.renderCallback()) {
            [NSApp terminate:nil];
        }
    }
}
@end

// Custom view that handles events
@interface EventView : NSView
{
    @public
    WindowCallbacks* callbacks;
    std::unordered_map<unsigned short, bool>* keyStates;
    float lastMouseX;
    float lastMouseY;
}
@end

@implementation EventView

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)keyDown:(NSEvent*)event
{
    unsigned short keyCode = [event keyCode];
    (*keyStates)[keyCode] = true;
    
    if (callbacks && callbacks->onKey) {
        KeyEvent keyEvent;
        keyEvent.keyCode = keyCode;
        keyEvent.isPressed = true;
        keyEvent.shift = ([event modifierFlags] & NSEventModifierFlagShift)   != 0;
        keyEvent.ctrl =  ([event modifierFlags] & NSEventModifierFlagControl) != 0;
        keyEvent.alt =   ([event modifierFlags] & NSEventModifierFlagOption)  != 0;
        keyEvent.cmd =   ([event modifierFlags] & NSEventModifierFlagCommand) != 0;
        callbacks->onKey(keyEvent);
    }
}

- (void)keyUp:(NSEvent*)event
{
    unsigned short keyCode = [event keyCode];
    (*keyStates)[keyCode] = false;
    
    if (callbacks && callbacks->onKey) {
        KeyEvent keyEvent;
        keyEvent.keyCode = keyCode;
        keyEvent.isPressed = false;
        keyEvent.shift = ([event modifierFlags] & NSEventModifierFlagShift)   != 0;
        keyEvent.ctrl =  ([event modifierFlags] & NSEventModifierFlagControl) != 0;
        keyEvent.alt =   ([event modifierFlags] & NSEventModifierFlagOption)  != 0;
        keyEvent.cmd =   ([event modifierFlags] & NSEventModifierFlagCommand) != 0;
        callbacks->onKey(keyEvent);
    }
}

- (void)mouseDown:(NSEvent*)event
{
    if (callbacks && callbacks->onMouseButton) {
        NSPoint point = [event locationInWindow];
        MouseButtonEvent mouseEvent;
        mouseEvent.button = 0;
        mouseEvent.isPressed = true;
        mouseEvent.x = point.x;
        mouseEvent.y = point.y;
        callbacks->onMouseButton(mouseEvent);
    }
}

- (void)mouseUp:(NSEvent*)event
{
    if (callbacks && callbacks->onMouseButton) {
        NSPoint point = [event locationInWindow];
        MouseButtonEvent mouseEvent;
        mouseEvent.button = 0;
        mouseEvent.isPressed = false;
        mouseEvent.x = point.x;
        mouseEvent.y = point.y;
        callbacks->onMouseButton(mouseEvent);
    }
}

- (void)rightMouseDown:(NSEvent*)event
{
    if (callbacks && callbacks->onMouseButton) {
        NSPoint point = [event locationInWindow];
        MouseButtonEvent mouseEvent;
        mouseEvent.button = 1;
        mouseEvent.isPressed = true;
        mouseEvent.x = point.x;
        mouseEvent.y = point.y;
        callbacks->onMouseButton(mouseEvent);
    }
}

- (void)rightMouseUp:(NSEvent*)event
{
    if (callbacks && callbacks->onMouseButton) {
        NSPoint point = [event locationInWindow];
        MouseButtonEvent mouseEvent;
        mouseEvent.button = 1;
        mouseEvent.isPressed = false;
        mouseEvent.x = point.x;
        mouseEvent.y = point.y;
        callbacks->onMouseButton(mouseEvent);
    }
}

- (void)mouseMoved:(NSEvent*)event
{
    if (callbacks && callbacks->onMouseMove) {
        NSPoint point = [event locationInWindow];
        MouseMoveEvent mouseEvent;
        mouseEvent.x = point.x;
        mouseEvent.y = point.y;
        mouseEvent.deltaX = point.x - lastMouseX;
        mouseEvent.deltaY = point.y - lastMouseY;
        lastMouseX = point.x;
        lastMouseY = point.y;
        callbacks->onMouseMove(mouseEvent);
    }
}

- (void)mouseDragged:(NSEvent*)event
{
    [self mouseMoved: event];
}

- (void)rightMouseDragged:(NSEvent*)event
{
    [self mouseMoved: event];
}

- (void)scrollWheel:(NSEvent*)event
{
    if (callbacks && callbacks->onScroll) {
        ScrollEvent scrollEvent;
        scrollEvent.deltaX = [event scrollingDeltaX];
        scrollEvent.deltaY = [event scrollingDeltaY];
        callbacks->onScroll(scrollEvent);
    }
}

@end

// Window delegate for window events
@interface WindowDelegate : NSObject<NSWindowDelegate>
{
    @public
    WindowCallbacks* callbacks;
    NSWindow* window;
}
@end

@implementation WindowDelegate

- (void)windowWillClose:(NSNotification*)notification
{
    [NSApp terminate: nil];
}

- (void)windowDidResize:(NSNotification*)notification
{
    if (callbacks && callbacks->onResize) {
        NSRect frame = [[window contentView] frame];
        WindowResizeEvent event;
        event.width = (int)frame.size.width;
        event.height = (int)frame.size.height;
        callbacks->onResize(event);
        
        // Also update Metal layer size
        CAMetalLayer* layer = (CAMetalLayer*)[[window contentView] layer];
        layer.drawableSize = CGSizeMake(frame.size.width, frame.size.height);
    }
}

@end


Window::Window(int width, int height, const char* title)
{
    NSWindow* window = [[NSWindow alloc] 
        initWithContentRect: NSMakeRect(0, 0, width, height)
        styleMask: (NSWindowStyleMaskTitled | 
                    NSWindowStyleMaskClosable |
                    NSWindowStyleMaskResizable |
                    NSWindowStyleMaskMiniaturizable)
        backing: NSBackingStoreBuffered
        defer: NO];
    
    [window setTitle: [NSString stringWithUTF8String: title]];
    [window center];
    [window setReleasedWhenClosed: NO];
    [window setAcceptsMouseMovedEvents: YES];
    
    // Create delegate
    WindowDelegate* windowDelegate = [[WindowDelegate alloc] init];
    windowDelegate->window = window;
    [window setDelegate: windowDelegate];
    
    // Create custom view for event handling
    EventView* view = [[EventView alloc] initWithFrame:NSMakeRect(0, 0, width, height)];
    
    // Create a Metal layer
    CAMetalLayer* layer = [CAMetalLayer layer];
    layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    layer.device = MTLCreateSystemDefaultDevice();
    layer.drawableSize = CGSizeMake(width, height);
    
    [view setWantsLayer: YES];
    [view setLayer: layer];
    
    // Set the custom view as the window's content view
    [window setContentView: view];
    
    // Make the view the first responder so it receives events
    [window makeFirstResponder: view];
    
    impl        = (void*)window;
    metalLayer  = (void*)layer;
    timer       = nullptr;
    delegate    = (void*)windowDelegate;
    eventView   = (void*)view;
    callbacks   = new WindowCallbacks();
    keyStates   = new std::unordered_map<unsigned short, bool>();
    
    // Wire up the view to our callbacks
    view->callbacks = callbacks;
    view->keyStates = keyStates;
}

Window::~Window()
{
    if (timer) {
        [(NSTimer*)timer invalidate];
        [(RenderTimer*)[(NSTimer*)timer userInfo] release];
    }
    
    delete callbacks;
    delete keyStates;
    
    EventView* view = (EventView*)eventView;
    [view release];
    
    WindowDelegate* windowDelegate = (WindowDelegate*)delegate;
    [windowDelegate release];
    
    NSWindow* window = (NSWindow*)impl;
    [window release];
}

void
Window::show()
{
    NSWindow* window = (NSWindow*)impl;
    [window makeKeyAndOrderFront: nil];
}

void
Window::run(const WindowCallbacks& userCallbacks)
{
    NSApplication *app = [NSApplication sharedApplication];
    [app setActivationPolicy: NSApplicationActivationPolicyRegular];
    
    NSWindow* window = (NSWindow*)impl;
    WindowDelegate* windowDelegate = (WindowDelegate*)delegate;
    
    // Copy callbacks to our internal storage
    *callbacks = userCallbacks;
    windowDelegate->callbacks = callbacks;
    
    [window setIsVisible: YES];
    [window makeKeyAndOrderFront: nil];
    [app activateIgnoringOtherApps: YES];
    
    if (callbacks->onRender) {
        RenderTimer* timerObj = [[RenderTimer alloc] init];
        timerObj.renderCallback = ^BOOL() {
            return callbacks->onRender();
        };
        
        NSTimer* nsTimer = [NSTimer scheduledTimerWithTimeInterval: 1.0/60.0
            target: timerObj
            selector: @selector(tick:)
            userInfo: timerObj
            repeats: YES];

        timer = (void*)nsTimer;
    }
    
    [app run];
}

void
Window::run(std::function<bool()> renderCallback)
{
    WindowCallbacks callbacks;
    callbacks.onRender = renderCallback;
    run(callbacks);
}

void*
Window::getNativeHandle() const
{ return impl; }

void*
Window::getMetalLayerHandle() const
{ return metalLayer; }

void
Window::getSize(int& width, int& height) const
{
    NSWindow* window = (NSWindow*)impl;
    NSRect frame = [[window contentView] frame];
    width = (int)frame.size.width;
    height = (int)frame.size.height;
}

void
Window::getMousePosition(float& x, float& y) const
{
    NSWindow* window = (NSWindow*)impl;
    NSPoint point = [window mouseLocationOutsideOfEventStream];
    x = point.x;
    y = point.y;
}

bool
Window::isKeyPressed(unsigned short keyCode) const
{
    auto it = keyStates->find(keyCode);
    return it != keyStates->end() && it->second;
}

void
Window::quit()
{
    [NSApp terminate: nil];
}
