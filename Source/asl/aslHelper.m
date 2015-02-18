//
//  aslHelper.m
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 2/17/15.
//
//

#import "ASLHelper.h"

#define ASL_PATH @"/private/etc/asl.conf"
#define ASL_PATCH @"\n\
# Facility loginwindow gets saved in lockmenow.log\n\
> lockmenow.log mode=0777 format=bsd rotate=seq compress file_max=1M all_max=5M\n\
? [= Sender loginwindow] file lockmenow.log\n"

AuthorizationRef    _authRef;
NSData *            authorization;

@implementation ASLHelper

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
    if ([ASLHelper isASLPatched])
    {
        return YES;
    }
    
    BOOL result = NO;
    
    if ([ASLHelper authorizate])
    {
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
            
            [ASLHelper relaunchDeamons];
            
            result = YES;
        }
    }
    
    return result;
}

+ (AuthorizationRef)authorizationForExecutable:(NSString*)executablePath
{
    NSParameterAssert(executablePath);
    
    // Get authorization using advice in Apple's Technical Q&A1172
    
    // ...create authorization without specific rights
    AuthorizationRef auth = NULL;
    OSStatus validAuth = AuthorizationCreate(NULL,
                                             kAuthorizationEmptyEnvironment,
                                             kAuthorizationFlagDefaults,
                                             &auth);
    // ...then extend authorization with desired rights
    if ((validAuth == errAuthorizationSuccess) &&
        (auth != NULL))
    {
        const char* executableFileSystemRepresentation = [executablePath fileSystemRepresentation];
        
        // Prepare a right allowing script to execute with privileges
        AuthorizationItem right;
        memset(&right,0,sizeof(right));
        right.name = kAuthorizationRightExecute;
        right.value = (void*) executableFileSystemRepresentation;
        right.valueLength = strlen(executableFileSystemRepresentation);
        
        // Package up the single right
        AuthorizationRights rights;
        memset(&rights,0,sizeof(rights));
        rights.count = 1;
        rights.items = &right;
        
        // Extend rights to run script
        validAuth = AuthorizationCopyRights(auth,
                                            &rights,
                                            kAuthorizationEmptyEnvironment,
                                            kAuthorizationFlagPreAuthorize |
                                            kAuthorizationFlagExtendRights |
                                            kAuthorizationFlagInteractionAllowed,
                                            NULL);
        if (validAuth != errAuthorizationSuccess)
        {
            // Error, clean up authorization
            (void) AuthorizationFree(auth,kAuthorizationFlagDefaults);
            auth = NULL;
        }
    }
    
    return auth;
}

+ (BOOL)authorizate
{
    NSString *bundleIdentifier = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    AuthorizationRef authRef = [self authorizationForExecutable:bundleIdentifier];
    
    return authRef != nil;
}

+ (void)relaunchDeamons
{
    NSString *exec = @"/bin/launchctl";
    NSArray *commands = @[@"unload", @"load"];
    NSString *deamon = @"/System/Library/LaunchDaemons/com.apple.syslogd.plist";
    
    for (NSString *command in commands)
    {
        NSTask *task = [[NSTask alloc] init];
        
        NSArray *arguments = @[command, deamon];
        [task setArguments:arguments];
        [task setLaunchPath:exec];
        
        @try {
            [task launch];
        }
        @catch (NSException *exception) {
            DBNSLog(@"exception = %@", exception);
        }
        @finally {
            
        }
    }
}

@end
