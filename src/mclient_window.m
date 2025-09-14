
#include <poll.h>
#include <librdpc.h>
#include <libsvc.h>
#include <libcliprdr.h>
#include <librdpsnd.h>
#include <rlecodec_decode.h>
#include <rfxcodec_decode.h>
#import <Cocoa/Cocoa.h>
#import "mclient_app_delegate.h"
#import "mclient_view.h"
#import "mclient_window.h"
#import "rdpc_session.h"
#import "mclient_log.h"

@implementation MClientWindow

//*****************************************************************************
-(BOOL)canBecomeKeyWindow
{
    NSLog(@"MClientWindow canBecomeKeyWindow:");
    return YES;
}

//*****************************************************************************
-(void)becomeKeyWindow
{
    //NSLog(@"MClientWindow becomeKeyWindow:");
    [super becomeKeyWindow];
    NSView* cv = [self contentView];
    if (cv != nil)
    {
        int count = [[cv subviews] count];
        if (count == 1)
        {
            MClientView* view = [cv subviews][0];
            if (view != nil)
            {
                if (view != [self firstResponder])
                {
                    NSLog(@"MClientWindow becomeKeyWindow: setting firstResponder");
                    [self makeFirstResponder:view];
                }
                [view focusIn];
            }
        }
    }
}

//*****************************************************************************
-(void)resignKeyWindow
{
    //NSLog(@"MClientWindow resignKeyWindow:");
    [super resignKeyWindow];
    NSView* cv = [self contentView];
    if (cv != nil)
    {
        int count = [[cv subviews] count];
        if (count == 1)
        {
            MClientView* view = [cv subviews][0];
            if (view != nil)
            {
                [view focusOut];
            }
        }
    }
}

@end
