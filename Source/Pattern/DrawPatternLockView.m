//
//  DrawPatternLockView.m
//  AndroidLock
//
//  Created by Vitalii Parovishnyk on 03/06/13.
//  Copyright (c) 2013 IGR Software. All rights reserved.
//

#import "DrawPatternLockView.h"

@implementation DrawPatternLockView


- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
	  _paths = nil;
  }

  return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
  NSLog(@"drawrect...");
  
	if (!_trackPointValue)
		return;

	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
	CGContextSetLineWidth(context, 10.0);
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	CGFloat components[] = {0.5, 0.5, 0.5, 0.8};
	CGColorRef color = CGColorCreate(colorspace, components);
	CGContextSetStrokeColorWithColor(context, color);

	CGPoint from;
	NSView *lastDot;
	
	for (NSView *dotView in _dotViews)
	{
		from = CGPointMake(NSMidX(dotView.frame), NSMidY(dotView.frame));
		NSLog(@"drwaing dotview: %@", dotView);
		NSLog(@"\tdrawing from: %f, %f", from.x, from.y);

		if (!lastDot)
			CGContextMoveToPoint(context, from.x, from.y);
		else
			CGContextAddLineToPoint(context, from.x, from.y);

		lastDot = dotView;
	}

	NSPoint pt = [_trackPointValue pointValue];
	NSLog(@"\t to: %f, %f", pt.x, pt.y);
	CGContextAddLineToPoint(context, pt.x, pt.y);
  
	CGContextStrokePath(context);
	CGColorSpaceRelease(colorspace);
	CGColorRelease(color);

	_trackPointValue = nil;
}


- (void)clearDotViews
{
	[_dotViews removeAllObjects];
}


- (void)addDotView:(NSView *)view
{
	if (!_dotViews)
		_dotViews = [NSMutableArray array];

	[_dotViews addObject:view];
}


- (void) drawLineFromLastDotTo:(NSPoint)pt
{
	_trackPointValue = [NSValue valueWithPoint:pt];
	[self setNeedsDisplay:YES];
}

- (void)setHighlighted:(bool)yesNo imageView:(NSImageView*)imageView
{
	NSImage *img = [NSImage imageNamed:@"dot_off"];
	
	if (yesNo) {
		img = [NSImage imageNamed:@"dot_on"];
	}
	
	[imageView setImage:img];
}

- (void) mouseDown:(NSEvent *)theEvent
{
	_paths = [[NSMutableArray alloc] init];
	DBNSLog(@"mouseDown");
}

- (void)mouseDragged:(NSEvent *) theEvent
{
	DBNSLog(@"mouseDragged");
	
	NSPoint pt = [[[theEvent window] contentView] convertPoint:[theEvent locationInWindow] toView:self];
	NSPoint pt2 = [self convertPoint:[theEvent locationInWindow] toView:self];
	
	[self drawLineFromLastDotTo:pt];
	
	NSView *touched = [self hitTest:pt2];
	
	if ([touched isKindOfClass:[NSImageView class]])
	{
		if (touched.tag <= 0) {
			return;
		}
		
		NSLog(@"touched view tag: %ld ", (long)touched.tag);
	 
		BOOL found = NO;
		for (NSNumber *tag in _paths) {
			found = (tag.integerValue == touched.tag);
		
			if (found)
				break;
		}

		if (found)
			return;

		[_paths addObject:@(touched.tag)];
		[self addDotView:touched];

		NSImageView* iv = (NSImageView*)touched;
		
		[self setHighlighted:true imageView:iv];
	}
}


- (void) mouseUp:(NSEvent *)theEvent
{
	DBNSLog(@"mouseUp");
	// clear up hilite
	DrawPatternLockView *v = (DrawPatternLockView*)self;
	[v clearDotViews];
	
	for (NSImageView *view in self.subviews)
		if ([view isKindOfClass:[NSImageView class]])
			[self setHighlighted:false imageView:view];
	 
	[self setNeedsDisplay:YES];
	
	// pass the output to target action...
	if (_target && _action)
		[_target performSelector:_action withObject:[self getKey]];
	
	_paths = nil;
}

// get key from the pattern drawn
// replace this method with your own key-generation algorithm
- (NSString*)getKey
{
	NSMutableString *key;
	key = [NSMutableString string];
	
	// simple way to generate a key
	for (NSNumber *tag in _paths) {
		[key appendFormat:@"%02ld", (long)tag.integerValue];
	}
	
	return key;
}


- (void)setTarget:(id)target withAction:(SEL)action {
	_target = target;
	_action = action;
}

@end
