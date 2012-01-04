//
//  SMFileDragView.m
//  SimDeploy
//
//  Created by Jerry Jones on 1/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SMFileDragView.h"

@implementation SMFileDragView

@synthesize delegate;

#pragma mark - Drag & Drop

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
	
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
	
    if ([[pboard types] containsObject:NSFilenamesPboardType]) {
		return NSDragOperationCopy;
    }
	
    return NSDragOperationNone;
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
