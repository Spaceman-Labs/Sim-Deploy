//
//  SMFileDragView.m
//  SimDeploy
//
//  Created by Jerry Jones on 1/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SMFileDragView.h"

@implementation SMFileDragView

@synthesize validDrag;
@synthesize delegate;

#pragma mark - Drag & Drop

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
	
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
	
    if ([[pboard types] containsObject:NSFilenamesPboardType]) {
		// Check extension, needs to be .zip or .app
		NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
		NSString *file = [files lastObject];
		if ([file hasSuffix:@".zip"] || [file hasSuffix:@".app"]){
			self.validDrag = YES;
			return NSDragOperationCopy;
		}
    }
	
	self.validDrag = NO;
    return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id < NSDraggingInfo >)sender
{
	if (NO == self.validDrag) {
		return NSDragOperationNone;
	}

	CGColorRef color = CGColorCreateGenericRGB(0.0f, 0.0f, 0.0f, 0.2f);
	self.layer.backgroundColor = color;
	CGColorRelease(color);
	
	return NSDragOperationCopy;
}

- (void)draggingExited:(id < NSDraggingInfo >)sender
{
	CGColorRef color = CGColorCreateGenericRGB(0.0f, 0.0f, 0.0f, 0.0f);
	self.layer.backgroundColor = color;
	CGColorRelease(color);	
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
	
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
	
	if ([[pboard types] containsObject:NSFilenamesPboardType] ) {
		NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
		[self.delegate fileDragView:self didReceiveFiles:files];
    }
    return YES;
}


@end
