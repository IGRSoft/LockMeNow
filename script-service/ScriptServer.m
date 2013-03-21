//
//  ScriptHelper.m
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 2/13/13.
//
//

#import "ScriptServer.h"
#include <AppKit/AppKit.h>
#include <pwd.h>
#import "AEVTBuilder.h"
#include <SystemConfiguration/SystemConfiguration.h>

@implementation ScriptServer

#pragma mark -
#pragma mark NSXPCConnection method overrides

+ (ScriptServer *)sharedScriptServer {
    static dispatch_once_t onceToken;
    static ScriptServer *shared;
    dispatch_once(&onceToken, ^{
        shared = [ScriptServer new];
    });
    return shared;
}

// Implement the one method in the NSXPCListenerDelegate protocol.
- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    // Configure the new connection and resume it. Because this is a singleton object, we set 'self' as the exported object and configure the connection to export the 'Zip' protocol that we implement on this object.
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(ScriptAgent)];
    newConnection.exportedObject = self;
    [newConnection resume];
    
    return YES;
}

- (void)checkEncription:(void (^)(bool encription))reply
{
	bool encription = false;
	
	NSString *outputString = [self doShell:@"filevault_2_encryption_check_extension_attribute"];
	
	NSRange textRange;
	textRange =[outputString rangeOfString:@"FileVault 2 Encryption Complete"];
	if(textRange.location != NSNotFound)
	{
		encription = true;
	}
	
	reply(encription);
}

- (NSString*)doShell:(NSString*)file
{
	NSString *scriptPath = [[NSBundle mainBundle] pathForResource:file ofType:@"sh"];
	
	NSTask *scriptTask = [NSTask new];
	NSPipe *outputPipe = [NSPipe pipe];
	
	if ([[NSFileManager defaultManager] isExecutableFileAtPath:scriptPath] == NO) {
		NSArray *chmodArguments = [NSArray arrayWithObjects:@"+x", scriptPath, nil];
		
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

- (void)makeLoginWindowLock
{
	ProcessSerialNumber psn = {0, 0};
	[[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"com.apple.logind"
														 options:NSWorkspaceLaunchWithoutAddingToRecents
								  additionalEventParamDescriptor:nil
												launchIdentifier:NULL];
	
	NSEnumerator *enumerator = [[[NSWorkspace sharedWorkspace] runningApplications] objectEnumerator];
	NSDictionary *dict;
	while ((dict = [enumerator nextObject])) {
		if ([[dict objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:@"com.apple.logind"]) {
			psn.highLongOfPSN = [[dict objectForKey:@"NSApplicationProcessSerialNumberHigh"] unsignedIntValue];
			psn.lowLongOfPSN  = [[dict objectForKey:@"NSApplicationProcessSerialNumberLow"] unsignedIntValue];
			break;
		}
	}
	
	NSAppleEventDescriptor *descriptor = [AEVT class:kCoreEventClass id:kAEQuitApplication
											  target:psn,
										  ENDRECORD];
	[descriptor sendWithImmediateReplyWithTimeout:5];
	
	NSTask *task;
	NSMutableArray *arguments = [NSArray arrayWithObject:@"-suspend"];
	
	task = [[NSTask alloc] init];
	[task setArguments: arguments];
	[task setLaunchPath: @"/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession"];
	[task launch];
	
	//fpsystem('/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession -suspen');

	
	//[self doShell:@"loginWindow"];
}

@end
