//
//  IGRLoginItems.m
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 2/3/15.
//
//

#import "IGRLoginItems.h"

NSString *IGRLoginItemsErrorDomain = @"IGRLoginItemsError";

@implementation IGRLoginItems

+ (NSArray *)copyLoginItems:(NSError **)error
{
    LSSharedFileListRef loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    
    if (!loginItemsRef)
    {
         *error = [NSError errorWithDomain:IGRLoginItemsErrorDomain
                                      code:1
                                  userInfo:[NSDictionary
                                            dictionaryWithObject:@"Can't get List of Login Items"
                                            forKey:NSLocalizedDescriptionKey]];
        return nil;
    }
    
    NSArray *loginItems = CFBridgingRelease(LSSharedFileListCopySnapshot(loginItemsRef, nil));
    
    return loginItems;

}

+ (BOOL)isLoginItem:(NSURL *)itemUrl
{
    __block BOOL result = NO;
    
    NSError *error = nil;
    NSArray *loginItems = [IGRLoginItems copyLoginItems:&error];
    
    if (error)
    {
        return result;
    }
    
    [loginItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)obj;
        
        CFURLRef urlRef;
        OSStatus err = LSSharedFileListItemResolve(itemRef, 0, &urlRef, NULL);
        
        if (err == noErr)
        {
            if (CFEqual(urlRef, (__bridge CFURLRef)itemUrl))
            {
                result = YES;
                *stop = YES;
            }
        };
    }];
    
    CFRelease((__bridge LSSharedFileListRef)loginItems);
    
    return result;
}

+ (NSError *)addLoginItem:(NSURL *)itemUrl hide:(BOOL)hide
{
    NSError *error = nil;
    
    NSArray *loginItems = [IGRLoginItems copyLoginItems:&error];
    
    if (!error)
    {
        LSSharedFileListItemRef item = LSSharedFileListInsertItemURL((__bridge LSSharedFileListRef)loginItems,
                                                                     kLSSharedFileListItemLast,
                                                                     NULL,
                                                                     NULL,
                                                                     (__bridge CFURLRef)itemUrl,
                                                                     NULL,
                                                                     NULL);
        
        if (item)
        {
            CFRelease(item);
        }
        else
        {
            error = [NSError errorWithDomain:IGRLoginItemsErrorDomain
                                        code:1
                                    userInfo:[NSDictionary
                                              dictionaryWithObject:@"Can't create Login Item"
                                              forKey:NSLocalizedDescriptionKey]];
        }
        
        CFRelease((__bridge LSSharedFileListRef)loginItems);
    }
    
    return error;
}

+ (NSError *)removeLoginItem:(NSURL *)itemUrl
{
    NSError *error = nil;
    
    NSArray *loginItems = [IGRLoginItems copyLoginItems:&error];
    
    if (!error)
    {
        LSSharedFileListItemRef loginItemRef = [IGRLoginItems itemRefForURL:itemUrl inList:loginItems];
        
        if (loginItemRef)
        {
            LSSharedFileListItemRemove((__bridge LSSharedFileListRef)loginItems, loginItemRef);
        }
    }
    
    return error;
}

+ (LSSharedFileListItemRef)itemRefForURL:(NSURL *)itemUrl inList:(NSArray *)loginItems
{
    __block LSSharedFileListItemRef result = NULL;
    
    [loginItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)obj;
        
        CFURLRef urlRef;
        OSStatus err = LSSharedFileListItemResolve(itemRef, 0, &urlRef, NULL);
        
        if (err == noErr)
        {
            if (CFEqual(urlRef, (__bridge CFURLRef)itemUrl))
            {
                result = itemRef;
                *stop = YES;
            }
        };
    }];
    
    return result;
}

@end
