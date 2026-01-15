#include <window.hpp>

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CAMetalLayer.h>
#import <objc/runtime.h>


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
    
    // Create a Metal layer
    CAMetalLayer* layer = [CAMetalLayer layer];
    layer.bounds = CGRectMake(0, 0, width, height);
    layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    // Set the layer as the window's content view layer
    NSView* contentView = [window contentView];
    [contentView setWantsLayer: YES];
    [contentView setLayer: layer];
    
    impl        = (void*)window;
    metalLayer  = (void*)layer;
    timer       = nullptr;
}

Window::~Window()
{
    if (timer) {
        [(NSTimer*)timer invalidate];
        [(RenderTimer*)[(NSTimer*)timer userInfo] release];
    }
    
    // Release the Metal layer
    CAMetalLayer* layer = (CAMetalLayer*)metalLayer;
    [layer release];
    
    NSWindow* window = (NSWindow*)impl;
    [window release];
}

void
Window::show()
{
    [(NSWindow*)impl makeKeyAndOrderFront: nil];
}

void
Window::run(std::function<bool()> renderCallback)
{
    NSApplication *app = [NSApplication sharedApplication];
    [app setActivationPolicy: NSApplicationActivationPolicyRegular];
    
    NSWindow* window = (NSWindow*)impl;
    [window setIsVisible: YES];
    [app activateIgnoringOtherApps: YES];
    
    [[NSNotificationCenter defaultCenter] 
        addObserverForName: NSWindowWillCloseNotification 
        object: window
        queue: nil
        usingBlock: ^(NSNotification *note) {
            [NSApp terminate:nil];
        }];
    
    if (renderCallback) {
        RenderTimer* timerObj = [[RenderTimer alloc] init];
        timerObj.renderCallback = ^BOOL() {
            return renderCallback();
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

void*
Window::getNativeHandle() const
{ return impl; }

void*
Window::getMetalLayerHandle() const
{ return metalLayer; }

void
Window::debugPrintHandle()
{
    void* handle = metalLayer;
    id obj = (__bridge id)handle;
    printf("Handle pointer: %p\n", handle);
    printf("Object class: %s\n", object_getClassName(obj));
    printf("Is CAMetalLayer: %d\n", [obj isKindOfClass:[CAMetalLayer class]]);
    printf("Is NSWindow: %d\n", [obj isKindOfClass:[NSWindow class]]);
}
