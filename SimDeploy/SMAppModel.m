//
//  SMSimApplication.m
//  SimDeploy
//
//  Created by Jerry Jones on 12/31/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SMAppModel.h"

@implementation SMAppModel

@synthesize guidPath, mainBundle, infoDictionary, name, identifier, version, marketingVersion;

- (id)initWithBundle:(NSBundle *)bundle;
{
	if (nil == bundle) {
		[self release];
		return nil;
	}
	
	self = [super init];
	if (nil == self) {
		return nil;
	}
	
	self.guidPath = [[bundle bundlePath] stringByDeletingLastPathComponent];
	self.mainBundle = bundle;
	self.infoDictionary = [bundle infoDictionary];
	
	self.name = [infoDictionary objectForKey:@"CFBundleDisplayName"];
	self.identifier = [infoDictionary objectForKey:@"CFBundleIdentifier"];
	self.version = [infoDictionary objectForKey:@"CFBundleVersion"];
	self.marketingVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
				 
	
	return self;
}

- (void)dealloc
{
	self.guidPath = nil;
	self.mainBundle = nil;
	self.infoDictionary = nil;
	self.name = nil;
	self.identifier = nil;
	self.version = nil;
	self.marketingVersion = nil;
	[super dealloc];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"{%@ %@ %@}", self.name, self.identifier, self.version];
}

@end
