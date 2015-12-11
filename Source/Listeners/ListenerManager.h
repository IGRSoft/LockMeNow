//
//  ListenerManager.h
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 1/27/15.
//
//

#import <Foundation/Foundation.h>

@class IGRUserDefaults;

@protocol ListenerManagerDelegate <NSObject>

- (void)makeAction:(id)sender;

@end

@interface ListenerManager : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithSettings:(IGRUserDefaults *)aSettings;

- (void)startListen;
- (void)stopListen;
- (void)makeAction:(id)sender;

@property (nonatomic, weak  ) IGRUserDefaults *userSettings;
@property (nonatomic, weak  ) id<ListenerManagerDelegate> delegate;

@end
