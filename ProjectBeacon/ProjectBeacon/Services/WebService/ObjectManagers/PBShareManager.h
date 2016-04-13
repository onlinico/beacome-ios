//
// Created by Oleksandr Malyarenko on 2/4/16.
// Copyright (c) 2016 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBBaseObjectManager.h"


@class PBWebCard;


@interface PBShareManager : PBBaseObjectManager

- (void)acceptShare:(NSString *)shareGuid success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

- (void)shareCard:(PBWebCard *)card toUserEmail:(NSString *)userEmail withPermission:(BOOL)permission success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

- (void)changeSharingPermission:(BOOL)permission forShareGuid:(NSString *)shareGuid success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

- (void)deleteSharingForShareGuid:(NSString *)shareGuid success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

- (void)changeSharingPermission:(BOOL)permission forUserId:(NSInteger)userId cardGuid:(NSString *)cardGuid success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

- (void)deleteSharingForUserId:(NSInteger)userId cardGuid:(NSString *)cardGuid success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

@end