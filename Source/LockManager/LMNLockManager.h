//
//  LMNLockManager.h
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 1/22/15.
//
//

#import <Foundation/Foundation.h>

@class IGRUserDefaults;

@protocol LMNLockManagerDelegate <NSObject>

- (void)unLockSuccess;

- (void)detectedEnterPassword;
- (void)detectedUnplygMagSafeAction;

@end

@interface LMNLockManager : NSObject

- (instancetype)initWithConnection:(NSXPCConnection *)aConnection settings:(IGRUserDefaults *)aSettings;

- (void)lock;
- (void)unlockByLockManager:(BOOL)byManager;

@property (nonatomic, weak  ) NSXPCConnection *scriptServiceConnection;
@property (nonatomic, weak  ) IGRUserDefaults *userSettings;
@property (nonatomic, assign) BOOL useSecurity;
@property (nonatomic, assign) BOOL allowTerminate;

@property (nonatomic, assign) BOOL isLocked;

@property (nonatomic, weak) id<LMNLockManagerDelegate> delegate;

@end
