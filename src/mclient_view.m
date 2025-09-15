
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
    if (self)
    {
        keymap[0]   = setkc(30,  0x0000, 0x8000); // A              kVK_ANSI_A
        keymap[1]   = setkc(31,  0x0000, 0x8000); // S              kVK_ANSI_S
        keymap[2]   = setkc(32,  0x0000, 0x8000); // D              kVK_ANSI_D
        keymap[3]   = setkc(33,  0x0000, 0x8000); // F              kVK_ANSI_F
        keymap[4]   = setkc(35,  0x0000, 0x8000); // H              kVK_ANSI_H
        keymap[5]   = setkc(34,  0x0000, 0x8000); // G              kVK_ANSI_G
        keymap[6]   = setkc(44,  0x0000, 0x8000); // Z              kVK_ANSI_Z
        keymap[7]   = setkc(45,  0x0000, 0x8000); // X              kVK_ANSI_X
        keymap[8]   = setkc(46,  0x0000, 0x8000); // C              kVK_ANSI_C
        keymap[9]   = setkc(47,  0x0000, 0x8000); // V              kVK_ANSI_V
        // 10                                                       kVK_ISO_Section
        keymap[11]  = setkc(48,  0x0000, 0x8000); // B              kVK_ANSI_B
        keymap[12]  = setkc(16,  0x0000, 0x8000); // Q              kVK_ANSI_Q
        keymap[13]  = setkc(17,  0x0000, 0x8000); // W              kVK_ANSI_W
        keymap[14]  = setkc(18,  0x0000, 0x8000); // E              kVK_ANSI_E
        keymap[15]  = setkc(19,  0x0000, 0x8000); // R              kVK_ANSI_R
        keymap[16]  = setkc(21,  0x0000, 0x8000); // Y              kVK_ANSI_Y
        keymap[17]  = setkc(20,  0x0000, 0x8000); // T              kVK_ANSI_T
        keymap[18]  = setkc(2,   0x0000, 0x8000); // 1              kVK_ANSI_1
        keymap[19]  = setkc(3,   0x0000, 0x8000); // 2              kVK_ANSI_2
        keymap[20]  = setkc(4,   0x0000, 0x8000); // 3              kVK_ANSI_3
        keymap[21]  = setkc(5,   0x0000, 0x8000); // 4              kVK_ANSI_4
        keymap[22]  = setkc(7,   0x0000, 0x8000); // 6              kVK_ANSI_6
        keymap[23]  = setkc(6,   0x0000, 0x8000); // 5              kVK_ANSI_5
        keymap[24]  = setkc(13,  0x0000, 0x8000); // =              kVK_ANSI_Equal
        keymap[25]  = setkc(10,  0x0000, 0x8000); // 9              kVK_ANSI_9
        keymap[26]  = setkc(8,   0x0000, 0x8000); // 7              kVK_ANSI_7
        keymap[27]  = setkc(12,  0x0000, 0x8000); // -              kVK_ANSI_Minus
        keymap[28]  = setkc(9,   0x0000, 0x8000); // 8              kVK_ANSI_8
        keymap[29]  = setkc(11,  0x0000, 0x8000); // 0              kVK_ANSI_0
        keymap[30]  = setkc(27,  0x0000, 0x8000); // ]              kVK_ANSI_RightBracket
        keymap[31]  = setkc(24,  0x0000, 0x8000); // O              kVK_ANSI_O
        keymap[32]  = setkc(22,  0x0000, 0x8000); // U              kVK_ANSI_U
        keymap[33]  = setkc(26,  0x0000, 0x8000); // [              kVK_ANSI_LeftBracket
        keymap[34]  = setkc(23,  0x0000, 0x8000); // I              kVK_ANSI_I
        keymap[35]  = setkc(25,  0x0000, 0x8000); // P              kVK_ANSI_P
        keymap[36]  = setkc(28,  0x0000, 0x8000); // enter          kVK_Return
        keymap[37]  = setkc(38,  0x0000, 0x8000); // L              kVK_ANSI_L
        keymap[38]  = setkc(36,  0x0000, 0x8000); // J              kVK_ANSI_J
        keymap[39]  = setkc(40,  0x0000, 0x8000); // '              kVK_ANSI_Quote
        keymap[40]  = setkc(37,  0x0000, 0x8000); // K              kVK_ANSI_K
        keymap[41]  = setkc(39,  0x0000, 0x8000); // ;              kVK_ANSI_Semicolon
        keymap[42]  = setkc(43,  0x0000, 0x8000); // backslash      kVK_ANSI_Backslash
        keymap[43]  = setkc(51,  0x0000, 0x8000); // ,              kVK_ANSI_Comma
        keymap[44]  = setkc(53,  0x0000, 0x8000); // /              kVK_ANSI_Slash
        keymap[45]  = setkc(49,  0x0000, 0x8000); // N              kVK_ANSI_N
        keymap[46]  = setkc(50,  0x0000, 0x8000); // M              kVK_ANSI_M
        keymap[47]  = setkc(52,  0x0000, 0x8000); // .              kVK_ANSI_Period
        keymap[48]  = setkc(15,  0x0000, 0x8000); // tab            kVK_Tab
        keymap[49]  = setkc(57,  0x0000, 0x8000); // space          kVK_Space
        keymap[50]  = setkc(41,  0x0000, 0x8000); // `              kVK_ANSI_Grave
        keymap[51]  = setkc(14,  0x0000, 0x8000); // backspace      kVK_Delete
        // 52                                                       ?
        keymap[53]  = setkc(1,   0x0000, 0x8000); // esc            kVK_Escape
        keymap[54]  = setkc(92,  0x0100, 0x8100); // right win      kVK_RightCommand
        keymap[55]  = setkc(91,  0x0100, 0x8100); // left win       kVK_Command
        keymap[56]  = setkc(42,  0x0000, 0xC000); // left shift     kVK_Shift
        keymap[57]  = setkc(58,  0x0000, 0xC000); // caps lock      kVK_CapsLock
        keymap[58]  = setkc(56,  0x0000, 0xC000); // left alt       kVK_Option
        keymap[59]  = setkc(29,  0x0000, 0xC000); // left ctrl      kVK_Control
        keymap[60]  = setkc(54,  0x0000, 0xC000); // right shift    kVK_RightShift
        keymap[61]  = setkc(56,  0x0100, 0xC100); // right alt      kVK_RightOption
        keymap[62]  = setkc(29,  0x0100, 0xC100); // right ctrl     kVK_RightControl
        // 63                                                       kVK_Function
        // 64                                                       kVK_F17
        keymap[65]  = setkc(83,  0x0000, 0x8000); // NP .           kVK_ANSI_KeypadDecimal
        // 66                                                       ?
        keymap[67]  = setkc(55,  0x0000, 0x8000); // NP *           kVK_ANSI_KeypadMultiply
        // 68                                                       ?
        keymap[69]  = setkc(78,  0x0000, 0x8000); // NP +           kVK_ANSI_KeypadPlus
        // 70                                                       ?
        keymap[71]  = setkc(69,  0x0000, 0xC000); // num lock       kVK_ANSI_KeypadClear
        // 72                                                       kVK_VolumeUp
        // 73                                                       kVK_VolumeDown
        // 74                                                       kVK_Mute
        keymap[75]  = setkc(53,  0x0100, 0x8100); // NP /           kVK_ANSI_KeypadDivide
        keymap[76]  = setkc(28,  0x0100, 0xC100); // NP enter       kVK_ANSI_KeypadEnter
        // 77                                                       ?
        keymap[78]  = setkc(74,  0x0000, 0x8000); // NP -           kVK_ANSI_KeypadMinus
        // 79                                                       kVK_F18
        // 80                                                       kVK_F19
        // 81                                                       kVK_ANSI_KeypadEquals
        keymap[82]  = setkc(82,  0x0000, 0x8000); // NP 0           kVK_ANSI_Keypad0
        keymap[83]  = setkc(79,  0x0000, 0x8000); // NP 1           kVK_ANSI_Keypad1
        keymap[84]  = setkc(80,  0x0000, 0x8000); // NP 2           kVK_ANSI_Keypad2
        keymap[85]  = setkc(81,  0x0000, 0x8000); // NP 3           kVK_ANSI_Keypad3
        keymap[86]  = setkc(75,  0x0000, 0x8000); // NP 4           kVK_ANSI_Keypad4
        keymap[87]  = setkc(76,  0x0000, 0x8000); // NP 5           kVK_ANSI_Keypad5
        keymap[88]  = setkc(77,  0x0000, 0x8000); // NP 6           kVK_ANSI_Keypad6
        keymap[89]  = setkc(71,  0x0000, 0x8000); // NP 7           kVK_ANSI_Keypad7
        // 90                                                       kVK_F20
        keymap[91]  = setkc(72,  0x0000, 0x8000); // NP 8           kVK_ANSI_Keypad8
        keymap[92]  = setkc(73,  0x0000, 0x8000); // NP 9           kVK_ANSI_Keypad9
        // 93                                                       kVK_JIS_Yen
        // 94                                                       kVK_JIS_Underscore
        // 95                                                       kVK_JIS_KeypadComma
        keymap[96]  = setkc(63,  0x0000, 0x8000); // F5             kVK_F5
        keymap[97]  = setkc(64,  0x0000, 0x8000); // F6             kVK_F6
        keymap[98]  = setkc(65,  0x0000, 0x8000); // F7             kVK_F7
        keymap[99]  = setkc(61,  0x0000, 0x8000); // F3             kVK_F3
        keymap[100] = setkc(66,  0x0000, 0x8000); // F8             kVK_F8
        keymap[101] = setkc(67,  0x0000, 0x8000); // F9             kVK_F9
        // 102                                                      kVK_JIS_Eisu
        keymap[103] = setkc(87,  0x0000, 0x8000); // F11            kVK_F11
        // 104                                                      kVK_JIS_Kana
        //keymap[105]  = setkc(?,  0x0100, 0x8100); // print screen   kVK_F13
        // 106                                                      kVK_F16
        // 107                                                      kVK_F14
        // 108                                                      ?
        keymap[109] = setkc(68,  0x0000, 0x8000); // F10            kVK_F10
        keymap[110] = setkc(93,  0x0100, 0x8100); // menu           kVK_ContextualMenu
        keymap[111] = setkc(88,  0x0000, 0x8000); // F12            kVK_F12
        // 112                                                      ?
        // 113                                                      kVK_F15
        keymap[114] = setkc(82,  0x0100, 0x8100); // insert         kVK_Help
        keymap[115] = setkc(71,  0x0100, 0x8100); // home           kVK_Home
        keymap[116] = setkc(73,  0x0100, 0x8100); // page up        kVK_PageUp
        keymap[117] = setkc(83,  0x0100, 0x8100); // delete         kVK_ForwardDelete
        keymap[118] = setkc(62,  0x0000, 0x8000); // F4             kVK_F4
        keymap[119] = setkc(79,  0x0100, 0x8100); // end            kVK_End
        keymap[120] = setkc(60,  0x0000, 0x8000); // F2             kVK_F2
        keymap[121] = setkc(81,  0x0100, 0x8100); // page down      kVK_PageDown
        keymap[122] = setkc(59,  0x0000, 0x8000); // F1             kVK_F1
        keymap[123] = setkc(75,  0x0100, 0x8100); // left arrow     kVK_LeftArrow
        keymap[124] = setkc(77,  0x0100, 0x8100); // right arrow    kVK_RightArrow
        keymap[125] = setkc(80,  0x0100, 0x8100); // down arrow     kVK_DownArrow
        keymap[126] = setkc(72,  0x0100, 0x8100); // up arrow       kVK_UpArrow

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
-(NSRect)flipRect:(NSRect)arect
{
    arect.origin.y = (content_size.height - arect.origin.y) -
            arect.size.height;
    return arect;
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
    NSRect contentRect = [window contentRectForFrameRect:frameRect];
    NSSize save_contexnt_size = content_size;
    content_size = contentRect.size;
    NSLog(@"updateTrackingAreas: contextRect size width %f height %f",
            content_size.width, content_size.height);
    origin.x = NSWidth(frameRect) - NSWidth(contentRect);
    origin.y = NSHeight(frameRect) - NSHeight(contentRect);
    NSLog(@"updateTrackingAreas: origin x %f y %f", origin.x, origin.y);
    // resize the view to match the window
    NSRect frame = window.frame;
    frame.origin.x = 0;
    frame.origin.y = 0;
    self.frame = frame;
    // Add the new tracking area
    NSTrackingAreaOptions opts = NSTrackingActiveAlways |
            NSTrackingInVisibleRect | NSTrackingMouseMoved |
            NSTrackingMouseEnteredAndExited;
    area = [NSTrackingArea alloc];
    NSRect bounds = [self bounds];
    [area initWithRect:bounds options:opts owner:self userInfo:nil];
    [self addTrackingArea:area];
    [super updateTrackingAreas]; // Call super's implementation
    [area release];

    // create new backing store, copy old to new
    CGContextRef save_bs_context = bs_context;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    if (colorSpace != NULL)
    {
        bs_context = CGBitmapContextCreate(NULL,
                NSWidth(contentRect), NSHeight(contentRect), 8, 0, colorSpace,
                kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst);
        CGColorSpaceRelease(colorSpace);
        if (bs_context == NULL)
        {
            NSLog(@"updateTrackingAreas: failed to create bs_context");
            [app terminate:self];
            return;
        }
    }

    CGImageRef cgImage = CGBitmapContextCreateImage(save_bs_context);
    if (cgImage != NULL)
    {
        CGContextSaveGState(bs_context);
        NSRect rect = NSMakeRect(0, 0,
                save_contexnt_size.width, save_contexnt_size.height);
        rect = [self flipRect:rect];
        CGContextDrawImage(bs_context, rect, cgImage);
        CGContextRestoreGState(bs_context);
        CGImageRelease(cgImage);
    }
    CGContextRelease(save_bs_context);
}

//*****************************************************************************
-(bool)getLocation:(NSEvent*)event :(NSPoint*)pt;
{
    NSPoint location;
    // convert the click location into the view coords
    location = [self convertPoint:[event locationInWindow] fromView:nil];
    if ((location.x < 0) || (location.y < 0) ||
            (location.x > content_size.width) ||
            (location.y > content_size.height))
    {
        return false;
    }
    location.x += 0.5;
    location.y += 0.5;
    location.y = content_size.height - location.y;
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
    NSLog(@"keyDown: key_code %d", key_code);
    [self processKeyCode:key_code :1];
}

//*****************************************************************************
-(void)keyUp:(NSEvent*)event
{
    uint16_t key_code = [event keyCode];
    NSLog(@"keyUp: key_code %d", key_code);
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
    NSLog(@"flagsChanged: key_code %d mod_flags 0x%8.8X", key_code, mod_flags);
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
    CGContextRef cgContext =
            [[NSGraphicsContext currentContext] CGContext];
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
                rect.origin = NSMakePoint(0, 0);
                rect.size = content_size;
                CGContextDrawImage(cgContext, rect, cgImage);
                CGContextRestoreGState(cgContext);
                CGImageRelease(cgImage);
            }
        }
    }
    [super drawRect:dirtyRect];
}

//*****************************************************************************
-(int)drawImage:(unsigned int)src_width :(unsigned int)src_height
        :(int)dst_left :(int)dst_top
        :(unsigned int)dst_width :(unsigned int)dst_height
        :(char*)pixels :(struct rfx_rect*)clips :(unsigned int)num_clips
{
    CGColorSpaceRef colorSpace;
    CGContextRef context;
    CGImageRef image;
    NSRect rect;
    NSRect clip;
    NSRect* ns_clips;
    int index;

    //NSLog(@"drawImage:");
    colorSpace = CGColorSpaceCreateDeviceRGB();
    if (colorSpace != NULL)
    {
        CGContextSaveGState(bs_context);
        clip = NSMakeRect(dst_left, dst_top, dst_width, dst_height);
        clip = [self flipRect:clip];
        CGContextClipToRect(bs_context, clip);
        if (num_clips > 0)
        {
            // convert clips
            ns_clips = (NSRect*)malloc(sizeof(NSRect) * num_clips);
            if (ns_clips != NULL)
            {
                for (index = 0; index < num_clips; index++)
                {
                    rect = NSMakeRect(clips[index].x, clips[index].y,
                            clips[index].cx, clips[index].cy);
                    ns_clips[index] = [self flipRect:rect];
                }
                CGContextClipToRects(bs_context, ns_clips, num_clips);
                free(ns_clips);
            }
        }
        context = CGBitmapContextCreate(pixels,
                src_width, src_height, 8, src_width * 4, colorSpace,
                kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst);
        if (context != NULL)
        {
            image = CGBitmapContextCreateImage(context);
            if (image != NULL)
            {
                // must be src_width and src_height or else
                // CGContextDrawImage will stretch
                rect = NSMakeRect(dst_left, dst_top, src_width, src_height);
                rect = [self flipRect:rect];
                CGContextDrawImage(bs_context, rect, image);
                CGImageRelease(image);
            }
            CGContextRelease(context);
        }
        CGContextRestoreGState(bs_context);
        CGColorSpaceRelease(colorSpace);
        [self setNeedsDisplayInRect:clip];
    }
    return 0;
}

//*****************************************************************************
-(void)setSessionApp:(RDPSession*)asession :(NSApplication*)aapp
{
    session = asession;
    app = aapp;
    [session retain];
}

//*****************************************************************************
-(void)focusIn
{
    NSLog(@"MClientView focusIn:");
    struct rdp_key_code_t* kc;
    int index;
    for (index = 0; index < 256; index++)
    {
        kc = (struct rdp_key_code_t*)keymap + index;
        if (kc->is_down)
        {
            NSLog(@"MClientView focusIn: key was down rdp_code %d", kc->code);
            if ([session sendKeyboardScancode:kc->flags[1] :kc->code] == 0)
            {
                kc->is_down = false;
            }
        }
    }
    need_keyboard_sync = true;
}

//*****************************************************************************
-(void)focusOut
{
    NSLog(@"MClientView focusOut:");
}

@end
