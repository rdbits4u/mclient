
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
    //NSLog(@"isFlipped");
    return YES;
}

//*****************************************************************************
-(BOOL)acceptsFirstResponder
{
    //NSLog(@"acceptsFirstResponder");
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
    bs_context = CGBitmapContextCreate(NULL,
            NSWidth(contentRect), NSHeight(contentRect), 8, 0, colorSpace,
            kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst);
    CGColorSpaceRelease(colorSpace);
}

//*****************************************************************************
-(void)mouseDown:(NSEvent *)event
{
    NSPoint clickLocation;
    // convert the click location into the view coords
    clickLocation = [self convertPoint:[event locationInWindow] fromView:nil];
    clickLocation = [self toClientArea:clickLocation];
    uint16_t x = clickLocation.x + 0.5;
    uint16_t y = clickLocation.y + 0.5;
    NSLog(@"mouseDown x %f y %f", clickLocation.x, clickLocation.y);
    [session sendMouseDownEvent:1 :x :y];
}

//*****************************************************************************
-(void)mouseUp:(NSEvent *)event
{
    NSPoint clickLocation;
    // convert the click location into the view coords
    clickLocation = [self convertPoint:[event locationInWindow] fromView:nil];
    clickLocation = [self toClientArea:clickLocation];
    uint16_t x = clickLocation.x + 0.5;
    uint16_t y = clickLocation.y + 0.5;
    NSLog(@"mouseUp x %f y %f", clickLocation.x, clickLocation.y);
    [session sendMouseUpEvent:1 :x :y];
}

//*****************************************************************************
-(void)mouseMoved:(NSEvent *)event
{
    //NSLog(@"mouseMoved: %@", [NSThread currentThread]);
    NSPoint clickLocation;
    // convert the click location into the view coords
    clickLocation = [self convertPoint:[event locationInWindow] fromView:nil];
    clickLocation = [self toClientArea:clickLocation];
    uint16_t x = clickLocation.x + 0.5;
    uint16_t y = clickLocation.y + 0.5;
    NSLog(@"mouseMoved x %f %d y %f %d", clickLocation.x, x, clickLocation.y, y);
    [session sendMouseMovedEvent:x :y];
}

//*****************************************************************************
-(void)mouseDragged:(NSEvent *)event
{
    //NSLog(@"mouseMoved: %@", [NSThread currentThread]);
    NSPoint clickLocation;
    // convert the click location into the view coords
    clickLocation = [self convertPoint:[event locationInWindow] fromView:nil];
    clickLocation = [self toClientArea:clickLocation];
    uint16_t x = clickLocation.x + 0.5;
    uint16_t y = clickLocation.y + 0.5;
    NSLog(@"mouseDragged x %f %d y %f %d", clickLocation.x, x, clickLocation.y, y);
    [session sendMouseMovedEvent:x :y];
}

//*****************************************************************************
-(void)drawRect:(NSRect) dirtyRect
{
    NSLog(@"drawRect");
    if (bs_context != NULL)
    {
        CGContextRef cgContext =
                [[NSGraphicsContext currentContext] CGContext];
        if (cgContext != NULL)
        {
            NSLog(@"drawRect: got CGContext");
            CGImageRef cgImage = CGBitmapContextCreateImage(bs_context);
            if (cgImage != NULL)
            {
                CGContextSaveGState(cgContext);
                CGRect rect = dirtyRect;
                CGContextClipToRect(cgContext, rect);
                rect.origin = origin;
                rect.size = content_size;
                CGContextDrawImage(cgContext, rect, cgImage);
                CGContextRestoreGState(cgContext);
                CGImageRelease(cgImage);
            }
        }
    }
    else
    {
        [[NSColor blueColor] set];
        NSRectFill(dirtyRect);
    }
    [super drawRect:dirtyRect];
}

//*****************************************************************************
-(int)drawTiles:(char*)pixels :(size_t)width :(size_t)height
        :(struct rfx_rect*)rects :(int)numRects
        :(struct rfx_tile*)tiles :(int)numTiles
{
    CGColorSpaceRef colorSpace;
    CGContextRef con;
    CGImageRef cgImage;
    CGRect* clip_rects;
    NSRect rect;
    char* tile_pixels;
    char* src;
    char* dst;
    int x;
    int y;
    int cx;
    int cy;
    int index;
    int jndex;

    NSLog(@"drawTiles:");
    if (bs_context == NULL)
    {
        return 1;
    }
    clip_rects = (CGRect*)malloc(sizeof(CGRect) * numRects);
    if (clip_rects == NULL)
    {
        return 2;
    }
    tile_pixels = (char*)malloc(64 * 64 * 4);
    if (tile_pixels == NULL)
    {
        free(clip_rects);
        return 3;
    }
    colorSpace = CGColorSpaceCreateDeviceRGB();
    if (colorSpace == NULL)
    {
        free(tile_pixels);
        free(clip_rects);
        return 4;
    }
    con = CGBitmapContextCreate(tile_pixels,
            64, 64, 8, 64 * 4, colorSpace,
            kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst);
    if (con == NULL)
    {
        CGColorSpaceRelease(colorSpace);
        free(tile_pixels);
        free(clip_rects);
        return 5;
    }
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
        cgImage = CGBitmapContextCreateImage(con);
        if (cgImage != NULL)
        {
            CGContextDrawImage(bs_context, rect, cgImage);
            CGImageRelease(cgImage);
        }
        rect = [self fromClientAreaRect:rect];
        [self setNeedsDisplayInRect:rect];
    }
    CGContextRestoreGState(bs_context);
    CGContextRelease(con);
    CGColorSpaceRelease(colorSpace);
    free(tile_pixels);
    free(clip_rects);
    return 0;
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
