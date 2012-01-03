//
//  SMViewController.h
//  SimDeploy
//
//  Created by Jerry Jones on 1/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMSimDeployer.h"

@interface SMViewController : NSObject <NSAlertDelegate>

@property (nonatomic, retain) IBOutlet NSPanel *confirmSheet;
@property (nonatomic, retain) IBOutlet NSPanel *restartSheet;
@property (nonatomic, assign) BOOL simulatorIsRunning;
@property (nonatomic, retain) IBOutlet NSTextField *textField;
@property (nonatomic, retain) IBOutlet NSTextField *appNameLabel;
@property (nonatomic, retain) IBOutlet NSTextField *appVersionLabel;
@property (nonatomic, retain) IBOutlet NSView *progressContainer;

- (void)downloadURLAtLocation:(NSString *)location;
- (IBAction)downloadAppAtTextFieldURL:(id)sender;
- (IBAction)resetButton:(id)sender;

- (void)showRestartAlertIfNeeded;

- (void)checkVersionsAndInstall;

@end
