//
// Created by Oleksandr Malyarenko on 11/16/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import "PBBluetoothPublisher.h"
#import "PBSettingsManager.h"
#import "PBError.h"


@interface PBBluetoothPublisher () <CBPeripheralManagerDelegate>


@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) CLBeaconRegion *region;
@property (nonatomic, assign) BOOL isPublishing;
@property (nonatomic, assign) BOOL isSettedUp;
@property (nonatomic, strong) NSString *beaconIdentifier;

@end


@implementation PBBluetoothPublisher {

}


- (void)setupPublisher {
    if (!self.isSettedUp) {
        PBSettingsManager *settings = [PBSettingsManager sharedManager];
        self.beaconIdentifier = settings.beaconIdentifier;
        NSUUID *uuid = nil;
        if (settings.deviceAsBeaconUUID) {
            uuid = [[NSUUID alloc] initWithUUIDString:settings.deviceAsBeaconUUID];
        }
        else {
            uuid = [NSUUID UUID];
            [settings setDeviceAsBeaconUUID:[uuid UUIDString]];
        }
        _advertisenmentUUID = uuid;
        _advertisenmentMajor = 0;
        _advertisenmentMinor = 0;
        _devicePower = -59;

        if (!self.peripheralManager) {
            self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
        }
        else {
            self.peripheralManager.delegate = self;
        }
        self.isSettedUp = YES;
    }

}


- (void)startAdvertising {
    [self setupPublisher];
    if (self.peripheralManager.state < CBPeripheralManagerStatePoweredOn) {
        NSError *error;
        switch (self.peripheralManager.state) {

            case CBPeripheralManagerStateUnknown: {
                error = [NSError errorWithDomain:kPBErrorDomain code:kPBBluetoothErrorUnknownCode userInfo:@{NSLocalizedDescriptionKey : [PBError localizedDescriptionForKey:kPBBluetoothErrorUnknown]}];
                break;
            }
            case CBPeripheralManagerStateResetting: {
                error = [NSError errorWithDomain:kPBErrorDomain code:kPBBluetoothErrorBluetoothIsResettingCode userInfo:@{NSLocalizedDescriptionKey : [PBError localizedDescriptionForKey:kPBBluetoothErrorBluetoothIsResetting]}];
                break;
            }
            case CBPeripheralManagerStateUnsupported: {
                error = [NSError errorWithDomain:kPBErrorDomain code:kPBBluetoothErrorPublishingNotSupportedCode userInfo:@{NSLocalizedDescriptionKey : [PBError localizedDescriptionForKey:kPBBluetoothErrorPublishingNotSupported]}];
                break;
            }
            case CBPeripheralManagerStateUnauthorized: {
                error = [NSError errorWithDomain:kPBErrorDomain code:kPBBluetoothErrorBluetoothIsNotAuthorizedCode userInfo:@{NSLocalizedDescriptionKey : [PBError localizedDescriptionForKey:kPBBluetoothErrorBluetoothIsNotAuthorized]}];
                break;
            }
            case CBPeripheralManagerStatePoweredOff: {
                (error = [NSError errorWithDomain:kPBErrorDomain code:kPBBluetoothErrorBluetoothIsOffCode userInfo:@{NSLocalizedDescriptionKey : [PBError localizedDescriptionForKey:kPBBluetoothErrorBluetoothIsOff]}]);
                break;
            }
            case CBPeripheralManagerStatePoweredOn:
                break;
        }
        [self.delegate bluetoothDidFailWithError:error];
        return;
    }

    [self.peripheralManager stopAdvertising];
    NSDictionary *peripheralData = nil;

    self.region = [[CLBeaconRegion alloc] initWithProximityUUID:self.advertisenmentUUID major:(CLBeaconMajorValue) self.advertisenmentMajor minor:(CLBeaconMinorValue) self.advertisenmentMinor identifier:self.beaconIdentifier];
    peripheralData = [self.region peripheralDataWithMeasuredPower:@(self.devicePower)];

    if (peripheralData) {
        [self.peripheralManager startAdvertising:peripheralData];
        self.isPublishing = YES;
    }

}


- (void)stopAdvertising {
    [self.peripheralManager stopAdvertising];
    self.isPublishing = NO;
}


- (BOOL)publisherStatus {
    return self.isPublishing;
}


- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    switch (peripheral.state) {

        case CBPeripheralManagerStateUnknown:
        case CBPeripheralManagerStateResetting:
        case CBPeripheralManagerStateUnsupported:
        case CBPeripheralManagerStateUnauthorized:
        case CBPeripheralManagerStatePoweredOff: {
            if (self.isPublishing) {
                [self stopAdvertising];
                [self.delegate bluetoothDidUpdateBluetoothStatus:NO];
            }
            break;
        }
        case CBPeripheralManagerStatePoweredOn: {
            if ([[PBSettingsManager sharedManager] isPublisherEnabled]) {
                [self startAdvertising];
                [self.delegate bluetoothDidUpdateBluetoothStatus:NO];
            }
            break;
        }
    }
}

@end