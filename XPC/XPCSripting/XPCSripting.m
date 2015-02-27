//
//  XPCSripting.m
//  XPCSripting
//
//  Created by Vitalii Parovishnyk on 2/27/15.
//
//

#import "XPCSripting.h"

@implementation XPCSripting

- (NSString *)doShell:(NSString *)file
{
    NSString *scriptPath = [[NSBundle mainBundle] pathForResource:file ofType:@"sh"];
    
    NSTask *scriptTask = [NSTask new];
    NSPipe *outputPipe = [NSPipe pipe];
    
    if ([[NSFileManager defaultManager] isExecutableFileAtPath:scriptPath] == NO) {
        NSArray *chmodArguments = @[@"+x", scriptPath];
        
        NSTask *chmod = [NSTask launchedTaskWithLaunchPath:@"/bin/chmod" arguments:chmodArguments];
        
        [chmod waitUntilExit];
    }
    
    [scriptTask setStandardOutput:outputPipe];
    [scriptTask setLaunchPath:scriptPath];
    
    NSFileHandle *filehandle = [outputPipe fileHandleForReading];
    
    [scriptTask launch];
    [scriptTask waitUntilExit];
    
    NSData *outputData    = [filehandle readDataToEndOfFile];
    
    NSString *outputString  = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
    
    return outputString;
}

- (void)checkEncriptionWithReply:(void (^)(BOOL))reply
{
    BOOL encription = NO;
    
    NSString *outputString = [self doShell:@"filevault_2_encryption_check_extension_attribute"];
    
    NSRange textRange;
    textRange =[outputString rangeOfString:@"FileVault 2 Encryption Complete"];
    if(textRange.location != NSNotFound)
    {
        encription = YES;
    }
    
    reply(encription);
}

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
