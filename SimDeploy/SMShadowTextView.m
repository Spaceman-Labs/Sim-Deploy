//
//  SMShadowTextView.m
//  SimDeploy
//
//  Created by Jerry Jones on 12/2/12.
//  Copyright (c) 2012 Spaceman Labs. All rights reserved.
//

#import "SMShadowTextView.h"

@implementation SMShadowTextView

- (void)drawRect:(NSRect)dirtyRect
{
	if (self.shadow) {
		[self.shadow set];
	}
	
	[super drawRect:dirtyRect];
}

@end
