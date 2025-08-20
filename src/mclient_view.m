
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

//#import <QuartzCore/QuartzCore.h> // Required for CALayer

@implementation MyCustomLayer

- (id)init
{
    self = [super init];
    if (self)
    {
        // Perform custom initialization for your layer
        self.backgroundColor = [NSColor blueColor].CGColor;
    }
    return self;
}

// Override to provide custom drawing if needed
- (void)drawInContext:(CGContextRef)ctx
{
    NSLog(@"MyCustomLayer drawInContext:");
    CGRect rect = CGContextGetClipBoundingBox(ctx);
    NSLog(@"MyCustomLayer drawInContext: x %d y %d width %d height %d",
            rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    // Custom drawing for your layer
    CGContextSetRGBFillColor(ctx, 1.0, 0.0, 0.0, 1.0); // Red color
    //CGContextFillEllipseInRect(ctx, self.bounds);
    CGContextFillRect(ctx, rect);
}

@end

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
-(BOOL)wantsUpdateLayer1
{
    NSLog(@"wantsUpdateLayer:");
    return YES;
}

//*****************************************************************************
-(CALayer*)makeBackingLayer1
{
    NSLog(@"makeBackingLayer:");
    //return [[CALayer alloc] init];
    ca_layer = [[MyCustomLayer alloc] init];
    return ca_layer;
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

    if (bs_layer != NULL)
    {
        CGLayerRelease(bs_layer);
        bs_layer = NULL;
        //bs_context = NULL;
    }

    // create / recreate backing store
    // if (bs_context != NULL)
    // {
    //     CGContextRelease(bs_context);
    // }
    // CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // bs_context = CGBitmapContextCreate(NULL,
    //         NSWidth(contentRect), NSHeight(contentRect), 8, 0, colorSpace,
    //         kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst);
    // CGColorSpaceRelease(colorSpace);
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

    CGContextRef cgContext =
            [[NSGraphicsContext currentContext] CGContext];
    if (cgContext != NULL)
    {
        if (bs_layer == NULL)
        {
            //CGContextRef currentContext = UIGraphicsGetCurrentContext();
            //bs_layer = CGLayerCreateWithContext(currentContext, content_size, NULL);
            bs_layer = CGLayerCreateWithContext(cgContext, content_size, NULL);
            //if (bs_layer != NULL)
            //{
            //    if (bs_context == NULL)
            //    {
            //        bs_context = CGLayerGetContext(bs_layer);
            //        NSLog(@"drawRect: bs_context set to %p", bs_context);
            //    }
            //}
        }
        if (bs_gc == NULL)
        {
            //bs_gc = [NSGraphicsContext graphicsContextWithCGContext :cgContext flipped:NO];
            //NSLog(@"drawRect: bs_gc set to %p", bs_gc);
        }
    }

    //[NSGraphicsContext saveGraphicsState];
    //[NSGraphicsContext setCurrentContext:bs_gc];
    //[NSGraphicsContext restoreGraphicsState];

    if (bs_layer != NULL)
    {
        if (cgContext != NULL)
        {
            CGContextSaveGState(cgContext);
            CGContextClipToRect(cgContext, dirtyRect);
            CGContextDrawLayerAtPoint(cgContext, origin, bs_layer);
            CGContextRestoreGState(cgContext);

            //CGContextFlush(cgContext);
            //CGContextSynchronize(cgContext);

            //CGLayerRef new_bs_layer = CGLayerCreateWithContext(cgContext, content_size, NULL);
            //CGContextRef new_bs_context = CGLayerGetContext(new_bs_layer);
            //CGContextDrawLayerAtPoint(new_bs_context, CGPointMake(0, 0), bs_layer);
            //CGLayerRelease(bs_layer);
            //bs_layer = new_bs_layer;

        }
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
    CGContextRef bs_context;
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
    if (bs_layer == NULL)
    {
        //[ca_layer setNeedsDisplayInRect:CGRectMake(0, 0, 100, 100)];
        return 1;
    }
    bs_context = CGLayerGetContext(bs_layer);
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
    CGColorSpaceRelease(colorSpace);
    if (con == NULL)
    {
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
    //CGContextBeginTransparencyLayer(bs_context, NULL);
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

        //con = CGBitmapContextCreate(tile_pixels,
        //    64, 64, 8, 64 * 4, colorSpace,
        //    kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst);

        // draw iamge to backing store
        cgImage = CGBitmapContextCreateImage(con);
        if (cgImage != NULL)
        {
            //CGImageRef new_iamge = CGImageCreateCopy(cgImage);
            //CGContextClearRect(bs_context, rect);
            CGContextDrawImage(bs_context, rect, cgImage);
            CGContextFlush(bs_context);
            //CGContextDrawImage(bs_context, rect, cgImage);
            //CGContextClearRect(bs_context, rect);
            int rc1 = CFGetRetainCount(cgImage);
            NSLog(@"old rc %d", rc1);
            //int rc2 = CFGetRetainCount(new_iamge);
            //NSLog(@"new rc %d", rc2);
            //CGImageRelease(cgImage);
            //CGImageRelease(new_iamge);
            CGImageRelease(cgImage);
        }

        // con = CGBitmapContextCreate(tile_pixels,
        //     64, 64, 8, 64 * 4, colorSpace,
        //     kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst);
        // CGLayerRef lay1 = CGLayerCreateWithContext(con, CGSizeMake(64, 64), NULL);
        // NSLog(@"drawTiles: lay1 %p", lay1);
        // CGContextDrawLayerAtPoint(bs_context, rect.origin, lay1);
        // CGLayerRelease(lay1);
        //CGContextRelease(con);

    }
    //CGContextEndTransparencyLayer(bs_context);
    CGContextRestoreGState(bs_context);
    for (index = 0; index < numRects; index++)
    {
        // invalidate to cause draw
        rect = [self fromClientAreaRect:clip_rects[index]];
        [self setNeedsDisplayInRect:rect];
    }

    //CGContextFlush(bs_context);
    //CGContextSynchronize(bs_context);

    CGContextRelease(con);
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
