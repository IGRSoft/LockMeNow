//
//  MailHelper.m
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 2/18/15.
//
//

#import "MailHelper.h"
#import "Mail.h"
#import <CoreLocation/CoreLocation.h>

#define DEFAULT_TEXT @"Someone has entered an incorrect password!\n\n"

@interface MailHelper () <CLLocationManagerDelegate>

@property (nonatomic, copy) NSMutableArray *photoPaths;
@property (nonatomic, copy) NSString *mailAddres;
@property (nonatomic) NSString *messageContent;

@property (nonatomic) CLLocationManager *locationManager;

@end

@implementation MailHelper

- (instancetype)initWithMailAddres:(NSString *)aMail userPhoto:(NSString *)photoPath
{
    if (self = [super init])
    {
        _mailAddres = aMail;
        _photoPaths = photoPath ? [NSMutableArray arrayWithObject:photoPath] : nil;
        _messageContent = DEFAULT_TEXT;
    }
    
    return self;
}

- (void)sendDefaultMessageAddLocation:(BOOL)anAddLocation
{
    if (anAddLocation)
    {
        self.locationManager = [[CLLocationManager alloc] init];
        _locationManager.distanceFilter = kCLDistanceFilterNone;
        _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        [_locationManager startUpdatingLocation];
        _locationManager.delegate = self;
    }
    else
    {
        [self sendMail];
    }
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
    _messageContent = [_messageContent stringByAppendingFormat:@"%@\n\n", APP_SITE];
    
    /* create a new outgoing message object */
    MailOutgoingMessage *emailMessage = [[[mail classForScriptingClass:@"outgoing message"] alloc] initWithProperties:
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
    MailToRecipient *theRecipient = [[[mail classForScriptingClass:@"to recipient"] alloc] initWithProperties:
                                     @{@"address": _mailAddres}];
    [emailMessage.toRecipients addObject: theRecipient];
    
    /* Test for errors */
    if ( [mail lastError] != nil )
        return;
    
    /* add an attachment, if one was specified */
    for (NSString *attachmentFilePath in _photoPaths)
    {
        MailAttachment *theAttachment = [[[mail classForScriptingClass:@"attachment"] alloc] initWithProperties:
                                         @{@"fileName": [NSURL URLWithString:attachmentFilePath]}];
        
        /* add it to the list of attachments */
        [[emailMessage.content attachments] addObject: theAttachment];
    }
    
    /* Test for errors */
    if ( [mail lastError] != nil )
        return;
    
    /* send the message */
    [emailMessage send];
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    [_locationManager stopUpdatingLocation];
    _locationManager.delegate = nil;
    
    CLLocation *location = [locations lastObject];
    
    NSString *theLocation = [NSString stringWithFormat:@"https://maps.google.com/maps?q=%f,%f&num=1&vpsrc=0&ie=UTF8&t=m",
                             location.coordinate.latitude,
                             location.coordinate.longitude];
    
    self.messageContent = [self.messageContent stringByAppendingFormat:@"Location: %@\n\n", theLocation];
    
    [self sendMail];
}

@end
