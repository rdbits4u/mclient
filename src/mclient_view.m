
#include <poll.h>
#include <librdpc.h>
#include <libsvc.h>
#include <libcliprdr.h>
#include <librdpsnd.h>
#include <rfxcodec_decode.h>
#import <Cocoa/Cocoa.h>
#import "mclient_app_delegate.h"
#import "mclient_view.h"
#import "mclient_window.h"
#import "rdpc_session.h"
#import "mclient_log.h"

//*****************************************************************************
static struct rdp_key_code_t
setkc(uint16_t code, uint16_t flags0, uint16_t flags1)
{
    struct rdp_key_code_t kc;
    kc.code = code;
    kc.flags[0] = flags0;
    kc.flags[1] = flags1;
    kc.is_down = false;
    return kc;
}

@implementation MClientView

//*****************************************************************************
// /Library/Developer/CommandLineTools/SDKs/MacOSX15.5.sdk/System/Library
// /Frameworks/Carbon.framework/Versions/A/Frameworks/HIToolbox.framework
// /Versions/A/Headers/Events.h
-(MClientView*)initWithFrame:(CGRect)theFrame
{
    NSLog(@"MClientView initWithFrame:");
    self = [super initWithFrame:theFrame];
    if (self != nil)
    {
        keymap[0x00] = setkc(0x1E, 0x0000, 0x8000); // A            kVK_ANSI_A
        keymap[0x01] = setkc(0x1F, 0x0000, 0x8000); // S            kVK_ANSI_S
        keymap[0x02] = setkc(0x20, 0x0000, 0x8000); // D            kVK_ANSI_D
        keymap[0x03] = setkc(0x21, 0x0000, 0x8000); // F            kVK_ANSI_F
        keymap[0x04] = setkc(0x23, 0x0000, 0x8000); // H            kVK_ANSI_H
        keymap[0x05] = setkc(0x22, 0x0000, 0x8000); // G            kVK_ANSI_G
        keymap[0x06] = setkc(0x2C, 0x0000, 0x8000); // Z            kVK_ANSI_Z
        keymap[0x07] = setkc(0x2D, 0x0000, 0x8000); // X            kVK_ANSI_X
        keymap[0x08] = setkc(0x2E, 0x0000, 0x8000); // C            kVK_ANSI_C
        keymap[0x09] = setkc(0x2F, 0x0000, 0x8000); // V            kVK_ANSI_V
        // 0x0A                                                     kVK_ISO_Section
        keymap[0x0B] = setkc(0x30, 0x0000, 0x8000); // B            kVK_ANSI_B
        keymap[0x0C] = setkc(0x10, 0x0000, 0x8000); // Q            kVK_ANSI_Q
        keymap[0x0D] = setkc(0x11, 0x0000, 0x8000); // W            kVK_ANSI_W
        keymap[0x0E] = setkc(0x12, 0x0000, 0x8000); // E            kVK_ANSI_E
        keymap[0x0F] = setkc(0x13, 0x0000, 0x8000); // R            kVK_ANSI_R
        keymap[0x10] = setkc(0x15, 0x0000, 0x8000); // Y            kVK_ANSI_Y
        keymap[0x11] = setkc(0x14, 0x0000, 0x8000); // T            kVK_ANSI_T
        keymap[0x12] = setkc(0x02, 0x0000, 0x8000); // 1            kVK_ANSI_1
        keymap[0x13] = setkc(0x03, 0x0000, 0x8000); // 2            kVK_ANSI_2
        keymap[0x14] = setkc(0x04, 0x0000, 0x8000); // 3            kVK_ANSI_3
        keymap[0x15] = setkc(0x05, 0x0000, 0x8000); // 4            kVK_ANSI_4
        keymap[0x16] = setkc(0x07, 0x0000, 0x8000); // 6            kVK_ANSI_6
        keymap[0x17] = setkc(0x06, 0x0000, 0x8000); // 5            kVK_ANSI_5
        keymap[0x18] = setkc(0x0D, 0x0000, 0x8000); // =            kVK_ANSI_Equal
        keymap[0x19] = setkc(0x0A, 0x0000, 0x8000); // 9            kVK_ANSI_9
        keymap[0x1A] = setkc(0x08, 0x0000, 0x8000); // 7            kVK_ANSI_7
        keymap[0x1B] = setkc(0x0C, 0x0000, 0x8000); // -            kVK_ANSI_Minus
        keymap[0x1C] = setkc(0x09, 0x0000, 0x8000); // 8            kVK_ANSI_8
        keymap[0x1D] = setkc(0x0B, 0x0000, 0x8000); // 0            kVK_ANSI_0
        keymap[0x1E] = setkc(0x1B, 0x0000, 0x8000); // ]            kVK_ANSI_RightBracket
        keymap[0x1F] = setkc(0x18, 0x0000, 0x8000); // O            kVK_ANSI_O
        keymap[0x20] = setkc(0x16, 0x0000, 0x8000); // U            kVK_ANSI_U
        keymap[0x21] = setkc(0x1A, 0x0000, 0x8000); // [            kVK_ANSI_LeftBracket
        keymap[0x22] = setkc(0x17, 0x0000, 0x8000); // I            kVK_ANSI_I
        keymap[0x23] = setkc(0x19, 0x0000, 0x8000); // P            kVK_ANSI_P
        keymap[0x24] = setkc(0x1C, 0x0000, 0x8000); // enter        kVK_Return
        keymap[0x25] = setkc(0x26, 0x0000, 0x8000); // L            kVK_ANSI_L
        keymap[0x26] = setkc(0x24, 0x0000, 0x8000); // J            kVK_ANSI_J
        keymap[0x27] = setkc(0x28, 0x0000, 0x8000); // '            kVK_ANSI_Quote
        keymap[0x28] = setkc(0x25, 0x0000, 0x8000); // K            kVK_ANSI_K
        keymap[0x29] = setkc(0x27, 0x0000, 0x8000); // ;            kVK_ANSI_Semicolon
        keymap[0x2A] = setkc(0x2B, 0x0000, 0x8000); // backslash    kVK_ANSI_Backslash
        keymap[0x2B] = setkc(0x33, 0x0000, 0x8000); // ,            kVK_ANSI_Comma
        keymap[0x2C] = setkc(0x35, 0x0000, 0x8000); // /            kVK_ANSI_Slash
        keymap[0x2D] = setkc(0x31, 0x0000, 0x8000); // N            kVK_ANSI_N
        keymap[0x2E] = setkc(0x32, 0x0000, 0x8000); // M            kVK_ANSI_M
        keymap[0x2F] = setkc(0x34, 0x0000, 0x8000); // .            kVK_ANSI_Period
        keymap[0x30] = setkc(0x0F, 0x0000, 0x8000); // tab          kVK_Tab
        keymap[0x31] = setkc(0x39, 0x0000, 0x8000); // space        kVK_Space
        keymap[0x32] = setkc(0x29, 0x0000, 0x8000); // `            kVK_ANSI_Grave
        keymap[0x33] = setkc(0x0E, 0x0000, 0x8000); // backspace    kVK_Delete
        // 0x34                                                     ?
        keymap[0x35] = setkc(0x01, 0x0000, 0x8000); // esc          kVK_Escape
        keymap[0x36] = setkc(0x5C, 0x0100, 0x8100); // right win    kVK_RightCommand
        keymap[0x37] = setkc(0x5B, 0x0100, 0x8100); // left win     kVK_Command
        keymap[0x38] = setkc(0x2A, 0x0000, 0xC000); // left shift   kVK_Shift
        keymap[0x39] = setkc(0x3A, 0x0000, 0xC000); // caps lock    kVK_CapsLock
        keymap[0x3A] = setkc(0x38, 0x0000, 0xC000); // left alt     kVK_Option
        keymap[0x3B] = setkc(0x1D, 0x0000, 0xC000); // left ctrl    kVK_Control
        keymap[0x3C] = setkc(0x36, 0x0000, 0xC000); // right shift  kVK_RightShift
        keymap[0x3D] = setkc(0x38, 0x0100, 0xC100); // right alt    kVK_RightOption
        keymap[0x3E] = setkc(0x1D, 0x0100, 0xC100); // right ctrl   kVK_RightControl
        // 0x3F                                                     kVK_Function
        // 0x40                                                     kVK_F17
        keymap[0x41] = setkc(0x53, 0x0000, 0x8000); // NP .         kVK_ANSI_KeypadDecimal
        // 0x42                                                     ?
        keymap[0x43] = setkc(0x37, 0x0000, 0x8000); // NP *         kVK_ANSI_KeypadMultiply
        // 0x44                                                     ?
        keymap[0x45] = setkc(0x4E, 0x0000, 0x8000); // NP +         kVK_ANSI_KeypadPlus
        // 0x46                                                     ?
        keymap[0x47] = setkc(0x45, 0x0000, 0xC000); // num lock     kVK_ANSI_KeypadClear
        // 0x48                                                     kVK_VolumeUp
        // 0x49                                                     kVK_VolumeDown
        // 0x4A                                                     kVK_Mute
        keymap[0x4B] = setkc(0x35, 0x0100, 0x8100); // NP /         kVK_ANSI_KeypadDivide
        keymap[0x4C] = setkc(0x1C, 0x0100, 0xC100); // NP enter     kVK_ANSI_KeypadEnter
        // 0x4D                                                     ?
        keymap[0x4E] = setkc(0x4A, 0x0000, 0x8000); // NP -         kVK_ANSI_KeypadMinus
        // 0x4F                                                     kVK_F18
        // 0x50                                                     kVK_F19
        // 0x51                                                     kVK_ANSI_KeypadEquals
        keymap[0x52] = setkc(0x52, 0x0000, 0x8000); // NP 0         kVK_ANSI_Keypad0
        keymap[0x53] = setkc(0x4F, 0x0000, 0x8000); // NP 1         kVK_ANSI_Keypad1
        keymap[0x54] = setkc(0x50, 0x0000, 0x8000); // NP 2         kVK_ANSI_Keypad2
        keymap[0x55] = setkc(0x51, 0x0000, 0x8000); // NP 3         kVK_ANSI_Keypad3
        keymap[0x56] = setkc(0x4B, 0x0000, 0x8000); // NP 4         kVK_ANSI_Keypad4
        keymap[0x57] = setkc(0x4C, 0x0000, 0x8000); // NP 5         kVK_ANSI_Keypad5
        keymap[0x58] = setkc(0x4D, 0x0000, 0x8000); // NP 6         kVK_ANSI_Keypad6
        keymap[0x59] = setkc(0x47, 0x0000, 0x8000); // NP 7         kVK_ANSI_Keypad7
        // 0x5A                                                     kVK_F20
        keymap[0x5B] = setkc(0x48, 0x0000, 0x8000); // NP 8         kVK_ANSI_Keypad8
        keymap[0x5C] = setkc(0x49, 0x0000, 0x8000); // NP 9         kVK_ANSI_Keypad9
        // 0x5D                                                     kVK_JIS_Yen
        // 0x5E                                                     kVK_JIS_Underscore
        // 0x5F                                                     kVK_JIS_KeypadComma
        keymap[0x60] = setkc(0x3F, 0x0000, 0x8000); // F5           kVK_F5
        keymap[0x61] = setkc(0x40, 0x0000, 0x8000); // F6           kVK_F6
        keymap[0x62] = setkc(0x41, 0x0000, 0x8000); // F7           kVK_F7
        keymap[0x63] = setkc(0x3D, 0x0000, 0x8000); // F3           kVK_F3
        keymap[0x64] = setkc(0x42, 0x0000, 0x8000); // F8           kVK_F8
        keymap[0x65] = setkc(0x43, 0x0000, 0x8000); // F9           kVK_F9
        // 0x66                                                     kVK_JIS_Eisu
        keymap[0x67] = setkc(0x57, 0x0000, 0x8000); // F11          kVK_F11
        // 0x68                                                     kVK_JIS_Kana
        keymap[0x69] = setkc(0x37, 0x0100, 0x8100); // print scrn   kVK_F13
        // 0x6A                                                     kVK_F16
        // 0x6B                                                     kVK_F14
        // 0x6C                                                     ?
        keymap[0x6D] = setkc(0x44, 0x0000, 0x8000); // F10          kVK_F10
        keymap[0x6E] = setkc(0x5D, 0x0100, 0x8100); // menu         kVK_ContextualMenu
        keymap[0x6F] = setkc(0x58, 0x0000, 0x8000); // F12          kVK_F12
        // 0x70                                                     ?
        // 0x71                                                     kVK_F15
        keymap[0x72] = setkc(0x52, 0x0100, 0x8100); // insert       kVK_Help
        keymap[0x73] = setkc(0x47, 0x0100, 0x8100); // home         kVK_Home
        keymap[0x74] = setkc(0x49, 0x0100, 0x8100); // page up      kVK_PageUp
        keymap[0x75] = setkc(0x53, 0x0100, 0x8100); // delete       kVK_ForwardDelete
        keymap[0x76] = setkc(0x3E, 0x0000, 0x8000); // F4           kVK_F4
        keymap[0x77] = setkc(0x4F, 0x0100, 0x8100); // end          kVK_End
        keymap[0x78] = setkc(0x3C, 0x0000, 0x8000); // F2           kVK_F2
        keymap[0x79] = setkc(0x51, 0x0100, 0x8100); // page down    kVK_PageDown
        keymap[0x7A] = setkc(0x3B, 0x0000, 0x8000); // F1           kVK_F1
        keymap[0x7B] = setkc(0x4B, 0x0100, 0x8100); // left arrow   kVK_LeftArrow
        keymap[0x7C] = setkc(0x4D, 0x0100, 0x8100); // right arrow  kVK_RightArrow
        keymap[0x7D] = setkc(0x50, 0x0100, 0x8100); // down arrow   kVK_DownArrow
        keymap[0x7E] = setkc(0x48, 0x0100, 0x8100); // up arrow     kVK_UpArrow
    }
    return self;
}

//*****************************************************************************
-(void)dealloc
{
    NSLog(@"MClientView dealloc:");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [session release];
    [super dealloc];
}

//*****************************************************************************
-(BOOL)isFlipped
{
    //NSLog(@"isFlipped:");
    return NO;
}

//*****************************************************************************
-(BOOL)acceptsFirstResponder
{
    NSLog(@"MClientView acceptsFirstResponder:");
    return YES;
}

//*****************************************************************************
-(BOOL)canBecomeKeyView
{
    NSLog(@"MClientView canBecomeKeyView:");
    return YES;
}

//*****************************************************************************
-(void)resizeTimerCallback:(NSTimer*)timer
{
    NSLog(@"resizeTimerCallback");
}

//*****************************************************************************
-(void)updateTrackingAreas
{
    NSLog(@"updateTrackingAreas");
    // Remove existing tracking areas to prevent duplicates
    NSTrackingArea* area;
    for (area in [self trackingAreas])
    {
        [self removeTrackingArea:area];
    }
    NSWindow* window = [self window];
    NSRect frameRect = window.frame;
    contentRect = [window contentRectForFrameRect:frameRect];
    NSLog(@"updateTrackingAreas: contextRect origin x %f y %f "
            "size width %f height %f",
            contentRect.origin.x, contentRect.origin.y,
            contentRect.size.width, contentRect.size.height);
    // resize the view to match the window
    NSRect frame = window.frame;
    frame.origin.x = 0;
    frame.origin.y = 0;
    self.frame = frame;
    // Add the new tracking area
    NSTrackingAreaOptions opts = NSTrackingActiveAlways |
            NSTrackingInVisibleRect |
            NSTrackingMouseEnteredAndExited |
            NSTrackingMouseMoved |
            NSTrackingCursorUpdate |
            NSTrackingEnabledDuringMouseDrag |
            NSTrackingActiveWhenFirstResponder;
    area = [NSTrackingArea alloc];
    NSRect bounds = [self bounds];
    [area initWithRect:bounds options:opts owner:self userInfo:nil];
    [self addTrackingArea:area];
    [super updateTrackingAreas]; // Call super's implementation
    [area release];
    [resizeTimer invalidate];
    [resizeTimer release];
    resizeTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self
            selector:@selector(resizeTimerCallback:) userInfo:nil repeats:NO];
    [resizeTimer retain];
}

//*****************************************************************************
-(bool)getLocation:(NSEvent*)event :(NSPoint*)pt;
{
    NSPoint location;
    CGFloat width = NSWidth(contentRect);
    CGFloat height = NSHeight(contentRect);
    // convert the click location into the view coords
    location = [self convertPoint:[event locationInWindow] fromView:nil];
    if ((location.x < 0) || (location.y < 0) ||
            (location.x > width) || (location.y > height))
    {
        return false;
    }
    location.y = height - location.y;
    location.x += bs_origin.x + 0.5;
    location.y += bs_origin.y + 0.5;
    //NSLog(@"getLocation: x %f y %f", location.x, location.y);
    *pt = location;
    return true;
}

//*****************************************************************************
-(void)mouseDown:(NSEvent*)event
{
    NSPoint location;
    if ([self getLocation:event :&location])
    {
        [session sendMouseDownEvent:1 :location.x :location.y];
    }
}

//*****************************************************************************
-(void)mouseUp:(NSEvent*)event
{
    NSPoint location;
    if ([self getLocation:event :&location])
    {
        [session sendMouseUpEvent:1 :location.x :location.y];
    }
}

//*****************************************************************************
-(void)mouseMoved:(NSEvent*)event
{
    NSPoint location;
    if ([self getLocation:event :&location])
    {
        [session sendMouseMovedEvent:location.x :location.y];
    }
}

//*****************************************************************************
-(void)mouseDragged:(NSEvent*)event
{
    NSPoint location;
    if ([self getLocation:event :&location])
    {
        [session sendMouseMovedEvent:location.x :location.y];
    }
}

//*****************************************************************************
-(void)rightMouseDown:(NSEvent*)event
{
    NSPoint location;
    if ([self getLocation:event :&location])
    {
        [session sendMouseDownEvent:2 :location.x :location.y];
    }
}

//*****************************************************************************
-(void)rightMouseUp:(NSEvent*)event
{
    NSPoint location;
    if ([self getLocation:event :&location])
    {
        [session sendMouseUpEvent:2 :location.x :location.y];
    }
}

//*****************************************************************************
-(void)rightMouseDragged:(NSEvent*)event
{
    NSPoint location;
    if ([self getLocation:event :&location])
    {
        [session sendMouseMovedEvent:location.x :location.y];
    }
}

//*****************************************************************************
-(void)otherMouseDown:(NSEvent*)event
{
    NSPoint location;
    if ([self getLocation:event :&location])
    {
        int pressed = [event buttonNumber] + 1;
        [session sendMouseDownEvent:pressed :location.x :location.y];
    }
}

//*****************************************************************************
-(void)otherMouseUp:(NSEvent*)event
{
    NSPoint location;
    if ([self getLocation:event :&location])
    {
        int pressed = [event buttonNumber] + 1;
        [session sendMouseUpEvent:pressed :location.x :location.y];
    }
}

//*****************************************************************************
-(void)otherMouseDragged:(NSEvent*)event
{
    NSPoint location;
    if ([self getLocation:event :&location])
    {
        [session sendMouseMovedEvent:location.x :location.y];
    }
}

//*****************************************************************************
-(void)scrollWheel:(NSEvent*)event
{
    NSPoint location;
    if ([self getLocation:event :&location])
    {
        float dx = [event deltaX] * -60.0;
        float dy = [event deltaY] * 60;
        [session sendMouseWheel: dx :true :location.x :location.y];
        [session sendMouseWheel: dy :false :location.x :location.y];
    }
}

//*****************************************************************************
-(void)mouseEntered:(NSEvent*)event
{
    NSLog(@"mouseEntered:");
    [last_cur set];
}

//*****************************************************************************
-(void)mouseExited:(NSEvent*)event
{
    NSLog(@"mouseExited:");
}

//*****************************************************************************
-(void)processKeyCode:(uint32_t)key_code :(uint32_t)down
{
    struct rdp_key_code_t* kc = keymap + (key_code & 0xFF);
    if ([session sendKeyboardScancode:kc->flags[!down] :kc->code] == 0)
    {
        kc->is_down = !!down;
    }
}

//*************************************************************************
-(void)sendKeyboardSync:(uint32_t)mod_flags
{
    NSLog(@"keyUp: key_code %d", mod_flags);
    uint32_t toggle_flags = TS_SYNC_NUM_LOCK;
    if (mod_flags & NSEventModifierFlagCapsLock)
    {
        toggle_flags |= TS_SYNC_CAPS_LOCK;
    }
    int rv = [session sendKeyboardSync:toggle_flags];
    need_keyboard_sync = rv != 0;
}

//*****************************************************************************
-(void)keyDown:(NSEvent*)event
{
    uint16_t key_code = [event keyCode];
    if (need_keyboard_sync)
    {
        uint32_t mod_flags = [event modifierFlags];
        [self sendKeyboardSync:mod_flags];
        last_mod_flags = mod_flags;
    }
    NSLog(@"keyDown: key_code 0x%4.4X", (uint32_t)key_code);
    [self processKeyCode:key_code :1];
}

//*****************************************************************************
-(void)keyUp:(NSEvent*)event
{
    uint16_t key_code = [event keyCode];
    NSLog(@"keyUp: key_code 0x%4.4X", (uint32_t)key_code);
    [self processKeyCode:key_code :0];
}

//*****************************************************************************
-(void)checkModifier:(uint32_t)mod_flags :(uint16_t)key_code :(uint32_t)flag
{
    uint32_t down = mod_flags & flag;
    if (down != (last_mod_flags & flag))
    {
        if (key_code == 57) // kVK_CapsLock
        {
            [self processKeyCode:57 :1];
            [self processKeyCode:57 :0];
            return;
        }
        [self processKeyCode:key_code :down];
    }
}

//*****************************************************************************
-(void)flagsChanged:(NSEvent*)event
{
    uint16_t key_code = [event keyCode];
    uint32_t mod_flags = [event modifierFlags];
    NSLog(@"flagsChanged: key_code %d mod_flags 0x%8.8X", (int)key_code, mod_flags);
    [self checkModifier:mod_flags :key_code :NSEventModifierFlagControl];
    [self checkModifier:mod_flags :key_code :NSEventModifierFlagShift];
    [self checkModifier:mod_flags :key_code :NSEventModifierFlagOption];
    [self checkModifier:mod_flags :key_code :NSEventModifierFlagCommand];
    [self checkModifier:mod_flags :key_code :NSEventModifierFlagCapsLock];
    last_mod_flags = mod_flags;
}

//*****************************************************************************
-(void)drawRect:(NSRect) dirtyRect
{
    //NSLog(@"drawRect");
    //NSLog(@"drawRect: %f %f %f %f", contentRect.origin.x, contentRect.origin.y,
    //        contentRect.size.width, contentRect.size.height);
    CGContextRef cgContext =
            [[NSGraphicsContext currentContext] CGContext];
    CGContextRef bs_context = [session getBackingStore];
    if (bs_context != NULL)
    {
        if (cgContext != NULL)
        {
            CGImageRef cgImage = CGBitmapContextCreateImage(bs_context);
            if (cgImage != NULL)
            {
                CGContextSaveGState(cgContext);
                CGContextSetInterpolationQuality(cgContext,
                        kCGInterpolationNone);
                CGRect rect = dirtyRect;
                CGContextClipToRect(cgContext, rect);
                int image_width = CGImageGetWidth(cgImage);
                int image_height = CGImageGetHeight(cgImage);
                rect = NSMakeRect(0, 0, image_width, image_height);
                rect.origin.y += NSHeight(contentRect) - image_height;
                CGContextDrawImage(cgContext, rect, cgImage);
                CGContextRestoreGState(cgContext);
                CGImageRelease(cgImage);
            }
        }
    }
    [super drawRect:dirtyRect];
}

//*****************************************************************************
-(void)setSessionApp:(RDPSession*)asession :(NSApplication*)aapp
{
    session = asession;
    app = aapp;
    [session retain];
}

//*****************************************************************************
-(void)upAllDownKeys
{
    struct rdp_key_code_t* kc;
    int index;
    for (index = 0; index < 256; index++)
    {
        kc = keymap + index;
        if (kc->is_down)
        {
            NSLog(@"MClientView focusIn: key was down rdp_code %d", kc->code);
            if ([session sendKeyboardScancode:kc->flags[1] :kc->code] == 0)
            {
                kc->is_down = false;
            }
        }
    }
}

//*****************************************************************************
-(void)focusIn
{
    NSLog(@"MClientView focusIn:");
    [self upAllDownKeys];
    need_keyboard_sync = true;
    [last_cur set];
}

//*****************************************************************************
-(void)focusOut
{
    NSLog(@"MClientView focusOut:");
}

//*****************************************************************************
-(void)invalidate:(NSRect)arect :(int)width :(int)height
{
    arect.origin.y += NSHeight(contentRect) - height;
    [self setNeedsDisplayInRect:arect];
}

//*****************************************************************************
-(void)setCursor:(NSCursor*)cur
{
    NSLog(@"MClientView setCursor: cur %p", cur);
    [last_cur release];
    last_cur = cur;
    [cur retain];
    [cur set];
}

@end
