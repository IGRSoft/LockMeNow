//
//  XPCScreen.m
//  XPCScreen
//
//  Created by Vitalii Parovishnyk on 3/1/15.
//
//

#import "XPCScreen.h"

@interface XPCScreen ()

@property (nonatomic, copy) DetectedUnlockBlock detectedUnlockBlock;

@end

@implementation XPCScreen

- (void)startListenScreenUnlock:(DetectedUnlockBlock __nonnull)replyBlock
{
    self.detectedUnlockBlock = [replyBlock copy];
    
    NSDistributedNotificationCenter* distCenter = [NSDistributedNotificationCenter defaultCenter];
    [distCenter addObserver:self
                   selector:@selector(screenIsLocked:)
                       name:@"IGRNotificationScreenLocked"
                     object:nil];
    
    [distCenter addObserver:self
                   selector:@selector(screenIsUnlocked:)
                       name:@"IGRNotificationScreenUnLocked"
                     object:nil];
}

- (void)stopListenScreenUnlock
{    
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - NSDistributedNotificationCenter

- (void)screenIsLocked:(NSNotification *)aNotification
{
    NSLog(@"Screen Lock");
}

- (void)screenIsUnlocked:(NSNotification *)aNotification
{
    NSLog(@"Screen Unlock");
    
    [self stopListenScreenUnlock];
    
    if (self.detectedUnlockBlock)
    {
        self.detectedUnlockBlock();
    }
}

@end
