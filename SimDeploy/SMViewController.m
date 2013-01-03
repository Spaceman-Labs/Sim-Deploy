//
//  SMViewController.m
//  SimDeploy
//
//  Created by Jerry Jones on 1/2/12.
//  Copyright (c) 2012 Spaceman Labs. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "SMViewController.h"
#import "NSAlert-OAExtensions.h"

@implementation SMViewController

@synthesize showingAppInfoView;

@synthesize fileDragView;
@synthesize downloadTextField;
@synthesize downloadURLSheet;
@synthesize titleLabel;
@synthesize iconView;
@synthesize boxView;
@synthesize appInfoView;
@synthesize versionLabel;
@synthesize installedVersionLabel;
@synthesize downloadFromURLButton;
@synthesize pendingApp;
@synthesize controlContainer;
@synthesize cancelButton;
@synthesize installButton;
@synthesize progressIndicator;
@synthesize downloadButton;
@synthesize mainWindow;
@synthesize installTitleLabel;
@synthesize installMessageLabel;
@synthesize installProgressIndicator;
@synthesize installPanel;
@synthesize urlLabel;
@synthesize cleanInstallButton;

- (void)awakeFromNib
{	
	[self.installProgressIndicator startAnimation:self];
	[self.installProgressIndicator setUsesThreadedAnimation:YES];
	self.downloadTextField.target = self;
	[self.downloadTextField setAction:@selector(downloadAppAtTextFieldURL:)];
	self.fileDragView.delegate = self;
	self.fileDragView.layer.cornerRadius = 15.0f;
	[self registerForDragAndDrop];
	
	[self.progressIndicator setMinValue:0.0f];
	[self.progressIndicator setMaxValue:100.0f];
	
	NSString *lastURL = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastURL"];
	if (nil != lastURL) {
		self.downloadTextField.stringValue = lastURL;
	}
	
	self.mainView.backgroundColor = [NSColor colorWithDeviceRed:230.0f/255.0f green:230.0f/255.0f blue:230.0f/255.0f alpha:1.0f];
	self.mainView.noiseOpacity = 0.12f;
	self.mainView.noiseBlendMode = kCGBlendModeMultiply;
	
//	CGRect frame = self.titleLabel.frame;
//	frame.size.height += 20.0f;
//	frame.origin.y -= 25.0f;
//	self.titleLabel.frame = frame;
//	
//	frame = self.versionLabel.frame;
//	frame.origin.y = CGRectGetMinY(self.titleLabel.frame) - 5.0f;
//	self.versionLabel.frame = frame;
//
//	frame = self.installedVersionLabel.frame;
//	frame.origin.y = CGRectGetMinY(self.installedVersionLabel.frame) - 5.0f;
//	self.installedVersionLabel.frame = frame;
	
//	[[self.versionLabel cell] setBackgroundStyle:NSBackgroundStyleRaised];
//	[[self.titleLabel cell] setBackgroundStyle:NSBackgroundStyleRaised];
//	[[self.installedVersionLabel cell] setBackgroundStyle:NSBackgroundStyleRaised];
//	[[self.cleanInstallButton cell] setBackgroundStyle:NSBackgroundStyleRaised];
	
	NSShadow *shadow = [[NSShadow alloc] init];
	shadow.shadowColor = [NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:0.7f];
	shadow.shadowOffset = CGSizeMake(0, 1.0f);

	self.titleLabel.shadow = shadow;
	self.versionLabel.shadow = shadow;
	self.installedVersionLabel.shadow = shadow;
	self.orLabel.shadow = shadow;	
	self.cleanInstallButton.shadow = shadow;
	
	self.iconView.image = [NSImage imageNamed:@"Icon@2x.png"];
	
	if (nil == self.appInfoView.superview) {
		[CATransaction begin];
		self.appInfoView.layer.opacity = 0.0f;
		self.appInfoView.hidden = YES;
		[self.boxView addSubview:self.appInfoView];
		
		[CATransaction commit];
		[CATransaction flush];
	}
	
	
}

- (IBAction)downloadFromURL:(id)sender
{
	if (nil != modalSession) {
		return;
	}
	
	self.downloadFromURLButton.state = 1;
	
	[self deregisterForDragAndDrop];
	[[NSApplication sharedApplication] beginSheet:self.downloadURLSheet
								   modalForWindow:self.mainWindow
									modalDelegate:nil
								   didEndSelector:nil
									  contextInfo:nil];
	
	modalSession = [NSApp beginModalSessionForWindow:self.downloadURLSheet];
	[NSApp runModalSession:modalSession];
	
	NSText *textEditor = [self.downloadTextField currentEditor];
	NSRange range = { [[textEditor string] length], 0 };
	[textEditor setSelectedRange: range];
}

- (IBAction)cancelDownloadFromURL:(id)sender
{
	[[SMSimDeployer defaultDeployer].download cancel];
	self.progressIndicator.hidden = YES;
	self.downloadTextField.hidden = NO;
	self.downloadButton.enabled = YES;
	showingProgressIndicator = NO;
	
	
	[self registerForDragAndDrop];
	[NSApp endModalSession:modalSession];
    [NSApp endSheet:self.downloadURLSheet];
    [self.downloadURLSheet orderOut:nil];
	modalSession = nil;
}

- (void)downloadURLAtLocation:(NSString *)location
{
	[self.downloadTextField setStringValue:location];
	[self downloadFromURL:self];
}

- (IBAction)downloadAppAtTextFieldURL:(id)sender
{	
	NSString *urlPath = [self.downloadTextField stringValue];
	if (nil == urlPath || [urlPath length] < 1) {
		return;
	}
	
	self.downloadButton.enabled = NO;
	
	NSURL *url = [NSURL URLWithString:urlPath];
	
	SMSimDeployer *deployer = [SMSimDeployer defaultDeployer];
	[[NSUserDefaults standardUserDefaults] setObject:urlPath forKey:@"lastURL"];
	NSString *oldLabelString = self.urlLabel.stringValue;
	self.urlLabel.stringValue = @"Downloading...";
	
	[deployer downloadAppAtURL:url 
			   percentComplete:^(CGFloat percentComplete) {
				   if (NO == showingProgressIndicator) {
					   showingProgressIndicator = YES;
					   [self.downloadTextField setHidden:YES];
					   [self.progressIndicator setHidden:NO];
					   [self.progressIndicator setDoubleValue:0.0f];
				   }
				   
				   if (percentComplete > 0.0f) {
					   NSString *value = [NSString stringWithFormat:@"Downloading... %.2f%%", percentComplete];
					   self.urlLabel.stringValue = value;
					   [self.progressIndicator setIndeterminate:NO];
					   [self.progressIndicator setDoubleValue:percentComplete];
				   } else {
					   [self.progressIndicator setIndeterminate:YES];
					   [self.progressIndicator startAnimation:nil];
				   }
			   }
					completion:^(BOOL failed) {
						self.urlLabel.stringValue = oldLabelString;
						self.downloadButton.enabled = YES;
						[self registerForDragAndDrop];
						[NSApp endModalSession:modalSession];
						[NSApp endSheet:self.downloadURLSheet];
						modalSession = nil;
						[self.downloadURLSheet orderOut:nil];
						
						
						[self.downloadFromURLButton setEnabled:YES];
						if (showingProgressIndicator) {
							showingProgressIndicator = NO;
							[self.downloadTextField setHidden:NO];
							[self.progressIndicator setHidden:YES];
						}
						
						if (failed) {
							NSAlert *alert = [[NSAlert alloc] init];
							[alert addButtonWithTitle:NSLocalizedString(@"Ok", @"Ok")];
							[alert setMessageText:NSLocalizedString(@"Download Failed", nil)];
							[alert setInformativeText:NSLocalizedString(@"Unable to download a simulator build, please check your URL and try again.", nil)];
							[alert setAlertStyle:NSCriticalAlertStyle];
							
							
							[alert beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
							return;
						}

						SMAppModel *downloadedApp = [deployer unzipAppArchive];
						
						if (nil == downloadedApp) {
							self.downloadButton.enabled = YES;
							[self errorWithTitle:NSLocalizedString(@"No Valid Application Found", nil) 
										 message:NSLocalizedString(@"The downloaded file did not contain a valid simulator build. Please check your URL and try again.", nil)];							
							return;
						}
						
						self.pendingApp = downloadedApp;
				   }];
}

- (void)checkVersionsAndInstallApp:(SMAppModel *)app
{
	SMSimDeployer *deployer = [SMSimDeployer defaultDeployer];
	
	NSArray *simulators = deployer.simulators;
	SMSimulatorModel *sim = [simulators lastObject];
	SMAppCompare appCompare = [sim compareInstalledAppsAgainstApp:app installedApp:nil];
	
	if (SMAppCompareSame == appCompare) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:NSLocalizedString(@"Ok", @"Ok")];
		[alert setMessageText:NSLocalizedString(@"You're Already Up To Date", nil)];
		[alert setInformativeText:NSLocalizedString(@"Your download was successful, but you already have this version installed!", nil)];
		[alert setAlertStyle:NSInformationalAlertStyle];
		
		[alert beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
		return;
	} else if (SMAppCompareGreaterThan == appCompare) {
		[NSAlert beginAlertSheet:@"Your Current Version is Newer!" 
						 message:@"Your download was successful, but the simulator currently has a newer version installed. would you like to overwrite it?" 
				   defaultButton:@"Overwrite" 
				 alternateButton:@"Cancel" 
					 otherButton:nil 
						  window:[NSApp mainWindow] 
					  completion:^(NSAlert *alert, NSInteger returnCode) {
						  if (returnCode == NSAlertFirstButtonReturn) {
							  [[SMSimDeployer defaultDeployer] installApplication:app clean:YES completion:nil];							  
							  [self showRestartAlertIfNeeded];
						  }
					  }];
		
	} else {
		[[SMSimDeployer defaultDeployer] installApplication:app clean:YES completion:nil];
		[self showRestartAlertIfNeeded];	
	}
	

}

- (void)installPendingApp:(id)sender
{
	SMSimDeployer *deployer = [SMSimDeployer defaultDeployer];
	
	NSArray *simulators = deployer.simulators;
	SMSimulatorModel *sim = [simulators lastObject];
	SMAppCompare appCompare = [sim compareInstalledAppsAgainstApp:self.pendingApp installedApp:nil];
	
	void (^installBlock)(void) = ^{
		[[NSApplication sharedApplication] beginSheet:self.installPanel
									   modalForWindow:self.mainWindow
										modalDelegate:nil
									   didEndSelector:nil
										  contextInfo:nil];

		
		[[SMSimDeployer defaultDeployer] installApplication:self.pendingApp 
													  clean:self.cleanInstallButton.state == NSOnState
												 completion:^{
													 [NSApp endSheet:self.installPanel];
													 [self.installPanel orderOut:nil];
													 [self showRestartAlertIfNeeded];
												 }];

	};
	
	if (SMAppCompareGreaterThan == appCompare) {
		[NSAlert beginAlertSheet:@"Your Current Version is Newer!" 
						 message:@"Your current installed version is newer, are you sure you want to downgrade?" 
				   defaultButton:@"Downgrade" 
				 alternateButton:@"Cancel" 
					 otherButton:nil 
						  window:[NSApp mainWindow] 
					  completion:^(NSAlert *alert, NSInteger returnCode) {
						  if (returnCode == NSAlertFirstButtonReturn) {
							  installBlock();
						  }
					  }];
		
	} else {
		installBlock();
	}
}

- (void)errorWithTitle:(NSString *)title message:(NSString *)message
{
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:NSLocalizedString(@"Ok", @"Ok")];
	[alert setMessageText:title];
	[alert setInformativeText:message];
	[alert setAlertStyle:NSCriticalAlertStyle];
	
	[alert beginSheetModalForWindow:nil modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

#pragma mark - App Info View

- (void)setAppInfoViewShowing:(BOOL)showing
{	
	if (showing) {
		self.appInfoView.hidden = NO;
		self.cleanInstallButton.state = NSOffState;
		[self deregisterForDragAndDrop];
	} else {
		[self registerForDragAndDrop];
	}
	
	[CATransaction begin];
	[CATransaction setAnimationDuration:0.3f];
	[CATransaction setCompletionBlock:^{
		if (NO == showing) {
			self.appInfoView.hidden = YES;
		}
	}];
	
	CATransition *fade = [CATransition animation];
	fade.type = kCATransitionFade;
	fade.duration = 0.3f;
	[self.appInfoView.layer addAnimation:fade forKey:@"fade"];
	
	if (showing) {
		self.appInfoView.layer.opacity = 1.0f;
		self.controlContainer.layer.opacity = 0.0f;
		self.downloadFromURLButton.enabled = NO;
	} else { 		
		self.appInfoView.layer.opacity = 0.0f;
		self.controlContainer.layer.opacity = 1.0f;
		self.downloadFromURLButton.enabled = YES;
	}	
	[CATransaction commit];
}

- (void)setupAppInfoViewWithApp:(SMAppModel *)app
{	
	if (nil == app) {
		NSLog(@"nil!");
	}
	
	versionsAreTheSame = NO;

	self.titleLabel.stringValue = app.name;
	
	NSMutableString *version = [NSMutableString stringWithFormat:@"Version: %@", app.marketingVersion];
	[version appendFormat:@" (%@)", app.version];
	self.versionLabel.stringValue = version;
	if (nil != app.iconPath) {
		self.iconView.image = [[NSImage alloc] initWithContentsOfFile:app.iconPath];
	} else {
		self.iconView.image = nil;
	}
	
	NSArray *simulators = [[SMSimDeployer defaultDeployer] simulators];
	SMSimulatorModel *sim = [simulators lastObject];
	SMAppModel *installedApp = nil;
	SMAppCompare compare = [sim compareInstalledAppsAgainstApp:app installedApp:&installedApp];
	
	self.installButton.enabled = YES;
	
	if (SMAppCompareNotInstalled == compare || nil == installedApp) {
		self.installedVersionLabel.stringValue = @"";
		self.installButton.title = @"Install";
		self.cleanInstallButton.hidden = YES;
	} else {
		NSMutableString *version = [NSMutableString stringWithFormat:@"Installed Version: %@", installedApp.marketingVersion];
		[version appendFormat:@" (%@)", installedApp.version];
		self.installedVersionLabel.stringValue = version;
		self.cleanInstallButton.hidden = NO;
		
		if (SMAppCompareLessThan == compare) {
			self.installButton.title = @"Upgrade";
		} else if (SMAppCompareGreaterThan == compare) {
			self.installButton.title = @"Downgrade";
		} else if (SMAppCompareSame == compare) {
			versionsAreTheSame = YES;
			self.installButton.enabled = NO;
			self.installButton.title = @"Install";
			self.installedVersionLabel.stringValue = [NSString stringWithFormat:@"This Version Is Already Installed."];
		}

	}
	
	self.appInfoView.installDisabled = ![self.installButton isEnabled];
	[self updateInstallButton];
	
}

#pragma mark -

- (void)showRestartAlertIfNeeded
{
	
	double delayInSeconds = 0.3;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		// Check for a running simulator
		
		NSArray *runningSims = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.iphonesimulator"];
		if ([runningSims count] < 1) {
			NSAlert *alert = [[NSAlert alloc] init];
			[alert addButtonWithTitle:NSLocalizedString(@"Launch Simulator", @"Launch Simulator")];
			[alert addButtonWithTitle:NSLocalizedString(@"No Thanks", @"No Thanks")];
			[alert setMessageText:NSLocalizedString(@"Success!", nil)];
			[alert setInformativeText:NSLocalizedString(@"Your builds were installed successfully! Would you like us to fire up the simulator for you?", nil)];
			[alert setAlertStyle:NSInformationalAlertStyle];
			[alert beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:(void *)[NSNull null]];
		}
		
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:NSLocalizedString(@"Restart Now", @"Restart Now")];
		[alert addButtonWithTitle:NSLocalizedString(@"Restart Later", @"Restart Later")];
		[alert setMessageText:NSLocalizedString(@"Success!", nil)];
		[alert setInformativeText:NSLocalizedString(@"Your builds were installed successfully, but the simulator is running and must be restarted before newly downloaded versions will be available.", nil)];
		[alert setAlertStyle:NSInformationalAlertStyle];
		[alert beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
	});
	
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	NSArray *simulators = [SMSimDeployer defaultDeployer].simulators;
	SMSimulatorModel *sim = [simulators lastObject];
	SMAppModel *newApp = nil;
	for (SMAppModel *app in sim.userApplications) {
		if ([app.identifier isEqualToString:self.pendingApp.identifier]) {
			newApp = app;
		}
	}
	
	if ([NSNull null] == (__bridge NSNull *)contextInfo) {
		if (returnCode == NSAlertFirstButtonReturn) {
			[[SMSimDeployer defaultDeployer] launchApplication:newApp];	
		}		
	} else {
		if (returnCode == NSAlertFirstButtonReturn) {
			[[SMSimDeployer defaultDeployer] launchApplication:newApp];	
		}
	}
		
//	[[SMSimDeployer defaultDeployer] launchApplication:newApp];	
	[self setAppInfoViewShowing:NO];
}

- (void)registerForDragAndDrop
{
	[self.fileDragView registerForDraggedTypes:@[NSFilenamesPboardType]];
}

- (void)deregisterForDragAndDrop
{
	[self.fileDragView unregisterDraggedTypes];
}

- (void)updateInstallButton
{
	if (NO == versionsAreTheSame) {
		self.installButton.enabled = YES;
	} else {
		self.installButton.enabled = self.cleanInstallButton.state == NSOnState;
	}
}

- (IBAction)cleanInstall:(id)sender
{
	[self updateInstallButton];
}

- (IBAction)install:(id)sender
{
	self.installButton.state = NSOnState;
	[self installPendingApp:self];
}

- (IBAction)cancelInstall:(id)sender
{
	self.cancelButton.state = NSOnState;
	[self setAppInfoViewShowing:NO];
}


#pragma mark - Accessors

- (void)setPendingApp:(SMAppModel *)newPendingApp
{
	if (newPendingApp == pendingApp) {
		return;
	}
	
	pendingApp = newPendingApp;
	if (nil != pendingApp) {
		[self setupAppInfoViewWithApp:pendingApp];
		[self setAppInfoViewShowing:YES];
	}
	
}

#pragma mark - Drag & Drop

- (void)fileDragView:(SMFileDragView *)dragView didReceiveFiles:(NSArray *)files
{	
	// Check for valid application
	
	SMAppModel *newApp = nil;
	
	for (NSString *path in files) {
		if ([path hasSuffix:@".zip"]) {
			newApp = [[SMSimDeployer defaultDeployer] unzipAppArchiveAtPath:path];
			if (nil != newApp) {
				break;
			}		
		}
		
		NSBundle *bundle = [NSBundle bundleWithPath:path];
		SMAppModel *appModel = [[SMAppModel alloc] initWithBundle:bundle];
				
		newApp = appModel;
		break;
	}
	
	if (nil != newApp) {
		self.pendingApp = newApp;
	} else {
		[self errorWithTitle:NSLocalizedString(@"Not a Valid Application", nil) 
					 message:NSLocalizedString(@"The provided file did not contain a valid simulator build.", nil)];
	}
	[self.fileDragView setHighlighted:NO];
}


@end
