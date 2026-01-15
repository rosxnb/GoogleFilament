#import <Cocoa/Cocoa.h>
#include <window.hpp>


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
    
    [window setTitle:[NSString stringWithUTF8String: title]];
    [window center];
    [window setReleasedWhenClosed: NO]; // Managing memory manually
    impl = (void*)window;
}

Window::~Window()
{
    NSWindow* window = (NSWindow*)impl;
    [window release];
}

void Window::show()
{
    [(NSWindow*)impl makeKeyAndOrderFront: nil];
}


void Window::run()
{
    NSApplication *app = [NSApplication sharedApplication];
    [app setActivationPolicy: NSApplicationActivationPolicyRegular];

    NSWindow* window = (NSWindow*)impl;
    [window setIsVisible: YES];

    [app activateIgnoringOtherApps: YES];

    // Terminate app when last window closes
    [[NSNotificationCenter defaultCenter]
        addObserverForName: NSWindowWillCloseNotification
        object: window
        queue: nil
        usingBlock: ^(NSNotification* note) {
            [NSApp terminate: nil];
        }];

    [app run];
}
