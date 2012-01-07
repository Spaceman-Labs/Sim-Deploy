//
//  SMSimApplication.m
//  SimDeploy
//
//  Created by Jerry Jones on 12/31/11.
//  Copyright (c) 2011 Spaceman Labs. All rights reserved.
//

#import "SMAppModel.h"

@implementation SMAppModel

@synthesize deleteGUIDWhenFinished, guidPath, mainBundle, infoDictionary, name, identifier, version, marketingVersion, iconPath, iconIsPreRendered;

- (id)initWithBundle:(NSBundle *)bundle;
{
	if (nil == bundle) {
		[self release];
		return nil;
	}
	
	if (NO == [[bundle.infoDictionary objectForKey:@"DTPlatformName"] isEqualToString:@"iphonesimulator"]) {
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
	
	// Find biggest icon file
	NSString *biggestIconPath = nil;
	NSSize biggestSize = NSMakeSize(0.0f, 0.0f);
	for (NSString *iconName in [infoDictionary objectForKey:@"CFBundleIconFiles"]) {
		NSString *path = [self.mainBundle.bundlePath stringByAppendingPathComponent:iconName];
		NSImage *image = [[NSImage alloc] initWithContentsOfFile:path];
		NSSize imageSize = [image size];
		
		NSString *nameWithoutExtension = [iconName stringByDeletingPathExtension];
		if ([nameWithoutExtension hasSuffix:@"@2x"]) {
			imageSize.width *= 2.0f;
			imageSize.height *= 2.0f;
		}
		
		if (imageSize.width > biggestSize.width || imageSize.height > biggestSize.height) {
			biggestIconPath = path;
			biggestSize = imageSize;
		}
		[image release];
	}
	
	self.iconPath = biggestIconPath;
	
	return self;
}

- (void)dealloc
{
	if (self.deleteGUIDWhenFinished) {
		[[NSFileManager defaultManager] removeItemAtPath:self.guidPath error:nil];
	}
	
	self.guidPath = nil;
	self.mainBundle = nil;
	self.infoDictionary = nil;
	self.name = nil;
	self.identifier = nil;
	self.version = nil;
	self.marketingVersion = nil;
	self.iconPath = nil;
	[super dealloc];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"{%@ %@ %@}", self.name, self.identifier, self.version];
}

@end
