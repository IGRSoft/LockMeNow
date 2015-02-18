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

#define DEFAULT_TEXT @"Someone has entered an incorrect password!"

@interface MailHelper () <CLLocationManagerDelegate>

@property (nonatomic, copy) NSMutableArray *photoPaths;
@property (nonatomic, copy) NSString *mailAddres;
@property (nonatomic) NSString *messageContent;

@property (nonatomic) CLLocationManager *locationManager;

@end

@implementation MailHelper

- (id)initWithMailAddres:(NSString *)aMail userPhoto:(NSString *)photoPath
{
    if (self = [super init])
    {
        _mailAddres = aMail;
        _photoPaths = [NSMutableArray arrayWithObject:photoPath];
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
    
    /* create a new outgoing message object */
    MailOutgoingMessage *emailMessage = [[[mail classForScriptingClass:@"outgoing message"] alloc] initWithProperties:
                                         [NSDictionary dictionaryWithObjectsAndKeys:
                                          @"Lock Me Now Security Warning", @"subject",
                                          _messageContent, @"content",
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
                                      _mailAddres, @"address",
                                      nil]];
    [emailMessage.toRecipients addObject: theRecipient];
    
    /* Test for errors */
    if ( [mail lastError] != nil )
        return;
    
    /* add an attachment, if one was specified */
    for (NSString *attachmentFilePath in _photoPaths)
    {
        MailAttachment *theAttachment = [[[mail classForScriptingClass:@"attachment"] alloc] initWithProperties:
                                         [NSDictionary dictionaryWithObjectsAndKeys:
                                          [NSURL URLWithString:attachmentFilePath], @"fileName",
                                          nil]];
        
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
    _locationManager.delegate = nil;
    CLLocation *location = [locations lastObject];
    
    NSString *theLocation = [NSString stringWithFormat:@"https://maps.google.com/maps?q=%f,%f&num=1&vpsrc=0&ie=UTF8&t=m",
                             location.coordinate.latitude,
                             location.coordinate.longitude];
    
    self.messageContent = [self.messageContent stringByAppendingString:@"\n"];
    self.messageContent = [self.messageContent stringByAppendingFormat:@"Location: %@", theLocation];
    self.messageContent = [self.messageContent stringByAppendingString:@"\n\n"];
    
    [self sendMail];
}

@end
