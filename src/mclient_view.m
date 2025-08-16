
#include <poll.h>
#include <librdpc.h>
#include <libsvc.h>
#include <libcliprdr.h>
#include <librdpsnd.h>
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
    return TRUE;
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
    // [[NSColor redColor] set];
    // //NSRectFill(dirtyRect);
    // NSRect rect = NSMakeRect(0, 0, content_size.width, content_size.height);
    // rect = [self fromClientAreaRect:rect];
    // NSRectFill(rect);

    // [[NSColor greenColor] set];
    // NSBezierPath *line = [NSBezierPath bezierPath];
    // rect = NSMakeRect(0, 0, content_size.width, content_size.height);
    // rect = [self fromClientAreaRect:rect];
    // [line moveToPoint:NSMakePoint(NSMinX(rect), NSMinY(rect))];
    // [line lineToPoint:NSMakePoint(NSMaxX(rect), NSMaxY(rect))];
    // [line setLineWidth:5.0]; /// Make it easy to see
    // [line stroke];
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
