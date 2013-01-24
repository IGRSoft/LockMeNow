//
//  SKProduct+Price.m
//
//  Copyright (c) 2012 Symbiotic Software LLC. All rights reserved.
//

#import "SKProduct+Price.h"

@implementation SKProduct (Price)

- (NSString *)localizedPrice
{
	NSString *localizedPrice;
	NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
	[numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
	[numberFormatter setLocale:self.priceLocale];
	localizedPrice = [numberFormatter stringFromNumber:self.price];

	return localizedPrice;
}

@end
