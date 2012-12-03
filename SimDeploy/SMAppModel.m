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
@synthesize executableName;
@dynamic executablePath;

- (id)initWithBundle:(NSBundle *)bundle;
{
	if (nil == bundle) {
		return nil;
	}
	
	NSString *infoPath = [[bundle bundlePath] stringByAppendingPathComponent:@"Info.plist"];
	NSDictionary *infoDict = [NSDictionary dictionaryWithContentsOfFile:infoPath];
	
	if (NO == [infoDict[@"DTPlatformName"] isEqualToString:@"iphonesimulator"]) {
		return nil;
	}
	
	self = [super init];
	if (nil == self) {
		return nil;
	}
	
	self.guidPath = [[bundle bundlePath] stringByDeletingLastPathComponent];
	self.mainBundle = bundle;
	self.infoDictionary = infoDict;
	
	self.name = infoDictionary[@"CFBundleDisplayName"];
	self.identifier = infoDictionary[@"CFBundleIdentifier"];
	self.version = infoDictionary[@"CFBundleVersion"];
	self.marketingVersion = infoDictionary[@"CFBundleShortVersionString"];
	self.executableName = infoDictionary[@"CFBundleExecutable"];
	
	// Find biggest icon file
	NSString *biggestIconPath = nil;
	NSSize biggestSize = NSMakeSize(0.0f, 0.0f);
	for (NSString *iconName in infoDictionary[@"CFBundleIconFiles"]) {
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
	}
	
	self.iconPath = biggestIconPath;
	
	return self;
}

- (void)dealloc
{
	if (self.deleteGUIDWhenFinished) {
		[[NSFileManager defaultManager] removeItemAtPath:self.guidPath error:nil];
	}
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"{%@ %@ %@}", self.name, self.identifier, self.version];
}

- (NSString *)executablePath
{
	
	return [[self.mainBundle bundlePath] stringByAppendingPathComponent:infoDictionary[@"CFBundleExecutable"]];
}

@end
