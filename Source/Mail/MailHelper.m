//
//  MailHelper.m
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 2/18/15.
//
//

#import "MailHelper.h"
#import "Mail.h"

@implementation MailHelper

+ (void)sendUserPhoto:(NSString *)photoPath to:(NSString *)eMail
{
    /* create a Scripting Bridge object for talking to the Mail application */
    MailApplication *mail = [SBApplication applicationWithBundleIdentifier:@"com.apple.Mail"];
    
    /* create a new outgoing message object */
    MailOutgoingMessage *emailMessage = [[[mail classForScriptingClass:@"outgoing message"] alloc] initWithProperties:
                                         [NSDictionary dictionaryWithObjectsAndKeys:
                                          @"Lock Me Now Security Warning", @"subject",
                                          @"Someone has entered an incorrect password!", @"content",
                                          nil]];
				
    /* add the object to the mail app  */
    [[mail outgoingMessages] addObject: emailMessage];
    
    /* set the sender, show the message */
    emailMessage.visible = NO;
    
    /* Test for errors */
    if ( [mail lastError] != nil )
        return;
				
    /* create a new recipient and add it to the recipients list */
    MailToRecipient *theRecipient = [[[mail classForScriptingClass:@"to recipient"] alloc] initWithProperties:
                                     [NSDictionary dictionaryWithObjectsAndKeys:
                                      eMail, @"address",
                                      nil]];
    [emailMessage.toRecipients addObject: theRecipient];
    
    /* Test for errors */
    if ( [mail lastError] != nil )
        return;
    
    /* add an attachment, if one was specified */
    NSString *attachmentFilePath = [photoPath copy];
    if ( [attachmentFilePath length] > 0 ) {
        MailAttachment *theAttachment;
        
        /* create an attachment object */
        theAttachment = [[[mail classForScriptingClass:@"attachment"] alloc] initWithProperties:
                         [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSURL URLWithString:attachmentFilePath], @"fileName",
                          nil]];
        
        /* add it to the list of attachments */
        [[emailMessage.content attachments] addObject: theAttachment];
        
        /* Test for errors */
        if ( [mail lastError] != nil )
            return;
    }
    /* send the message */
    [emailMessage send];
}

@end
