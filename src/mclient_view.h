
@class RDPSession;

@interface MClientView : NSView
{
    NSPoint origin;
    NSSize content_size;
    RDPSession* session;
    CGContextRef bs_context;
    CGContextRef tile_context;
    char* tile_pixels;
}

-(void)setSession:(RDPSession*)asession;
-(int)drawTiles:(char*)pixels :(size_t)width :(size_t)height
        :(struct rfx_rect*)rects :(int)numRects
        :(struct rfx_tile*)tiles :(int)numTiles;

@end
