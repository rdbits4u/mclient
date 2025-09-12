
#include <poll.h>
#include <librdpc.h>
#include <libsvc.h>
#include <libcliprdr.h>
#include <librdpsnd.h>
#include <rfxcodec_decode.h>
#import <Cocoa/Cocoa.h>
#import "mclient_app_delegate.h"
#import "mclient_view.h"
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
-(MClientView*)initWithFrame:(CGRect)theFrame
{
    NSLog(@"MClientView initWithFrame:");
    self = [super initWithFrame:theFrame];
    if (self)
    {
        keymap[0]   = setkc(30,  0x0000, 0x8000); // A
        keymap[1]   = setkc(31,  0x0000, 0x8000); // S
        keymap[2]   = setkc(32,  0x0000, 0x8000); // D
        keymap[3]   = setkc(33,  0x0000, 0x8000); // F
        keymap[4]   = setkc(35,  0x0000, 0x8000); // H
        keymap[5]   = setkc(34,  0x0000, 0x8000); // G
        keymap[6]   = setkc(44,  0x0000, 0x8000); // Z
        keymap[7]   = setkc(45,  0x0000, 0x8000); // X
        keymap[8]   = setkc(46,  0x0000, 0x8000); // C
        keymap[9]   = setkc(47,  0x0000, 0x8000); // V
        // 10
        keymap[11]  = setkc(48,  0x0000, 0x8000); // B
        keymap[12]  = setkc(16,  0x0000, 0x8000); // Q
        keymap[13]  = setkc(17,  0x0000, 0x8000); // W
        keymap[14]  = setkc(18,  0x0000, 0x8000); // E
        keymap[15]  = setkc(19,  0x0000, 0x8000); // R
        keymap[16]  = setkc(21,  0x0000, 0x8000); // Y
        keymap[17]  = setkc(20,  0x0000, 0x8000); // T
        keymap[18]  = setkc(2,   0x0000, 0x8000); // 1
        keymap[19]  = setkc(3,   0x0000, 0x8000); // 2
        keymap[20]  = setkc(4,   0x0000, 0x8000); // 3
        keymap[21]  = setkc(5,   0x0000, 0x8000); // 4
        keymap[22]  = setkc(7,   0x0000, 0x8000); // 6
        keymap[23]  = setkc(6,   0x0000, 0x8000); // 5
        keymap[24]  = setkc(13,  0x0000, 0x8000); // =
        keymap[25]  = setkc(10,  0x0000, 0x8000); // 9
        keymap[26]  = setkc(8,   0x0000, 0x8000); // 7
        keymap[27]  = setkc(12,  0x0000, 0x8000); // -
        keymap[28]  = setkc(9,   0x0000, 0x8000); // 8
        keymap[29]  = setkc(11,  0x0000, 0x8000); // 0
        keymap[30]  = setkc(27,  0x0000, 0x8000); // ]
        keymap[31]  = setkc(24,  0x0000, 0x8000); // O
        keymap[32]  = setkc(22,  0x0000, 0x8000); // U
        keymap[33]  = setkc(26,  0x0000, 0x8000); // [
        keymap[34]  = setkc(23,  0x0000, 0x8000); // I
        keymap[35]  = setkc(25,  0x0000, 0x8000); // P
        keymap[36]  = setkc(28,  0x0000, 0x8000); // enter
        keymap[37]  = setkc(38,  0x0000, 0x8000); // L
        keymap[38]  = setkc(36,  0x0000, 0x8000); // J
        keymap[39]  = setkc(40,  0x0000, 0x8000); // '
        keymap[40]  = setkc(37,  0x0000, 0x8000); // K
        keymap[41]  = setkc(39,  0x0000, 0x8000); // ;
        keymap[42]  = setkc(43,  0x0000, 0x8000); // backslash
        keymap[43]  = setkc(51,  0x0000, 0x8000); // ,
        keymap[44]  = setkc(53,  0x0000, 0x8000); // /
        keymap[45]  = setkc(49,  0x0000, 0x8000); // N
        keymap[46]  = setkc(50,  0x0000, 0x8000); // M
        keymap[47]  = setkc(52,  0x0000, 0x8000); // .
        keymap[48]  = setkc(15,  0x0000, 0x8000); // tab
        keymap[49]  = setkc(57,  0x0000, 0x8000); // space
        keymap[50]  = setkc(41,  0x0000, 0x8000); // `
        keymap[51]  = setkc(14,  0x0000, 0x8000); // backspace
        // 52
        keymap[53]  = setkc(1,   0x0000, 0x8000); // esc
        // 54
        //keymap[55]  = setkc(36,  0x0000, 0x8000); // left win


        keymap[96]  = setkc(63,  0x0000, 0x8000); // F5
        keymap[97]  = setkc(64,  0x0000, 0x8000); // F6
        keymap[98]  = setkc(65,  0x0000, 0x8000); // F7
        keymap[99]  = setkc(61,  0x0000, 0x8000); // F3
        keymap[100] = setkc(66,  0x0000, 0x8000); // F8
        keymap[101] = setkc(67,  0x0000, 0x8000); // F9
        // 102
        keymap[103] = setkc(87,  0x0000, 0x8000); // F11

        keymap[109] = setkc(68,  0x0000, 0x8000); // F10
        // 110
        keymap[111] = setkc(88,  0x0000, 0x8000); // F12

        keymap[118] = setkc(62,  0x0000, 0x8000); // F4
        // 119
        keymap[120] = setkc(60,  0x0000, 0x8000); // F2
        // 121
        keymap[122] = setkc(59,  0x0000, 0x8000); // F1
        keymap[123] = setkc(75,  0x0100, 0x8100); // left arrow
        keymap[124] = setkc(77,  0x0100, 0x8100); // right arrow
        keymap[125] = setkc(80,  0x0100, 0x8100); // down arrow
        keymap[126] = setkc(72,  0x0100, 0x8100); // up arrow

    }
    return self;
}

//*****************************************************************************
-(void)dealloc
{
    NSLog(@"MClientView dealloc:");
    [session release];
    CGContextRelease(tile_context);
    free(tile_pixels);
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
    //NSLog(@"acceptsFirstResponder:");
    return YES;
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

    // create / recreate backing store
    if (bs_context != NULL)
    {
        CGContextRelease(bs_context);
    }
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    if (colorSpace != NULL)
    {
        bs_context = CGBitmapContextCreate(NULL,
                NSWidth(contentRect), NSHeight(contentRect), 8, 0, colorSpace,
                kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst);
        CGColorSpaceRelease(colorSpace);
    }
}

//*****************************************************************************
-(NSPoint)getLocation:(NSEvent*)event
{
    NSPoint location;
    // convert the click location into the view coords
    location = [self convertPoint:[event locationInWindow] fromView:nil];
    location.x = MAX(location.x + 0.5, 0);
    location.y = MAX((content_size.height - location.y) + 0.5, 0);
    NSLog(@"getLocation: x %f y %f", location.x, location.y);
    return location;
}

//*****************************************************************************
-(void)mouseDown:(NSEvent*)event
{
    NSPoint location = [self getLocation:event];
    [session sendMouseDownEvent:1 :location.x :location.y];
}

//*****************************************************************************
-(void)mouseUp:(NSEvent*)event
{
    NSPoint location = [self getLocation:event];
    [session sendMouseUpEvent:1 :location.x :location.y];
}

//*****************************************************************************
-(void)mouseMoved:(NSEvent*)event
{
    NSPoint location = [self getLocation:event];
    [session sendMouseMovedEvent:location.x :location.y];
}

//*****************************************************************************
-(void)mouseDragged:(NSEvent*)event
{
    NSPoint location = [self getLocation:event];
    [session sendMouseMovedEvent:location.x :location.y];
}

//*****************************************************************************
-(void)rightMouseDown:(NSEvent*)event
{
    NSPoint location = [self getLocation:event];
    [session sendMouseDownEvent:2 :location.x :location.y];
}

//*****************************************************************************
-(void)rightMouseUp:(NSEvent*)event
{
    NSPoint location = [self getLocation:event];
    [session sendMouseUpEvent:2 :location.x :location.y];
}

//*****************************************************************************
-(void)rightMouseDragged:(NSEvent*)event
{
    NSPoint location = [self getLocation:event];
    [session sendMouseMovedEvent:location.x :location.y];
}

//*****************************************************************************
-(void)otherMouseDown:(NSEvent*)event
{
    NSPoint location = [self getLocation:event];
    int pressed = [event buttonNumber] + 1;
    [session sendMouseDownEvent:pressed :location.x :location.y];
}

//*****************************************************************************
-(void)otherMouseUp:(NSEvent*)event
{
    NSPoint location = [self getLocation:event];
    int pressed = [event buttonNumber] + 1;
    [session sendMouseUpEvent:pressed :location.x :location.y];
}

//*****************************************************************************
-(void)otherMouseDragged:(NSEvent*)event
{
    NSPoint location = [self getLocation:event];
    [session sendMouseMovedEvent:location.x :location.y];
}

//*****************************************************************************
-(void)scrollWheel:(NSEvent*)event
{
    NSPoint location = [self getLocation:event];
    float dx = [event deltaX] * -60.0;
    float dy = [event deltaY] * 60;
    [session sendMouseWheel: dx :true :location.x :location.y];
    [session sendMouseWheel: dy :false :location.x :location.y];
}

//*****************************************************************************
-(void)keyDown:(NSEvent*)event
{
    uint16_t key_code = [event keyCode];
    NSLog(@"keyDown: key_code %d", key_code);
    if (key_code < 256)
    {
        struct rdp_key_code_t* kc = keymap + key_code;
        if ([session sendKeyboardScancode:kc->flags[0] :kc->code])
        {
            kc->is_down = true;
        }
    }
}

//*****************************************************************************
-(void)keyUp:(NSEvent*)event
{
    uint16_t key_code = [event keyCode];
    NSLog(@"keyUp: key_code %d", key_code);
    if (key_code < 256)
    {
        struct rdp_key_code_t* kc = keymap + key_code;
        if ([session sendKeyboardScancode:kc->flags[1] :kc->code])
        {
            kc->is_down = false;
        }
    }
}

//*****************************************************************************
-(NSRect)flipRect:(NSRect)arect
{
    arect.origin.y = (content_size.height - arect.origin.y) -
            arect.size.height;
    return arect;
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
-(void)setSession:(RDPSession*)asession
{
    session = asession;
    [session retain];
}

@end
