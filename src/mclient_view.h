
@class RDPSession;

@interface MyCustomLayer : CALayer
// You can add custom properties or methods here
@end

@interface MClientView : NSView
{
    NSPoint origin;
    NSSize content_size;
    RDPSession* session;
    //CGContextRef bs_context;
    CGLayerRef bs_layer;
    NSGraphicsContext* bs_gc;
    MyCustomLayer* ca_layer;
}

-(void)setSession:(RDPSession*)asession;
-(int)drawTiles:(char*)pixels :(size_t)width :(size_t)height
        :(struct rfx_rect*)rects :(int)numRects
        :(struct rfx_tile*)tiles :(int)numTiles;

@end
