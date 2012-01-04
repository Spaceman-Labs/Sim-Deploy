//
//  SMViewController.m
//  SimDeploy
//
//  Created by Jerry Jones on 1/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SMViewController.h"
#import "NSAlert-OAExtensions.h"

@implementation SMViewController

@synthesize view;
@synthesize simulatorIsRunning;
@synthesize textField;
@synthesize appNameLabel;
@synthesize appVersionLabel;
@synthesize confirmSheet;
@synthesize restartSheet;
@synthesize progressContainer;

- (void)awakeFromNib
{	
	self.textField.target = self;
	[self.textField setAction:@selector(downloadAppAtTextFieldURL:)];
	[self.view registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
	self.view.delegate = self;
}

- (void)dealloc
{
	self.view = nil;
	self.confirmSheet = nil;
	self.restartSheet = nil;
	self.textField = nil;
	self.appNameLabel = nil;
	self.appVersionLabel = nil;
	self.progressContainer = nil;
	[super dealloc];
}

- (IBAction)resetButton:(id)sender
{
	
}

- (void)downloadURLAtLocation:(NSString *)location
{
	[self.textField setStringValue:location];
	[self downloadAppAtTextFieldURL:self];
}

- (IBAction)downloadAppAtTextFieldURL:(id)sender
{
	NSString *urlPath = [self.textField stringValue];
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
		[[SMSimDeployer defaultDeployer] installApplication:newApp];
		[self showRestartAlertIfNeeded];
		return;
	}
}


@end
