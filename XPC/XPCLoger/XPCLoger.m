//
//  XPCLoger.m
//  XPCLoger
//
//  Created by Vitalii Parovishnyk on 2/28/15.
//
//

#import "XPCLoger.h"

#define LOG_PATH @"/private/var/log/opendirectoryd.log"

@interface XPCLoger ()

@property (nonatomic, strong) NSFileHandle *fileHandle;
@property (nonatomic, strong) NSString *lastLine;
@property (nonatomic, copy  ) FoudWrongPasswordBlock foudWrongPasswordBlock;
@property (nonatomic, strong) NSArray *modes;
@property (nonatomic, assign) BOOL taskRuning;

@end

@implementation XPCLoger

- (void)startCheckIncorrectPassword:(FoudWrongPasswordBlock __nonnull)replyBlock
{
    self.foudWrongPasswordBlock = [replyBlock copy];
    self.lastLine = nil;
    
    NSURL *filePath = [NSURL URLWithString:LOG_PATH];
    NSError *error = nil;
    
    self.fileHandle = [NSFileHandle fileHandleForReadingFromURL:filePath error:&error];
    
    if (!error)
    {
        self.taskRuning = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleChannelDataAvailable:)
                                                     name:NSFileHandleDataAvailableNotification
                                                   object:self.fileHandle];
        
        self.modes = @[@"XPCLoger"];
        [self.fileHandle waitForDataInBackgroundAndNotifyForModes:self.modes];
        
        [self runCustomLoop];
    }
}

- (void)stopCheckIncorrectPassword
{
	self.taskRuning = NO;
	
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSFileHandleDataAvailableNotification
                                                  object:self.fileHandle];
    
    self.fileHandle = nil;
    self.lastLine = nil;
    self.foudWrongPasswordBlock = nil;
}

- (void)updateReplayBlock:(FoudWrongPasswordBlock __nonnull)replyBlock
{
    self.foudWrongPasswordBlock = [replyBlock copy];
}

- (void)handleChannelDataAvailable:(NSNotification*)notification
{
    NSFileHandle *fileHandle = notification.object;
    
    NSString *str = [[NSString alloc] initWithData:fileHandle.availableData
                                          encoding:NSUTF8StringEncoding];
    
    NSString *contentForSearch = @"";
    
    BOOL skipCheck = NO;
    if (!self.lastLine)
    {
        self.lastLine = [str copy];
        skipCheck = YES;
    }
    
    NSRange newChunkRange = [str rangeOfString:self.lastLine];
    
    if (newChunkRange.location != NSNotFound)
    {
        contentForSearch = [str substringFromIndex:newChunkRange.location + newChunkRange.length - 1];
    }
    else
    {
        contentForSearch = [str copy];
    }
    
    if (!skipCheck)
    {
        NSArray *lines = [contentForSearch componentsSeparatedByString:@"\n"];
        
        [lines enumerateObjectsUsingBlock:^(NSString *line, NSUInteger idx, BOOL * _Nonnull stop) {
            NSRange range = [line rangeOfString:@"Client: loginwindow"];
            if (range.location != NSNotFound)
            {
                NSString *nextLine = lines[MIN(idx + 1, lines.count - 1)];
                range = [nextLine rangeOfString:@"ODRecordVerifyPassword failed with error 'Invalid credentials' (5000)"];
                if (range.location != NSNotFound)
                {
                    if (self.foudWrongPasswordBlock)
                    {
                        self.foudWrongPasswordBlock();
                    }
                    
                    *stop = YES;
                }
            }
        }];
    }
    
    NSArray *components = [str componentsSeparatedByString: @"\n"];
    
    if (components.count)
    {
        self.lastLine = components[components.count - 2];
    }
    
    [self.fileHandle waitForDataInBackgroundAndNotifyForModes:self.modes];
}

- (void)runCustomLoop
{
    NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];
    [currentRunLoop runMode:[self.modes firstObject] beforeDate:[NSDate distantFuture]];
    
    if (_taskRuning)
    {
		__weak typeof(self) weak = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            [weak runCustomLoop];
        });
    }
}

@end
