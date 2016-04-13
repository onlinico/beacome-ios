//
//  AppDelegate.h
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 11/16/15.
//  Copyright © 2015 Onlinico. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AppDelegate : UIResponder <UIApplicationDelegate>


@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, assign) BOOL needsToProcessURLSchemeRequest;

- (void)extendBackgroundRunningTime;

- (void)processURLSchemeRequest;

@end

