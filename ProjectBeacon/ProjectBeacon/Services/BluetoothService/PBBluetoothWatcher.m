//
// Created by Oleksandr Malyarenko on 11/16/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import "PBBluetoothWatcher.h"
#import "PBSettingsManager.h"
#import "PBError.h"
#import "PBApplicationFacade.h"
#import "AppDelegate.h"
#import "Constants.h"


static CGFloat const kScannerTimer = 5.0;


@interface PBBluetoothWatcher () <CLLocationManagerDelegate>


@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) PBBBeaconRegionAny *beaconRegionAny;
@property (nonatomic, assign) BOOL isScanning;
@property (nonatomic, assign) BOOL isWatching;
@property (nonatomic, strong) NSMutableDictionary *beacons;
@property (nonatomic, strong) NSMutableDictionary *scannedBeacons;

@end


@implementation PBBluetoothWatcher {

}


- (instancetype)init {
    if (self = [super init]) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;

        NSOperatingSystemVersion systemVersion;
        systemVersion.majorVersion = 9;
        systemVersion.minorVersion = 0;
        systemVersion.patchVersion = 0;
        if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:systemVersion]) {
            self.locationManager.allowsBackgroundLocationUpdates = YES;
        }

        [self.locationManager requestAlwaysAuthorization];

        self.beacons = [NSMutableDictionary dictionary];
        self.scannedBeacons = [NSMutableDictionary dictionary];
        self.beaconRegionAny = [[PBBBeaconRegionAny alloc] initWithIdentifier:@"Any"];
        self.beaconRegionAny.notifyOnEntry = YES;
        self.beaconRegionAny.notifyOnExit = YES;
        self.beaconRegionAny.notifyEntryStateOnDisplay = YES;
    }

    return self;
}

- (CLLocation *)currentLocation {
    return [self.locationManager location];
}

#pragma mark - Main methods


- (void)startWatching {
    if (![CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]] && ![CLLocationManager isRangingAvailable]) {
        NSError *error = [NSError errorWithDomain:kPBErrorDomain code:kPBBluetoothErrorMonitoringNotAvailableCode userInfo:@{NSLocalizedDescriptionKey : [PBError localizedDescriptionForKey:kPBBluetoothErrorMonitoringNotAvailable]}];
        [self.delegate bluetoothDidFailWithError:error];
        return;
    }
    if (self.isScanning) {
        [self stopScanning];
    }
    if (!self.isWatching) {
        [self.beacons removeAllObjects];
        [self.locationManager startMonitoringForRegion:self.beaconRegionAny];
        [self.locationManager startRangingBeaconsInRegion:self.beaconRegionAny];
        [self.locationManager startUpdatingLocation];
        self.isWatching = YES;
    }
}


- (void)stopWatching {
    if (self.isWatching) {
        [self.locationManager stopMonitoringForRegion:self.beaconRegionAny];
        [self.locationManager stopRangingBeaconsInRegion:self.beaconRegionAny];
        self.isWatching = NO;

    }

}


- (void)startScanning {
    if (![CLLocationManager isRangingAvailable]) {
        return;
    }
    [self stopWatching];
    if (!self.isScanning) {
        [self.scannedBeacons removeAllObjects];
        [self.locationManager startRangingBeaconsInRegion:self.beaconRegionAny];
        self.isScanning = YES;

        [NSTimer scheduledTimerWithTimeInterval:kScannerTimer target:self selector:@selector(stopScanning) userInfo:nil repeats:NO];
    }

}


- (void)stopScanning {
    if (self.isScanning) {
        [self.locationManager stopRangingBeaconsInRegion:self.beaconRegionAny];
        self.isScanning = NO;
    }
    if ([[PBSettingsManager sharedManager] isWatcherEnabled]) {
        [self startWatching];
    }

}


- (BOOL)watcherStatus {
    return self.isWatching;
}


- (BOOL)scannerStatus {
    return self.isScanning;
}


#pragma mark - CLLocation delegate methods


- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    DDLogInfo(@"locationManagerDidChangeAuthorizationStatus: %d", status);
}


- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    DDLogInfo(@"locationManagerDidStartMonitoringForRegion: %@", region);
}


- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region {
    if (self.isScanning) {
        BOOL isChanged = NO;
        for (CLBeacon *beacon in beacons) {
            NSString *uuid = [beacon.proximityUUID UUIDString];
            if (!self.scannedBeacons[uuid]) {
                self.scannedBeacons[uuid] = beacon;
                isChanged = YES;
            }
        }
        if (isChanged) {
            [self.delegate bluetoothWatcher:self didUpdateBeaconsScannedInRange:self.scannedBeacons.allValues];
        }
    }
    if (self.isWatching) {
        __block BOOL isChanged = NO;
        __block NSMutableArray *newUids = [NSMutableArray array];
        [beacons enumerateObjectsUsingBlock:^(CLBeacon *beacon, NSUInteger index, BOOL *stop) {
            NSString *uuid = [beacon.proximityUUID UUIDString];
            [newUids addObject:uuid];
        }];
        [[PBApplicationFacade sharedManager] compareOldUids:self.beacons.allKeys withNewUids:newUids result:^(NSArray *arrayForAdd, NSArray *arrayForDelete) {
            [arrayForDelete enumerateObjectsUsingBlock:^(NSString *uid, NSUInteger index, BOOL *stop) {
                [self.beacons removeObjectForKey:uid];
                isChanged = YES;
            }];
            [arrayForAdd enumerateObjectsUsingBlock:^(NSString *uid, NSUInteger index, BOOL *stop) {
                [beacons enumerateObjectsUsingBlock:^(CLBeacon *beacon, NSUInteger inIndex, BOOL *inStop) {
                    NSString *uuid = [beacon.proximityUUID UUIDString];
                    if ([uid isEqualToString:uuid] && beacon.rssi != 0) {
                        if (!self.beacons[uuid]) {
                            self.beacons[uuid] = beacon;
                            isChanged = YES;
                        }
                        else{
                            self.beacons[uuid] = beacon;
                        }
                        *inStop = YES;
                    }
                }];
            }];
            if (isChanged) {
                [self.delegate bluetoothWatcher:self didUpdateBeaconsWatchedInRange:self.beacons.allValues];
            }
        }];
    }

}


- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    DDLogInfo(@"ENTER REGION %@", region.identifier);
    if ([region isMemberOfClass:[CLBeaconRegion class]]) {
        [((AppDelegate *) [UIApplication sharedApplication].delegate) extendBackgroundRunningTime];
        NSString *beaconUUID = ((CLBeaconRegion *) region).proximityUUID.UUIDString;
        if (!self.beacons[beaconUUID] && [UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
            [self.locationManager startRangingBeaconsInRegion:(CLBeaconRegion *) region];
        }
    }
}


- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    DDLogInfo(@"EXIT REGION %@", region.identifier);
    if ([region isMemberOfClass:[CLBeaconRegion class]]) {
        [((AppDelegate *) [UIApplication sharedApplication].delegate) extendBackgroundRunningTime];
        NSString *beaconUUID = ((CLBeaconRegion *) region).proximityUUID.UUIDString;
        if (self.isWatching) {
            [self.beacons removeObjectForKey:beaconUUID];
            [self.delegate bluetoothWatcher:self didUpdateBeaconsWatchedInRange:self.beacons.allValues];
        }
        if (self.isScanning) {
            [self.scannedBeacons removeObjectForKey:beaconUUID];
            [self.delegate bluetoothWatcher:self didUpdateBeaconsScannedInRange:self.scannedBeacons.allValues];
        }
    }
}


- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error {
    DDLogError(@"locationManager:%@ rangingBeaconsDidFailForRegion:%@ withError:%@", manager, region, error);
    self.isScanning = NO;
    self.isWatching = NO;
    NSError *bwError = [NSError errorWithDomain:kPBErrorDomain code:kPBBluetoothErrorRangingNotAvailableCode userInfo:@{NSLocalizedDescriptionKey : [PBError localizedDescriptionForKey:kPBBluetoothErrorRangingNotAvailable]}];
    [self.delegate bluetoothDidFailWithError:bwError];
}

@end