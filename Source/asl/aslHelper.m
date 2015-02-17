//
//  aslHelper.m
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 2/17/15.
//
//

#import "aslHelper.h"

#define ASL_PATH @"/private/etc/asl.conf"
#define ASL_PATCH @"# Facility loginwindow gets saved in lockmenow.log\n\
> lockmenow.log mode=0777 format=bsd rotate=seq compress file_max=1M all_max=5M\n\
? [= Sender loginwindow] file lockmenow.log\n"

@implementation aslHelper

+ (BOOL)isASLPatched
{
    BOOL result = NO;
    
    NSURL *filePath = [NSURL URLWithString:ASL_PATH];
    NSError *error = nil;
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingFromURL:filePath error:&error];
    
    if (!error)
    {
        NSData *data = [fileHandle readDataToEndOfFile];
        
        NSString *str = [[NSString alloc] initWithData:data
                                              encoding:NSUTF8StringEncoding];
        
        NSRange range = [str rangeOfString:ASL_PATCH];
        
        result = range.location != NSNotFound;
        
        [fileHandle closeFile];
    }
    
    return result;
}

+ (BOOL)patchASL
{
    BOOL result = NO;
    
    NSURL *filePath = [NSURL URLWithString:ASL_PATH];
    NSError *error = nil;
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingToURL:filePath error:&error];
    
    if (!error)
    {
        [fileHandle seekToEndOfFile];
        
        [fileHandle readDataToEndOfFile];
        
        NSString *str = [ASL_PATCH copy];
        NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
        
        [fileHandle writeData:data];
        
        [fileHandle closeFile];
    }
    
    return result;
}

@end
