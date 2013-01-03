//
//  SMAppDelegate.m
//  SimDeploy
//
//  Created by Jerry Jones on 12/30/11.
//  Copyright (c) 2011 Spaceman Labs. All rights reserved.
//

#import "SMAppDelegate.h"
#import "PFMoveApplication.h"

@implementation SMAppDelegate

@synthesize window = _window;
@synthesize viewController;

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
#ifndef DEBUG
	PFMoveToApplicationsFolderIfNecessary();
#endif
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[SMSimDeployer defaultDeployer];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[[SMSimDeployer defaultDeployer] cleanup];
}

- (void)handleURLEvent:(NSAppleEventDescriptor*)event withReplyEvent:(NSAppleEventDescriptor*)replyEvent
{
    NSString *urlString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
	NSURL *url = [NSURL URLWithString:urlString];
	
	NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
	NSArray *components = [[url query] componentsSeparatedByString:@"&"];
	
	for (NSString *component in components) {
		NSArray *pair = [component componentsSeparatedByString:@"="];
		
		queryParams[pair[0]] = [pair[1] stringByReplacingPercentEscapesUsingEncoding: NSMacOSRomanStringEncoding]; 
	}
	
	NSString *fetchLocation = queryParams[@"url"];
		
	if (nil != fetchLocation) {
		if (NO == [fetchLocation hasPrefix:@"http://"]) {
			fetchLocation = [NSString stringWithFormat:@"http://%@", fetchLocation];
		}

		[self.viewController downloadURLAtLocation:fetchLocation];
		return;
	}
	
	NSString *localFile = queryParams[@"file"];
	if (nil != localFile) {
		localFile = [localFile stringByExpandingTildeInPath];
		[self application:nil openFile:localFile];
	}

}

// Handle a file dropped on the dock icon
- (BOOL)application:(NSApplication *)sender openFile:(NSString *)path
{
	if ([path hasSuffix:@".zip"]) {
		SMAppModel *app = [[SMSimDeployer defaultDeployer] unzipAppArchiveAtPath:path];
		if (nil != app) {
			[self.viewController setupAppInfoViewWithApp:app];
			[self.viewController setAppInfoViewShowing:YES];
			return YES;
		}		
	}
	
	NSBundle *bundle = [NSBundle bundleWithPath:path];
	SMAppModel *appModel = [[SMAppModel alloc] initWithBundle:bundle];
	
	if (nil == appModel) {
		[self.viewController errorWithTitle:NSLocalizedString(@"Not a Valid Application", nil) 
									message:NSLocalizedString(@"The provided file did not contain a valid simulator build.", nil)];

	}
	
	if (nil != appModel) {
		[self.viewController setupAppInfoViewWithApp:appModel];
		return YES;
	}
	
	return YES;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

- (IBAction)openDocument:(id)sender
{
	NSOpenPanel *panel	= [NSOpenPanel openPanel];
	panel.delegate = self;
	[panel setAllowsMultipleSelection:NO];
	
	[panel beginSheetModalForWindow:[NSApp mainWindow]
				  completionHandler:^(NSInteger result) {
					  if (NSFileHandlingPanelOKButton == result) {
						  NSArray *urls = [panel URLs];
						  NSURL *url = [urls lastObject];
						  NSString *path = [url path];
						  [self application:nil openFile:path];
					  }
				  }];
}

- (BOOL)panel:(id)sender shouldEnableURL:(NSURL *)url
{
	
	NSString *filename = [url lastPathComponent];
	if ([filename hasSuffix:@".zip"] || [filename hasSuffix:@".app"]) {
		return YES;
	}
	
	// Allow Directories to be opened
	BOOL directory = NO;
	[[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:&directory];
	if (directory) {
		return YES;
	}
	
	return NO;
}

@end
