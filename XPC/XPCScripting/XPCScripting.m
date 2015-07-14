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

- (void)makeJustLock:(BOOL)useCurrentScrrenSaver
{
    if (useCurrentScrrenSaver)
    {
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath: @"/System/Library/Frameworks/ScreenSaver.framework/Resources/ScreenSaverEngine.app/Contents/MacOS/ScreenSaverEngine"];
        [task launch];
    }
    else
    {
        io_registry_entry_t r =	IORegistryEntryFromPath(kIOMasterPortDefault, "IOService:/IOResources/IODisplayWrangler");
        if(!r) return;
        IORegistryEntrySetCFProperty(r, CFSTR("IORequestIdle"), kCFBooleanTrue);
        IOObjectRelease(r);
    }
}

@end
