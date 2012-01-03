//
//  SMAppModel.h
//  SimDeploy
//
//  Created by Jerry Jones on 12/31/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMAppModel : NSObject

@property (nonatomic, retain) NSString *guidPath;
@property (nonatomic, retain) NSBundle *mainBundle;
@property (nonatomic, retain) NSDictionary *infoDictionary;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, retain) NSString *version;
@property (nonatomic, retain) NSString *marketingVersion;

- (id)initWithBundle:(NSBundle *)bundle;

@end
