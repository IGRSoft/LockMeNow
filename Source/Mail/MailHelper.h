//
//  MailHelper.h
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 2/18/15.
//
//

#import <Foundation/Foundation.h>

@interface MailHelper : NSObject

+ (void)sendUserPhoto:(NSString *)photoPath to:(NSString *)eMail;

@end
