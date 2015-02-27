//
//  LockManager.h
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 1/22/15.
//
//

#import <Foundation/Foundation.h>

@class IGRUserDefaults;

@protocol LockManagerDelegate <NSObject>

- (void)unLockSuccess;
- (void)detectedWrongPassword;

@end

@interface LockManager : NSObject

- (instancetype)initWithConnection:(NSXPCConnection *)aConnection settings:(IGRUserDefaults *)aSettings NS_DESIGNATED_INITIALIZER;

- (void)lock;
- (void)unlock;

@property (nonatomic, weak  ) NSXPCConnection *scriptServiceConnection;
@property (nonatomic, weak  ) IGRUserDefaults *userSettings;
@property (nonatomic, assign) BOOL useSecurity;
@property (nonatomic, assign) BOOL allowTerminate;

@property (nonatomic, weak) id<LockManagerDelegate> delegate;

@end
