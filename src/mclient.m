
#import "mclient_app_delegate.h"
#import "mclient_log.h"

//*****************************************************************************
int
main(int argc, const char** argv)
{
    log_init();
    NSLog(@"main: argc %d", argc);
    NSLog(@"main: %@", [NSThread currentThread]);
    // Create an instance of your application delegate
    MClientAppDelegate* delegate = [MClientAppDelegate new];
    // Get the shared NSApplication instance
    NSApplication* app = [NSApplication sharedApplication];
    [delegate setApp:app]; // my setter
    if ([delegate processArgs:argc :argv] != 0)
    {
        NSLog(@"main: error processing argc");
        [delegate release];
        log_deinit();
        return 0;
    }
    // Assign the delegate to the NSApplication instance
    [app setDelegate:delegate];
    [app setActivationPolicy:NSApplicationActivationPolicyRegular];
    [app activateIgnoringOtherApps:YES];
    //dispatch_async(dispatch_get_main_queue(), ^{[app activateIgnoringOtherApps:YES];});
    // read some items out of bundle
    NSBundle* bundleInfo = [[NSBundle mainBundle] infoDictionary];
    NSString* appName = [bundleInfo objectForKey:@"CFBundleName"];
    [delegate setAppName:appName]; // my setter
    NSString* appVersion = [bundleInfo objectForKey:@"CFBundleVersion"];
    [delegate setAppVersion:appVersion]; // my setter
    [delegate release];
    // setup menu
    NSString* quitMenuItemTitle = [@"Quit " stringByAppendingString:appName];
    NSMenuItem* quitMenuItem = [NSMenuItem alloc];
    [quitMenuItem
        initWithTitle:quitMenuItemTitle
        action:@selector(terminate:)
        keyEquivalent:@"q"];
    NSMenu* appMenu = [NSMenu new];
    [appMenu addItem:quitMenuItem];
    [quitMenuItem release];
    NSMenuItem* appMenuItem = [NSMenuItem new];
    [appMenuItem setSubmenu:appMenu];
    [appMenu release];
    NSMenu* mainMenu = [NSMenu new];
    [mainMenu addItem:appMenuItem];
    [app setMainMenu:mainMenu];
    [mainMenu release];
    NSLog(@"main starting main loop");
    [app run];
    return 0;
}
