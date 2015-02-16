//
//  ProcessHelper.m
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 1/19/15.
//
//

#import <ScriptingBridge/ScriptingBridge.h>
#import "iTunesHelper.h"
#import "iTunes.h"

@implementation iTunesHelper

static NSString *iTunesID = @"com.apple.iTunes";

+ (NSRunningApplication *)processIsRunningWithBundleID:(NSString *)aBundleID
{
	NSRunningApplication *runningApplication = nil;

	NSArray *applications = [NSRunningApplication runningApplicationsWithBundleIdentifier:aBundleID];
	
	if (applications.count)
	{
		runningApplication = [applications firstObject];
	}
	
	return runningApplication;
}

+ (BOOL)isItunesRuning
{
	return [iTunesHelper processIsRunningWithBundleID:iTunesID] != nil;
}

+ (BOOL)isMusicPlaing
{
	iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:iTunesID];
	
	return ([iTunes playerState] == iTunesEPlSPlaying);
}

+ (BOOL)isMusicPaused
{
	iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:iTunesID];
	
	return ([iTunes playerState] == iTunesEPlSPaused || [iTunes playerState] == iTunesEPlSStopped);
}

+ (void)playpause
{
	iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:iTunesID];
	[iTunes playpause];
}
@end
