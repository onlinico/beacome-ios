//
// Created by Oleksandr Malyarenko on 12/2/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>


@interface PBSettingsManager : NSObject


@property (nonatomic, assign) BOOL firstLaunch;
@property (nonatomic, assign) NSInteger lastSessionUserId;
@property (nonatomic, strong) NSString *lastSessionUserToken;
@property (nonatomic, strong) NSString *lastSessionUserAuthProvider;
@property (nonatomic, strong) NSString *deviceAsBeaconUUID;
@property (nonatomic, strong) NSString *beaconIdentifier;
@property (nonatomic, assign) BOOL isPublisherEnabled;
@property (nonatomic, assign) BOOL isWatcherEnabled;

+ (id)sharedManager;

@end