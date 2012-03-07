//
//  SMIconView.m
//  SimDeploy
//
//  Created by Jerry Jones on 1/4/12.
//  Copyright (c) 2012 Spaceman Labs. All rights reserved.
//

#import "SMIconView.h"

static CGPathRef createRoundedRectWithRadius(CGRect rect, CGFloat radius)
{
	CGFloat minX = CGRectGetMinX(rect);
	CGFloat maxX = CGRectGetMaxX(rect);
	CGFloat minY = CGRectGetMinY(rect);
	CGFloat maxY = CGRectGetMaxY(rect);
	CGMutablePathRef path  = CGPathCreateMutable();
	CGPathAddArc(path, NULL, minX + radius, minY + radius, radius, M_PI, -M_PI / 2.0f, NO);
	CGPathAddArc(path, NULL, maxX - radius, minY + radius, radius, -M_PI / 2.0f, 0, NO);
	CGPathAddArc(path, NULL, maxX - radius, maxY - radius, radius, 0, M_PI / 2.0f, NO);
	CGPathAddArc(path, NULL, minX + radius, maxY - radius, radius,  M_PI / 2.0f, M_PI, NO);
	CGPathCloseSubpath(path);
	return path;
}

@implementation SMIconView

@synthesize image;

- (void)dealloc
{
	self.image = nil;
	[super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
	CGRect insetRect = CGRectInset(dirtyRect, 4.0f, 4.0f);
	
	CGContextRef context = (CGContextRef) [[NSGraphicsContext currentContext] graphicsPort];

	CGPathRef path = createRoundedRectWithRadius(insetRect, 19.0f);
	CGColorRef black = CGColorCreateGenericRGB(0.0f, 0.0f, 0.0f, 1.0f);
	CGColorRef clear = CGColorCreateGenericRGB(0.0f, 0.0f, 0.0f, 0.5f);
	
	CGContextSaveGState(context);
	CGContextSetShadowWithColor(context, CGSizeMake(0.0f, -2.0f), 3.0f, black);
	CGContextAddPath(context, path);
	CGContextSetFillColorWithColor(context, clear);
	CGContextFillPath(context);
	CGContextRestoreGState(context);
	
	if (nil != self.image) {
		CGContextSaveGState(context);
		CGContextAddPath(context, path);
		CGContextClip(context);
		
		CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)[image TIFFRepresentation], NULL);
		CGImageRef imageRef =  CGImageSourceCreateImageAtIndex(source, 0, NULL);
		CGContextDrawImage(context, insetRect, imageRef);
		CGContextRestoreGState(context);
		if (NULL != source) {
			CFRelease(source);
		}
		if (NULL != imageRef) {
			CFRelease(imageRef);
		}
	}
	
	CGColorRelease(black);
	CGColorRelease(clear);
	CGPathRelease(path);
}

- (void)setImage:(NSImage *)anImage
{
	if (anImage == image) {
		return;
	}
	
	[image release];
	image = [anImage retain];
	[self setNeedsDisplay];
}


@end
