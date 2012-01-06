//
//  SMLayerView.m
//  SimDeploy
//
//  Created by Jerry Jones on 1/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SMLayerView.h"

@implementation SMLayerView

@synthesize tintColor;

- (void)drawRect:(NSRect)dirtyRect
{
	
    // Load the image through NSImage and set it as the current color.
    [[NSColor colorWithPatternImage:[NSImage imageNamed:@"noise"]] set];
	
    // Fill the entire view with the image.
    [NSBezierPath fillRect:[self bounds]];

	// Add tint color
	if (NULL != tintColor) {
		CGContextRef context = (CGContextRef) [[NSGraphicsContext currentContext] graphicsPort];
		CGContextSetFillColorWithColor(context, tintColor);
		
	}
}

- (void)dealloc
{
	if (NULL != tintColor) {
		CGColorRelease(tintColor);
	}
	
	[super dealloc];
}

- (void)setTintColor:(CGColorRef)newTintColor
{
	if (tintColor == newTintColor) {
		return;
	}
	
	if (NULL != tintColor) {
		CGColorRelease(tintColor);
	}
	
	tintColor = CGColorRetain(newTintColor);
}

@end
