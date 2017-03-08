//
//  XPCScripting.m
//  XPCScripting
//
//  Created by Vitalii Parovishnyk on 2/27/15.
//
//

#import "XPCScripting.h"

@implementation XPCScripting

- (void)makeLoginWindowLock
{
    NSTask *task;
    NSMutableArray *arguments = [NSMutableArray arrayWithObject:@"-suspend"];
    
    task = [[NSTask alloc] init];
    [task setArguments: arguments];
    [task setLaunchPath: @"/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession"];
    [task launch];
}

- (void)makeJustLock:(BOOL)useCurrentScrrenSaver scriptPath:(NSString *)scriptPath
{
	BOOL runnedCurrentScreenSaver = NO;
    if (useCurrentScrrenSaver)
    {
		NSDictionary *error = nil;
		NSURL *path = [NSURL fileURLWithPath:scriptPath];
		NSAppleScript* appleScript = [[NSAppleScript alloc] initWithContentsOfURL:path
																			error:&error];
		if (!error.count)
		{
			[appleScript executeAndReturnError:&error];
		}
		
		runnedCurrentScreenSaver = (error.count == 0);
    }
	
	if (!runnedCurrentScreenSaver)
    {
        io_registry_entry_t r =	IORegistryEntryFromPath(kIOMasterPortDefault, "IOService:/IOResources/IODisplayWrangler");
        if(!r) return;
        IORegistryEntrySetCFProperty(r, CFSTR("IORequestIdle"), kCFBooleanTrue);
        IOObjectRelease(r);
    }
}

- (void)makeJustUnLock
{
    io_registry_entry_t r =	IORegistryEntryFromPath(kIOMasterPortDefault, "IOService:/IOResources/IODisplayWrangler");
    if(!r) return;
    IORegistryEntrySetCFProperty(r, CFSTR("IORequestIdle"), kCFBooleanFalse);
    IOObjectRelease(r);
}

@end
