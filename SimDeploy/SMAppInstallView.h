//
//  SMAppInstallView.h
//  SimDeploy
//
//  Created by Jerry Jones on 1/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SMAppInstallView : NSView
{
	BOOL installDisabled;
}

@property (nonatomic, assign) BOOL installDisabled;
@property (nonatomic, retain) IBOutlet NSButton *installButton;

@end
