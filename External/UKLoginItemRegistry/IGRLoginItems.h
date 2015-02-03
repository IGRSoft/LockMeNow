//
//  IGRLoginItems.h
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 2/3/15.
//
//

#import <Foundation/Foundation.h>

@interface IGRLoginItems : NSObject

+ (BOOL)isLoginItem:(NSURL *)itemUrl;
+ (NSError *)addLoginItem:(NSURL *)itemUrl hide:(BOOL)hide;
+ (NSError *)removeLoginItem:(NSURL *)itemUrl;

@end
