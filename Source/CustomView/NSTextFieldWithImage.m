//
//  NSTextFieldWithImage.m
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 1/17/13.
//
//

#import "NSTextFieldWithImage.h"

@implementation NSTextFieldWithImage

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)awakeFromNib
{
    [self setDrawsBackground:NO];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
	
    NSImage *image = [NSImage imageNamed:@"TextFieldBG"]; //image for background
    [image setFlipped:YES]; //image need to be flipped
	
    //use this if You need borders
	
    NSRect rectForBorders = NSMakeRect(0, 0, dirtyRect.size.width, dirtyRect.size.height);
    [image drawInRect:rectForBorders fromRect:rectForBorders operation:NSCompositeSourceOver fraction:1.0];
	
    //if You don't need borders use this:
	
    [image drawInRect:dirtyRect fromRect:dirtyRect operation:NSCompositeSourceOver fraction:1.0];
}


@end
