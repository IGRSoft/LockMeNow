//
//  DCLALAppDelegate.m
//  LaunchAtLogin
//
//  Created by Boy van Amstel on 07-08-12.
//  Copyright (c) 2012 Danger Cove. All rights reserved.
//

#import "DCLALAppDelegate.h"

@implementation DCLALAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    // From: http://stackoverflow.com/questions/11292058/how-to-add-a-sandboxed-app-to-the-login-items
    loginController = [[StartAtLoginController alloc] init];
	[loginController setBundle:[NSBundle bundleWithPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Library/LoginItems/LaunchAtLoginHelper.app"]]];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

- (IBAction)toggleStartup:(id)sender {
    bool enableStartup = [[NSUserDefaults standardUserDefaults] boolForKey:@"enableStartup"];
    [loginController setStartAtLogin: enableStartup];
}

@end
