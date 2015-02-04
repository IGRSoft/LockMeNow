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
	
	NSString *path = [[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent]; //Library
	path = [[path stringByDeletingLastPathComponent] stringByDeletingLastPathComponent]; //Contents
	path = [path stringByDeletingLastPathComponent]; //App
	
	[[NSWorkspace sharedWorkspace] launchApplication:path];
	[NSApp terminate:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	// Insert code here to tear down your application
}

@end
