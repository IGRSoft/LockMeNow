//
//  DCLALHAppDelegate.m
//  LaunchAtLoginHelper
//
//  Created by Boy van Amstel on 07-08-12.
//  Copyright (c) 2012 Danger Cove. All rights reserved.
//

#import "DCLALHAppDelegate.h"

@implementation DCLALHAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Get the app path by removing LoginItems, Library, Contens
    NSString *appPath = [[[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent]  stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
    
    // Get app executable name
    NSString *appFileName = [[appPath lastPathComponent] stringByDeletingPathExtension];
    
    // Create path to executable
    NSArray *p = [appPath pathComponents];
    NSMutableArray *pathComponents = [NSMutableArray arrayWithArray:p];
    [pathComponents addObject:@"Contents"];
    [pathComponents addObject:@"MacOS"];
    [pathComponents addObject:appFileName];
    NSString *execPath = [NSString pathWithComponents:pathComponents];
    
    // Run the app
    [[NSWorkspace sharedWorkspace] launchApplication:execPath];
    
    // Terminate self
    [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0];
}

@end
