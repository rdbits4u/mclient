
@class RDPSession;

@interface MClientView : NSView
{
    NSPoint origin;
    NSSize content_size;
    RDPSession* session;
}

-(void)setSession:(RDPSession*)asession;

@end
