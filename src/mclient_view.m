
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

@implementation MClientView

//*****************************************************************************
-(void)dealloc
{
    NSLog(@"MClientView dealloc:");
    [session release];
    [super dealloc];
}

//*****************************************************************************
-(BOOL)isFlipped
{
    //NSLog(@"isFlipped:");
    return YES;
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
    location = [self toClientArea:location];
    location.x = MAX(location.x + 0.5, 0);
    location.y = MAX(location.y + 0.5, 0);
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
    float dx = [event deltaX] * -120.0;
    float dy = [event deltaY] * 120;
    [session sendMouseWheel: dx :true :location.x :location.y];
    [session sendMouseWheel: dy :false :location.x :location.y];
}

//*****************************************************************************
-(void)keyDown:(NSEvent*)event
{
    NSLog(@"keyDown: %@", [NSThread currentThread]);
}

//*****************************************************************************
-(void)keyUp:(NSEvent*)event
{
    NSLog(@"keyUp: %@", [NSThread currentThread]);
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
                CGRect rect = dirtyRect;
                CGContextClipToRect(cgContext, rect);
                rect.origin = origin;
                rect.size = content_size;
                CGContextDrawImage(cgContext, rect, cgImage);
                //int rc1 = CFGetRetainCount(cgImage);
                //NSLog(@"drawRect rc1 %d", rc1);
                CGContextRestoreGState(cgContext);
                CGImageRelease(cgImage);
            }
        }
    }
    [super drawRect:dirtyRect];
}

//*****************************************************************************
-(int)drawTileSet:(char*)pixels :(size_t)width :(size_t)height
        :(struct rfx_rect*)rects :(int)numRects
        :(struct rfx_tile*)tiles :(int)numTiles
        :(CGRect*)clip_rects :(char*)tile_pixels :(CGContextRef)con
{
    CGImageRef cgImage;
    NSRect rect;
    char* src;
    char* dst;
    int x;
    int y;
    int cx;
    int cy;
    int index;
    int jndex;

    for (index = 0; index < numRects; index++)
    {
        x = rects[index].x;
        y = rects[index].y;
        cx = rects[index].cx;
        cy = rects[index].cy;
        clip_rects[index] = CGRectMake(x, y, cx, cy);
    }
    CGContextSaveGState(bs_context);
    CGContextClipToRects(bs_context, clip_rects, numRects);
    for (index = 0; index < numTiles; index++)
    {
        x = tiles[index].x;
        y = tiles[index].y;
        cx = tiles[index].cx;
        cy = tiles[index].cy;
        rect = NSMakeRect(x, y, cx, cy);
        // flip tile image
        src = pixels + width * 4 * y + x * 4;
        dst = tile_pixels + (64 * 64 * 4 - 64 * 4);
        for (jndex = 0; jndex < 64; jndex++)
        {
            memcpy(dst, src, 64 * 4);
            dst -= 64 * 4;
            src += width * 4;
        }
        // draw iamge to backing store
        cgImage = CGBitmapContextCreateImage(con);
        if (cgImage != NULL)
        {
            CGContextDrawImage(bs_context, rect, cgImage);
            CGImageRelease(cgImage);
        }
    }
    CGContextRestoreGState(bs_context);
    for (index = 0; index < numRects; index++)
    {
        // invalidate to cause draw
        rect = [self fromClientAreaRect:clip_rects[index]];
        [self setNeedsDisplayInRect:rect];
    }
    return 0;
}

//*****************************************************************************
-(int)drawTiles:(char*)pixels :(size_t)width :(size_t)height
        :(struct rfx_rect*)rects :(int)numRects
        :(struct rfx_tile*)tiles :(int)numTiles
{
    CGColorSpaceRef colorSpace;
    CGContextRef con;
    CGRect* clip_rects;
    char* tile_pixels;
    int rv;

    //NSLog(@"drawTiles:");
    rv = 1;
    if (bs_context != NULL)
    {
        rv = 2;
        clip_rects = (CGRect*)malloc(sizeof(CGRect) * numRects);
        if (clip_rects != NULL)
        {
            rv = 3;
            tile_pixels = (char*)malloc(64 * 64 * 4);
            if (tile_pixels != NULL)
            {
                rv = 4;
                colorSpace = CGColorSpaceCreateDeviceRGB();
                if (colorSpace != NULL)
                {
                    rv = 5;
                    con = CGBitmapContextCreate(tile_pixels,
                            64, 64, 8, 64 * 4, colorSpace,
                            kCGBitmapByteOrder32Little |
                            kCGImageAlphaNoneSkipFirst);
                    if (con != NULL)
                    {
                        rv = [self drawTileSet:pixels :width :height
                                :rects :numRects :tiles :numTiles
                                :clip_rects :tile_pixels :con];
                        CGContextRelease(con);
                    }
                    CGColorSpaceRelease(colorSpace);
                }
                free(tile_pixels);
            }
            free(clip_rects);
        }
    }
    return rv;
}

//*****************************************************************************
-(NSPoint)toClientArea:(NSPoint)pt
{
    NSPoint lpt = pt;
    lpt.x -= origin.x;
    lpt.y -= origin.y;
    return lpt;
}

//*****************************************************************************
-(NSRect)toClientAreaRect:(NSRect)rect
{
    NSRect lrect = rect;
    lrect.origin.x -= origin.x;
    lrect.origin.y -= origin.y;
    return lrect;
}

//*****************************************************************************
-(NSPoint)fromClientArea:(NSPoint)pt
{
    NSPoint lpt = pt;
    lpt.x += origin.x;
    lpt.y += origin.y;
    return lpt;
}

//*****************************************************************************
-(NSRect)fromClientAreaRect:(NSRect)rect
{
    NSRect lrect = rect;
    lrect.origin.x += origin.x;
    lrect.origin.y += origin.y;
    return lrect;
}

//*****************************************************************************
-(void)setSession:(RDPSession*)asession
{
    session = asession;
    [session retain];
}

@end
