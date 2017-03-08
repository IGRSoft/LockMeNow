//
//  XPCScriptingBridge.m
//  XPCScriptingBridge
//
//  Created by Vitalii Parovishnyk on 3/3/15.
//
//

#import "XPCScriptingBridge.h"
#import <ScriptingBridge/ScriptingBridge.h>
#import "iTunes.h"

#import "Mail.h"

@interface XPCScriptingBridge ()

@property (nonatomic, copy) NSMutableArray *photoPaths;
@property (nonatomic, copy) NSString *mailAddres;
@property (nonatomic) NSString *messageContent;
@property (nonatomic) NSUInteger actionType;

@end

@implementation XPCScriptingBridge

static NSString * const kiTunesID = @"com.apple.iTunes";
static NSString * const kPasswordDefaultText = @"Someone has entered an incorrect password\n\n";
static NSString * const kMagSafeDefaultText = @"Someone has unpluged MagSafe!\n\n";

#pragma mark - iTunes

- (BOOL)isItunesRuning
{
    iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:kiTunesID];
    
    return iTunes.isRunning;
}

- (void)isMusicPlaingWithReply:(void (^ _Nonnull)(BOOL))reply
{
    if (![self isItunesRuning])
    {
        reply(NO);
		
		return;
    }
    
    iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:kiTunesID];
    
    reply([iTunes playerState] == iTunesEPlSPlaying);
}

- (void)isMusicPausedWithReply:(void (^ _Nonnull)(BOOL))reply
{
    if (![self isItunesRuning])
    {
        reply(NO);
		
		return;
    }
    
    iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:kiTunesID];
    
    reply([iTunes playerState] == iTunesEPlSPaused || [iTunes playerState] == iTunesEPlSStopped);
}

- (void)playPauseMusic
{
    if (![self isItunesRuning])
    {
        return;
    }
    
    iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:kiTunesID];
    [iTunes playpause];
}

#pragma mark - Mail

- (void)setupMailAddres:(NSString * _Nonnull)aMail userPhoto:(NSString * _Nullable)photoPath type:(NSUInteger)type
{
    _mailAddres = aMail;
    _photoPaths = photoPath ? [NSMutableArray arrayWithObject:photoPath] : nil;
    _actionType = type;
}

- (void)sendDefaultMessageAddLocation:(NSString * _Nullable)aLocation
{
    self.messageContent = self.actionType == 0 ? kPasswordDefaultText : kMagSafeDefaultText;
    if (aLocation)
    {
        self.messageContent = [self.messageContent stringByAppendingFormat:@"Location: %@\n\n", aLocation];
    }
    
    [self sendMail];
}

- (void)sendMail
{
    /* create a Scripting Bridge object for talking to the Mail application */
    MailApplication *mail = [SBApplication applicationWithBundleIdentifier:@"com.apple.Mail"];
    
    /* update message */
    NSDateFormatter *formatter;
    NSString        *dateString;
    
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd/MM/yyyy HH:mm:ss"];
    
    dateString = [formatter stringFromDate:[NSDate date]];
    
    _messageContent = [_messageContent stringByAppendingFormat:@"Time: %@\n\n", dateString];
    
    _messageContent = [_messageContent stringByAppendingString:@"--\n"];
    _messageContent = [_messageContent stringByAppendingString:@"Lock Me Now\n"];
    _messageContent = [_messageContent stringByAppendingFormat:@"%@\n\n", @"http://www.IGRSoft.com"];
    
    /* create a new outgoing message object */
    MailOutgoingMessage *emailMessage = [[NSClassFromString(@"MailOutgoingMessage") alloc] initWithProperties:
                                         @{@"subject": @"Lock Me Now Security Warning",
                                           @"content" : _messageContent}];
				
    /* add the object to the mail app  */
    [[mail outgoingMessages] addObject: emailMessage];
    
    /* set the sender, show the message */
    emailMessage.visible = NO;
    
    /* Test for errors */
    if ( [mail lastError] != nil )
        return;
				
    /* create a new recipient and add it to the recipients list */
    MailToRecipient *theRecipient = [[NSClassFromString(@"MailToRecipient") alloc] initWithProperties:
                                     @{@"address": _mailAddres}];
    [emailMessage.toRecipients addObject: theRecipient];
    
    /* Test for errors */
    if ( [mail lastError] != nil )
        return;
    
    /* add an attachment, if one was specified */
    for (NSString *attachmentFilePath in _photoPaths)
    {
        MailAttachment *theAttachment = [[NSClassFromString(@"MailAttachment") alloc] initWithProperties:
                                         @{@"fileName": [NSURL URLWithString:attachmentFilePath]}];
        
        /* add it to the list of attachments */
        [[emailMessage.content attachments] addObject:theAttachment];
    }
	
	sleep(1); //Need wait 1 sec for 10.11
	
    /* Test for errors */
    if ( [mail lastError] != nil )
        return;
    
    /* send the message */
    [emailMessage send];
}

@end
