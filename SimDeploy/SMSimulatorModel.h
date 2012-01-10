//
//  SMSimulatorModel.h
//  SimDeploy
//
//  Created by Jerry Jones on 1/2/12.
//  Copyright (c) 2012 Spaceman Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMAppModel.h"

typedef enum SMAppCompare {
	SMAppCompareLessThan = 0,
	SMAppCompareGreaterThan,
	SMAppCompareSame,
	SMAppCompareNotInstalled,

} SMAppCompare;

@interface SMSimulatorModel : NSObject

@property (nonatomic, retain) NSString *path;	
@property (nonatomic, retain) NSString *version;
@property (nonatomic, retain) NSArray *userApplications;

- (id)initWithPath:(NSString *)path;
// Old app compared against provided app
- (SMAppCompare)compareInstalledAppsAgainstApp:(SMAppModel *)app installedApp:(SMAppModel **)appBuffer;
- (void)installApplication:(SMAppModel *)app upgradeIfPossible:(BOOL)shouldUpgrade;
- (BOOL)isNewerThan:(SMSimulatorModel *)sim;

@end
