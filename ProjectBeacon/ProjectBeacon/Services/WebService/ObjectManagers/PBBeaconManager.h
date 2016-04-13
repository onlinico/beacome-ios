//
// Created by Oleksandr Malyarenko on 12/9/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBBaseObjectManager.h"


@class PBWebBeacon;


@interface PBBeaconManager : PBBaseObjectManager


- (void)getBeaconsWithSuccess:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;
- (void)getBeaconByGuid:(NSString *)guid success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

- (void)getBeaconsByCardGuid:(NSString *)guid success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

- (void)postBeacon:(PBWebBeacon *)beacon success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

- (void)putBeacon:(PBWebBeacon *)beacon success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

- (void)deleteBeacon:(PBWebBeacon *)beacon success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

@end