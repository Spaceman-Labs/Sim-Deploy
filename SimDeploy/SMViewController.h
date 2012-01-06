//
//  SMViewController.h
//  SimDeploy
//
//  Created by Jerry Jones on 1/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMSimDeployer.h"
#import "SMFileDragView.h"
#import "SMIconView.h"

@interface SMViewController : NSObject <NSAlertDelegate, SMFileDragViewDelegate>
{
	NSModalSession	modalSession;
}

@property (nonatomic, retain) SMAppModel *pendingApp;
@property (nonatomic, readonly) BOOL showingAppInfoView;

@property (nonatomic, retain) IBOutlet NSPanel *downloadURLSheet;
@property (nonatomic, retain) IBOutlet NSTextField *downloadTextField;

@property (nonatomic, retain) IBOutlet NSView *progressContainer;

@property (nonatomic, retain) IBOutlet NSView *controlContainer;
@property (nonatomic, retain) IBOutlet NSBox *boxView;
@property (nonatomic, retain) IBOutlet NSButton *downloadButton;
@property (nonatomic, retain) IBOutlet SMFileDragView *fileDragView;

@property (nonatomic, retain) IBOutlet NSView *appInfoView;
@property (nonatomic, retain) IBOutlet NSTextField *titleLabel;
@property (nonatomic, retain) IBOutlet NSTextField *versionLabel;
@property (nonatomic, retain) IBOutlet NSTextField *installedVersionLabel;
@property (nonatomic, retain) IBOutlet NSButton *cancelButton;
@property (nonatomic, retain) IBOutlet NSButton *installButton;
@property (nonatomic, retain) IBOutlet SMIconView *iconView;

- (IBAction)downloadFromURL:(id)sender;
- (IBAction)cancelDownloadFromURL:(id)sender;
- (void)downloadURLAtLocation:(NSString *)location;
- (IBAction)downloadAppAtTextFieldURL:(id)sender;

- (void)setAppInfoViewShowing:(BOOL)showing;
- (void)setupAppInfoViewWithApp:(SMAppModel *)app;
- (void)checkVersionsAndInstallApp:(SMAppModel *)app;
- (IBAction)installPendingApp:(id)sender;

- (IBAction)install:(id)sender;
- (IBAction)cancelInstall:(id)sender;
- (void)showRestartAlertIfNeeded;

- (void)registerForDragAndDrop;
- (void)deregisterForDragAndDrop;

@end
