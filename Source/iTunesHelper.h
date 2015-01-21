//
//  ProcessHelper.h
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 1/19/15.
//
//

#import <Foundation/Foundation.h>

@interface iTunesHelper : NSObject

+ (BOOL)isItunesRuning;
+ (BOOL)isMusicPlaing;
+ (BOOL)isMusicPaused;
+ (void)playpause;

@end
