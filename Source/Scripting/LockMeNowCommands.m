//
//  LockMeNowCommands.m
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 2/16/15.
//
//

#import "LockMeNowCommands.h"
#import "LockMeNowAppDelegate.h"

@interface LockMeNowCommands ()

@end

@implementation LockMeNowCommands

- (id)performDefaultImplementation
{
    /* output to the log */
    
    NSScriptCommandDescription *command = [self commandDescription];
    BOOL result = NO;
    
    if ([command.commandName isEqualToString:@"takePhoto"])
    {
        DBNSLog(@"Take User Photo");
        
        LockMeNowAppDelegate *app = [[NSApplication sharedApplication] delegate];
        
        NSString *filePath = [app takePhoto];
        
        result = filePath != nil;
    }
    
    /* return status */
    return @(result);
}

@end
