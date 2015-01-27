//
//  BlockViewLock.m
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 1/26/15.
//
//

#import "BlockViewLock.h"

@interface BlockViewLock ()

@property (nonatomic) NSMutableArray *blockObjects;

@end

@implementation BlockViewLock

- (instancetype)initWithConnection:(xpc_connection_t)aConnection settings:(IGRUserDefaults *)aSettings
{
	if (self = [super initWithConnection:aConnection settings:aSettings])
	{

	}
	
	return self;
}

- (void)lock
{
	[super lock];
	
	self.allowTerminate = NO;
	
	if (_blockObjects != nil)
	{
		return;
	}
	
	_blockObjects = [[NSMutableArray alloc] init];
	
	NSRect screenRect = NSZeroRect;
	NSArray *screenArray = [NSScreen screens];
	NSUInteger screenCount = [screenArray count];
	NSUInteger index = 0;
	
	for (index = 0; index < screenCount; ++index)
	{
		NSScreen *screen = screenArray[index];
		screenRect = [screen frame];
		
		NSWindow *blocker = [[NSWindow alloc] initWithContentRect:screenRect
														styleMask:0
														  backing:NSBackingStoreBuffered
															defer:NO
														   screen:[NSScreen mainScreen]];
		[blocker setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"lock-bg"]]];
		[blocker setIsVisible:YES];
		[blocker setLevel:NSScreenSaverWindowLevel];
		[blocker makeKeyAndOrderFront:nil];
		[_blockObjects insertObject:blocker
							atIndex:index];
	}
	
	@try {
		
		NSApplication *currentApp = [NSApplication sharedApplication];
		appPresentationOptions = [currentApp presentationOptions];
		NSApplicationPresentationOptions options = NSApplicationPresentationHideDock
		+ NSApplicationPresentationHideMenuBar
		+ NSApplicationPresentationDisableForceQuit
		+ NSApplicationPresentationDisableProcessSwitching;
		[currentApp setPresentationOptions:options];
	}
	@catch(NSException * exception) {
		
		DBNSLog(@"Error.  Make sure you have a valid combination of options.");
	}
}

- (void)unlock
{
	[super unlock];
	
	_blockObjects = nil;
	
	if (!self.allowTerminate)
	{
		NSApplication *currentApp = [NSApplication sharedApplication];
		[currentApp setPresentationOptions:appPresentationOptions];
	}
	
	self.allowTerminate = YES;
}

@end
