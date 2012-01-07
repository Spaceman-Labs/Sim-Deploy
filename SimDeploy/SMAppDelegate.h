//
//  SMAppDelegate.h
//  SimDeploy
//
//  Created by Jerry Jones on 12/30/11.
//  Copyright (c) 2011 Spaceman Labs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SMViewController.h"

@interface SMAppDelegate : NSObject <NSApplicationDelegate, NSOpenSavePanelDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, retain) IBOutlet SMViewController *viewController;

- (IBAction)openDocument:(id)sender;

@end
