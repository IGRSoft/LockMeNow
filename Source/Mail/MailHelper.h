//
//  MailHelper.h
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 2/18/15.
//
//

#import <Foundation/Foundation.h>

@interface MailHelper : NSObject

- (instancetype)initWithMailAddres:(NSString *)aMail userPhoto:(NSString *)photoPath;

- (void)sendDefaultMessageAddLocation:(BOOL)anAddLocation;

@end
