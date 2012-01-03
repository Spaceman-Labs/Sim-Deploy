//
//  SMAppDelegate.m
//  SimDeploy
//
//  Created by Jerry Jones on 12/30/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SMAppDelegate.h"

@implementation SMAppDelegate

@synthesize window = _window;
@synthesize viewController;

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
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
		
		[queryParams setObject:[[pair objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding: NSMacOSRomanStringEncoding]
						forKey:[pair objectAtIndex:0]]; 
	}
	
	NSString *fetchLocation = [queryParams objectForKey:@"url"];
	if (nil != fetchLocation) {
		[self.viewController downloadURLAtLocation:fetchLocation];
	}
	
	
}

@end
