//
//  SMSimDeploy.m
//  SimDeploy
//
//  Created by Jerry Jones on 12/29/11.
//  Copyright (c) 2011 Spaceman Labs. All rights reserved.
//

#import "SMSimDeployer.h"
#import "ZipArchive/ZipArchive.h"
#include <sys/types.h>
#include <sys/stat.h>
#import <ScriptingBridge/ScriptingBridge.h>

/* App bundle ID. Used to request that the simulator be brought to the foreground */
#define SIM_APP_BUNDLE_ID @"com.apple.iphonesimulator"

/* Load a class from the runtime-loaded iPhoneSimulatorRemoteClient framework */
#define C(name) NSClassFromString(@"" #name)



@implementation SMSimDeployer

@synthesize download;
@synthesize simulators;
@synthesize downloadResponse;
@synthesize sdkRoot;

+ (SMSimDeployer *)defaultDeployer {
	static dispatch_once_t pred;
	static SMSimDeployer *shared = nil;
	
	dispatch_once(&pred, ^{
		shared = [[SMSimDeployer alloc] init];
	});
	
	return shared;
}

#pragma mark - Simulator

- (id)init
{
	self = [super init];
	if (nil == self) {
		return nil;
	}
	

	NSArray *roots = [DTiPhoneSimulatorSystemRoot knownRoots];
	for (DTiPhoneSimulatorSystemRoot *root in roots) {
		if (nil == sdkRoot) {
			self.sdkRoot = root;
			continue;
		}
		
		NSString *oldVersion = [sdkRoot sdkVersion];
		NSString *newVersion = [root sdkVersion];
		BOOL newer = ([newVersion compare:oldVersion options:NSNumericSearch] != NSOrderedAscending);
		
		if (newer) {
			self.sdkRoot = root;
		}		
	}

	
	return self;
}

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


- (void)launchApplication:(SMAppModel *)app
{
	if (nil == app) {
		return;
	}
	
	[self killiOSSimulator];
	
	if (nil != session) {
//		[session requestEndWithTimeout:0];
		[session release];
		session = nil;
	}
	
	double delayInSeconds = 2.0;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		DTiPhoneSimulatorApplicationSpecifier *appSpec;
		DTiPhoneSimulatorSessionConfig *config;
		NSError *error;
		
		/* Create the app specifier */
//		NSLog(@"launch app: %@", app.mainBundle.bundlePath);
		appSpec = [DTiPhoneSimulatorApplicationSpecifier specifierWithApplicationPath: app.mainBundle.bundlePath];
		if (appSpec == nil) {
			NSLog(@"Could not load application specification for %@", app.mainBundle.bundlePath);
			return;
		}
		
		/* Set up the session configuration */
		config = [[[DTiPhoneSimulatorSessionConfig alloc] init] autorelease];
		[config setApplicationToSimulateOnStart: appSpec];
		[config setSimulatedSystemRoot: sdkRoot];
		[config setSimulatedApplicationShouldWaitForDebugger: NO];
		
		[config setSimulatedApplicationLaunchArgs:[NSArray array]];
		[config setSimulatedApplicationLaunchEnvironment:[[NSProcessInfo processInfo] environment]];
		
		[config setLocalizedClientName:@"Sim Deploy"];
		
		// this was introduced in 3.2 of SDK
		if ([config respondsToSelector:@selector(setSimulatedDeviceFamily:)])
		{
			//		if (family == nil)
			//		{
			//			family = @"iphone";
			//		}
			
			//		nsprintf(@"using device family %@",family);
			
			//		if ([family isEqualToString:@"ipad"])
			//		{
			//			[config setSimulatedDeviceFamily:[NSNumber numberWithInt:2]];
			//		}
			//		else
			//		{
			//			[config setSimulatedDeviceFamily:[NSNumber numberWithInt:1]];
			//		}
			
			[config setSimulatedDeviceFamily:[NSNumber numberWithInt:2]];
		}
		
		/* Start the session */
		session = [[DTiPhoneSimulatorSession alloc] init];
		[session setDelegate: self];
		[session setSimulatedApplicationPID: [NSNumber numberWithInt: 35]];
		//	if (uuid!=nil)
		//	{
		//		[session setUuid:uuid];
		//	}
		
		if (![session requestStartWithConfig:config timeout:35 error:&error]) {
			NSLog(@"Could not start simulator session: %@", error);
		}
	});
}

- (void)killApp:(SMAppModel *)app
{
	NSString *command = [NSString stringWithFormat:@"killall %@", app.executablePath];
	 (void)system([command cStringUsingEncoding:NSASCIIStringEncoding]);
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

- (void)deleteTempFile
{
	[[NSFileManager defaultManager] removeItemAtPath:tempFile error:nil];
	[tempFile release];
	tempFile = nil;
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
	
	SMSimulatorModel *sim1 = nil;
	SMSimulatorModel *sim2 = nil;
	
	
	NSString *simulatorPath = [self simulatorDirectoryPath];
	NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:simulatorPath error:nil];
	for (NSString *path in contents) {
		NSString *fullPath = [simulatorPath stringByAppendingPathComponent:path];
		
		// Check for preferences to determine if the simulator is valid
		NSString *springboardPlistPath = [fullPath stringByAppendingPathComponent:@"Library/Preferences/com.apple.springboard.plist"];
		if (NO == [[NSFileManager defaultManager] fileExistsAtPath:springboardPlistPath isDirectory:NULL]) {
			continue;
		}

		SMSimulatorModel *sim = [[SMSimulatorModel alloc] initWithPath:fullPath];
		if (nil == sim) {
			continue;
		}
		
		if (nil == sim1) {
			sim1 = sim;
		} else if (nil == sim2) {
			if ([sim isNewerThan:sim1]) {
				sim2 = sim;
			} else {
				sim2 = sim1;
				sim1 = sim;				
			}
		} else {
			if ([sim isNewerThan:sim2]) {
				sim1 = sim2;
				sim2 = sim;
			}
		}
	}
	
	NSArray *foundSims = [NSArray arrayWithObjects:sim1, sim2, nil];
	
	self.simulators = foundSims;
	return foundSims;
}

#pragma mark - 



- (void)downloadAppAtURL:(NSURL *)url percentComplete:(void(^)(CGFloat percentComplete))percentComplete completion:(void(^)(BOOL failed))completion
{
	[downloadCompletionBlock release];
	downloadCompletionBlock = [completion copy];
	
	[percentCompleteBlock release];
	percentCompleteBlock = [percentComplete copy];
	
	[self deleteTempFile];
	
	[[NSFileManager defaultManager] removeItemAtPath:[self tempArchivePath] error:nil];
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0f];
	self.download = [[[NSURLDownload alloc] initWithRequest:request delegate:self] autorelease];
	[download setDestination:[self tempArchivePath] allowOverwrite:YES];
}

- (SMAppModel *)unzipAppArchive
{
	return [self unzipAppArchiveAtPath:[self tempArchivePath]];
}

- (SMAppModel *)unzipAppArchiveAtPath:(NSString *)path
{	
//	[self resetTempArchivePath];
//	self.downloadedApplication = nil;
	
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *error = nil;
	ZipArchive *za = [[[ZipArchive alloc] init] autorelease];
	NSString *tempApplicationPath = [self tempApplicationPath];
	[fm removeItemAtPath:tempApplicationPath error:&error];
	
	if ([za UnzipOpenFile:path]) {
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
			[appModel setDeleteGUIDWhenFinished:YES];
			
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
			
			return appModel;
		}
	}

	return NO;
}

- (void)finishedInstallingApplication
{	
	if (installQueue.operationCount > 0) {
//		NSLog(@"too many pending: %li", installQueue.operationCount);
		return;
	}
	
	[installQueue release];
	installQueue = nil;
	
	if (nil != installCompletion) {
		dispatch_async(dispatch_get_main_queue(), installCompletion);
		[installCompletion release];
		installCompletion = nil;
	}
	
	
}

- (void)installApplication:(SMAppModel *)app clean:(BOOL)clean completion:(void(^)(void))completion
{
	if (nil != installQueue) {
		return;
	}
		
	installQueue = [[NSOperationQueue alloc] init];
	[installQueue setName:@"com.spacemanlabs.simdeploy.install"];
	
	[installCompletion release];
	installCompletion = [completion copy];
	
	for (SMSimulatorModel *sim in self.simulators) {
		[installQueue addOperationWithBlock:^{
			[sim installApplication:app upgradeIfPossible:!clean];
			[[NSOperationQueue mainQueue] addOperationWithBlock:^{
				[self finishedInstallingApplication];
			}];
		}];
	}
}

#pragma mark - NSURLDownloadDelegate

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response
{
    // Reset the progress, this might be called multiple times.
    // bytesReceived is an instance variable defined elsewhere.
    bytesReceived = 0;
	
    // Retain the response to use later.
	self.downloadResponse = nil;
    [self setDownloadResponse:response];
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(NSUInteger)length
{
	long long expectedLength = [[self downloadResponse] expectedContentLength];
	
    bytesReceived = bytesReceived + length;
	
    if (expectedLength != NSURLResponseUnknownLength) {
        // If the expected content length is
        // available, display percent complete.
        CGFloat percentComplete = (bytesReceived/(CGFloat)expectedLength)*100.0;
		
		if (nil != percentCompleteBlock) {
			percentCompleteBlock(percentComplete);
		}
    } else {
        // If the expected content length is
        // unknown, just log the progress.
		if (nil != percentCompleteBlock) {
			percentCompleteBlock(-1.0f);
		}
//        NSLog(@"Bytes received - %i",bytesReceived);
    }	
}

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

#pragma mark - Simulator

// from DTiPhoneSimulatorSessionDelegate protocol
- (void) session: (DTiPhoneSimulatorSession *) aSession didEndWithError: (NSError *) error {
    // Do we care about this?
    NSLog(@"Did end with error: %@", error);
	[session release];
	session = nil;
}

// from DTiPhoneSimulatorSessionDelegate protocol
- (void) session: (DTiPhoneSimulatorSession *)aSession didStart: (BOOL) started withError: (NSError *) error {
    /* If the application starts successfully, we can exit */
    if (started) {
//        NSLog(@"Did start app %@ successfully, exiting", _app.path);
		
        /* Bring simulator to foreground */
        [[SBApplication applicationWithBundleIdentifier:SIM_APP_BUNDLE_ID] activate];
		
        /* Exit */
//        [[NSApplication sharedApplication] terminate: self];
        return;
    } else {
		NSLog(@"Error starting simulator: %@", error);
		[session release];
		session = nil;
//		[self restartiOSSimulator];
	}
	
//    /* Otherwise, an error occured. Inform the user. */
//    NSLog(@"Simulator session did not start: %@", error);
//    NSString *text = NSLocalizedString(@"The iPhone Simulator could not be started. If another Simulator application "
//                                       "is currently running, please close the Simulator and try again.", 
//                                       @"Simulator error alert info");
//    [self displayLaunchError: text];
}


@end
