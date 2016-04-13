//
// Created by Oleksandr Malyarenko on 12/7/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>


@class PBBluetoothWatcher;


@protocol PBBluetoothDelegate <NSObject>


@required
- (void)bluetoothDidFailWithError:(NSError *)error;

- (void)bluetoothDidUpdateBluetoothStatus:(BOOL)status;

@optional
- (void)bluetoothWatcher:(PBBluetoothWatcher *)watcher didUpdateBeaconsWatchedInRange:(NSArray *)beacons;

- (void)bluetoothWatcher:(PBBluetoothWatcher *)watcher didUpdateBeaconsScannedInRange:(NSArray *)beacons;

@end