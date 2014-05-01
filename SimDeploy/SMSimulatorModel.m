//
//  SMSimulatorModel.m
//  SimDeploy
//
//  Created by Jerry Jones on 1/2/12.
//  Copyright (c) 2012 Spaceman Labs. All rights reserved.
//

#import "SMSimulatorModel.h"

@implementation SMSimulatorModel

@synthesize path, version, userApplications;

- (id)initWithPath:(NSString *)aPath
{
	if (nil == aPath) {
		[self release];
		return nil;
	}
	
	self = [super init];
	if (nil == self) {
		return nil;
	}
	
	self.path = aPath;
	self.version = [aPath lastPathComponent];

	return self;
}

- (void)dealloc
{
	self.path = nil;
	self.version = nil;
	self.userApplications = nil;
	
	[super dealloc];
}

- (NSString *)applicationsPath
{
	return [self.path stringByAppendingPathComponent:@"Applications"];
}

- (NSArray *)userApplications
{
	if (nil != userApplications) {
		return userApplications;
	}
	
	NSMutableArray *applications = [NSMutableArray array];
	NSString *simApplicationsPath = [self.path stringByAppendingPathComponent:@"Applications"];

	NSFileManager *fm = [NSFileManager defaultManager];
	NSArray *contents = [fm contentsOfDirectoryAtPath:simApplicationsPath error:nil];

	for (NSString *aPath in contents) {
		NSString *guidPath = [simApplicationsPath stringByAppendingPathComponent:aPath];
		
		BOOL directory = NO;
		[fm fileExistsAtPath:guidPath isDirectory:&directory];
		if (NO == directory) {
			continue;
		}
		
		NSArray *guidContents = [fm contentsOfDirectoryAtPath:guidPath error:nil];
		
		for (NSString *appBundlePath in guidContents) {
			NSString *fullPath = [guidPath stringByAppendingPathComponent:appBundlePath];
			NSBundle *bundle = [NSBundle bundleWithPath:fullPath];
			
			
			SMAppModel *appModel = [[SMAppModel alloc] initWithBundle:bundle];
			if (nil != appModel) {
				[applications addObject:appModel];
			}
			[appModel release];
		}
	}

	self.userApplications = applications;
	return applications;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"Simulator %@: %@", self.version, self.path];
}

#pragma mark

- (NSString *)createDummyGUIDDirectoryWithName:(NSString *)name
{
	NSString *aPath = [[self applicationsPath] stringByAppendingPathComponent:name];
	NSError *error = nil;
	[[NSFileManager defaultManager] createDirectoryAtPath:aPath withIntermediateDirectories:YES attributes:nil error:&error];
	return aPath;
}

- (SMAppCompare)compareInstalledAppsAgainstApp:(SMAppModel *)app installedApp:(SMAppModel **)appBuffer
{
	SMAppCompare result = SMAppCompareNotInstalled;
	SMAppModel *installedMatch = nil;
	for (SMAppModel *installedApp in self.userApplications) {
		if ([app.identifier isEqualToString:installedApp.identifier]) {
			installedMatch = installedApp;
			break;
		}
	}
	
	if (nil != installedMatch) {
		if ([installedMatch.version isEqualToString:app.version]) {
			result = SMAppCompareSame;
		} else {
			NSString *oldVersion = installedMatch.version;
			NSString *newVersion = app.version;
			BOOL newer = ([newVersion compare:oldVersion options:NSNumericSearch] != NSOrderedAscending);
			result = newer ? SMAppCompareLessThan : SMAppCompareGreaterThan;
		}		
	}	
	if (nil != appBuffer) {
		*appBuffer = installedMatch;
	}
	
	return result;

}

- (void)installApplication:(SMAppModel *)app upgradeIfPossible:(BOOL)shouldUpgrade
{	
	SMAppModel *installedMatch = nil;
	for (SMAppModel *installedApp in self.userApplications) {
		if ([app.identifier isEqualToString:installedApp.identifier]) {
			installedMatch = installedApp;
			break;
		}
	}

	NSString *destinationGUIDPath = [self createDummyGUIDDirectoryWithName:[NSString stringWithFormat:@"%@-%@", app.identifier, app.version]];
	NSString *destinationBundlePath = [destinationGUIDPath stringByAppendingPathComponent:[app.mainBundle.bundlePath lastPathComponent]];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *error = nil;
	
	if (NO == shouldUpgrade) {
		// Remove old directory
		BOOL pathsMatch = [installedMatch.guidPath isEqualToString:destinationGUIDPath];
		
		if (nil != installedMatch) {
			[fm removeItemAtPath:installedMatch.guidPath error:&error];
			if (nil != error) {
				NSLog(@"error: %@", error);
				error = nil;
			}
			
			// If the new app is the same version as the old, and we're not upgrading, then we're basically reinstalling.
			// This is fine, but code later expects the destination GUID to exist
			if (pathsMatch) {
				[fm createDirectoryAtPath:destinationGUIDPath withIntermediateDirectories:YES attributes:nil error:&error];
				if (nil != error) {
					NSLog(@"error: %@", error);
					error = nil;
				}
				
			}
		}
	} else {
		// Copy old contents to new guid directory
		if (nil != installedMatch) {
			// Remove new dummy GUID path, we'll copy the old directory to the new GUID
			[fm removeItemAtPath:destinationGUIDPath error:&error];
			if (nil != error) {
				NSLog(@"error: %@", error);
				error = nil;
			}
			
			// Remove Old App
			[fm removeItemAtPath:installedMatch.mainBundle.bundlePath error:&error];
			if (nil != error) {
				NSLog(@"error: %@", error);
				error = nil;
			}
			
			// Copy old GUID contents to new GUID path
			[fm copyItemAtPath:installedMatch.guidPath toPath:destinationGUIDPath error:&error];
			if (nil != error) {
				NSLog(@"error: %@", error);
				error = nil;
			}	
		}		
	}
	
	
	// Move App to new directory
	[fm copyItemAtPath:app.mainBundle.bundlePath toPath:destinationBundlePath error:&error];	
	if (nil != error) {
		NSLog(@"error: %@", error);
		error = nil;
	}
	
	// Create some initial subdirectories to mimic Xcode's setup
	for (NSString *subdir in @[@"tmp", @"Documents", @"Library/Caches"]) {
		NSString *tmpPath = [destinationGUIDPath stringByAppendingPathComponent:subdir];
		if (NO == [fm createDirectoryAtPath:tmpPath withIntermediateDirectories:YES attributes:nil error:&error]) {
			NSLog(@"Error creating directory %@: %@", tmpPath, error);
			error = nil;
		}
	}
	
	// Invalidate old application list
	self.userApplications = nil;
	
}

- (BOOL)isNewerThan:(SMSimulatorModel *)sim
{
	return ([self.version compare:sim.version options:NSNumericSearch] == NSOrderedDescending);
}

@end
