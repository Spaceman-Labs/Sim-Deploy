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
	if (NO == shouldUpgrade) {
		NSLog(@"clean!!!!!");
	}
	
	SMAppModel *installedMatch = nil;
	for (SMAppModel *installedApp in self.userApplications) {
		if ([app.identifier isEqualToString:installedApp.identifier]) {
			installedMatch = installedApp;
			break;
		}
	}

	NSString *destinationGUIDPath = [self createDummyGUIDDirectoryWithName:[NSString stringWithFormat:@"%@-%@", app.identifier, app.version]];
	NSString *destinationBundlePath = [destinationGUIDPath stringByAppendingPathComponent:[app.mainBundle.bundlePath lastPathComponent]];
	
	// Remove old app
	if (nil != installedMatch) {
		NSError *error = nil;
		if (shouldUpgrade) {
			
			[[NSFileManager defaultManager] removeItemAtPath:destinationGUIDPath	error:&error];
			// Copy old guid to new guid location
			[[NSFileManager defaultManager] moveItemAtPath:installedMatch.guidPath toPath:destinationGUIDPath error:&error];
		}
		
		// Remove old item
		[[NSFileManager defaultManager] removeItemAtPath:installedMatch.guidPath error:&error];
		[(NSMutableArray *)self.userApplications removeObject:installedMatch];
	}
		
	NSError *error = nil;
	// Remove Old App
	[[NSFileManager defaultManager] removeItemAtPath:destinationBundlePath error:&error];
	
	[[NSFileManager defaultManager] copyItemAtPath:app.mainBundle.bundlePath toPath:destinationBundlePath error:&error];
	
	// Invalidate old application list
	self.userApplications = nil;
	
}

- (BOOL)isNewerThan:(SMSimulatorModel *)sim
{
	return ([self.version compare:sim.version options:NSNumericSearch] == NSOrderedDescending);
}

@end
