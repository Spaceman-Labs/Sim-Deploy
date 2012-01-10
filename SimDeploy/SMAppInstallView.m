//
//  SMAppInstallView.m
//  SimDeploy
//
//  Created by Jerry Jones on 1/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SMAppInstallView.h"

@implementation SMAppInstallView

@synthesize installButton;
@synthesize installDisabled;

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
    // Drawing code here.
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)flagsChanged:(NSEvent *)theEvent
{
	
	if (self.installDisabled) {
		if ([theEvent modifierFlags] & NSAlternateKeyMask) {
			self.installButton.enabled = YES;
		} else {
			self.installButton.enabled = NO;
		}
	}
}

- (void)dealloc
{
	self.installButton = nil;
	[super dealloc];
}

@end
