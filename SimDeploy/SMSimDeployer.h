//
//  SMSimDeploy.h
//  SimDeploy
//
//  Created by Jerry Jones on 12/29/11.
//  Copyright (c) 2011 Spaceman Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMAppModel.h"
#import "SMSimulatorModel.h"
#import "iPhoneSimulator.h"

@interface SMSimDeployer : NSObject <NSURLDownloadDelegate, DTiPhoneSimulatorSessionDelegate>
{
	void (^downloadCompletionBlock)(BOOL);
	void (^percentCompleteBlock)(CGFloat);
	BOOL downloading;
	NSString *tempFile;
	NSUInteger bytesReceived;
	
	/** Instance used to find the required simulator platform SDK */
	DTiPhoneSimulatorSystemRoot *sdkRoot;
	DTiPhoneSimulatorSession *session;
}

//@property (nonatomic, retain) SMAppModel *downloadedApplication;
@property (nonatomic, retain) NSURLDownload *download;
@property (nonatomic, retain) NSURLResponse *downloadResponse;
@property (nonatomic, retain) NSArray *simulators;

+ (SMSimDeployer *)defaultDeployer;

- (void)launchiOSSimulator;
- (void)killiOSSimulator;
- (void)restartiOSSimulator;
- (void)launchApplication:(SMAppModel *)app;
- (void)killApp:(SMAppModel *)app;


- (void)downloadAppAtURL:(NSURL *)url percentComplete:(void(^)(CGFloat percentComplete))percentComplete completion:(void(^)(BOOL failed))completion;
- (SMAppModel *)unzipAppArchiveAtPath:(NSString *)path;
- (SMAppModel *)unzipAppArchive;

- (void)installApplication:(SMAppModel *)app clean:(BOOL)clean;
- (void)cleanup;

@end
