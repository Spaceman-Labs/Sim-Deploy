//
//  SMSimDeploy.m
//  SimDeploy
//
//  Created by Jerry Jones on 12/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SMSimDeployer.h"
#import "ZipArchive/ZipArchive.h"
#include <sys/types.h>
#include <sys/stat.h>

@implementation SMSimDeployer

@synthesize downloadedApplication;
@synthesize simulators;

+ (SMSimDeployer *)defaultDeployer {
	static dispatch_once_t pred;
	static SMSimDeployer *shared = nil;
	
	dispatch_once(&pred, ^{
		shared = [[SMSimDeployer alloc] init];
	});
	
	return shared;
}

#pragma mark - Simulator

- (void)launchiOSSimulator
{
	[[NSWorkspace sharedWorkspace] launchApplication:@"iPhone Simulator.app"];
}

- (void)killiOSSimulator
{
//	system("killall \"iPhone Simulator\"");
	NSArray *runningSims = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.iphonesimulator"];
	for (NSRunningApplication *app in runningSims) {
		[app terminate];
	}
}

- (void)restartiOSSimulator
{
	[self killiOSSimulator];
	double delayInSeconds = 2.0;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[self launchiOSSimulator];
	});

}

#pragma mark - Paths

- (NSString *)applicationDirectoryPath
{
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    NSFileManager *fm = [NSFileManager defaultManager];
	
    // Find the application support directory in the home directory.
	NSString *path = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
	
    // Append the bundle ID to the URL for the
	// Application Support directory
	path = [path stringByAppendingPathComponent:bundleID];
	
	// If the directory does not exist, this method creates it.
	// This method call works in Mac OS X 10.7 and later only.
	NSError	*theError = nil;
	[fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&theError];
	
    return path;
}

- (NSString *)tempArchivePath
{
	NSString *applicationDirectoryPath = [self applicationDirectoryPath];
	return [applicationDirectoryPath stringByAppendingPathComponent:@"temp.zip"];
}

- (void)cleanup
{
	NSString *applicationDirectoryPath = [self applicationDirectoryPath];
	NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:applicationDirectoryPath error:nil];
	for (NSString *path in contents) {
		NSString *fullPath = [applicationDirectoryPath stringByAppendingPathComponent:path];
		[[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil];
	}
}

- (void)resetTempArchivePath
{
	[[NSFileManager defaultManager] removeItemAtPath:tempFile error:nil];
	[tempFile release];
	tempFile = nil;
}

- (NSString *)tempApplicationPath
{
	if (nil != tempFile) {
		return tempFile;
	}
	
	NSString *applicationDirectoryPath = [self applicationDirectoryPath];
	CFUUIDRef	uuidObj = CFUUIDCreate(nil);//create a new UUID
	//get the string representation of the UUID
	NSString	*uuidString = (NSString*)CFUUIDCreateString(nil, uuidObj);
	CFRelease(uuidObj);
	
	tempFile = [[applicationDirectoryPath stringByAppendingPathComponent:uuidString] retain];
	
	return tempFile;
}

//- (void)deleteApplicationWithBundleIdentifier:(NSString *)bundleIdentifier
//{
//
//	NSArray *applicationPaths = [self applicationDirectories];
//	
//	for (NSString *path in applicationPaths) {
//		NSDictionary *plist = [self infoPlistForApplicationAtPath:path];
//		if (nil == plist) {
//			continue;
//		}
//		
//		NSString *thisBundleId = [plist objectForKey:@"CFBundleIdentifier"];
//		if ([thisBundleId isEqualToString:bundleIdentifier]) {
//			[[NSFileManager defaultManager] removeItemAtPath:path error:nil];
//			break;
//		}
//	}
//}

- (NSString *)simulatorDirectoryPath
{
	// Find the application support directory in the home directory.
	NSString *applicationSupport = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
	NSString *simulator = [applicationSupport stringByAppendingPathComponent:@"iPhone Simulator"];
	return simulator;
}

#pragma mark - Accessors

- (NSArray *)simulators
{
	if (nil != simulators) {
		return simulators;
	}
	
	NSMutableArray *sims = [NSMutableArray array];
	
	NSString *simulatorPath = [self simulatorDirectoryPath];
	NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:simulatorPath error:nil];
	for (NSString *path in contents) {
		BOOL directory = NO;
		NSString *fullPath = [simulatorPath stringByAppendingPathComponent:path];
		[[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&directory];
		
		if ([path isEqualToString:@"User"] || NO == directory) {
			continue;
		}
		

		SMSimulatorModel *sim = [[SMSimulatorModel alloc] initWithPath:fullPath];

		
		if (nil != sim) {
			[sims addObject:sim];
		}
	}
	self.simulators = sims;
	return simulators;
}

#pragma mark - 



- (void)downloadAppAtURL:(NSURL *)url completion:(void(^)(BOOL failed))completion
{
	[downloadCompletionBlock release];
	downloadCompletionBlock = [completion copy];
	
	[[NSFileManager defaultManager] removeItemAtPath:[self tempArchivePath] error:nil];
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0f];
	NSURLDownload *download = [[NSURLDownload alloc] initWithRequest:request delegate:self];
	[download setDestination:[self tempArchivePath] allowOverwrite:YES];
}

- (BOOL)unzipAppArchive
{	
	[self resetTempArchivePath];
	self.downloadedApplication = nil;
	
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *error = nil;
	ZipArchive *za = [[[ZipArchive alloc] init] autorelease];
	NSString *tempApplicationPath = [self tempApplicationPath];
	[fm removeItemAtPath:tempApplicationPath error:&error];
	
	if ([za UnzipOpenFile:[self tempArchivePath]]) {
		BOOL success = [za UnzipFileTo:tempApplicationPath overWrite:YES];
		if (NO == success) {
			NSLog(@"Invalid Zip");
			return NO;
		}
		[za UnzipCloseFile];
	} else {
		NSLog(@"Invalid Zip");
		return NO;
	}
	
	// Try to find an application bundle
	

	
	NSArray *contents = [fm contentsOfDirectoryAtPath:tempApplicationPath error:&error];
	for (NSString *path in contents) {
		NSString *fullPath = [tempApplicationPath stringByAppendingPathComponent:path];
		NSBundle *bundle = [NSBundle bundleWithPath:fullPath];
		
		if (nil == bundle) {
			continue;
		}
		
		SMAppModel *appModel = [[SMAppModel alloc] initWithBundle:bundle];
		if (nil != appModel) {
			self.downloadedApplication = appModel;
			
			// Some bug causes the executable to lose it's +x permissions. Do that here.
			NSString *executable = [appModel.infoDictionary objectForKey:@"CFBundleExecutable"];
			NSString *executablePath = [appModel.mainBundle.bundlePath stringByAppendingPathComponent:executable];
						
			const char *path = [executablePath cStringUsingEncoding:NSASCIIStringEncoding];
			
			/* Get the current mode. */
			struct stat buf;
			int error = stat(path, &buf);
			/* check and handle error */
			
			/* Make the file user-executable. */
			mode_t mode = buf.st_mode;
			mode |= S_IXUSR;
			error = chmod(path, mode);
			/* check and handle error */
			
			return YES;
		}
	}

	return NO;
}

#pragma mark - NSURLDownloadDelegate

- (void)downloadDidFinish:(NSURLDownload *)download
{
	if (nil != downloadCompletionBlock) {
		downloadCompletionBlock(NO);
	}
	
	[downloadCompletionBlock release];
	downloadCompletionBlock = nil;
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
	if (nil != downloadCompletionBlock) {
		downloadCompletionBlock(YES);
	}
	
	[downloadCompletionBlock release];
	downloadCompletionBlock = nil;
}

@end
