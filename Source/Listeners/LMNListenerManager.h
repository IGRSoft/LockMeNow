//
//  LMNListenerManager.h
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 1/27/15.
//
//

#import <Foundation/Foundation.h>

@class IGRUserDefaults;

@protocol LMNListenerManagerDelegate <NSObject>

- (void)makeLockAction:(id)sender;
- (void)makeUnlockAction:(id)sender;

@end

@interface LMNListenerManager : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithSettings:(IGRUserDefaults *)aSettings;

- (void)startListen;
- (void)stopListen;

- (void)makeLockAction:(id)sender;
- (void)makeUnlockAction:(id)sender;

- (void)reset;

@property (nonatomic, weak  ) IGRUserDefaults *userSettings;
@property (nonatomic, weak  ) id<LMNListenerManagerDelegate> delegate;

@end
