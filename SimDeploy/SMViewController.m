//
//  SMViewController.m
//  SimDeploy
//
//  Created by Jerry Jones on 1/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "SMViewController.h"
#import "NSAlert-OAExtensions.h"


@implementation SMViewController

@synthesize fileDragView;
@synthesize downloadTextField;
@synthesize downloadURLSheet;
@synthesize progressContainer;
@synthesize titleLabel;
@synthesize iconView;
@synthesize boxView;
@synthesize appInfoView;
@synthesize versionLabel;
@synthesize downloadButton;

- (void)awakeFromNib
{	
	self.downloadTextField.target = self;
	[self.downloadTextField setAction:@selector(downloadAppAtTextFieldURL:)];
	self.fileDragView.delegate = self;
	[self registerForDragAndDrop];

	CGRect frame = self.titleLabel.frame;
	frame.size.height = 100.0f;
	frame.origin.y -= 100.0f;
	self.titleLabel.frame = frame;
	
	[[self.titleLabel cell] setBackgroundStyle:NSBackgroundStyleRaised];
	
	CGColorRef someCGColor = NULL;
	CGColorSpaceRef genericRGBSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	if (genericRGBSpace != NULL)
	{
		float colorComponents[4] = {1.0f, 0.0f, 0.0f, 1.0f};
		someCGColor = CGColorCreate(genericRGBSpace, (CGFloat *)colorComponents);
		CGColorSpaceRelease(genericRGBSpace);
	}
	
	self.iconView.image = [NSImage imageNamed:@"Icon@2x.png"];
}

- (void)dealloc
{
	self.fileDragView = nil;
	self.downloadURLSheet = nil;
	self.downloadTextField = nil;
	self.progressContainer = nil;
	self.boxView = nil;
	self.appInfoView = nil;
	self.versionLabel = nil;
	self.downloadButton = nil;
	[super dealloc];
}

- (IBAction)downloadFromURL:(id)sender
{
	self.downloadButton.state = 1;
	
	[self deregisterForDragAndDrop];
	[[NSApplication sharedApplication] beginSheet:self.downloadURLSheet
								   modalForWindow:[NSApp mainWindow]
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
	[self registerForDragAndDrop];
	[NSApp endModalSession:modalSession];
    [NSApp endSheet:self.downloadURLSheet];
    [self.downloadURLSheet orderOut:nil];
}

- (void)downloadURLAtLocation:(NSString *)location
{
	[self.downloadTextField setStringValue:location];
	[self downloadAppAtTextFieldURL:self];
}

- (IBAction)downloadAppAtTextFieldURL:(id)sender
{
	
	NSString *urlPath = [self.downloadTextField stringValue];
	if (nil == urlPath || [urlPath length] < 1) {
		return;
	}
	
	NSURL *url = [NSURL URLWithString:urlPath];
	
	SMSimDeployer *deployer = [SMSimDeployer defaultDeployer];
	
	[deployer downloadAppAtURL:url 
					completion:^(BOOL failed) {
						if (failed) {
							NSAlert *alert = [[[NSAlert alloc] init] autorelease];
							[alert addButtonWithTitle:NSLocalizedString(@"Ok", @"Ok")];
							[alert setMessageText:NSLocalizedString(@"Download Failed", nil)];
							[alert setInformativeText:NSLocalizedString(@"Unable to download a simulator build, please check your URL and try again.", nil)];
							[alert setAlertStyle:NSCriticalAlertStyle];
							
							
							[alert beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
							return;
						}

						SMAppModel *downloadedApp = [deployer unzipAppArchive];
						
						if (nil == downloadedApp) {
							NSAlert *alert = [[[NSAlert alloc] init] autorelease];
							[alert addButtonWithTitle:NSLocalizedString(@"Ok", @"Ok")];
							[alert setMessageText:NSLocalizedString(@"No Valid Application Found", nil)];
							[alert setInformativeText:NSLocalizedString(@"The downloaded file did not contain a valid simulator build. Please check your URL and try again.", nil)];
							[alert setAlertStyle:NSCriticalAlertStyle];
							
							[alert beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
							return;
						}
						
						[self checkVersionsAndInstallApp:downloadedApp];
				   }];
}

- (void)checkVersionsAndInstallApp:(SMAppModel *)app
{
	SMSimDeployer *deployer = [SMSimDeployer defaultDeployer];
	
	NSArray *simulators = deployer.simulators;
	SMSimulatorModel *sim = [simulators lastObject];
	SMAppCompare appCompare = [sim compareInstalledAppsAgainstApp:app installedApp:nil];
	
	if (SMAppCompareSame == appCompare) {
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
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
							  [[SMSimDeployer defaultDeployer] installApplication:app];							  
							  [self showRestartAlertIfNeeded];
						  }
					  }];
		
	} else {
		[[SMSimDeployer defaultDeployer] installApplication:app];
		[self showRestartAlertIfNeeded];	
	}
	

}

#pragma mark - App Info View

- (void)setupAppInfoViewWithApp:(SMAppModel *)app
{
	self.titleLabel.stringValue = app.name;
	self.versionLabel.stringValue = [NSString stringWithFormat:@"Version: %@", app.marketingVersion];
	if (nil != app.iconPath) {
		self.iconView.image = [[[NSImage alloc] initWithContentsOfFile:app.iconPath] autorelease];
	} else {
		self.iconView.image = nil;
	}
}

#pragma mark -

- (void)showRestartAlertIfNeeded
{
	// Check for a running simulator
	
	NSArray *runningSims = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.iphonesimulator"];
	if ([runningSims count] < 1) {
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert addButtonWithTitle:NSLocalizedString(@"Launch Simulator", @"Launch Simulator")];
		[alert addButtonWithTitle:NSLocalizedString(@"No Thanks", @"No Thanks")];
		[alert setMessageText:NSLocalizedString(@"Success!", nil)];
		[alert setInformativeText:NSLocalizedString(@"Your builds were installed successfully! Would you like us to fire up the simulator for you?", nil)];
		[alert setAlertStyle:NSInformationalAlertStyle];
		[alert beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:[NSNull null]];
	}
	
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert addButtonWithTitle:NSLocalizedString(@"Restart Now", @"Restart Now")];
	[alert addButtonWithTitle:NSLocalizedString(@"Restart Later", @"Restart Later")];
	[alert setMessageText:NSLocalizedString(@"Success!", nil)];
	[alert setInformativeText:NSLocalizedString(@"Your builds were installed successfully, but the simulator is running and must be restarted before newly downloaded versions will be available.", nil)];
	[alert setAlertStyle:NSInformationalAlertStyle];
	[alert beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if ([NSNull null] == contextInfo) {
		if (returnCode == NSAlertFirstButtonReturn) {
			[[SMSimDeployer defaultDeployer] launchiOSSimulator];
		}		
	} else {
		if (returnCode == NSAlertFirstButtonReturn) {
			[[SMSimDeployer defaultDeployer] restartiOSSimulator];
		}
	}
}

- (void)registerForDragAndDrop
{
	[self.fileDragView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
}

- (void)deregisterForDragAndDrop
{
	[self.fileDragView unregisterDraggedTypes];
}

#pragma mark - Drag & Drop

- (void)fileDragView:(SMFileDragView *)dragView didReceiveFiles:(NSArray *)files
{
	// Check for valid application
	
	SMAppModel *newApp = nil;
	
	for (NSString *path in files) {
		NSBundle *bundle = [NSBundle bundleWithPath:path];
		SMAppModel *appModel = [[SMAppModel alloc] initWithBundle:bundle];
		
		if (nil == appModel) {
			return;
		}
		
		newApp = appModel;
		break;
	}
	
	if (nil != newApp) {
		[self setupAppInfoViewWithApp:newApp];
		[self.boxView addSubview:self.appInfoView];
		
//		[[SMSimDeployer defaultDeployer] installApplication:newApp];
//		[self showRestartAlertIfNeeded];
		return;
	}
}


@end
