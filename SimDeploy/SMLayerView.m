//
//  SMLayerView.m
//  SimDeploy
//
//  Created by Jerry Jones on 1/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SMLayerView.h"

@implementation SMLayerView

- (void)drawRect:(NSRect)dirtyRect {
	
    // Load the image through NSImage and set it as the current color.
    [[NSColor colorWithPatternImage:[NSImage imageNamed:@"noise"]] set];
	
    // Fill the entire view with the image.
    [NSBezierPath fillRect:[self bounds]];

}

@end
