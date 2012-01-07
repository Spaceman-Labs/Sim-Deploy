//
//  SMDividerView.m
//  SimDeploy
//
//  Created by Jerry Jones on 1/5/12.
//  Copyright (c) 2012 Spaceman Labs. All rights reserved.
//

#import "SMDividerView.h"

@implementation SMDividerView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	CGContextRef context = (CGContextRef) [[NSGraphicsContext currentContext] graphicsPort];
	CGColorRef topColor = CGColorCreateGenericRGB(0.0f, 0.0f, 0.0f, 0.3f);
	CGColorRef bottomColor = CGColorCreateGenericRGB(1.0f, 1.0f, 1.0f, 0.2f);
	
	CGContextSetFillColorWithColor(context, topColor);
	CGContextFillRect(context, CGRectMake(0, 1.0f, dirtyRect.size.width, 1.0f));
	CGContextSetFillColorWithColor(context, bottomColor);
	CGContextFillRect(context, CGRectMake(0, 0.0f, dirtyRect.size.width, 1.0f));
}

@end
