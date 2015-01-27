//
//  ListenerManager.m
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 1/27/15.
//
//

#import "ListenerManager.h"

@implementation ListenerManager

- (instancetype)initWithSettings:(IGRUserDefaults *)aSettings
{
    if (self = [super init])
    {
        _userSettings = aSettings;
    }
    
    return self;
}

- (void)startListen
{
    DBNSLog(@"%s", __func__);
}

- (void)stopListen
{
    DBNSLog(@"%s", __func__);
}

- (void)setUserSettings:(IGRUserDefaults *)userSettings
{
    [self stopListen];
    
    _userSettings = userSettings;
    
    [self startListen];
}

- (void)makeAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(makeAction:)])
    {
        [self.delegate makeAction:sender];
    }
}

@end
