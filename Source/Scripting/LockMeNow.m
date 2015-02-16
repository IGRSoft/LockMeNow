//
//  ScriptApplication.m
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 2/16/15.
//
//

#import "LockMeNow.h"
#import "LockMeNowAppDelegate.h"

@implementation NSApplication (LockMeNow)

- (NSNumber*) takePhoto
{
    /* output to the log */
    DBNSLog(@"Take User Photo");
    
    LockMeNowAppDelegate *app = [[NSApplication sharedApplication] delegate];
    
    [app takePhoto];
    
    /* return always ready */
    return [NSNumber numberWithBool:YES];
}

@end
