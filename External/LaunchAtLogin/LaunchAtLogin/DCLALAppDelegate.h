//
//  DCLALAppDelegate.h
//  LaunchAtLogin
//
//  Created by Boy van Amstel on 07-08-12.
//  Copyright (c) 2012 Danger Cove. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "StartAtLoginController.h"

@interface DCLALAppDelegate : NSObject <NSApplicationDelegate> {
    StartAtLoginController *loginController;
}

@property (assign) IBOutlet NSWindow *window;

@end
