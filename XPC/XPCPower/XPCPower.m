//
//  XPCPower.m
//  XPCPower
//
//  Created by Vitalii Parovishnyk on 12/15/15.
//
//

#import "XPCPower.h"

#import <IOKit/IOKitLib.h>
#import <IOKit/ps/IOPSKeys.h>
#import <IOKit/ps/IOPowerSources.h>
#import <IOKit/pwr_mgt/IOPMLib.h>

@interface XPCPower ()
{
	CFRunLoopRef _runLoop;
	CFRunLoopSourceRef _runLoopSource;
}

@property (nonatomic, copy) FoudChangesInPowerBlock foudChangesInPowerBlock;
@property (nonatomic, assign) IGRPowerMode	powerMode;
@end

@implementation XPCPower

- (void)startCheckPower:(FoudChangesInPowerBlock __nonnull)replyBlock
{
	self.foudChangesInPowerBlock = [replyBlock copy];
	_powerMode = IGRPowerMode_None;
	
	[self runCustomLoop];
}

- (void)stopCheckPower
{
	self.foudChangesInPowerBlock = nil;
	
	if (_runLoopSource && _runLoop)
	{
		CFRunLoopRemoveSource(_runLoop,_runLoopSource,kCFRunLoopDefaultMode);
	}
	if (_runLoopSource)
	{
		CFRelease(_runLoopSource);
	}
}

- (void)updateReplayBlock:(FoudChangesInPowerBlock __nonnull)replyBlock
{
	self.foudChangesInPowerBlock = [replyBlock copy];
}

void IGRPowerMonitorCallback(void *context)
{
	XPCPower* xpcPower = (__bridge XPCPower *)(context);
	
    CFTypeRef powerSource = IOPSCopyPowerSourcesInfo();
	CFStringRef source = IOPSGetProvidingPowerSourceType(powerSource);
	if (source)
	{
		NSString *sSource = (__bridge NSString *)(source);
		
		BOOL isBatteryPower = [@"Battery Power" isEqualToString:sSource];
		BOOL isACPower = [@"AC Power" isEqualToString:sSource];
		
		if (xpcPower.powerMode == IGRPowerMode_None)
		{
			xpcPower.powerMode = isBatteryPower ? IGRPowerMode_Battery : IGRPowerMode_ACPower;
		}
		else if (isBatteryPower && xpcPower.powerMode == IGRPowerMode_ACPower)
		{
			xpcPower.powerMode = IGRPowerMode_Battery;
			if (xpcPower.foudChangesInPowerBlock)
			{
				xpcPower.foudChangesInPowerBlock();
			}
		}
		else if (isACPower && xpcPower.powerMode == IGRPowerMode_Battery)
		{
			xpcPower.powerMode = IGRPowerMode_ACPower;
		}
	}
    
    CFRelease(powerSource);
}

- (void)runCustomLoop
{
	_runLoop = CFRunLoopGetCurrent();
	_runLoopSource = IOPSCreateLimitedPowerNotification(IGRPowerMonitorCallback, (__bridge void *)(self));
	
	if (_runLoop && _runLoopSource)
	{
		CFRunLoopAddSource(_runLoop, _runLoopSource, kCFRunLoopDefaultMode);
	}
	
	IGRPowerMonitorCallback((__bridge void *)(self)); // get current power state
	
	CFRunLoopRun();
}

@end
