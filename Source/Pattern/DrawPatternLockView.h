//
//  DrawPatternLockView.h
//  AndroidLock
//
//  Created by Vitalii Parovishnyk on 03/06/13.
//  Copyright (c) 2013 IGR Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DrawPatternLockView : NSView {
	NSValue *_trackPointValue;
	NSMutableArray *_dotViews;
	
	NSMutableArray* _paths;
	
	// after pattern is drawn, call this:
	id _target;
	SEL _action;
}

// get key from the pattern drawn
- (NSString*)getKey;

- (void)setTarget:(id)target withAction:(SEL)action;
- (void)clearDotViews;
- (void)addDotView:(NSView*)view;
- (void)drawLineFromLastDotTo:(CGPoint)pt;

@end
