//
//  AppDelegate.m
//  LaunchHelper
//
//  Created by Vitalii Parovishnyk on 2/4/15.
//  Copyright (c) 2015 IGR Software. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	
    NSString *launchAppId = [[NSBundle mainBundle] infoDictionary][@"LaunchAppId"];
    
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    NSArray *runningApplications = [[ws runningApplications] valueForKey:@"bundleIdentifier"];
    
    NSLog(@"launchAppName - %@", launchAppId);
    NSLog(@"runningApplications: %@", runningApplications);
    
    if (![runningApplications containsObject:launchAppId])
    {
        NSString *launchAppName = [[NSBundle mainBundle] infoDictionary][@"LaunchAppName"];
        [ws launchApplication:launchAppName];
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	// Insert code here to tear down your application
}

@end
