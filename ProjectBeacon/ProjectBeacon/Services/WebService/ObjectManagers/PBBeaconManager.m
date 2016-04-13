//
// Created by Oleksandr Malyarenko on 12/9/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import "PBBeaconManager.h"
#import "PBWebBeacon.h"


@implementation PBBeaconManager {

}


- (void)getBeaconsWithSuccess:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self getObjectsAtPath:@"Beacons" parameters:nil success:success failure:failure];
}


- (void)getBeaconByGuid:(NSString *)guid success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self getObjectsAtPath:[NSString stringWithFormat:@"Beacons/%@", guid] parameters:nil success:success failure:failure];
}


- (void)getBeaconsByCardGuid:(NSString *)guid success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self getObjectsAtPath:[NSString stringWithFormat:@"Beacons/Card/%@", guid] parameters:nil success:success failure:failure];
}


- (void)postBeacon:(PBWebBeacon *)beacon success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self postObject:beacon path:@"Beacons" parameters:nil success:success failure:failure];
}


- (void)putBeacon:(PBWebBeacon *)beacon success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self putObject:beacon path:[NSString stringWithFormat:@"Beacons/%@", beacon.uid] parameters:nil success:success failure:failure];
}


- (void)deleteBeacon:(PBWebBeacon *)beacon success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self deleteObject:beacon path:[NSString stringWithFormat:@"Beacons/%@", beacon.uid] parameters:nil success:success failure:failure];
}


#pragma mark - Helper methods


- (void)setupResponseDescriptors {
    [super setupResponseDescriptors];

    RKResponseDescriptor *beaconsResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[PBWebBeacon mapping] method:RKRequestMethodAny pathPattern:@"Beacons" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    RKResponseDescriptor *beaconResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[PBWebBeacon mapping] method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    RKResponseDescriptor *beaconsCardResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[PBWebBeacon mapping] method:RKRequestMethodGET pathPattern:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    [self addResponseDescriptorsFromArray:@[beaconsResponseDescriptor, beaconResponseDescriptor, beaconsCardResponseDescriptor]];

}


- (void)setupRequestDescriptors {
    [super setupRequestDescriptors];

    RKRequestDescriptor *beaconRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:[PBWebBeacon requestMapping] objectClass:[PBWebBeacon class] rootKeyPath:nil method:RKRequestMethodAny];

    [self addRequestDescriptorsFromArray:@[beaconRequestDescriptor]];
}

@end