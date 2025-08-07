
#import <Cocoa/Cocoa.h>
#import "rdpc_session.h"

@interface MClientView : NSView
{
    NSPoint origin;
    NSSize content_size;
    RDPSession* session;
}

-(void)setSession:(RDPSession*)asession;

@end
