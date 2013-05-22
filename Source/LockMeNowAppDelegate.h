//
//  LockMeNowAppDelegate.m
//  Lock Me Now
//
//  Created by Vitaly Parovishnik on 20.07.11.
//  Copyright 2010 IGR Software. All rights reserved.
//

#import <xpc/xpc.h>

@class PTHotKey;
@class IKImageView;
@class SRRecorderControl;
@class StartAtLoginController;

extern NSString *kGlobalHotKey;

typedef enum _LockingType {
	LOCK_LOGIN_WINDOW = 0,
	LOCK_SCREEN,
	LOCK_BLOCK,
	} LockingType;

@interface LockMeNowAppDelegate : NSObject <NSApplicationDelegate> {
	//Interface
    NSStatusItem		*m_statusItem;
	NSApplicationPresentationOptions appPresentationOptions;
	//Lock
	bool				m_bUseIconOnMainMenu;
	bool				m_bPauseiTunes;
	bool				m_bResumeiTunes;
	bool				m_bNeedResumeiTunes;
	bool				m_bAutoPrefs;
	LockingType			m_iLockType;
	
	bool				m_bShouldTerminate;
	
	//TEst
	NSTimer				*m_TestTimer;
	
	StartAtLoginController *loginController;
}

@property (nonatomic, strong) IBOutlet NSWindow				*window;
@property (nonatomic, strong) IBOutlet SRRecorderControl	*hotKeyControl;
@property (nonatomic, strong) IBOutlet NSMenu				*statusMenu;
@property (nonatomic, strong) IBOutlet NSTabView			*tabView;

@property (nonatomic, strong) PTHotKey						*hotKey;
@property (nonatomic) bool	bMonitoring;
@property (nonatomic) bool	bEncription;

@property (nonatomic) NSMutableArray *blockObjects;
@property (nonatomic, strong) IBOutlet NSView *lockBlockView;

- (void) makeLock;
- (IBAction) doUnLock:(id)sender;
- (IBAction) doLock:(id)sender;
- (IBAction) setLockType:(id)sender;
- (IBAction) setiTunesPause:(id)sender;
- (IBAction) setiTunesResume:(id)sender;
- (IBAction) setAutoPrefs:(id)sender;
- (IBAction) goToURL:(id)sender;
- (IBAction) openPrefs:(id)sender;
- (IBAction) toggleStartup:(id)sender;

- (void) makeMenu;
- (void) loadUserSettings;
- (void) saveUserSettings;

- (void) setSecuritySetings:(bool)seter withSkip:(bool)skip;
- (IBAction) setMenuIcon:(id)sender;
@end
