//
//  SMFileDragView.h
//  SimDeploy
//
//  Created by Jerry Jones on 1/3/12.
//  Copyright (c) 2012 Spaceman Labs. All rights reserved.
//

#import <AppKit/AppKit.h>

@protocol SMFileDragViewDelegate;

@interface SMFileDragView : NSView 

@property (nonatomic, assign) BOOL validDrag;
@property (nonatomic, assign) id <SMFileDragViewDelegate> delegate;

- (void)setHighlighted:(BOOL)highlighted;

@end

@protocol SMFileDragViewDelegate <NSObject>
@required
- (void)fileDragView:(SMFileDragView *)dragView didReceiveFiles:(NSArray *)files;
@end
