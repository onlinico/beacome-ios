//
// Created by Oleksandr Malyarenko on 11/16/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBBBeaconRegionAny.h"
#import "PBBUtils.h"
#import "PBBluetoothDelegate.h"


@interface PBBluetoothWatcher : NSObject


@property (nonatomic, assign) id <PBBluetoothDelegate> delegate;

@property (nonatomic, strong, readonly) CLLocation *currentLocation;

- (void)startWatching;

- (void)stopWatching;

- (void)startScanning;

- (void)stopScanning;

- (BOOL)watcherStatus;

- (BOOL)scannerStatus;

@end